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
    <div className="flex-1 overflow-y-auto bg-[#F8FAFC]">
      <div className="max-w-[1400px] mx-auto px-12 py-12">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-10 gap-6">
          <div>
            <h2 className="text-2xl font-bold text-[#0F172A] tracking-tight mb-2">Property Management</h2>
            <p className="text-[#64748B] text-sm font-medium">Review and moderate listings from across the platform.</p>
          </div>
          
          <div className="flex items-center gap-3">
             <button onClick={fetchProperties} className="h-10 px-4 bg-white border border-[#E2E8F0] rounded-lg hover:bg-gray-50 flex items-center gap-2 text-[12px] font-bold text-[#475569] transition-all shadow-sm">
               <RefreshCcw size={14} className={loading ? 'animate-spin' : ''} /> 
               Refresh
             </button>
             <button className="h-10 px-4 bg-white border border-[#E2E8F0] rounded-lg hover:bg-gray-50 flex items-center gap-2 text-[12px] font-bold text-[#475569] transition-all shadow-sm">
               <Filter size={14} /> Filter
             </button>
          </div>
        </div>
          </div>
        </motion.div>

        {loading ? (
          <div className="flex flex-col justify-center items-center py-40 gap-4">
            <Loader2 className="animate-spin text-[#2563EB]" size={32} />
            <p className="text-[#A1A1A1] text-xs font-bold uppercase tracking-widest">Loading properties</p>
            <p className="text-[#A1A1A1] text-xs font-bold uppercase tracking-widest">Loading</p>
          </div>
        ) : properties.length === 0 ? (
          <div className="text-center py-40 rounded-[2.5rem] bg-white border border-[#E2E8F0] border-dashed">
             <div className="w-20 h-20 rounded-[2rem] bg-blue-50 flex items-center justify-center mx-auto mb-6">
                <Building2 size={36} className="text-[#2563EB]/40" />
             </div>
              <h3 className="text-[#0F172A] text-xl font-extrabold mb-2">No Listings</h3>
              <p className="text-[#64748B] text-sm font-medium">There are no property listings to display right now.</p>
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
                  <div className="p-6 flex-1 flex flex-col">
                    <h3 className="text-lg font-bold text-[#0F172A] mb-2 truncate">{p.title || 'No Title'}</h3>
                    <div className="flex items-center gap-2 text-[#64748B] mb-4">
                      <MapPin size={14} />
                      <span className="text-[12px] font-medium truncate">{p.area_name || 'Unknown Location'}</span>
                    </div>

                    <div className="grid grid-cols-2 gap-4 mb-6">
                      <div className="p-3 bg-[#F8FAFC] rounded-lg border border-[#E2E8F0]">
                        <p className="text-[10px] font-bold text-[#94A3B8] uppercase mb-1">Price</p>
                        <p className="text-sm font-bold text-[#0F172A]">NPR {p.price?.toLocaleString() || 'N/A'}</p>
                      </div>
                      <div className="p-3 bg-[#F8FAFC] rounded-lg border border-[#E2E8F0]">
                        <p className="text-[10px] font-bold text-[#94A3B8] uppercase mb-1">Agent</p>
                        <p className="text-sm font-bold text-[#0F172A] truncate">{p.profiles?.full_name || 'System'}</p>
                      </div>
                    </div>

                    <div className="mt-auto flex gap-3 pt-4 border-t border-[#E2E8F0]">
                      {p.status === 'pending' && (
                        <button 
                          onClick={() => handleApprove(p.id)}
                          disabled={processingId === p.id}
                          className="flex-1 h-10 bg-[#2563EB] text-white rounded-lg text-[12px] font-bold hover:bg-[#1D4ED8] transition-colors flex items-center justify-center gap-2"
                        >
                          {processingId === p.id ? <Loader2 size={14} className="animate-spin" /> : <CheckCircle2 size={14} />} Approve
                        </button>
                      )}
                      <button 
                        onClick={() => handleDelete(p.id)}
                        disabled={processingId === p.id}
                        className="h-10 px-4 bg-white border border-[#E2E8F0] text-[#EF4444] rounded-lg text-[12px] font-bold hover:bg-[#FEF2F2] hover:border-[#FCA5A5] transition-all flex items-center justify-center"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </AnimatePresence>
          </div>
        )}
      </div>
    </div>
  );
};
