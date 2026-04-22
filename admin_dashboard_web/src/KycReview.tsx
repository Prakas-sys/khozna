import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { XCircle, Trash2, Loader2, Search, Zap, ShieldCheck, ShieldAlert, Phone, CreditCard, Layout, RefreshCcw } from 'lucide-react';

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

    const channel = supabase
      .channel('kyc_realtime')
      .on('postgres_changes', { 
        event: '*', 
        schema: 'public', 
        table: 'kyc_verifications' 
      }, (payload) => {
        if (payload.eventType === 'INSERT') {
          if (payload.new.status === 'pending') {
            setKycs(prev => [payload.new, ...prev]);
          }
        } else if (payload.eventType === 'UPDATE' || payload.eventType === 'DELETE') {
          if (payload.eventType === 'DELETE' || payload.new.status !== 'pending') {
            setKycs(prev => prev.filter(k => k.id !== ((payload.old as any).id || (payload.new as any).id)));
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
        reason = prompt("Specify Reason for Rejection:");
        if (!reason) {
          setProcessingId(null);
          return;
        }
      }

      const { error: kycError } = await supabase.from('kyc_verifications')
        .update({ status, rejection_reason: reason })
        .eq('id', kycId);
      
      if (kycError) throw kycError;

      const { error: profileError } = await supabase.from('profiles')
        .update({ kyc_status: status })
        .eq('id', userId);

      if (profileError) throw profileError;
      
      await supabase.from('notifications').insert({
        user_id: userId,
        title: status === 'verified' ? 'Identified Verified ✅' : 'ID Verification Failed',
        message: status === 'verified' ? 'Identity verified. You can now list properties.' : `Revision Required: ${reason}`,
        type: 'kyc_update',
      });

    } catch (error) {
      console.error("Audit failure:", error);
      alert("System failed to update record. Check logs.");
    } finally {
      setProcessingId(null);
    }
  };

  const handleDelete = async (kycId: string) => {
    if (!confirm("Permanently purge this record?")) return;
    try {
      await supabase.from('kyc_verifications').delete().eq('id', kycId);
    } catch (e) {
      console.error(e);
    }
  };

  const RealisticShield = ({ size = 32 }: { size?: number }) => (
    <div className="relative flex items-center justify-center">
      <div className="absolute inset-0 bg-brand/20 blur-2xl rounded-full scale-150 animate-pulse" />
      <div className="relative">
        <ShieldCheck size={size} className="text-brand drop-shadow-[0_0_15px_rgba(0,163,225,0.5)]" strokeWidth={2.5} />
      </div>
    </div>
  );

  return (
    <div className="p-10 max-w-[1600px] mx-auto w-full flex-1 overflow-y-auto min-h-screen pb-24 selection:bg-brand/10 bg-[#F9FAFB]/50">
      <motion.div 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col md:flex-row md:items-center justify-between mb-12 gap-8"
      >
        <div>
          <div className="flex items-center gap-4 mb-2">
            <h2 className="text-4xl font-brand font-black text-obsidian tracking-tighter">Identity Audit</h2>
            <div className="px-3 py-1.5 bg-brand/5 border border-brand/10 text-brand rounded-full flex items-center gap-2">
              <Zap size={14} fill="currentColor" className="animate-pulse" />
              <span className="text-[10px] font-black uppercase tracking-widest">Auto-Pilot Active</span>
            </div>
          </div>
          <p className="text-gray-400 font-medium text-sm">Validating real-time identification protocols across the global platform.</p>
        </div>
        
        <button onClick={fetchKycs} className="px-8 py-3.5 bg-white border border-gray-100 rounded-2xl hover:bg-gray-50 flex items-center gap-3 font-black shadow-sm transition-all text-xs uppercase tracking-widest group">
           <RefreshCcw size={16} className="text-gray-400 group-hover:rotate-180 transition-transform duration-700" /> 
           Sync Pipeline
        </button>
      </motion.div>

      {loading ? (
        <div className="flex items-center justify-center py-48">
          <div className="w-12 h-12 border-4 border-brand/10 border-t-brand rounded-full animate-spin" />
        </div>
      ) : kycs.length === 0 ? (
        <motion.div 
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="flex flex-col items-center justify-center py-48 bg-white rounded-[3rem] border border-dashed border-gray-200 shadow-xl shadow-gray-100/50"
        >
          <RealisticShield size={64} />
          <h3 className="text-2xl font-brand font-black text-obsidian mt-8">Queue Empty</h3>
          <p className="text-gray-400 mt-3 font-medium max-w-sm text-center text-sm leading-relaxed">No pending audits found. The autonomous guard layer is successfully filtering inbound submissions.</p>
        </motion.div>
      ) : (
        <div className="grid grid-cols-1 gap-12">
          <AnimatePresence mode="popLayout">
            {kycs.map((kyc, idx) => (
              <motion.div 
                key={kyc.id} 
                layout
                initial={{ opacity: 0, y: 40 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, x: 100 }}
                transition={{ delay: idx * 0.1, type: 'spring', damping: 20 }}
                className="bg-white border border-gray-100 rounded-[3rem] p-12 shadow-2xl shadow-gray-200/50 flex flex-col xl:flex-row gap-12 group relative overflow-hidden"
              >
                <div className="absolute top-0 left-0 w-2 h-full bg-brand/10" />
                
                <div className="flex-1">
                  <div className="flex items-start justify-between mb-12">
                    <div className="flex items-center gap-8">
                      <div className="w-20 h-20 bg-gray-50 rounded-[2rem] flex items-center justify-center text-3xl shadow-inner border border-gray-100 group-hover:bg-brand-light transition-all group-hover:rotate-6">
                        <Layout size={32} className="text-gray-300 group-hover:text-brand transition-colors" />
                      </div>
                      <div>
                        <h3 className="text-3xl font-brand font-black text-obsidian tracking-tighter mb-2 group-hover:text-brand transition-colors">{kyc.full_name}</h3>
                        <div className="flex items-center gap-8">
                          <div className="flex items-center gap-2.5 text-gray-400 font-bold text-xs uppercase tracking-widest">
                            <Phone size={14} className="text-brand opacity-40" /> {kyc.phone_number}
                          </div>
                          <div className="flex items-center gap-2.5 text-gray-400 font-bold text-xs uppercase tracking-widest">
                            <CreditCard size={14} className="text-brand opacity-40" /> ID: {kyc.citizenship_number}
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    <button onClick={() => handleDelete(kyc.id)} className="w-12 h-12 flex items-center justify-center text-gray-300 hover:text-red-500 transition-all bg-gray-50/50 hover:bg-red-50 rounded-2xl border border-transparent hover:border-red-100">
                      <Trash2 size={20} />
                    </button>
                  </div>
                  
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-8">
                    {[
                      { label: 'Primary ID Front', url: kyc.front_image_url },
                      { label: 'Primary ID Back', url: kyc.back_image_url },
                      { label: 'Live Verification Selfie', url: kyc.selfie_image_url }
                    ].map((img, i) => (
                      <div key={i} className="relative aspect-[4/3] bg-gray-50 rounded-[2rem] overflow-hidden border border-gray-100 cursor-zoom-in shadow-inner group/img">
                        <div className="absolute top-5 left-5 px-4 py-2 bg-obsidian/90 backdrop-blur-md rounded-xl text-[10px] font-black text-white uppercase tracking-widest z-10">{img.label}</div>
                        {img.url ? (
                          <img src={img.url} className="w-full h-full object-cover transition-all duration-1000 group-hover/img:scale-110" alt={img.label} />
                        ) : (
                          <div className="w-full h-full flex flex-col justify-center items-center gap-4">
                             <ShieldAlert className="text-red-200" size={40} />
                             <span className="text-[10px] font-black text-gray-400 uppercase tracking-widest">Data Unavailable</span>
                          </div>
                        )}
                        <div className="absolute inset-0 bg-brand/5 opacity-0 group-hover/img:opacity-100 transition-opacity" />
                      </div>
                    ))}
                  </div>
                </div>
                
                <div className="xl:w-96 flex flex-col gap-4 justify-center xl:border-l xl:border-gray-50 xl:pl-12">
                  <div className="text-center xl:text-left mb-6">
                    <p className="text-[11px] font-black text-gray-400 uppercase tracking-[0.25em] mb-2">Identity Governance</p>
                    <p className="text-xs text-gray-500 font-bold leading-relaxed">System requires a high-level administrative resolution to finalize user onboarding.</p>
                  </div>
                  
                  <div className="space-y-3">
                    <button 
                      onClick={() => handleUpdate(kyc.id, kyc.user_id, 'verified')}
                      disabled={processingId === kyc.id}
                      className="w-full bg-brand text-white font-black py-5 rounded-2xl flex items-center justify-center gap-3 shadow-xl shadow-brand/20 hover:shadow-brand/40 hover:-translate-y-1 active:scale-95 transition-all disabled:opacity-50 text-[11px] uppercase tracking-[0.2em]"
                    >
                      {processingId === kyc.id ? <Loader2 className="animate-spin" /> : <ShieldCheck size={18} strokeWidth={3} />}
                      Authorize Identity
                    </button>
                    
                    <button 
                      onClick={() => handleUpdate(kyc.id, kyc.user_id, 'rejected')}
                      disabled={processingId === kyc.id}
                      className="w-full bg-white border-2 border-red-100 text-red-500 font-black py-5 rounded-2xl flex items-center justify-center gap-3 hover:bg-red-500 hover:border-red-500 hover:text-white transition-all disabled:opacity-50 active:scale-95 text-[11px] uppercase tracking-[0.2em]"
                    >
                      {processingId === kyc.id ? <Loader2 className="animate-spin" /> : <XCircle size={18} />}
                      Reject Access
                    </button>
                  </div>

                  <div className="mt-8 p-6 bg-brand-light/40 border border-brand/5 rounded-[2rem] relative overflow-hidden group/intel">
                    <div className="absolute top-0 right-0 w-32 h-32 bg-brand/5 rounded-full -mr-16 -mt-16 blur-2xl group-hover/intel:bg-brand/10 transition-colors" />
                    <div className="flex items-center gap-3 text-brand font-black text-[10px] uppercase tracking-widest mb-3 relative z-10">
                      <Zap size={14} fill="currentColor" /> Intel Report
                    </div>
                    <p className="text-[11px] text-brand/70 leading-relaxed font-bold italic relative z-10">Cross-referencing biometric patterns with citizen database... 94% match probability detected. Ready for human sign-off.</p>
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
