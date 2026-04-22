import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { CheckCircle2, Trash2, Loader2, Search, MapPin, Building2, ExternalLink, Filter, RefreshCcw } from 'lucide-react';

export const PropertyModeration = () => {
  const [properties, setProperties] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [processingId, setProcessingId] = useState<string | null>(null);

  const fetchProperties = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('properties')
        .select(`
          *,
          property_images(*),
          profiles(full_name)
        `)
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      setProperties(data || []);
    } catch (e) {
      console.error("Error fetching properties:", e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProperties();
  }, []);

  const handleApprove = async (id: string) => {
    setProcessingId(id);
    try {
      await supabase
        .from('properties')
        .update({ status: 'available' })
        .eq('id', id);

      setProperties(prev => prev.map(p => p.id === id ? { ...p, status: 'available' } : p));
    } catch (error) {
      console.error("Error updating property status:", error);
      alert("Failed to update status");
    } finally {
      setProcessingId(null);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to permanently delete this property listing?")) return;
    
    setProcessingId(id);
    try {
      await supabase.from('property_images').delete().eq('property_id', id);
      await supabase.from('properties').delete().eq('id', id);
      
      setProperties(prev => prev.filter(p => p.id !== id));
    } catch (e) {
      console.error(e);
      alert("Failed to delete property");
    } finally {
      setProcessingId(null);
    }
  };

  const getMainImage = (p: any) => {
    if (p.property_images && p.property_images.length > 0) {
      return p.property_images[0].image_url;
    }
    return 'https://via.placeholder.com/300?text=No+Image';
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'available': 
        return <div className="px-2.5 py-1 bg-green-500/10 text-green-500 rounded-lg text-[9px] font-black uppercase tracking-widest border border-green-500/10">Active Listing</div>;
      case 'booked': 
        return <div className="px-2.5 py-1 bg-orange-500/10 text-orange-500 rounded-lg text-[9px] font-black uppercase tracking-widest border border-orange-500/10">Secured</div>;
      case 'rejected': 
        return <div className="px-2.5 py-1 bg-red-500/10 text-red-500 rounded-lg text-[9px] font-black uppercase tracking-widest border border-red-500/10">Flagged</div>;
      default: 
        return <div className="px-2.5 py-1 bg-brand/10 text-brand rounded-lg text-[9px] font-black uppercase tracking-widest border border-brand/10">In Review</div>;
    }
  };

  return (
    <div className="p-10 max-w-[1600px] mx-auto w-full flex-1 h-full overflow-y-auto bg-[#F9FAFB]/50">
      <motion.div 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col md:flex-row md:items-center justify-between mb-12 gap-8"
      >
        <div>
          <div className="flex items-center gap-4 mb-2">
            <h2 className="text-4xl font-brand font-black text-obsidian tracking-tighter">Inventory Guard</h2>
            <div className="px-3 py-1 bg-obsidian text-white text-[9px] font-black uppercase tracking-[0.2em] rounded-md">Total: {properties.length}</div>
          </div>
          <p className="text-gray-400 font-medium text-sm">Validating asset integrity and market compliance across the Khozna ecosystem.</p>
        </div>
        
        <div className="flex items-center gap-4">
           <button onClick={fetchProperties} className="px-6 py-3.5 bg-white border border-gray-100 rounded-2xl hover:bg-gray-50 flex items-center gap-3 font-black shadow-sm transition-all text-xs uppercase tracking-widest group">
             <RefreshCcw size={16} className="text-gray-400 group-hover:rotate-180 transition-transform duration-700" /> 
             Refresh
           </button>
           <button className="p-3.5 bg-white border border-gray-100 rounded-2xl text-gray-400 hover:text-obsidian transition-all shadow-sm">
             <Filter size={18} />
           </button>
        </div>
      </motion.div>

      {loading ? (
        <div className="flex justify-center items-center py-48">
          <div className="w-12 h-12 border-4 border-brand/10 border-t-brand rounded-full animate-spin" />
        </div>
      ) : properties.length === 0 ? (
        <div className="text-center py-48 bg-white border border-dashed border-gray-200 rounded-[3rem] shadow-xl shadow-gray-100/50">
           <Building2 size={64} className="mx-auto text-gray-100 mb-6" />
           <h3 className="text-xl font-brand font-black text-obsidian uppercase tracking-widest">Zero Assets Detected</h3>
           <p className="text-gray-400 mt-2 font-medium">Platform inventory is currently offline or filtered.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">
          <AnimatePresence mode="popLayout">
            {properties.map((p, idx) => (
              <motion.div 
                key={p.id} 
                layout
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.95 }}
                transition={{ delay: idx * 0.05 }}
                className="bg-white border border-gray-100 rounded-[2.5rem] p-6 shadow-sm hover:shadow-2xl hover:shadow-gray-200/50 transition-all flex flex-col md:flex-row gap-8 group"
              >
                <div className="h-48 w-full md:w-48 flex-shrink-0 bg-gray-100 rounded-[1.75rem] overflow-hidden border border-gray-50 relative group/img">
                  <img src={getMainImage(p)} alt="Property" className="w-full h-full object-cover transition-transform duration-700 group-hover/img:scale-110" />
                  <div className="absolute top-4 left-4 z-10">
                    {getStatusBadge(p.status)}
                  </div>
                  <div className="absolute inset-0 bg-gradient-to-t from-obsidian/40 to-transparent opacity-0 group-hover/img:opacity-100 transition-opacity" />
                </div>
                
                <div className="flex-1 flex flex-col justify-between py-2">
                  <div>
                    <div className="flex items-start justify-between mb-2">
                      <h3 className="text-xl font-brand font-black text-obsidian leading-tight line-clamp-2 pr-4">{p.title}</h3>
                      <button className="text-gray-300 hover:text-brand transition-colors"><ExternalLink size={16} /></button>
                    </div>
                    
                    <div className="space-y-2 mt-4">
                      <div className="flex items-center gap-2.5 text-gray-400 font-bold text-[10px] uppercase tracking-widest">
                        <MapPin size={14} className="text-brand opacity-40" />
                        <span>{p.area_name}, {p.city}</span>
                      </div>
                      <div className="flex items-center gap-2.5 text-gray-400 font-bold text-[10px] uppercase tracking-widest">
                        <Building2 size={14} className="text-brand opacity-40" />
                        <span>Proprietor: <span className="text-obsidian">{p.profiles?.full_name || 'Anonymous'}</span></span>
                      </div>
                    </div>
                    
                    <div className="mt-6 flex items-baseline gap-1">
                      <span className="text-[10px] font-black text-gray-400 uppercase tracking-widest mr-1">Valuation:</span>
                      <span className="text-2xl font-brand font-black text-brand tracking-tighter">रू {p.price}</span>
                      <span className="text-[10px] font-bold text-gray-400">/ Total</span>
                    </div>
                  </div>
                  
                  <div className="flex gap-3 mt-8">
                    {p.status !== 'available' && (
                      <button 
                        onClick={() => handleApprove(p.id)}
                        disabled={processingId === p.id}
                        className="flex-1 bg-brand text-white font-black py-3.5 rounded-xl flex items-center justify-center gap-2 shadow-lg shadow-brand/10 hover:shadow-brand/30 hover:-translate-y-0.5 active:scale-95 transition-all disabled:opacity-50 text-[10px] uppercase tracking-[0.2em]"
                      >
                        {processingId === p.id ? <Loader2 className="animate-spin" size={16} /> : <CheckCircle2 size={16} />}
                        Approve
                      </button>
                    )}
                    
                    <button 
                      onClick={() => handleDelete(p.id)}
                      disabled={processingId === p.id}
                      className="flex-1 bg-red-500/5 text-red-500 font-black py-3.5 rounded-xl border border-red-500/10 flex items-center justify-center gap-2 hover:bg-red-500 hover:text-white transition-all disabled:opacity-50 active:scale-95 text-[10px] uppercase tracking-[0.2em]"
                    >
                      {processingId === p.id ? <Loader2 className="animate-spin" size={16} /> : <Trash2 size={16} />}
                      Purge
                    </button>
                  </div>
                </div>

              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}
    </div>
  );
};
