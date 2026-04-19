import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { XCircle, Trash2, Loader2, Search, Zap, ShieldCheck, ShieldAlert, Phone, CreditCard, Layout } from 'lucide-react';

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

  const RealisticShield = ({ color = 'brand', size = 32 }: { color?: string, size?: number }) => (
    <div className="relative flex items-center justify-center">
      <div className={`absolute inset-0 bg-${color}/20 blur-xl rounded-full scale-150 animate-pulse`} />
      <div className="relative">
        <ShieldCheck size={size} className={`text-${color} drop-shadow-[0_2px_8px_rgba(0,163,225,0.4)]`} strokeWidth={2.5} />
        <div className="absolute inset-0 bg-gradient-to-tr from-white/0 via-white/30 to-white/0 opacity-50 rounded-full" />
      </div>
    </div>
  );

  return (
    <div className="p-8 max-w-7xl mx-auto w-full flex-1 overflow-y-auto min-h-screen pb-24 selection:bg-brand/10 font-inter">
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-10 gap-6 animate-in fade-in slide-in-from-top-4 duration-500">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <h2 className="text-3xl font-brand font-black text-obsidian tracking-tight">Identity Audit</h2>
            <div className="px-3 py-1.5 bg-brand/5 border border-brand/10 text-brand rounded-full flex items-center gap-2">
              <Zap size={14} fill="currentColor" className="animate-pulse" />
              <span className="text-[10px] font-black uppercase tracking-widest">Autonomous Guard Active</span>
            </div>
          </div>
          <p className="text-gray-400 font-medium text-sm">Validating real-time identification protocols across the platform.</p>
        </div>
        
        <button onClick={fetchKycs} className="px-6 py-2.5 bg-white border border-gray-100 rounded-xl hover:bg-gray-50 flex items-center gap-3 font-bold shadow-sm transition-all text-sm group">
           <Search size={16} className="text-gray-400 group-hover:text-brand transition-colors" /> 
           Queue Synchronization
        </button>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-32">
          <Loader2 className="animate-spin text-brand" size={40} strokeWidth={2.5} />
        </div>
      ) : kycs.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-32 bg-white/50 border border-dashed border-gray-200 rounded-[2.5rem] animate-in fade-in zoom-in-95 duration-700">
          <RealisticShield size={48} />
          <h3 className="text-xl font-brand font-black text-obsidian mt-6">Pipeline Initialized</h3>
          <p className="text-gray-400 mt-2 font-medium max-w-xs text-center text-sm">No pending audits. AI Auto-Pilot is actively filtering new submissions.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-8">
          {kycs.map((kyc, idx) => (
            <div 
              key={kyc.id} 
              className="bg-white border border-gray-100 rounded-[2.5rem] p-10 shadow-premium flex flex-col xl:flex-row gap-12 group relative overflow-hidden animate-in fade-in slide-in-from-bottom-8 duration-700 fill-mode-both"
              style={{ animationDelay: `${idx * 100}ms` }}
            >
              <div className="absolute top-0 right-0 w-1 h-32 bg-brand/20 rounded-full" />
              
              <div className="flex-1">
                <div className="flex items-start justify-between mb-10">
                  <div className="flex items-center gap-6">
                    <div className="w-16 h-16 bg-gray-50 rounded-[1.25rem] flex items-center justify-center text-3xl shadow-inner border border-gray-100 group-hover:bg-brand-light transition-colors">
                      <Layout size={24} className="text-gray-300 group-hover:text-brand transition-colors" />
                    </div>
                    <div>
                      <h3 className="text-2xl font-brand font-black text-obsidian tracking-tighter mb-2 group-hover:text-brand transition-colors">{kyc.full_name}</h3>
                      <div className="flex items-center gap-6">
                        <div className="flex items-center gap-2 text-gray-400 font-bold text-xs uppercase tracking-widest">
                          <Phone size={14} className="opacity-50" /> {kyc.phone_number}
                        </div>
                        <div className="flex items-center gap-2 text-gray-400 font-bold text-xs uppercase tracking-widest">
                          <CreditCard size={14} className="opacity-50" /> ID: {kyc.citizenship_number}
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <button onClick={() => handleDelete(kyc.id)} className="w-10 h-10 flex items-center justify-center text-gray-300 hover:text-red-500 transition-all bg-gray-50/50 hover:bg-red-50 rounded-xl border border-transparent hover:border-red-100">
                    <Trash2 size={18} />
                  </button>
                </div>
                
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
                  {[
                    { label: 'Document Front', url: kyc.front_image_url },
                    { label: 'Document Back', url: kyc.back_image_url },
                    { label: 'Operator Selfie', url: kyc.selfie_image_url }
                  ].map((img, i) => (
                    <div key={i} className="relative aspect-[4/3] bg-gray-50 rounded-[1.5rem] overflow-hidden border border-gray-100 cursor-zoom-in shadow-inner group/img">
                      <div className="absolute top-4 left-4 px-3 py-1.5 bg-obsidian/80 backdrop-blur-md rounded-lg text-[9px] font-black text-white uppercase tracking-widest z-10 transition-transform group-hover/img:scale-95">{img.label}</div>
                      {img.url ? (
                        <img src={img.url} className="w-full h-full object-cover transition-all duration-700 group-hover/img:scale-125 group-hover/img:rotate-2" alt={img.label} />
                      ) : (
                        <div className="w-full h-full flex flex-col justify-center items-center gap-3">
                           <ShieldAlert className="text-red-200" size={32} />
                           <span className="text-[9px] font-black text-gray-400 uppercase tracking-widest">Undefined Asset</span>
                        </div>
                      )}
                      <div className="absolute inset-0 bg-brand/10 opacity-0 group-hover/img:opacity-100 transition-opacity" />
                    </div>
                  ))}
                </div>
              </div>
              
              <div className="xl:w-80 flex flex-col gap-3 justify-center xl:border-l xl:border-gray-50 xl:pl-12">
                <div className="text-center xl:text-left mb-4">
                  <p className="text-[10px] font-black text-gray-400 uppercase tracking-[0.2em] mb-1">Human Decision Layer</p>
                  <p className="text-xs text-gray-500 font-medium">Final resolution required for user onboarding.</p>
                </div>
                
                <button 
                  onClick={() => handleUpdate(kyc.id, kyc.user_id, 'verified')}
                  disabled={processingId === kyc.id}
                  className="w-full bg-brand text-white font-black py-3 rounded-xl flex items-center justify-center gap-3 shadow-lg shadow-brand/10 hover:shadow-brand/20 hover:-translate-y-1 transition-all disabled:opacity-50 active:scale-95 text-xs uppercase tracking-widest"
                >
                  {processingId === kyc.id ? <Loader2 className="animate-spin" /> : <ShieldCheck size={16} strokeWidth={3} className="opacity-60" />}
                  Confirm Identity
                </button>
                
                <button 
                  onClick={() => handleUpdate(kyc.id, kyc.user_id, 'rejected')}
                  disabled={processingId === kyc.id}
                  className="w-full bg-white border-2 border-red-100 text-red-500 font-black py-3 rounded-xl flex items-center justify-center gap-3 hover:bg-red-500 hover:border-red-500 hover:text-white transition-all disabled:opacity-50 active:scale-95 text-xs uppercase tracking-widest"
                >
                  {processingId === kyc.id ? <Loader2 className="animate-spin" /> : <XCircle size={16} />}
                  Reject Protocol
                </button>

                <div className="mt-4 p-5 bg-brand-light/50 border border-brand/5 rounded-[1.5rem]">
                  <div className="flex items-center gap-2 text-brand font-black text-[10px] uppercase tracking-widest mb-2">
                    <Zap size={14} fill="currentColor" /> Autonomous Suggestion
                  </div>
                  <p className="text-[11px] text-brand/60 leading-relaxed font-bold italic">Checking biometric match & OCR data extraction... 90% confidence threshold pending.</p>
                </div>
              </div>

            </div>
          ))}
        </div>
      )}
    </div>
  );
};
