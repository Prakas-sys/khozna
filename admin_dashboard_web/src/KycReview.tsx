import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { CheckCircle2, XCircle, Trash2, Loader2, Search, Zap, ShieldCheck, ShieldAlert } from 'lucide-react';

export const KycReview = () => {
  const [kycs, setKycs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [processingId, setProcessingId] = useState<string | null>(null);

  const fetchKycs = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('kyc_verifications')
        .select('*')
        .eq('status', 'pending')
        .order('created_at', { ascending: true });
      
      if (error) throw error;
      setKycs(data || []);
    } catch (e) {
      console.error("Error fetching KYCs:", e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchKycs();

    // --- REALTIME AUTO-PILOT MONITORING ---
    // This allows the dashboard to reflect changes made by the Edge Function in the background
    const channel = supabase
      .channel('kyc_realtime')
      .on('postgres_changes', { 
        event: '*', 
        schema: 'public', 
        table: 'kyc_verifications' 
      }, (payload) => {
        if (payload.eventType === 'INSERT') {
          // If it's a new pending kyc, add to list if not already there
          if (payload.new.status === 'pending') {
            setKycs(prev => [payload.new, ...prev]);
          }
        } else if (payload.eventType === 'UPDATE' || payload.eventType === 'DELETE') {
          // If a KYC is approved/rejected (by AI or other admin), remove from current pending list
          if (payload.eventType === 'DELETE' || payload.new.status !== 'pending') {
            setKycs(prev => prev.filter(k => k.id !== (payload.old.id || payload.new.id)));
          }
        }
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const handleUpdate = async (kycId: string, userId: string, status: 'verified' | 'rejected') => {
    setProcessingId(kycId);
    try {
      let reason = null;
      if (status === 'rejected') {
        reason = prompt("Enter Rejection Reason:");
        if (!reason) {
          setProcessingId(null);
          return;
        }
      }

      await supabase.from('kyc_verifications').update({ status, rejection_reason: reason }).eq('id', kycId);
      await supabase.from('profiles').update({ kyc_status: status }).eq('id', userId);
      
      // Auto-notifications happen in Edge Function usually, but keeping here for manual actions as backup
      await supabase.from('notifications').insert({
        user_id: userId,
        title: status === 'verified' ? 'KYC Approved! ✅' : 'KYC Rejected ❌',
        message: status === 'verified' ? 'Congratulations! Your identity verification was successful.' : `Verification failed: ${reason}`,
        type: 'kyc_update',
      });

      // UI will auto-update via Realtime subscription!
    } catch (error) {
      console.error("Error updating KYC:", error);
      alert("Failed to update KYC");
    } finally {
      setProcessingId(null);
    }
  };

  const handleDelete = async (kycId: string) => {
    if (!confirm("Are you sure?")) return;
    try {
      await supabase.from('kyc_verifications').delete().eq('id', kycId);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className="p-10 max-w-7xl mx-auto w-full flex-1 h-full overflow-y-auto">
      <div className="flex flex-col md:flex-row md:items-center justify-between mb-10 gap-6">
        <div>
          <div className="flex items-center gap-3 mb-1">
            <h2 className="text-3xl font-black text-gray-900 tracking-tight">KYC Verification</h2>
            <div className="bg-orange-100 text-orange-600 px-3 py-1 rounded-full text-xs font-bold flex items-center gap-1.5 animate-pulse">
              <Zap size={14} fill="currentColor" /> 24/7 AUTO-PILOT ACTIVE
            </div>
          </div>
          <p className="text-gray-500 font-medium italic">Monitoring live identity submissions from the mobile app...</p>
        </div>
        
        <div className="flex gap-3">
          <button onClick={fetchKycs} className="px-5 py-3 bg-white border border-gray-200 rounded-2xl hover:bg-gray-50 flex items-center gap-2 font-bold shadow-sm transition-all whitespace-nowrap">
             <Search size={20} className="text-gray-400" /> Refresh Queue
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Loader2 className="animate-spin text-[#00A3E1]" size={40} /></div>
      ) : kycs.length === 0 ? (
        <div className="text-center py-32 bg-white border border-dashed border-gray-200 rounded-[2.5rem] shadow-sm">
          <div className="w-20 h-20 bg-green-50 text-green-500 rounded-full flex items-center justify-center mx-auto mb-6">
            <ShieldCheck size={40} />
          </div>
          <h3 className="text-2xl font-bold text-gray-900">Queue is Clear!</h3>
          <p className="text-gray-400 mt-2 font-medium">The AI Auto-Pilot is currently handling all new submissions.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6">
          {kycs.map(kyc => (
            <div key={kyc.id} className="bg-white border border-gray-200 rounded-[2rem] p-8 shadow-sm flex flex-col xl:flex-row gap-10 hover:border-[#00A3E1]/30 transition-all group">
              
              <div className="flex-1">
                <div className="flex items-start justify-between mb-8">
                  <div className="flex items-center gap-4">
                    <div className="w-14 h-14 bg-[#00A3E1]/10 rounded-2xl flex items-center justify-center text-2xl">👤</div>
                    <div>
                      <h3 className="text-2xl font-black text-gray-900 tracking-tight leading-none mb-2">{kyc.full_name}</h3>
                      <div className="flex items-center gap-4">
                        <span className="text-gray-500 font-bold text-sm bg-gray-100 px-3 py-1 rounded-lg">{kyc.phone_number}</span>
                        <span className="text-gray-400 font-bold text-sm tracking-widest uppercase">ID: {kyc.citizenship_number}</span>
                      </div>
                    </div>
                  </div>
                  <button onClick={() => handleDelete(kyc.id)} className="text-gray-300 hover:text-red-500 transition-all p-3 bg-gray-50 hover:bg-red-50 rounded-2xl">
                    <Trash2 size={22} />
                  </button>
                </div>
                
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  {['Front', 'Back', 'Selfie'].map((label, i) => {
                    const url = [kyc.front_image_url, kyc.back_image_url, kyc.selfie_image_url][i];
                    return (
                      <div key={label} className="relative aspect-[4/3] bg-gray-50 rounded-3xl overflow-hidden border border-gray-100 group/img cursor-zoom-in shadow-inner">
                        <div className="absolute top-3 left-3 px-3 py-1 bg-black/40 backdrop-blur-md rounded-full text-[10px] font-black text-white uppercase tracking-widest z-10">{label}</div>
                        {url ? (
                          <img src={url} className="w-full h-full object-cover transition-transform duration-500 group-hover/img:scale-110" alt={label} />
                        ) : (
                          <div className="w-full h-full flex flex-col justify-center items-center gap-2">
                             <ShieldAlert className="text-gray-300" size={32} />
                             <span className="text-[10px] font-bold text-gray-400 uppercase">Missing</span>
                          </div>
                        )}
                        <div className="absolute inset-0 bg-black/20 opacity-0 group-hover/img:opacity-100 transition-opacity" />
                      </div>
                    )
                  })}
                </div>
              </div>
              
              <div className="xl:w-72 flex flex-col gap-3 justify-center xl:border-l xl:border-gray-100 xl:pl-10">
                <p className="text-xs font-black text-gray-400 uppercase tracking-[0.2em] mb-4 text-center xl:text-left">Human Verdict Required</p>
                
                <button 
                  onClick={() => handleUpdate(kyc.id, kyc.user_id, 'verified')}
                  disabled={processingId === kyc.id}
                  className="w-full bg-[#00A3E1] text-white font-black py-4 rounded-2xl flex items-center justify-center gap-3 hover:shadow-xl hover:shadow-[#00A3E1]/30 hover:-translate-y-0.5 transition-all disabled:opacity-50 active:scale-95"
                >
                  {processingId === kyc.id ? <Loader2 className="animate-spin" /> : <><CheckCircle2 size={24} /> Approve User</>}
                </button>
                
                <button 
                  onClick={() => handleUpdate(kyc.id, kyc.user_id, 'rejected')}
                  disabled={processingId === kyc.id}
                  className="w-full bg-white border-2 border-red-100 text-red-500 font-black py-4 rounded-2xl flex items-center justify-center gap-3 hover:bg-red-50 hover:border-red-200 transition-all disabled:opacity-50 active:scale-95"
                >
                  {processingId === kyc.id ? <Loader2 className="animate-spin" /> : <><XCircle size={24} /> Deny Access</>}
                </button>

                <div className="mt-4 p-4 bg-blue-50 border border-blue-100 rounded-2xl">
                  <div className="flex items-center gap-2 text-blue-600 font-bold text-xs mb-1">
                    <Zap size={14} variant="bold" /> AI AUTO-PILOT TIP
                  </div>
                  <p className="text-[10px] text-blue-400 leading-relaxed font-medium">The AI is currently analyzing this submission. It will auto-approve if confidence exceeds 90%.</p>
                </div>
              </div>

            </div>
          ))}
        </div>
      )}
    </div>
  );
};
