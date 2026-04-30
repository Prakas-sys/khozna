import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { CheckCircle2, Trash2, Loader2, MapPin, Building2, Filter, RefreshCcw, Tag } from 'lucide-react';

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

        {loading ? (
          <div className="flex flex-col justify-center items-center py-40 gap-4">
            <Loader2 className="animate-spin text-[#2563EB]" size={32} />
            <p className="text-[#94A3B8] text-[11px] font-bold uppercase tracking-widest">Querying database...</p>
          </div>
        ) : properties.length === 0 ? (
          <div className="text-center py-32 rounded-xl bg-white border border-[#E2E8F0] border-dashed">
             <div className="w-16 h-16 rounded-lg bg-[#F8FAFC] border border-[#E2E8F0] flex items-center justify-center mx-auto mb-4">
                <Building2 size={28} className="text-[#94A3B8]" />
             </div>
              <h3 className="text-[#0F172A] text-lg font-bold mb-1">No Listings</h3>
              <p className="text-[#64748B] text-sm font-medium">There are no property listings to moderate right now.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {properties.map((p) => (
              <div key={p.id} className="bg-white border border-[#E2E8F0] rounded-xl overflow-hidden flex flex-col shadow-sm hover:shadow-md transition-shadow">
                <div className="relative aspect-video bg-gray-100">
                  <img src={getMainImage(p)} alt="Property" className="w-full h-full object-cover" />
                  <div className="absolute top-3 left-3 px-2 py-1 bg-white/90 rounded text-[9px] font-bold text-[#0F172A] uppercase shadow-sm">
                    {p.property_type || 'Residential'}
                  </div>
                  <div className={`absolute top-3 right-3 px-2 py-1 rounded text-[9px] font-bold uppercase shadow-sm ${
                    p.status === 'available' ? 'bg-emerald-500 text-white' : 'bg-amber-500 text-white'
                  }`}>
                    {p.status || 'Pending'}
                  </div>
                </div>

                <div className="p-5 flex-1 flex flex-col">
                  <h3 className="text-[14px] font-bold text-[#0F172A] mb-1 truncate">{p.title || 'Untitled Listing'}</h3>
                  <div className="flex items-center gap-1.5 text-[#64748B] mb-4">
                    <MapPin size={12} className="text-[#94A3B8]" />
                    <span className="text-[11px] font-medium truncate">{p.area_name}, {p.city}</span>
                  </div>

                  <div className="grid grid-cols-2 gap-3 mb-6">
                    <div className="p-2.5 bg-[#F8FAFC] rounded-lg border border-[#E2E8F0]">
                      <p className="text-[9px] font-bold text-[#94A3B8] uppercase mb-0.5">Price</p>
                      <p className="text-[12px] font-bold text-[#0F172A]">NPR {p.price?.toLocaleString() || 'N/A'}</p>
                    </div>
                    <div className="p-2.5 bg-[#F8FAFC] rounded-lg border border-[#E2E8F0]">
                      <p className="text-[9px] font-bold text-[#94A3B8] uppercase mb-0.5">Agent</p>
                      <p className="text-[12px] font-bold text-[#0F172A] truncate">{p.profiles?.full_name || 'System'}</p>
                    </div>
                  </div>

                  <div className="mt-auto flex gap-2 pt-4 border-t border-[#F1F5F9]">
                    {p.status === 'pending' && (
                      <button 
                        onClick={() => handleApprove(p.id)}
                        disabled={processingId === p.id}
                        className="flex-1 h-9 bg-[#2563EB] text-white rounded-lg text-[11px] font-bold hover:bg-[#1D4ED8] transition-colors flex items-center justify-center gap-2"
                      >
                        {processingId === p.id ? <Loader2 size={12} className="animate-spin" /> : <CheckCircle2 size={12} />} Approve
                      </button>
                    )}
                    <button 
                      onClick={() => handleDelete(p.id)}
                      disabled={processingId === p.id}
                      className="h-9 px-3 bg-white border border-[#E2E8F0] text-[#EF4444] rounded-lg text-[11px] font-bold hover:bg-[#FEF2F2] hover:border-[#FCA5A5] transition-all flex items-center justify-center"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
