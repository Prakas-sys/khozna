import { useState } from 'react';
import { 
  Landmark, ArrowRight, Wallet, CheckCircle2, 
  AlertCircle, ChevronDown, Filter, FileText, 
  Send, XCircle, ArrowLeft, Building2 
} from 'lucide-react';

export const Payouts = () => {
  const [selectedPayout, setSelectedPayout] = useState<any>(null);
  const [filter, setFilter] = useState('pending');

  // Dummy data based on the HTML provided
  const payouts = [
    { id: '1', providerName: 'Himalayan Base Camp Lodge', providerId: 'PRV-8821', bookingRef: 'BKG-2023-11A', amount: '125,500', method: 'Bank Transfer', bankName: 'Nabil Bank', accountName: 'Himalayan Retreat Pvt Ltd', accNumber: '010101******221', status: 'Pending', baseAmount: '139,444', fee: '13,944' },
    { id: '2', providerName: 'Kathmandu Heritage Stays', providerId: 'PRV-9012', bookingRef: 'BKG-2023-12A', amount: '45,200', method: 'eSewa', bankName: 'eSewa Wallet', accountName: 'Ktm Heritage', accNumber: '9841******21', status: 'Pending', baseAmount: '50,222', fee: '5,022' },
    { id: '3', providerName: 'Pokhara Lakeside Retreat', providerId: 'PRV-7734', bookingRef: 'BKG-2023-14C', amount: '210,000', method: 'Bank Transfer', bankName: 'Standard Chartered', accountName: 'Lakeside Co', accNumber: '020202******511', status: 'On Hold', baseAmount: '233,333', fee: '23,333' },
    { id: '4', providerName: 'Chitwan Safari Eco Lodge', providerId: 'PRV-6522', bookingRef: 'BKG-2023-09C', amount: '69,500', method: 'Khalti', bankName: 'Khalti Wallet', accountName: 'Chitwan Safaris', accNumber: '9801******99', status: 'Pending', baseAmount: '77,222', fee: '7,722' },
  ];

  const filteredPayouts = filter === 'all' ? payouts : filter === 'on hold' ? payouts.filter(p => p.status === 'On Hold') : payouts.filter(p => p.status === 'Pending');

  return (
    <div className="flex-1 overflow-y-auto px-12 py-12 bg-[#F8FAFC]">
      {/* ─── MAIN LIST VIEW ────────────────────────────────────────────── */}
      {!selectedPayout ? (
        <>
          <div className="flex items-center justify-between mb-10">
            <div>
              <h2 className="text-3xl font-bold text-[#0F172A] tracking-tight mb-2">Service Provider Payouts Overview</h2>
              <p className="text-[#64748B] text-sm font-medium">List of settlements awaiting execution for property owners.</p>
            </div>
            <div className="flex gap-4 items-center">
              <button className="px-6 py-2.5 bg-[#2563EB] text-white rounded-lg text-[13px] font-bold hover:bg-blue-700 transition-all shadow-sm flex items-center gap-2">
                <Landmark size={18} />
                Execute Batch
              </button>
            </div>
          </div>

          {/* KPI CARDS */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div className="card-pro p-6 flex flex-col justify-between">
              <div className="flex items-center justify-between mb-4 text-[#64748B]">
                <span className="text-[11px] font-bold uppercase tracking-wider">Total Pending Payouts</span>
                <Wallet size={18} />
              </div>
              <div>
                <p className="text-3xl font-black text-[#0F172A]">Rs. 450,200</p>
                <div className="flex items-center gap-2 mt-2 text-[#2563EB] text-[12px] font-bold">
                  <ArrowRight size={14} className="-rotate-45" />
                  +12% vs last week
                </div>
              </div>
            </div>

            <div className="card-pro p-6 flex flex-col justify-between border-[#EF4444]/20 bg-red-50/10">
              <div className="flex items-center justify-between mb-4 text-red-500">
                <span className="text-[11px] font-bold uppercase tracking-wider">Awaiting Verification</span>
                <AlertCircle size={18} />
              </div>
              <div>
                <p className="text-3xl font-black text-[#0F172A]">12</p>
                <p className="text-[12px] font-medium text-[#64748B] mt-2">Requires manual compliance check</p>
              </div>
            </div>

            <div className="card-pro p-6 flex flex-col justify-between">
              <div className="flex items-center justify-between mb-4 text-[#059669]">
                <span className="text-[11px] font-bold uppercase tracking-wider">Processed This Month</span>
                <CheckCircle2 size={18} />
              </div>
              <div>
                <p className="text-3xl font-black text-[#0F172A]">Rs. 1.2M</p>
                <p className="text-[12px] font-medium text-[#64748B] mt-2">Across 145 transactions</p>
              </div>
            </div>
          </div>

          {/* TABLE SECTION */}
          <div className="card-pro overflow-hidden">
            <div className="p-4 border-b border-[#E2E8F0] bg-white flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="relative">
                  <select className="appearance-none bg-[#F8FAFC] border border-[#E2E8F0] text-[12px] font-semibold text-[#0F172A] rounded-md py-2 pl-4 pr-10 focus:outline-none focus:border-[#2563EB]">
                    <option>All Payment Methods</option>
                    <option>Bank Transfer</option>
                    <option>eSewa</option>
                    <option>Khalti</option>
                  </select>
                  <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
                </div>
                <div className="relative">
                  <select 
                    value={filter} 
                    onChange={(e) => setFilter(e.target.value)}
                    className="appearance-none bg-[#F8FAFC] border border-[#E2E8F0] text-[12px] font-semibold text-[#0F172A] rounded-md py-2 pl-4 pr-10 focus:outline-none focus:border-[#2563EB]"
                  >
                    <option value="all">All Statuses</option>
                    <option value="pending">Status: Pending</option>
                    <option value="on hold">Status: On Hold</option>
                  </select>
                  <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
                </div>
              </div>
              <button className="flex items-center gap-2 text-[12px] font-bold text-[#64748B] hover:text-[#0F172A] px-4 py-2 border border-[#E2E8F0] rounded-md hover:bg-[#F8FAFC] transition-colors">
                <Filter size={14} /> More Filters
              </button>
            </div>

            <table className="w-full text-left border-collapse">
              <thead className="bg-[#F8FAFC] border-b border-[#E2E8F0]">
                <tr>
                  <th className="py-4 px-6 text-[11px] font-bold text-[#64748B] uppercase tracking-wider">Provider Name</th>
                  <th className="py-4 px-6 text-[11px] font-bold text-[#64748B] uppercase tracking-wider text-right">Amount (NPR)</th>
                  <th className="py-4 px-6 text-[11px] font-bold text-[#64748B] uppercase tracking-wider">Payment Method</th>
                  <th className="py-4 px-6 text-[11px] font-bold text-[#64748B] uppercase tracking-wider text-center">Status</th>
                  <th className="py-4 px-6 text-[11px] font-bold text-[#64748B] uppercase tracking-wider text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E2E8F0]">
                {filteredPayouts.map((p) => (
                  <tr key={p.id} className="hover:bg-[#F8FAFC] transition-colors">
                    <td className="py-4 px-6">
                      <div className="font-bold text-[#0F172A] text-sm">{p.providerName}</div>
                      <div className="text-[12px] font-medium text-[#64748B] mt-0.5">ID: {p.providerId}</div>
                    </td>
                    <td className="py-4 px-6 text-right font-black text-[#0F172A] text-[15px]">
                      Rs. {p.amount}
                    </td>
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-2 text-[13px] font-semibold text-[#475569]">
                        {p.method === 'Bank Transfer' ? <Landmark size={14} className="text-[#94A3B8]" /> : <Wallet size={14} className="text-[#94A3B8]" />}
                        {p.method}
                      </div>
                    </td>
                    <td className="py-4 px-6 text-center">
                      <span className={`inline-flex items-center px-2.5 py-1 rounded-md text-[10px] font-bold uppercase tracking-wider ${
                        p.status === 'Pending' ? 'bg-[#EFF6FF] text-[#2563EB]' : 'bg-[#FEF2F2] text-[#EF4444]'
                      }`}>
                        {p.status}
                      </span>
                    </td>
                    <td className="py-4 px-6 text-right">
                      <button 
                        onClick={() => setSelectedPayout(p)}
                        className="text-[12px] font-bold text-[#2563EB] hover:text-white border border-[#2563EB] hover:bg-[#2563EB] px-4 py-1.5 rounded-md transition-colors"
                      >
                        Review
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filteredPayouts.length === 0 && (
              <div className="py-16 text-center">
                <p className="text-[#64748B] text-sm">No payouts found matching your criteria.</p>
              </div>
            )}
          </div>
        </>
      ) : (

        /* ─── PAYOUT EXECUTION REVIEW VIEW ────────────────────────────── */
        <div className="max-w-5xl mx-auto pb-12">
          {/* Header Context */}
          <div className="flex flex-col mb-8">
            <div className="flex items-center gap-2 mb-4">
              <button 
                onClick={() => setSelectedPayout(null)}
                className="w-8 h-8 rounded-full bg-white border border-[#E2E8F0] shadow-sm flex items-center justify-center text-[#64748B] hover:text-[#0F172A] hover:bg-[#F8FAFC] transition-colors"
              >
                <ArrowLeft size={16} />
              </button>
              <span className="text-[12px] font-bold text-[#64748B] uppercase tracking-wider">Back to Payout Manager</span>
            </div>
            <div className="flex items-center gap-4">
              <h1 className="text-3xl font-black text-[#0F172A] tracking-tight">Payout Execution Review</h1>
              <span className="bg-[#FEF9C3] text-[#854D0E] border border-[#FEF08A] text-[10px] font-black px-2.5 py-1 rounded-md uppercase tracking-wider">
                Pending Approval
              </span>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Left Column */}
            <div className="lg:col-span-2 flex flex-col gap-6">
              
              {/* Provider Info */}
              <div className="card-pro p-6 flex items-center gap-6">
                <div className="w-16 h-16 rounded-xl bg-[#EFF6FF] border border-[#BFDBFE] flex items-center justify-center flex-shrink-0 text-[#2563EB]">
                  <Building2 size={24} />
                </div>
                <div className="flex-1 border-r border-[#E2E8F0] pr-6">
                  <div className="flex items-center gap-3 mb-1">
                    <h2 className="text-xl font-bold text-[#0F172A]">{selectedPayout.providerName}</h2>
                    <span className="flex items-center gap-1 bg-[#F0FDF4] text-[#166534] text-[10px] font-bold px-2 py-0.5 rounded-full border border-[#BBF7D0] uppercase">
                      <CheckCircle2 size={12} /> Verified
                    </span>
                  </div>
                  <p className="text-[13px] font-medium text-[#64748B]">Provider ID: {selectedPayout.providerId}</p>
                </div>
                <div className="pl-6 w-40 text-right">
                  <p className="text-[11px] font-bold text-[#64748B] uppercase mb-1">Booking Ref</p>
                  <p className="text-[14px] font-black text-[#0F172A]">{selectedPayout.bookingRef}</p>
                </div>
              </div>

              {/* Destination Details */}
              <div className="card-pro overflow-hidden">
                <div className="bg-[#F8FAFC] border-b border-[#E2E8F0] px-6 py-4 flex items-center gap-3">
                  <Landmark size={18} className="text-[#64748B]" />
                  <h3 className="text-[14px] font-bold text-[#0F172A]">Destination Details</h3>
                </div>
                <div className="p-6 grid grid-cols-2 gap-y-6 gap-x-8">
                  <div>
                    <p className="text-[11px] font-bold text-[#64748B] uppercase mb-1">Transfer Method</p>
                    <p className="text-[14px] font-semibold text-[#0F172A]">{selectedPayout.method}</p>
                  </div>
                  <div>
                    <p className="text-[11px] font-bold text-[#64748B] uppercase mb-1">Bank / Institution Name</p>
                    <p className="text-[14px] font-bold text-[#0F172A]">{selectedPayout.bankName}</p>
                  </div>
                  <div className="col-span-2 h-px bg-[#E2E8F0]"></div>
                  <div>
                    <p className="text-[11px] font-bold text-[#64748B] uppercase mb-1">Account Name</p>
                    <p className="text-[14px] font-semibold text-[#0F172A]">{selectedPayout.accountName}</p>
                  </div>
                  <div>
                    <p className="text-[11px] font-bold text-[#64748B] uppercase mb-1">Account Number</p>
                    <p className="text-[15px] font-mono font-bold tracking-widest text-[#0F172A]">{selectedPayout.accNumber}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Right Column */}
            <div className="flex flex-col gap-6">
              
              {/* Financials */}
              <div className="card-pro overflow-hidden">
                <div className="bg-[#F8FAFC] border-b border-[#E2E8F0] px-6 py-4 flex items-center gap-3">
                  <FileText size={18} className="text-[#64748B]" />
                  <h3 className="text-[14px] font-bold text-[#0F172A]">Financial Breakdown</h3>
                </div>
                <div className="p-6 space-y-4">
                  <div className="flex justify-between items-center text-[13px] font-medium text-[#475569]">
                    <span>Total Booking Amount</span>
                    <span className="font-bold text-[#0F172A]">Rs. {selectedPayout.baseAmount}</span>
                  </div>
                  <div className="flex justify-between items-center text-[13px] font-medium text-[#EF4444]">
                    <span>Platform Fee (10%)</span>
                    <span className="font-bold">- Rs. {selectedPayout.fee}</span>
                  </div>
                  <div className="h-px bg-[#E2E8F0] my-4"></div>
                  <div className="flex items-end justify-between">
                    <span className="text-[14px] font-bold text-[#0F172A]">Final Payout</span>
                    <span className="text-3xl font-black text-[#2563EB]">Rs. {selectedPayout.amount}</span>
                  </div>
                </div>
                <div className="bg-[#F1F5F9] px-6 py-3 border-t border-[#E2E8F0]">
                  <p className="text-[11px] font-bold text-[#64748B] text-center uppercase tracking-wider">Currency: NPR. Rates Locked.</p>
                </div>
              </div>

              {/* Actions */}
              <div className="card-pro p-6 flex flex-col gap-3 mt-auto bg-white border-[#E2E8F0]">
                <p className="text-[12px] font-medium text-[#64748B] text-center mb-2">Review all details carefully before execution.</p>
                <button 
                  onClick={() => setSelectedPayout(null)} // Mock execution
                  className="w-full bg-[#2563EB] text-white text-[13px] font-bold py-3.5 rounded-lg hover:bg-blue-700 transition-all flex justify-center items-center gap-2 shadow-sm"
                >
                  <Send size={16} />
                  Execute Payout
                </button>
                <button 
                  onClick={() => setSelectedPayout(null)} // Mock reject
                  className="w-full bg-white text-[#EF4444] border border-[#EF4444]/30 text-[13px] font-bold py-3.5 rounded-lg hover:bg-red-50 transition-all flex justify-center items-center gap-2"
                >
                  <XCircle size={16} />
                  Reject Payout
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
