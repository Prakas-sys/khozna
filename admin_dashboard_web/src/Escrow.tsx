import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { 
  Building2, 
  HelpCircle,
  Activity,
  AlertOctagon,
  Unlock,
  Eye,
  Filter,
  ArrowRight,
  Loader2
} from 'lucide-react';

export const Escrow = () => {
  const [filter, setFilter] = useState('all');
  const [escrowData, setEscrowData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchEscrow();
  }, [filter]);

  const fetchEscrow = async () => {
    setLoading(true);
    try {
      let query = supabase
        .from('payments')
        .select(`
          *,
          bookings (
            id,
            owner:profiles!bookings_owner_id_fkey (full_name)
          )
        `)
        .order('created_at', { ascending: false });

      if (filter !== 'all') {
        const mappedStatus = filter === 'holding' ? 'verified' : filter === 'disputed' ? 'rejected' : 'pending';
        query = query.eq('status', mappedStatus);
      }

      const { data, error } = await query;
      if (error) throw error;
      setEscrowData(data || []);
    } catch (e) {
      console.error('Error fetching escrow:', e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex-1 overflow-y-auto px-12 py-12 bg-[#F8FAFC]">
      <div className="flex items-center justify-between mb-10">
        <div>
          <h2 className="text-3xl font-bold text-[#0F172A] tracking-tight mb-2">Escrow & Reconciliation</h2>
          <p className="text-[#64748B] text-sm font-medium">Manage platform-held liquidity and process secured fund releases.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="card-pro p-6">
          <div className="flex items-center justify-between mb-4 text-[#2563EB]">
            <span className="text-[11px] font-bold uppercase tracking-wider">Total in Escrow</span>
            <Building2 size={18} />
          </div>
          <p className="text-3xl font-black text-[#0F172A]">Rs. 4.52M</p>
          <div className="flex items-center gap-2 mt-2 text-[#64748B] text-[12px] font-medium">
            <Activity size={14} /> Active platform liquidity
          </div>
        </div>

        <div className="card-pro p-6 border-orange-200 bg-orange-50/30">
          <div className="flex items-center justify-between mb-4 text-[#EA580C]">
            <span className="text-[11px] font-bold uppercase tracking-wider">Action Required</span>
            <HelpCircle size={18} />
          </div>
          <p className="text-3xl font-black text-[#0F172A]">12 <span className="text-lg font-bold text-[#64748B]">Bookings</span></p>
          <p className="text-[12px] font-medium text-[#64748B] mt-2">Disputes or audit requirements</p>
        </div>

        <div className="card-pro p-6">
          <div className="flex items-center justify-between mb-4 text-[#059669]">
            <span className="text-[11px] font-bold uppercase tracking-wider">Daily Disbursement</span>
            <ArrowRight size={18} className="text-[#059669]" />
          </div>
          <p className="text-3xl font-black text-[#0F172A]">Rs. 850K</p>
          <p className="text-[12px] font-medium text-[#64748B] mt-2">Rolling 24hr velocity</p>
        </div>
      </div>

      <div className="card-pro overflow-hidden">
        <div className="px-6 py-4 bg-white border-b border-[#E2E8F0] flex items-center justify-between">
          <div className="flex items-center bg-[#F8FAFC] p-1 rounded-lg border border-[#E2E8F0]">
            {['all', 'holding', 'releasing', 'disputed'].map(f => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-4 py-1.5 text-[11px] font-bold rounded-md capitalize transition-colors ${filter === f ? 'bg-white text-[#2563EB] shadow-sm border border-[#E2E8F0]' : 'text-[#64748B] hover:text-[#0F172A]'}`}
              >
                {f}
              </button>
            ))}
          </div>
          <button className="flex items-center gap-2 px-4 py-2 text-[12px] font-bold text-[#64748B] border border-[#E2E8F0] rounded-lg hover:bg-[#F8FAFC] transition-all">
            <Filter size={14} /> View Audits
          </button>
        </div>

        <div className="bg-white">
          <table className="w-full text-left">
            <thead className="bg-[#F8FAFC] border-b border-[#E2E8F0] text-[11px] font-bold text-[#64748B] uppercase tracking-wider">
              <tr>
                <th className="py-4 px-6">Ledger ID</th>
                <th className="py-4 px-6">Provider / Booking</th>
                <th className="py-4 px-6">Payment Source</th>
                <th className="py-4 px-6 text-right">Escrow Amount</th>
                <th className="py-4 px-6 text-center">Status</th>
                <th className="py-4 px-6 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E2E8F0]">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-20 text-center">
                    <Loader2 className="animate-spin text-[#2563EB] mx-auto mb-4" size={32} />
                    <p className="text-[#94A3B8] text-[12px] font-bold uppercase tracking-wider">Syncing Ledger</p>
                  </td>
                </tr>
              ) : escrowData.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-16 text-center text-[#64748B] text-sm font-medium">
                    No matching records in the escrow ledger.
                  </td>
                </tr>
              ) : (
                escrowData.map(e => {
                  const uiStatus = e.status === 'verified' ? 'holding' : e.status === 'rejected' ? 'disputed' : 'processing';
                  return (
                    <tr key={e.id} className="hover:bg-[#F8FAFC] transition-colors">
                      <td className="py-4 px-6">
                        <p className="text-[13px] font-bold text-[#0F172A] w-24 truncate" title={e.id}>{e.id.substring(0, 8)}...</p>
                      </td>
                      <td className="py-4 px-6">
                        <p className="text-[13px] font-bold text-[#0F172A]">{e.bookings?.owner?.full_name || 'Owner'}</p>
                        <p className="text-[11px] font-bold text-[#64748B] mt-0.5 w-24 truncate" title={e.booking_id}>{e.booking_id?.substring(0, 8)}...</p>
                      </td>
                      <td className="py-4 px-6">
                        <span className="text-[12px] font-semibold text-[#475569] bg-[#F1F5F9] px-2.5 py-1 rounded-md border border-[#E2E8F0]">
                          eSewa
                        </span>
                      </td>
                      <td className="py-4 px-6 text-right">
                        <p className="text-[14px] font-black text-[#0F172A]">Rs. {e.amount}</p>
                      </td>
                      <td className="py-4 px-6 text-center">
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-md text-[10px] font-bold uppercase tracking-wider ${
                          uiStatus === 'holding' ? 'bg-[#F1F5F9] text-[#475569]' :
                          uiStatus === 'processing' ? 'bg-[#ECFDF5] text-[#059669]' :
                          'bg-[#FEF2F2] text-[#DC2626]'
                        }`}>
                          {uiStatus}
                        </span>
                      </td>
                      <td className="py-4 px-6 text-right">
                        {uiStatus === 'disputed' ? (
                          <button className="text-[12px] font-bold text-white bg-red-600 hover:bg-red-700 px-4 py-1.5 rounded-md transition-colors flex items-center gap-2 ml-auto">
                            <AlertOctagon size={14} /> Review
                          </button>
                        ) : uiStatus === 'holding' ? (
                          <button className="text-[12px] font-bold text-[#2563EB] border border-[#2563EB] hover:bg-[#2563EB] hover:text-white px-4 py-1.5 rounded-md transition-colors flex items-center gap-2 ml-auto">
                            <Unlock size={14} /> Release
                          </button>
                        ) : (
                          <button className="w-8 h-8 rounded-full bg-white border border-[#E2E8F0] flex items-center justify-center text-[#64748B] hover:text-[#0F172A] ml-auto">
                            <Eye size={14} />
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
