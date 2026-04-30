import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { CheckCircle2, Trash2, Loader2, MapPin, Building2, ExternalLink, Filter, RefreshCcw, Tag } from 'lucide-react';

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


  return (
    <div className="flex-1 overflow-y-auto bg-[#FBFBF9]">
      <div className="max-w-[1600px] mx-auto px-10 py-12">
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-8"
        >
          <div>
            <div className="flex items-center gap-4 mb-3">
              <h2 className="text-3xl font-extrabold text-[#1A1A1A] tracking-tight">Property Control</h2>
              <span className="px-3 py-1 bg-[#2563EB]/10 text-[#2563EB] text-[10px] font-bold uppercase tracking-wider rounded-full">
                {properties.length} Inventory Items
              </span>
            </div>
            <p className="text-[#666666] text-sm font-medium">Reviewing global real estate submissions for compliance and data integrity.</p>
          </div>
          
          <div className="flex items-center gap-4">
             <button onClick={fetchProperties} className="h-11 px-6 bg-white border border-[#E8E6E1] rounded-2xl hover:bg-[#FBFBF9] flex items-center gap-2.5 font-bold transition-all text-xs text-[#666666] group">
               <RefreshCcw size={16} className={`group-hover:rotate-180 transition-transform duration-700 ${loading ? 'animate-spin' : ''}`} /> 
               Reload Feed
             </button>
             <button className="w-11 h-11 flex items-center justify-center bg-white border border-[#E8E6E1] rounded-xl text-[#666666] hover:bg-[#FBFBF9] transition-all">
              <Filter size={18} />
            </button>
          </div>
        </motion.div>

        {loading ? (
          <div className="flex flex-col justify-center items-center py-40 gap-4">
            <Loader2 className="animate-spin text-[#2563EB]" size={32} />
            <p className="text-[#A1A1A1] text-xs font-bold uppercase tracking-widest">Scanning inventory</p>
          </div>
        ) : properties.length === 0 ? (
          <div className="text-center py-40 rounded-[2.5rem] bg-white border border-[#E2E8F0] border-dashed">
             <div className="w-20 h-20 rounded-[2rem] bg-blue-50 flex items-center justify-center mx-auto mb-6">
                <Building2 size={36} className="text-[#2563EB]/40" />
             </div>
             <h3 className="text-[#0F172A] text-xl font-extrabold mb-2">Inventory Clean</h3>
             <p className="text-[#64748B] text-sm font-medium">No assets awaiting moderation at this time.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">
            <AnimatePresence mode="popLayout">
              {properties.map((p, idx) => (
                <motion.div 
                  key={p.id} 
                  layout
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  transition={{ delay: idx * 0.05 }}
                  className="card-platinum rounded-[2.5rem] p-6 bg-white border border-[#E8E6E1] flex flex-col md:flex-row gap-8 group"
                >
                  <div className="relative h-64 md:h-52 w-full md:w-64 flex-shrink-0 rounded-[2rem] overflow-hidden bg-[#F8FAFC]">
                    <img src={getMainImage(p)} alt="Property" className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110" />
                    <div className="absolute top-4 left-4 z-10 px-3 py-1.5 rounded-xl bg-white/90 backdrop-blur-md text-[10px] font-extrabold text-[#1A1A1A] uppercase tracking-wider shadow-sm border border-white/20">
                      {p.property_type || 'Residential'}
                    </div>
                    <div className={`absolute top-4 right-4 z-10 px-3 py-1.5 rounded-xl backdrop-blur-md text-[10px] font-extrabold uppercase tracking-wider border ${
                      p.status === 'available' ? 'bg-green-50/90 text-green-600 border-green-200' : 'bg-amber-50/90 text-amber-600 border-amber-200'
                    }`}>
                      {p.status || 'Pending'}
                    </div>
                  </div>
                  
                  <div className="flex-1 flex flex-col justify-between py-1">
                    <div>
                      <div className="flex items-start justify-between mb-3">
                        <h3 className="text-xl font-extrabold text-[#1A1A1A] leading-tight line-clamp-2 pr-4">{p.title}</h3>
                        <button className="text-[#A1A1A1] hover:text-[#2563EB] transition-colors"><ExternalLink size={18} /></button>
                      </div>
                      
                      <div className="space-y-2.5">
                        <div className="flex items-center gap-2.5 text-[#666666] font-bold text-[10px] uppercase tracking-wider">
                          <MapPin size={14} className="text-[#2563EB]/40" />
                          <span>{p.area_name}, {p.city}</span>
                        </div>
                        <div className="flex items-center gap-2.5 text-[#666666] font-bold text-[10px] uppercase tracking-wider">
                          <Building2 size={14} className="text-[#2563EB]/40" />
                          <span>Listed by: <span className="text-[#1A1A1A]">{p.profiles?.full_name || 'Anonymous User'}</span></span>
                        </div>
                      </div>
                      
                      <div className="mt-6 flex items-center gap-1.5">
                        <Tag size={12} className="text-[#2563EB]" />
                        <span className="text-2xl font-extrabold text-[#1A1A1A] tracking-tight">रू {p.price.toLocaleString()}</span>
                        <span className="text-[10px] font-bold text-[#A1A1A1] uppercase tracking-wider ml-1">Total Value</span>
                      </div>
                    </div>
                    
                    <div className="flex gap-4 mt-8">
                      {p.status !== 'available' && (
                        <button 
                          onClick={() => handleApprove(p.id)}
                          disabled={processingId === p.id}
                          className="flex-1 h-12 bg-[#2563EB] text-white font-bold rounded-2xl flex items-center justify-center gap-2 shadow-lg shadow-blue-500/20 hover:bg-[#1E40AF] active:scale-95 transition-all disabled:opacity-50 text-xs"
                        >
                          {processingId === p.id ? <Loader2 className="animate-spin" size={16} /> : <><CheckCircle2 size={16} /> Approve</>}
                        </button>
                      )}
                      
                      <button 
                        onClick={() => handleDelete(p.id)}
                        disabled={processingId === p.id}
                        className="w-12 h-12 bg-white border border-[#E8E6E1] text-[#A1A1A1] hover:text-[#EF4444] hover:bg-[#FFF1F1] rounded-2xl flex items-center justify-center transition-all disabled:opacity-50"
                      >
                        {processingId === p.id ? <Loader2 className="animate-spin" size={16} /> : <Trash2 size={16} />}
                      </button>
                    </div>
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
        )}
      </div>
    </div>
  );
};
