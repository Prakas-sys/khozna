import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { CheckCircle2, Trash2, Loader2, Search, MapPin, Building2 } from 'lucide-react';

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
      // Set to available
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
      // explicit wipe images first
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
    if (p.images && p.images.length > 0) {
      return p.images[0];
    }
    return 'https://via.placeholder.com/300?text=No+Image';
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'available': return 'text-green-600 bg-green-50 border-green-200';
      case 'booked': return 'text-orange-600 bg-orange-50 border-orange-200';
      case 'rejected': return 'text-red-600 bg-red-50 border-red-200';
      default: return 'text-green-600 bg-green-50 border-green-200';
    }
  };

  return (
    <div className="p-10 max-w-7xl mx-auto w-full flex-1 h-full overflow-y-auto">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-3xl font-extrabold text-gray-900">Property Moderation</h2>
          <p className="text-gray-500 mt-1">Review all active and pending listings on the platform.</p>
        </div>
        <button onClick={fetchProperties} className="p-3 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 flex items-center gap-2 font-semibold">
          {loading ? <Loader2 className="animate-spin text-gray-400" /> : <Search size={20} className="text-gray-400" />} 
          Refresh List
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Loader2 className="animate-spin text-[#00A3E1]" size={40} /></div>
      ) : properties.length === 0 ? (
        <div className="text-center py-20 bg-white border border-gray-100 rounded-3xl">
          <p className="text-gray-400 font-medium">No properties found.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
          {properties.map(p => (
            <div key={p.id} className="bg-white border border-gray-200 rounded-3xl p-5 shadow-sm flex flex-col md:flex-row gap-6">
              
              <div className="h-40 w-full md:w-40 flex-shrink-0 bg-gray-100 rounded-2xl overflow-hidden border border-gray-100 relative">
                <img src={getMainImage(p)} alt="Property" className="w-full h-full object-cover" />
                <div className={`absolute top-2 left-2 px-2 py-1 rounded border text-[10px] font-bold uppercase ${getStatusColor(p.status)}`}>
                  {p.status || 'AVAILABLE'}
                </div>
              </div>
              
              <div className="flex-1 flex flex-col justify-between">
                <div>
                  <h3 className="text-lg font-bold text-gray-900 leading-tight mb-2 line-clamp-2">{p.title}</h3>
                  <div className="flex items-center gap-2 text-sm text-gray-500 mb-1">
                    <MapPin size={14} className="text-gray-400" />
                    <span>{p.area_name}, {p.city}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm text-gray-500 mb-3">
                    <Building2 size={14} className="text-gray-400" />
                    <span>Owner: <span className="font-semibold text-gray-700">{p.profiles?.full_name || 'Unknown'}</span></span>
                  </div>
                  
                  <p className="text-xl font-black text-[#00A3E1]">रू {p.price}</p>
                </div>
                
                <div className="flex gap-3 mt-4">
                  {p.status !== 'available' && (
                    <button 
                      onClick={() => handleApprove(p.id)}
                      disabled={processingId === p.id}
                      className="flex-1 bg-green-500 text-white font-bold py-2 rounded-xl flex items-center justify-center gap-2 hover:bg-green-600 transition-all disabled:opacity-50"
                    >
                      {processingId === p.id ? <Loader2 className="animate-spin" size={18} /> : <><CheckCircle2 size={18} /> Approve</>}
                    </button>
                  )}
                  
                  <button 
                    onClick={() => handleDelete(p.id)}
                    disabled={processingId === p.id}
                    className="flex-1 bg-red-50 text-red-600 font-bold py-2 rounded-xl border border-red-200 flex items-center justify-center gap-2 hover:bg-red-100 transition-colors disabled:opacity-50"
                  >
                    {processingId === p.id ? <Loader2 className="animate-spin" size={18} /> : <><Trash2 size={18} /> Remove</>}
                  </button>
                </div>
              </div>

            </div>
          ))}
        </div>
      )}
    </div>
  );
};
