import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { CreditCard, ExternalLink, ArrowLeft, Loader2, ShieldCheck, XCircle, User, Landmark, QrCode, Building2 } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

export const Payments = () => {
  const [payments, setPayments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPayment, setSelectedPayment] = useState<any>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [filter, setFilter] = useState('pending');

  useEffect(() => {
    fetchPayments();
  }, [filter]);

  const fetchPayments = async () => {
    setLoading(true);
    try {
      let query = supabase
        .from('payments')
        .select(`
          *,
          bookings (
            id,
            guest_id,
            owner_id,
            properties (title),
            guest:profiles!bookings_guest_id_fkey (full_name),
            owner:profiles!bookings_owner_id_fkey (full_name, esewa_number, khalti_number, qr_code_url)
          )
        `)
        .order('created_at', { ascending: false });

      if (filter !== 'all') {
        query = query.eq('status', filter);
      }

      const { data, error } = await query;
      if (error) throw error;
      setPayments(data || []);
    } catch (e) {
      console.error('Error fetching payments:', e);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (payment: any) => {
    if (!window.confirm('Confirm verification of this transaction?')) return;
    
    try {
      await supabase.from('payments').update({ status: 'verified' }).eq('id', payment.id);
      await supabase.from('bookings').update({ status: 'confirmed' }).eq('id', payment.booking_id);
      await supabase.from('notifications').insert({
        user_id: payment.bookings.guest_id,
        title: 'Payment Verified',
        message: `Your payment for "${payment.bookings.properties.title}" has been confirmed.`,
        type: 'booking_alert',
      });
      setSelectedPayment(null);
      fetchPayments();
    } catch (e) {
      alert('Verification protocol failed');
    }
  };

  const handleReject = async (payment: any) => {
    if (!rejectReason) {
      alert('Exclusion reason required');
      return;
    }

    try {
      await supabase.from('payments').update({ status: 'rejected' }).eq('id', payment.id);
      await supabase.from('bookings').update({ status: 'awaiting_payment' }).eq('id', payment.booking_id);
      await supabase.from('notifications').insert({
        user_id: payment.bookings.guest_id,
        title: 'Payment Rejected',
        message: `Your payment for "${payment.bookings.properties.title}" was denied. ${rejectReason}`,
        type: 'booking_alert',
      });
      setSelectedPayment(null);
      setRejectReason('');
      fetchPayments();
    } catch (e) {
      alert('Rejection protocol failed');
    }
  };

  return (
    <div className="flex-1 overflow-y-auto px-8 py-8 bg-[#FAFAFA]">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">Payment Moderation</h2>
          <p className="text-[#737373] text-[13px]">Manual verification for clearing platform transactions.</p>
        </div>
        <div className="flex p-0.5 bg-white border border-[#E5E5E5] rounded-lg shadow-xs">
          {['pending', 'verified', 'rejected', 'all'].map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3.5 py-1.5 text-[11px] font-semibold rounded-md capitalize transition-all ${filter === f ? 'bg-[#FAFAFA] text-[#171717] border border-[#E5E5E5] shadow-xs' : 'text-[#737373] hover:text-[#171717]'}`}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="py-20 flex flex-col items-center justify-center gap-3">
          <div className="w-5 h-5 border-2 border-[#E5E5E5] border-t-[#171717] rounded-full animate-spin" />
          <p className="text-[12px] text-[#A3A3A3] font-medium">Auditing ledger...</p>
        </div>
      ) : payments.length === 0 ? (
        <div className="empty-state border border-dashed border-[#E5E5E5] rounded-xl">
          <div className="empty-state-icon">
            <CreditCard size={20} strokeWidth={1.5} />
          </div>
          <p className="empty-state-title">No transactions found</p>
          <p className="empty-state-desc">All payments in this category have been processed or none exist.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-3">
          {payments.map((p) => (
            <div key={p.id} className="card-minimal p-5 flex items-center justify-between group hover:border-[#A3A3A3] transition-all">
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 rounded-lg bg-[#F5F5F5] flex items-center justify-center text-[#171717]">
                  <CreditCard size={18} strokeWidth={1.5} />
                </div>
                <div>
                  <h4 className="text-[14px] font-semibold text-[#171717]">{p.bookings?.properties?.title || 'Unknown Asset'}</h4>
                  <div className="flex items-center gap-2.5 mt-0.5">
                    <span className="text-[11px] font-medium text-[#737373]">{p.bookings?.guest?.full_name || 'Anonymous'}</span>
                    <span className="w-1 h-1 rounded-full bg-[#E5E5E5]"></span>
                    <span className="text-[11px] text-[#A3A3A3]">{new Date(p.created_at).toLocaleString([], { dateStyle: 'short', timeStyle: 'short' })}</span>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-10">
                <div className="text-right">
                  <p className="text-[15px] font-semibold text-[#171717]">NPR {p.amount.toLocaleString()}</p>
                  <span className={`text-[9px] font-semibold uppercase tracking-wider px-1.5 py-0.5 rounded-md border ${
                    p.status === 'verified' ? 'bg-emerald-50 text-emerald-600 border-emerald-100' :
                    p.status === 'rejected' ? 'bg-rose-50 text-rose-600 border-rose-100' : 'bg-orange-50 text-orange-600 border-orange-100'
                  }`}>
                    {p.status}
                  </span>
                </div>
                
                <button 
                  onClick={() => setSelectedPayment(p)}
                  className="h-9 px-5 bg-[#171717] text-white rounded-lg text-[12px] font-semibold hover:bg-[#0A0A0A] transition-all shadow-sm"
                >
                  Verify
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal View */}
      <AnimatePresence>
        {selectedPayment && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-[#0A0A0A]/60 backdrop-blur-xs">
            <motion.div 
              initial={{ opacity: 0, scale: 0.98, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.98, y: 10 }}
              className="bg-white w-full max-w-5xl rounded-2xl overflow-hidden flex shadow-2xl h-[85vh] border border-[#E5E5E5]"
            >
              {/* Left: Screenshot */}
              <div className="flex-1 bg-[#FAFAFA] p-10 flex items-center justify-center relative overflow-hidden border-r border-[#F5F5F5]">
                 <img 
                   src={selectedPayment.proof_image_url} 
                   alt="Proof" 
                   className="max-w-full max-h-full object-contain rounded-xl shadow-lg border border-[#E5E5E5]"
                 />
                 <a 
                   href={selectedPayment.proof_image_url} 
                   target="_blank" 
                   rel="noreferrer"
                   className="absolute top-6 right-6 p-2.5 bg-white/90 rounded-full text-[#737373] hover:text-[#171717] shadow-xs border border-[#E5E5E5] transition-colors"
                 >
                   <ExternalLink size={16} strokeWidth={1.5} />
                 </a>
              </div>

              {/* Right: Info & Actions */}
              <div className="w-[420px] p-10 flex flex-col justify-between overflow-y-auto">
                <div>
                  <div className="mb-10">
                    <button 
                      onClick={() => setSelectedPayment(null)}
                      className="flex items-center gap-2 text-[11px] font-semibold text-[#A3A3A3] uppercase tracking-wider hover:text-[#171717] transition-colors mb-6"
                    >
                      <ArrowLeft size={14} strokeWidth={1.5} /> Back to Hub
                    </button>
                    <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest mb-2 block">Audit Context</span>
                    <h3 className="text-[20px] font-semibold text-[#171717] tracking-tight leading-tight mb-1">{selectedPayment.bookings?.properties?.title || 'Unknown Booking'}</h3>
                    <p className="text-[#737373] text-[13px]">Manual verification required</p>
                  </div>

                  <div className="space-y-4">
                    <div className="p-4 bg-[#FAFAFA] rounded-xl border border-[#E5E5E5]">
                      <div className="flex items-center gap-2 mb-3">
                        <User size={14} strokeWidth={1.5} className="text-[#A3A3A3]" />
                        <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Payer</span>
                      </div>
                      <p className="text-[14px] font-semibold text-[#171717]">{selectedPayment.bookings?.guest?.full_name || 'Guest User'}</p>
                    </div>

                    <div className="p-4 bg-[#FAFAFA] rounded-xl border border-[#E5E5E5]">
                      <div className="flex items-center gap-2 mb-4">
                        <Building2 size={14} strokeWidth={1.5} className="text-[#A3A3A3]" />
                        <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Beneficiary</span>
                      </div>
                      <div className="space-y-3">
                        <div className="flex justify-between items-center">
                          <span className="text-[12px] text-[#737373]">Owner</span>
                          <span className="text-[12px] font-semibold text-[#171717]">{selectedPayment.bookings?.owner?.full_name || 'N/A'}</span>
                        </div>
                        <div className="flex justify-between items-center text-[12px]">
                          <span className="text-[#737373]">Method</span>
                          <span className="text-[#171717] font-medium">eSewa / Khalti</span>
                        </div>
                        
                        {(selectedPayment.bookings?.owner?.esewa_number || selectedPayment.bookings?.owner?.khalti_number) && (
                          <div className="pt-3 border-t border-[#E5E5E5] space-y-2">
                             {selectedPayment.bookings?.owner?.esewa_number && (
                               <div className="flex justify-between text-[11px]">
                                 <span className="text-[#A3A3A3]">eSewa ID</span>
                                 <span className="font-mono text-[#171717]">{selectedPayment.bookings.owner.esewa_number}</span>
                               </div>
                             )}
                             {selectedPayment.bookings?.owner?.khalti_number && (
                               <div className="flex justify-between text-[11px]">
                                 <span className="text-[#A3A3A3]">Khalti ID</span>
                                 <span className="font-mono text-[#171717]">{selectedPayment.bookings.owner.khalti_number}</span>
                               </div>
                             )}
                          </div>
                        )}
                        
                        {selectedPayment.bookings?.owner?.qr_code_url && (
                          <div className="mt-4 pt-4 border-t border-[#E5E5E5]">
                            <div className="flex items-center gap-2 mb-3">
                              <QrCode size={14} strokeWidth={1.5} className="text-[#A3A3A3]" />
                              <p className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">QR Code Receipt</p>
                            </div>
                            <img 
                              src={selectedPayment.bookings.owner.qr_code_url} 
                              alt="Owner QR" 
                              className="w-full aspect-square object-cover rounded-lg border border-[#E5E5E5]"
                            />
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="flex justify-between items-center py-4 px-2">
                      <span className="text-[13px] font-medium text-[#737373]">Payment Amount</span>
                      <span className="text-[20px] font-semibold text-[#171717]">NPR {selectedPayment.amount.toLocaleString()}</span>
                    </div>
                  </div>

                  {selectedPayment.status === 'pending' && (
                    <div className="mt-8">
                      <label className="block text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest mb-2">Audit Notes (Optional)</label>
                      <textarea 
                        value={rejectReason}
                        onChange={(e) => setRejectReason(e.target.value)}
                        placeholder="e.g. Incomplete transfer, blurry capture..."
                        className="w-full bg-[#FAFAFA] border border-[#E5E5E5] rounded-xl p-4 text-[13px] focus:outline-none focus:border-[#171717] transition-all resize-none h-24 placeholder:text-[#D4D4D4]"
                      />
                    </div>
                  )}
                </div>

                <div className="flex flex-col gap-2 pt-8 border-t border-[#F5F5F5] mt-10">
                  {selectedPayment.status === 'pending' ? (
                    <>
                      <button 
                        onClick={() => handleVerify(selectedPayment)}
                        className="w-full h-11 bg-[#171717] text-white rounded-xl font-semibold text-[13px] hover:bg-[#0A0A0A] transition-all shadow-sm flex items-center justify-center gap-2"
                      >
                        <ShieldCheck size={16} strokeWidth={1.5} /> Clear Transaction
                      </button>
                      <button 
                        onClick={() => handleReject(selectedPayment)}
                        className="w-full h-11 bg-white text-rose-500 border border-rose-100 rounded-xl font-semibold text-[13px] hover:bg-rose-50 transition-all flex items-center justify-center gap-2"
                      >
                         Refuse Approval
                      </button>
                    </>
                  ) : (
                    <button 
                      onClick={() => setSelectedPayment(null)}
                      className="w-full h-11 bg-[#F5F5F5] text-[#525252] rounded-xl font-semibold text-[13px] hover:bg-[#E5E5E5] transition-all"
                    >
                      Close Review
                    </button>
                  )}
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};
