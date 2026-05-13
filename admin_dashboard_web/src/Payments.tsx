import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { CreditCard, ExternalLink } from 'lucide-react';

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
    if (!window.confirm('Verify this payment? This will confirm the booking.')) return;
    
    try {
      // 1. Update Payment
      await supabase.from('payments').update({ status: 'verified' }).eq('id', payment.id);

      // 2. Update Booking
      await supabase.from('bookings').update({ status: 'confirmed' }).eq('id', payment.booking_id);

      // 3. Notify Guest
      await supabase.from('notifications').insert({
        user_id: payment.bookings.guest_id,
        title: '✅ Payment Verified!',
        message: `Your payment for "${payment.bookings.properties.title}" has been verified. Booking confirmed!`,
        type: 'booking_alert',
      });

      setSelectedPayment(null);
      fetchPayments();
    } catch (e) {
      alert('Error verifying payment');
    }
  };

  const handleReject = async (payment: any) => {
    if (!rejectReason) {
      alert('Please provide a reason for rejection');
      return;
    }

    try {
      // 1. Update Payment
      await supabase.from('payments').update({ status: 'rejected' }).eq('id', payment.id);

      // 2. Update Booking
      await supabase.from('bookings').update({ status: 'awaiting_payment' }).eq('id', payment.booking_id);

      // 3. Notify Guest
      await supabase.from('notifications').insert({
        user_id: payment.bookings.guest_id,
        title: '❌ Payment Rejected',
        message: `Your payment for "${payment.bookings.properties.title}" was rejected. Reason: ${rejectReason}`,
        type: 'booking_alert',
      });

      setSelectedPayment(null);
      setRejectReason('');
      fetchPayments();
    } catch (e) {
      alert('Error rejecting payment');
    }
  };

  return (
    <div className="flex-1 overflow-y-auto px-12 py-12 bg-[#F8FAFC]">
      <div className="flex items-center justify-between mb-12">
        <div>
          <h2 className="text-3xl font-bold text-[#0F172A] tracking-tight mb-2">Payment Moderation</h2>
          <p className="text-[#64748B] text-sm font-medium">Verify eSewa screenshots and confirm property bookings.</p>
        </div>
        <div className="flex gap-2 bg-white p-1 rounded-lg border border-[#E2E8F0]">
          {['pending', 'verified', 'rejected', 'all'].map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-1.5 text-[11px] font-bold rounded-md transition-all capitalize ${filter === f ? 'bg-[#F1F5F9] text-[#2563EB]' : 'text-[#64748B]'}`}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20 text-[#64748B] font-medium text-sm">
          Fetching payment data...
        </div>
      ) : payments.length === 0 ? (
        <div className="card-pro py-20 text-center">
          <CreditCard size={48} className="mx-auto text-gray-200 mb-4" />
          <p className="text-[#94A3B8] text-[13px] font-medium">No payments found in this category</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4">
          {payments.map((p) => (
            <div key={p.id} className="card-pro p-6 flex items-center justify-between group hover:border-[#2563EB]/30 transition-all">
              <div className="flex items-center gap-6">
                <div className="w-12 h-12 rounded-xl bg-gray-50 flex items-center justify-center text-[#2563EB]">
                  <CreditCard size={20} />
                </div>
                <div>
                  <h4 className="text-[14px] font-bold text-[#0F172A]">{p.bookings?.properties?.title}</h4>
                  <div className="flex items-center gap-3 mt-1">
                    <span className="text-[11px] font-bold text-[#64748B] uppercase tracking-wider">{p.bookings?.guest?.full_name}</span>
                    <span className="w-1 h-1 rounded-full bg-gray-300"></span>
                    <span className="text-[11px] font-medium text-[#94A3B8]">{new Date(p.created_at).toLocaleString()}</span>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-12">
                <div className="text-right">
                  <p className="text-[18px] font-black text-[#0F172A]">Rs. {p.amount}</p>
                  <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded-md ${
                    p.status === 'verified' ? 'bg-green-50 text-green-600' :
                    p.status === 'rejected' ? 'bg-red-50 text-red-600' : 'bg-orange-50 text-orange-600'
                  }`}>
                    {p.status}
                  </span>
                </div>
                
                <button 
                  onClick={() => setSelectedPayment(p)}
                  className="px-6 py-2.5 bg-[#0F172A] text-white rounded-lg text-[12px] font-bold hover:bg-black transition-all shadow-sm"
                >
                  Review
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal View */}
      {selectedPayment && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-8 bg-black/60 backdrop-blur-sm">
          <div className="bg-white w-full max-w-5xl rounded-[2.5rem] overflow-hidden flex shadow-2xl h-[80vh]">
            {/* Left: Screenshot */}
            <div className="flex-1 bg-[#F8FAFC] p-8 flex items-center justify-center relative overflow-hidden">
               <img 
                 src={selectedPayment.proof_image_url} 
                 alt="Proof" 
                 className="max-w-full max-h-full object-contain rounded-2xl shadow-lg border border-white"
               />
               <a 
                 href={selectedPayment.proof_image_url} 
                 target="_blank" 
                 rel="noreferrer"
                 className="absolute top-8 right-8 p-3 bg-white/90 rounded-full text-gray-600 hover:text-black shadow-sm"
               >
                 <ExternalLink size={18} />
               </a>
            </div>

            {/* Right: Info & Actions */}
            <div className="w-[400px] border-l border-[#E2E8F0] p-12 flex flex-col justify-between">
              <div>
                <div className="mb-10">
                  <span className="text-[11px] font-bold text-[#2563EB] uppercase tracking-widest mb-4 block">Transaction Detail</span>
                  <h3 className="text-3xl font-bold text-[#0F172A] tracking-tight mb-2">{selectedPayment.bookings?.properties?.title}</h3>
                  <p className="text-[#64748B] text-sm font-medium">Verified by Prakash (System Admin)</p>
                </div>

                <div className="space-y-4">
                  <div className="p-4 bg-blue-50 rounded-xl border border-blue-100">
                    <span className="text-[10px] font-bold text-blue-600 uppercase tracking-widest block mb-2">Guest Detail</span>
                    <div className="flex justify-between items-center">
                      <span className="text-[13px] font-semibold text-blue-900">Payer</span>
                      <span className="text-[13px] font-bold text-blue-900">{selectedPayment.bookings?.guest?.full_name}</span>
                    </div>
                  </div>

                  <div className="p-4 bg-orange-50 rounded-xl border border-orange-100">
                    <span className="text-[10px] font-bold text-orange-600 uppercase tracking-widest block mb-3">Owner Payout Details</span>
                    <div className="space-y-2">
                      <div className="flex justify-between items-center">
                        <span className="text-[11px] font-semibold text-orange-800">Owner</span>
                        <span className="text-[11px] font-bold text-orange-900">{selectedPayment.bookings?.owner?.full_name}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-[11px] font-semibold text-orange-800">eSewa</span>
                        <span className="text-[11px] font-bold text-orange-900">{selectedPayment.bookings?.owner?.esewa_number || 'N/A'}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-[11px] font-semibold text-orange-800">Khalti</span>
                        <span className="text-[11px] font-bold text-orange-900">{selectedPayment.bookings?.owner?.khalti_number || 'N/A'}</span>
                      </div>
                      {selectedPayment.bookings?.owner?.qr_code_url && (
                        <div className="mt-4 pt-4 border-t border-orange-100 flex flex-col items-center">
                          <p className="text-[10px] font-bold text-orange-800 uppercase mb-2">Owner QR Code</p>
                          <img 
                            src={selectedPayment.bookings.owner.qr_code_url} 
                            alt="Owner QR" 
                            className="w-32 h-32 object-cover rounded-lg border border-orange-200"
                          />
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="flex justify-between items-center py-4 px-2">
                    <span className="text-[13px] font-semibold text-[#64748B]">Total Amount</span>
                    <span className="text-[20px] font-black text-[#0F172A]">Rs. {selectedPayment.amount}</span>
                  </div>
                </div>

                {selectedPayment.status === 'pending' && (
                  <div className="mt-12">
                    <label className="block text-[11px] font-bold text-[#64748B] uppercase mb-3">Rejection Reason (if any)</label>
                    <textarea 
                      value={rejectReason}
                      onChange={(e) => setRejectReason(e.target.value)}
                      placeholder="e.g. Invalid amount, Blur screenshot..."
                      className="w-full bg-[#F8FAFC] border border-[#E2E8F0] rounded-xl p-4 text-sm focus:outline-none focus:border-[#2563EB] transition-all"
                      rows={3}
                    />
                  </div>
                )}
              </div>

              <div className="flex flex-col gap-3">
                {selectedPayment.status === 'pending' ? (
                  <>
                    <button 
                      onClick={() => handleVerify(selectedPayment)}
                      className="w-full py-4 bg-[#2563EB] text-white rounded-xl font-bold text-sm hover:bg-blue-700 transition-all shadow-lg shadow-blue-200"
                    >
                      Verify & Confirm Booking
                    </button>
                    <button 
                      onClick={() => handleReject(selectedPayment)}
                      className="w-full py-4 bg-white text-red-600 border border-red-100 rounded-xl font-bold text-sm hover:bg-red-50 transition-all"
                    >
                      Reject Transaction
                    </button>
                  </>
                ) : (
                  <button 
                    onClick={() => setSelectedPayment(null)}
                    className="w-full py-4 bg-gray-100 text-gray-600 rounded-xl font-bold text-sm hover:bg-gray-200 transition-all"
                  >
                    Close Review
                  </button>
                )}
                
                <button 
                  onClick={() => setSelectedPayment(null)}
                  className="text-[11px] font-bold text-gray-400 hover:text-gray-600 transition-all mt-2"
                >
                  Cancel and go back
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
