import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { 
  Landmark, ArrowRight, Wallet, CheckCircle2, 
  AlertCircle, ChevronDown, Filter, FileText, 
  Send, XCircle, ArrowLeft, Building2, Loader2,
  TrendingUp, Circle
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

export const Payouts = () => {
  const [selectedPayout, setSelectedPayout] = useState<any>(null);
  const [filter, setFilter] = useState('pending');
  const [payouts, setPayouts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // KPIs
  const [kpiTotalPending, setKpiTotalPending] = useState(0);
  const [kpiAwaitingVerify, setKpiAwaitingVerify] = useState(0);

  useEffect(() => {
    fetchPayouts();
  }, [filter]);

  const fetchPayouts = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('payments')
        .select(`
          id,
          amount,
          status,
          created_at,
          bookings (
            id,
            owner:profiles!bookings_owner_id_fkey (full_name, id)
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      const realData = data || [];
      setKpiTotalPending(realData.filter(d => d.status === 'verified').reduce((acc, curr) => acc + (curr.amount || 0), 0));
      setKpiAwaitingVerify(realData.filter(d => d.status === 'pending').length);
      setPayouts(realData);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const filteredPayouts = payouts.filter(p => p.status === (filter === 'pending' ? 'verified' : filter === 'all' ? p.status : 'awaiting'));

  return (
    <div className="flex-1 overflow-y-auto px-8 py-8 bg-[#FAFAFA]">
      <AnimatePresence mode="wait">
        {!selectedPayout ? (
          <motion.div
            key="list"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.98 }}
          >
            <div className="flex items-center justify-between mb-8">
              <div>
                <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">Service Payouts</h2>
                <p className="text-[#737373] text-[13px]">Manage settlements and batches for property owners.</p>
              </div>
              <button className="h-10 px-5 bg-[#171717] text-white rounded-lg text-[12px] font-semibold hover:bg-[#0A0A0A] transition-all shadow-sm flex items-center gap-2">
                <Landmark size={16} strokeWidth={1.5} />
                Execute Global Batch
              </button>
            </div>

            {/* KPI CARDS */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
              <div className="card-minimal p-6 border-b-2 border-b-[#171717]">
                <div className="flex items-center justify-between mb-4">
                  <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Pending Settlement</span>
                  <Wallet size={16} strokeWidth={1.5} className="text-[#A3A3A3]" />
                </div>
                <div className="flex items-baseline gap-2">
                  <p className="text-[24px] font-semibold text-[#171717]">NPR {kpiTotalPending.toLocaleString()}</p>
                </div>
                <p className="text-[11px] text-[#A3A3A3] mt-1.5 flex items-center gap-1">
                  <TrendingUp size={10} /> 12 active releases
                </p>
              </div>

              <div className="card-minimal p-6">
                <div className="flex items-center justify-between mb-4">
                  <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Awaiting Verification</span>
                  <AlertCircle size={16} strokeWidth={1.5} className="text-[#A3A3A3]" />
                </div>
                <p className="text-[24px] font-semibold text-[#171717]">{kpiAwaitingVerify}</p>
                <p className="text-[11px] text-[#A3A3A3] mt-1.5">Compliance check required</p>
              </div>

              <div className="card-minimal p-6">
                <div className="flex items-center justify-between mb-4">
                  <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Settled (Monthly)</span>
                  <CheckCircle2 size={16} strokeWidth={1.5} className="text-[#A3A3A3]" />
                </div>
                <p className="text-[24px] font-semibold text-[#171717]">NPR 0</p>
                <p className="text-[11px] text-[#A3A3A3] mt-1.5">No disbursements yet</p>
              </div>
            </div>

            {/* TABLE SECTION */}
            <div className="card-minimal overflow-hidden shadow-xs">
              <div className="px-5 py-4 bg-white border-b border-[#E5E5E5] flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="relative">
                    <select className="appearance-none bg-[#FAFAFA] border border-[#E5E5E5] text-[12px] font-medium text-[#525252] rounded-lg py-1.5 pl-4 pr-9 focus:outline-none focus:border-[#A3A3A3] transition-all">
                      <option>All Channels</option>
                      <option>Bank-direct</option>
                      <option>Digital Wallet</option>
                    </select>
                    <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#A3A3A3] pointer-events-none" />
                  </div>
                  <div className="flex items-center bg-[#F5F5F5] p-0.5 rounded-lg border border-[#E5E5E5]">
                    {['pending', 'all', 'hold'].map(f => (
                      <button
                        key={f}
                        onClick={() => setFilter(f)}
                        className={`px-3.5 py-1.5 text-[11px] font-semibold rounded-md capitalize transition-all ${filter === f ? 'bg-white text-[#171717] shadow-xs border border-[#E5E5E5]' : 'text-[#737373] hover:text-[#171717]'}`}
                      >
                         {f === 'pending' ? 'Unsettled' : f}
                      </button>
                    ))}
                  </div>
                </div>
                <button className="flex items-center gap-2 text-[12px] font-medium text-[#525252] px-3.5 py-1.5 border border-[#E5E5E5] rounded-lg hover:bg-[#FAFAFA] transition-all shadow-xs">
                  <Filter size={14} strokeWidth={1.5} /> Filters
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left">
                  <thead className="bg-[#FAFAFA] border-b border-[#E5E5E5]">
                    <tr>
                      <th className="py-4 px-6 text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider">Recipient</th>
                      <th className="py-4 px-6 text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider text-right">Amount</th>
                      <th className="py-4 px-6 text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider">Method</th>
                      <th className="py-4 px-6 text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider text-center">Protocol</th>
                      <th className="py-4 px-6 text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider text-right"></th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#F5F5F5]">
                    {loading ? (
                      <tr>
                        <td colSpan={5} className="py-20 text-center">
                          <Loader2 className="animate-spin text-[#171717] mx-auto mb-3" size={24} strokeWidth={1.5} />
                          <p className="text-[#A3A3A3] text-[12px] font-medium uppercase tracking-widest">Reforming Ledger</p>
                        </td>
                      </tr>
                    ) : filteredPayouts.length === 0 ? (
                      <tr>
                        <td colSpan={5} className="py-16">
                          <div className="empty-state">
                            <FileText size={24} strokeWidth={1.5} className="text-[#E5E5E5] mb-2" />
                            <p className="text-[13px] text-[#A3A3A3]">No settleable records found</p>
                          </div>
                        </td>
                      </tr>
                    ) : (
                      filteredPayouts.map((p) => (
                        <tr key={p.id} className="hover:bg-[#FAFAFA] transition-colors group">
                          <td className="py-4 px-6">
                            <div className="font-semibold text-[#171717] text-[13px]">{p.bookings?.owner?.full_name || 'System Provider'}</div>
                            <div className="text-[11px] font-mono text-[#A3A3A3] mt-0.5">REF: {p.id.substring(0, 8)}</div>
                          </td>
                          <td className="py-4 px-6 text-right font-semibold text-[#171717] text-[14px]">
                            NPR {p.amount?.toLocaleString() || 0}
                          </td>
                          <td className="py-4 px-6">
                            <div className="flex items-center gap-2 text-[12px] font-medium text-[#737373]">
                              <Wallet size={12} strokeWidth={1.5} className="text-[#A3A3A3]" />
                              Internal Escrow
                            </div>
                          </td>
                          <td className="py-4 px-6 text-center">
                            <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-semibold uppercase tracking-wider border ${
                              p.status === 'verified' ? 'bg-emerald-50 text-emerald-600 border-emerald-100' : 'bg-[#FAFAFA] text-[#737373] border-[#E5E5E5]'
                            }`}>
                              {p.status === 'verified' ? 'Ready' : p.status}
                            </span>
                          </td>
                          <td className="py-4 px-6 text-right">
                            <button 
                              onClick={() => setSelectedPayout(p)}
                              className="text-[11px] font-semibold text-[#171717] border border-[#E5E5E5] bg-white hover:bg-[#FAFAFA] px-3.5 py-1.5 rounded-lg transition-all shadow-xs opacity-0 group-hover:opacity-100"
                            >
                              Review
                            </button>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </motion.div>
        ) : (
          /* ─── PAYOUT EXECUTION REVIEW VIEW ──────────────────────────────── */
          <motion.div
            key="detail"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="max-w-4xl mx-auto"
          >
            <div className="flex items-center gap-4 mb-8">
              <button 
                onClick={() => setSelectedPayout(null)}
                className="w-9 h-9 rounded-full bg-white border border-[#E5E5E5] shadow-xs flex items-center justify-center text-[#737373] hover:text-[#171717] hover:bg-[#FAFAFA] transition-all"
              >
                <ArrowLeft size={16} strokeWidth={1.5} />
              </button>
              <div>
                <p className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Back to Overview</p>
                <h1 className="text-[22px] font-semibold text-[#171717] tracking-tight">Settlement Review</h1>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="md:col-span-2 space-y-4">
                <div className="card-minimal p-8 bg-white">
                  <div className="flex items-center gap-5 mb-8 pb-8 border-b border-[#F5F5F5]">
                    <div className="w-14 h-14 rounded-xl bg-[#FAFAFA] border border-[#E5E5E5] flex items-center justify-center text-[#171717]">
                      <Building2 size={24} strokeWidth={1.5} />
                    </div>
                    <div>
                      <h2 className="text-[18px] font-semibold text-[#171717]">{selectedPayout.bookings?.owner?.full_name || 'System Provider'}</h2>
                      <p className="text-[12px] text-[#A3A3A3] font-mono tracking-wider">ID: {selectedPayout.bookings?.owner?.id || '—'}</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-y-8 gap-x-12">
                    <div>
                      <p className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest mb-2">Protocol</p>
                      <p className="text-[13px] font-medium text-[#171717] flex items-center gap-2">
                        <Circle size={8} fill="#10B981" className="text-emerald-500" /> Standard Release
                      </p>
                    </div>
                    <div>
                      <p className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest mb-2">Ref ID</p>
                      <p className="text-[13px] font-mono text-[#171717]">{selectedPayout.id.substring(0, 16)}</p>
                    </div>
                    <div>
                      <p className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest mb-2">Destination</p>
                      <p className="text-[13px] font-medium text-[#171717]">Verified Bank Account</p>
                      <p className="text-[11px] text-[#A3A3A3] mt-1 italic">Internal clearing required</p>
                    </div>
                    <div>
                      <p className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest mb-2">Cycle</p>
                      <p className="text-[13px] font-medium text-[#171717]">Bi-weekly Batch</p>
                    </div>
                  </div>
                </div>

                <div className="card-minimal p-8 bg-white border-rose-100 bg-rose-50/5">
                   <div className="flex items-center gap-3 mb-4">
                      <AlertCircle size={16} strokeWidth={1.5} className="text-rose-500" />
                      <h4 className="text-[14px] font-semibold text-[#171717]">Compliance Caution</h4>
                   </div>
                   <p className="text-[12px] text-[#737373] leading-relaxed">
                     Ensure the owner's bank details match the corporate registry. Mismatched information may lead to internal reconciliation delays. Release of these funds implies manual signature of transaction validity.
                   </p>
                </div>
              </div>

              <div className="space-y-4">
                <div className="card-minimal p-6 bg-white overflow-hidden">
                  <div className="flex items-center gap-2 mb-6">
                    <FileText size={16} strokeWidth={1.5} className="text-[#A3A3A3]" />
                    <h3 className="text-[13px] font-semibold text-[#171717]">Financial Recap</h3>
                  </div>
                  <div className="space-y-4">
                    <div className="flex justify-between items-center text-[12px]">
                      <span className="text-[#737373]">Initial Capture</span>
                      <span className="font-medium text-[#171717]">NPR {selectedPayout.amount?.toLocaleString()}</span>
                    </div>
                    <div className="flex justify-between items-center text-[12px]">
                      <span className="text-[#737373]">Service Fee</span>
                      <span className="font-medium text-rose-500">- 0.00</span>
                    </div>
                    <div className="pt-4 border-t border-[#E5E5E5] flex justify-between items-end">
                      <span className="text-[13px] font-semibold text-[#171717]">Disbursement</span>
                      <span className="text-[22px] font-semibold text-[#171717]">NPR {selectedPayout.amount?.toLocaleString()}</span>
                    </div>
                  </div>
                </div>

                <div className="flex flex-col gap-2">
                  <button 
                    onClick={() => setSelectedPayout(null)}
                    className="w-full h-11 bg-[#171717] text-white rounded-xl font-semibold text-[13px] hover:bg-[#0A0A0A] transition-all shadow-sm flex items-center justify-center gap-2"
                  >
                    <Send size={16} strokeWidth={1.5} />
                    Execute Release
                  </button>
                  <button 
                    onClick={() => setSelectedPayout(null)}
                    className="w-full h-11 bg-white border border-[#E5E5E5] text-[#737373] rounded-xl font-semibold text-[13px] hover:bg-[#FAFAFA] transition-all shadow-xs flex items-center justify-center gap-2"
                  >
                    <XCircle size={16} strokeWidth={1.5} />
                    Reject Payout
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
