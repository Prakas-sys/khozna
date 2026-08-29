import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { CreditCard, ExternalLink, ArrowLeft, ShieldCheck, User, QrCode, Building2, Trash2 } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

export const Payments = () => {
  const [payments, setPayments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPayment, setSelectedPayment] = useState<any>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    fetchPayments();
  }, [filter]);

  const fetchPayments = async () => {
    setLoading(true);
    try {
      // 1. Fetch all bookings with property & profile info
      let bookingsData: any[] | null = null;
      const { data: bData, error: bookingsErr } = await supabase
        .from('bookings')
        .select(`
          id,
          guest_id,
          owner_id,
          total_price,
          status,
          payment_proof_url,
          payment_type,
          rejection_reason,
          created_at,
          properties (title),
          guest:profiles!bookings_guest_id_fkey (full_name),
          owner:profiles!bookings_owner_id_fkey (full_name, esewa_number, khalti_number, qr_code_url)
        `)
        .order('created_at', { ascending: false });

      if (bookingsErr) {
        // Fallback without payment_proof_url if column does not exist on bookings table
        const { data: fallbackData } = await supabase
          .from('bookings')
          .select(`
            id,
            guest_id,
            owner_id,
            total_price,
            status,
            payment_type,
            rejection_reason,
            created_at,
            properties (title),
            guest:profiles!bookings_guest_id_fkey (full_name),
            owner:profiles!bookings_owner_id_fkey (full_name, esewa_number, khalti_number, qr_code_url)
          `)
          .order('created_at', { ascending: false });
        bookingsData = fallbackData;
      } else {
        bookingsData = bData;
      }

      // Create a quick lookup map for bookings by ID
      const bookingMap = new Map<string, any>();
      if (bookingsData) {
        bookingsData.forEach((b: any) => bookingMap.set(b.id, b));
      }

      // 2. Fetch payments table entries
      const { data: paymentsData, error: paymentsErr } = await supabase
        .from('payments')
        .select('*')
        .order('created_at', { ascending: false });

      if (paymentsErr) console.error('Error fetching payments:', paymentsErr);

      const combined: any[] = [];
      const processedBookingIds = new Set<string>();

      // First add payments from payments table
      if (paymentsData) {
        paymentsData.forEach((p: any) => {
          const bookingObj = bookingMap.get(p.booking_id);
          if (p.booking_id) processedBookingIds.add(p.booking_id);

          const resolvedStatus =
            p.status === 'rejected' || bookingObj?.status === 'rejected'
              ? 'rejected'
              : p.status === 'verified' || bookingObj?.status === 'confirmed'
              ? 'verified'
              : p.status || 'pending';

          combined.push({
            id: p.id,
            booking_id: p.booking_id,
            payer_id: p.payer_id,
            amount: p.amount || bookingObj?.total_price || 0,
            payment_method: p.payment_method || bookingObj?.payment_type || 'esewa',
            proof_image_url: p.proof_image_url || bookingObj?.payment_proof_url,
            reference_id: p.reference_id || null,
            status: resolvedStatus,
            created_at: p.created_at,
            bookings: bookingObj || null,
          });
        });
      }

      // Then add any bookings that are paid/under review or have proof_image_url that were not in payments table
      if (bookingsData) {
        bookingsData.forEach((b: any) => {
          if (!processedBookingIds.has(b.id) && (b.payment_proof_url || b.status === 'paid' || b.status === 'awaiting_payment' || b.status === 'confirmed' || b.status === 'rejected')) {
            combined.push({
              id: `b_${b.id}`,
              booking_id: b.id,
              payer_id: b.guest_id,
              amount: b.total_price || 0,
              payment_method: b.payment_type || 'esewa',
              proof_image_url: b.payment_proof_url,
              reference_id: null,
              status:
                b.status === 'paid' || b.status === 'awaiting_payment'
                  ? 'pending'
                  : b.status === 'confirmed'
                  ? 'verified'
                  : b.status === 'rejected'
                  ? 'rejected'
                  : 'pending',
              created_at: b.created_at,
              bookings: b,
            });
          }
        });
      }

      // Apply client-side filter
      let filtered = combined;
      if (filter === 'pending') {
        filtered = combined.filter(
          (p) => p.status === 'pending' || p.status === 'paid' || p.status === 'awaiting_payment'
        );
      } else if (filter === 'verified') {
        filtered = combined.filter((p) => p.status === 'verified' || p.status === 'confirmed');
      } else if (filter === 'rejected') {
        filtered = combined.filter((p) => p.status === 'rejected');
      }

      setPayments(filtered);
    } catch (e) {
      console.error('Error fetching payments:', e);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (payment: any) => {
    if (!window.confirm('Confirm verification of this transaction?')) return;

    try {
      if (payment.id && !payment.id.toString().startsWith('b_')) {
        await supabase.from('payments').update({ status: 'verified' }).eq('id', payment.id);
      }
      await supabase.from('bookings').update({ status: 'confirmed' }).eq('id', payment.booking_id);
      await supabase.from('notifications').insert({
        user_id: payment.bookings?.guest_id,
        booking_id: payment.booking_id,
        property_id: payment.bookings?.property_id,
        title: 'Payment Verified',
        message: `Your payment for "${payment.bookings?.properties?.title || 'Property'}" has been confirmed.`,
        type: 'booking_alert',
      });
      setSelectedPayment(null);
      fetchPayments();
    } catch (e) {
      alert('Verification protocol failed');
    }
  };

  const handleReject = async (payment: any) => {
    if (!rejectReason.trim()) {
      alert('Please enter a rejection reason before rejecting. The user will see this.');
      return;
    }
    try {
      if (payment.id && !payment.id.toString().startsWith('b_')) {
        await supabase.from('payments').update({ status: 'rejected' }).eq('id', payment.id);
      }
      await supabase.from('bookings').update({
        status: 'rejected',
        rejection_reason: rejectReason.trim(),
      }).eq('id', payment.booking_id);
      await supabase.from('notifications').insert({
        user_id: payment.bookings?.guest_id,
        booking_id: payment.booking_id,
        property_id: payment.bookings?.property_id,
        title: 'Payment Rejected',
        message: `Your payment for "${payment.bookings?.properties?.title || 'Property'}" was denied. Reason: ${rejectReason}`,
        type: 'booking_rejected',
      });
      setSelectedPayment(null);
      setRejectReason('');
      fetchPayments();
    } catch (e) {
      alert('Rejection protocol failed');
    }
  };

  const handleDelete = async (payment: any) => {
    if (!window.confirm('Are you sure you want to DELETE this payment/booking record permanently?')) return;
    try {
      if (payment.id && !payment.id.toString().startsWith('b_')) {
        await supabase.from('payments').delete().eq('id', payment.id);
      }
      if (payment.booking_id) {
        await supabase.from('bookings').delete().eq('id', payment.booking_id);
      }
      setSelectedPayment(null);
      fetchPayments();
    } catch (e) {
      alert('Delete failed');
    }
  };

  const modalProofUrl = selectedPayment ? (selectedPayment.proof_image_url || selectedPayment.bookings?.payment_proof_url || selectedPayment.bookings?.proof_image_url) : null;

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
          {payments.map((p) => {
            const proofUrl = p.proof_image_url || p.bookings?.payment_proof_url || p.bookings?.proof_image_url;
            return (
              <div 
                key={p.id} 
                onClick={() => setSelectedPayment(p)}
                className="card-minimal p-4 flex items-center justify-between group hover:border-[#171717] cursor-pointer transition-all bg-white rounded-xl border border-[#E5E5E5] shadow-xs"
              >
                <div className="flex items-center gap-4">
                  {/* Proof Thumbnail Image */}
                  <div className="w-12 h-12 rounded-lg bg-[#F5F5F5] overflow-hidden border border-[#E5E5E5] flex items-center justify-center relative shrink-0">
                    {proofUrl ? (
                      <img 
                        src={proofUrl} 
                        alt="Receipt" 
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform" 
                      />
                    ) : (
                      <CreditCard size={18} strokeWidth={1.5} className="text-[#737373]" />
                    )}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h4 className="text-[14px] font-semibold text-[#171717]">{p.bookings?.properties?.title || 'Direct Booking'}</h4>
                      {proofUrl && (
                        <span className="text-[10px] font-semibold bg-blue-50 text-blue-600 px-2 py-0.5 rounded-full border border-blue-100">
                          📷 Receipt
                        </span>
                      )}
                      {p.bookings?.rejection_reason && p.status === 'pending' && (
                        <span className="text-[10px] font-semibold bg-orange-50 text-orange-600 px-2 py-0.5 rounded-full border border-orange-200 flex items-center gap-1">
                          🔁 Re-upload
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-2.5 mt-1">
                      <span className="text-[11px] font-medium text-[#737373]">Guest: {p.bookings?.guest?.full_name || 'Guest User'}</span>
                      <span className="w-1 h-1 rounded-full bg-[#E5E5E5]"></span>
                      {p.reference_id ? (
                        <span className="text-[11px] font-mono font-semibold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded border border-emerald-100">
                          Ref: {p.reference_id}
                        </span>
                      ) : (
                        <span className="text-[11px] text-rose-400 font-medium">No Ref Code</span>
                      )}
                      <span className="w-1 h-1 rounded-full bg-[#E5E5E5]"></span>
                      <span className="text-[11px] text-[#A3A3A3]">{new Date(p.created_at).toLocaleString([], { dateStyle: 'short', timeStyle: 'short' })}</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-6">
                  <div className="text-right">
                    <p className="text-[15px] font-semibold text-[#171717]">NPR {p.amount.toLocaleString()}</p>
                    <span className={`text-[9px] font-semibold uppercase tracking-wider px-2 py-0.5 rounded-md border ${
                      p.status === 'verified' ? 'bg-emerald-50 text-emerald-600 border-emerald-100' :
                      p.status === 'rejected' ? 'bg-rose-50 text-rose-600 border-rose-100' : 'bg-orange-50 text-orange-600 border-orange-100'
                    }`}>
                      {p.status}
                    </span>
                  </div>
                  
                  <div className="flex items-center gap-2">
                    <button 
                      onClick={(e) => {
                        e.stopPropagation();
                        setSelectedPayment(p);
                      }}
                      className="h-9 px-4 bg-[#171717] text-white rounded-lg text-[12px] font-semibold hover:bg-[#0A0A0A] transition-all shadow-xs flex items-center gap-2"
                    >
                      <span>View Image & Verify</span>
                      <ExternalLink size={13} strokeWidth={1.5} />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDelete(p);
                      }}
                      title="Delete record permanently"
                      className="h-9 w-9 bg-rose-50 text-rose-600 border border-rose-100 rounded-lg flex items-center justify-center hover:bg-rose-100 transition-all"
                    >
                      <Trash2 size={14} strokeWidth={1.5} />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
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
                {modalProofUrl ? (
                  <>
                    <img 
                      src={modalProofUrl} 
                      alt="Payment Proof Screenshot" 
                      className="max-w-full max-h-full object-contain rounded-xl shadow-lg border border-[#E5E5E5]"
                    />
                    <a 
                      href={modalProofUrl} 
                      target="_blank" 
                      rel="noreferrer"
                      className="absolute top-6 right-6 p-2.5 bg-white/90 rounded-full text-[#737373] hover:text-[#171717] shadow-xs border border-[#E5E5E5] transition-colors flex items-center gap-2 text-xs font-semibold"
                      title="Open image in new tab"
                    >
                      <ExternalLink size={16} strokeWidth={1.5} />
                    </a>
                  </>
                ) : (
                  <div className="text-center p-6">
                    <CreditCard size={40} className="mx-auto text-[#D4D4D4] mb-3" strokeWidth={1.5} />
                    <p className="text-[14px] font-semibold text-[#171717]">No Screenshot Uploaded</p>
                    <p className="text-[12px] text-[#737373] mt-1">Payment ID / Ref: {selectedPayment.reference_id || 'Direct Transfer'}</p>
                  </div>
                )}
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
                    {selectedPayment.bookings?.rejection_reason && selectedPayment.status === 'pending' && (
                      <div className="mt-3 px-3 py-2 bg-orange-50 border border-orange-200 rounded-lg flex items-start gap-2">
                        <span className="text-orange-500 text-[14px] mt-0.5">🔁</span>
                        <div>
                          <p className="text-[11px] font-bold text-orange-700 uppercase tracking-wider">Re-uploaded Receipt</p>
                          <p className="text-[11px] text-orange-600 mt-0.5">Previously rejected — Reason: <span className="font-semibold">{selectedPayment.bookings.rejection_reason}</span></p>
                        </div>
                      </div>
                    )}
                  </div>

                  <div className="space-y-4">
                    <div className="p-4 bg-[#FAFAFA] rounded-xl border border-[#E5E5E5]">
                      <div className="flex items-center gap-2 mb-2">
                        <User size={14} strokeWidth={1.5} className="text-[#A3A3A3]" />
                        <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Payer</span>
                      </div>
                      <p className="text-[14px] font-semibold text-[#171717]">{selectedPayment.bookings?.guest?.full_name || 'Guest User'}</p>
                    </div>

                    <div className="p-4 bg-[#FAFAFA] rounded-xl border border-[#E5E5E5]">
                      <div className="flex items-center gap-2 mb-1">
                        <QrCode size={14} strokeWidth={1.5} className="text-[#A3A3A3]" />
                        <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Transaction Ref / Code</span>
                      </div>
                      {selectedPayment.reference_id ? (
                        <p className="text-[16px] font-mono font-bold text-emerald-600">
                          {selectedPayment.reference_id}
                        </p>
                      ) : (
                        <p className="text-[13px] font-semibold text-rose-500 flex items-center gap-1">
                          <span>⚠️</span> No reference code submitted
                        </p>
                      )}
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
                      <label className="block text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest mb-2">
                        Rejection Reason <span className="text-rose-400">*</span> <span className="normal-case text-[#A3A3A3] font-normal">(Required to reject — user will see this)</span>
                      </label>
                      <textarea 
                        value={rejectReason}
                        onChange={(e) => setRejectReason(e.target.value)}
                        placeholder="e.g. Wrong QR code, blurry screenshot, incorrect amount..."
                        className="w-full bg-[#FAFAFA] border border-[#E5E5E5] rounded-xl p-4 text-[13px] focus:outline-none focus:border-[#171717] transition-all resize-none h-24 placeholder:text-[#D4D4D4]"
                      />
                    </div>
                  )}
                </div>

                <div className="flex flex-col gap-2 pt-6 border-t border-[#F5F5F5] mt-6">
                  {selectedPayment.status !== 'verified' && (
                    <button 
                      onClick={() => handleVerify(selectedPayment)}
                      className="w-full h-11 bg-emerald-600 text-white rounded-xl font-semibold text-[13px] hover:bg-emerald-700 transition-all shadow-sm flex items-center justify-center gap-2"
                    >
                      <ShieldCheck size={16} strokeWidth={1.5} /> Verify & Approve Payment
                    </button>
                  )}
                  {selectedPayment.status !== 'rejected' && (
                    <button 
                      onClick={() => handleReject(selectedPayment)}
                      className="w-full h-11 bg-amber-50 text-amber-700 border border-amber-200 rounded-xl font-semibold text-[13px] hover:bg-amber-100 transition-all flex items-center justify-center gap-2"
                    >
                       Reject Payment
                    </button>
                  )}
                  <button 
                    onClick={() => handleDelete(selectedPayment)}
                    className="w-full h-11 bg-rose-50 text-rose-600 border border-rose-200 rounded-xl font-semibold text-[13px] hover:bg-rose-100 transition-all flex items-center justify-center gap-2"
                  >
                     Delete Record Permanently
                  </button>
                  <button 
                    onClick={() => setSelectedPayment(null)}
                    className="w-full h-10 bg-[#F5F5F5] text-[#525252] rounded-xl font-semibold text-[12px] hover:bg-[#E5E5E5] transition-all mt-1"
                  >
                    Close Review
                  </button>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};
