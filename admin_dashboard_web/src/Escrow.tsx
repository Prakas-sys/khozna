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
  Loader2,
  Lock,
  ArrowUpRight
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
    <div className="flex-1 overflow-y-auto px-8 py-8 bg-[#FAFAFA]">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">Escrow Treasury</h2>
          <p className="text-[#737373] text-[13px]">Manage platform-held liquidity and security deposits.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div className="card-minimal p-6 border-b-2 border-b-[#171717]">
          <div className="flex items-center justify-between mb-4">
            <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">In Custody</span>
            <Lock size={16} strokeWidth={1.5} className="text-[#A3A3A3]" />
          </div>
          <p className="text-[24px] font-semibold text-[#171717]">
            NPR {loading ? '--' : escrowData.filter(d => d.status === 'verified').reduce((a,b) => a + (b.amount || 0), 0).toLocaleString()}
          </p>
          <div className="flex items-center gap-1.5 mt-2 text-[#A3A3A3] text-[11px] font-medium">
            <Activity size={10} /> Internal platform liquidity active
          </div>
        </div>

        <div className="card-minimal p-6">
          <div className="flex items-center justify-between mb-4">
            <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Pending Audit</span>
            <HelpCircle size={16} strokeWidth={1.5} className="text-[#A3A3A3]" />
          </div>
          <p className="text-[24px] font-semibold text-[#171717]">
            {loading ? '--' : escrowData.filter(d => d.status === 'rejected').length} <span className="text-[14px] font-medium text-[#A3A3A3]">Disputes</span>
          </p>
          <p className="text-[11px] text-[#A3A3A3] mt-1.5 flex items-center gap-1">
             Actionable records found
          </p>
        </div>

        <div className="card-minimal p-6">
          <div className="flex items-center justify-between mb-4">
            <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Rolling Payouts</span>
            <ArrowRight size={16} strokeWidth={1.5} className="text-[#A3A3A3]" />
          </div>
          <p className="text-[24px] font-semibold text-[#171717]">NPR 0</p>
          <p className="text-[11px] text-[#A3A3A3] mt-1.5">No disbursements scheduled today</p>
        </div>
      </div>

      <div className="card-minimal overflow-hidden shadow-xs">
        <div className="px-5 py-4 bg-white border-b border-[#E5E5E5] flex items-center justify-between">
          <div className="flex items-center bg-[#F5F5F5] p-0.5 rounded-lg border border-[#E5E5E5]">
            {['all', 'holding', 'disputed'].map(f => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3.5 py-1.5 text-[11px] font-semibold rounded-md capitalize transition-all ${filter === f ? 'bg-white text-[#171717] shadow-xs border border-[#E5E5E5]' : 'text-[#737373] hover:text-[#171717]'}`}
              >
                {f}
              </button>
            ))}
          </div>
          <button className="flex items-center gap-2 px-3.5 py-1.5 text-[12px] font-semibold text-[#525252] border border-[#E5E5E5] rounded-lg hover:bg-[#FAFAFA] transition-all shadow-xs">
            <Filter size={14} strokeWidth={1.5} /> Audits
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-[#FAFAFA] border-b border-[#E5E5E5] text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider">
              <tr>
                <th className="py-4 px-6">Ledger Entry</th>
                <th className="py-4 px-6">Source / Booking</th>
                <th className="py-4 px-6">Channel</th>
                <th className="py-4 px-6 text-right">Balance</th>
                <th className="py-4 px-6 text-center">Protocol</th>
                <th className="py-4 px-6 text-right"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F5F5F5]">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-20 text-center">
                    <Loader2 className="animate-spin text-[#171717] mx-auto mb-3" size={24} strokeWidth={1.5} />
                    <p className="text-[#A3A3A3] text-[12px] font-medium uppercase tracking-widest">Syncing Treasury</p>
                  </td>
                </tr>
              ) : escrowData.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-16 text-center">
                    <p className="text-[#A3A3A3] text-[13px] font-medium">No active records in the escrow register.</p>
                  </td>
                </tr>
              ) : (
                escrowData.map(e => {
                  const uiStatus = e.status === 'verified' ? 'holding' : e.status === 'rejected' ? 'disputed' : 'processing';
                  return (
                    <tr key={e.id} className="hover:bg-[#FAFAFA] transition-colors group">
                      <td className="py-4 px-6">
                        <p className="text-[11px] font-mono font-medium text-[#171717] uppercase tracking-wider" title={e.id}>ENTRY_{e.id.substring(0, 8)}</p>
                      </td>
                      <td className="py-4 px-6">
                        <p className="text-[13px] font-semibold text-[#171717]">{e.bookings?.owner?.full_name || 'System Provider'}</p>
                        <p className="text-[10px] font-mono text-[#A3A3A3] mt-0.5 tracking-tight border-l border-[#E5E5E5] pl-2">BK_{e.booking_id?.substring(0, 8)}</p>
                      </td>
                      <td className="py-4 px-6">
                        <span className="text-[10px] font-semibold text-[#737373] bg-[#F5F5F5] px-2 py-0.5 rounded border border-[#E5E5E5] uppercase tracking-wider">
                          Internal
                        </span>
                      </td>
                      <td className="py-4 px-6 text-right">
                        <p className="text-[14px] font-semibold text-[#171717]">NPR {e.amount.toLocaleString()}</p>
                      </td>
                      <td className="py-4 px-6 text-center">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-semibold uppercase tracking-wider border ${
                          uiStatus === 'holding' ? 'bg-[#FAFAFA] text-[#737373] border-[#E5E5E5]' :
                          uiStatus === 'processing' ? 'bg-emerald-50 text-emerald-600 border-emerald-100' :
                          'bg-rose-50 text-rose-600 border-rose-100'
                        }`}>
                          {uiStatus}
                        </span>
                      </td>
                      <td className="py-4 px-6 text-right">
                        {uiStatus === 'disputed' ? (
                          <button className="h-8 px-3.5 bg-rose-500 text-white text-[11px] font-semibold rounded-lg hover:bg-rose-600 transition-all flex items-center justify-center gap-1.5 ml-auto shadow-sm">
                            <AlertOctagon size={12} strokeWidth={1.5} /> Resolve
                          </button>
                        ) : uiStatus === 'holding' ? (
                          <button className="h-8 px-3.5 border border-[#E5E5E5] bg-white text-[#171717] text-[11px] font-semibold rounded-lg hover:bg-[#FAFAFA] transition-all flex items-center justify-center gap-1.5 ml-auto shadow-xs">
                            <Unlock size={12} strokeWidth={1.5} /> Release
                          </button>
                        ) : (
                          <button className="w-8 h-8 rounded-lg bg-white border border-[#E5E5E5] flex items-center justify-center text-[#A3A3A3] hover:text-[#171717] opacity-0 group-hover:opacity-100 ml-auto transition-all shadow-xs">
                            <Eye size={14} strokeWidth={1.5} />
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
