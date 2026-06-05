import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { 
  CalendarDays, 
  MapPin, 
  Search, 
  Filter,
  CheckCircle2,
  Clock,
  XCircle,
  Eye,
  Calendar,
  Loader2,
  ArrowUpRight
} from 'lucide-react';

export const Bookings = () => {
  const [filter, setFilter] = useState('pending');
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchBookings();
  }, [filter]);

  const fetchBookings = async () => {
    setLoading(true);
    try {
      let query = supabase
        .from('bookings')
        .select(`
          *,
          properties (title, location),
          guest:profiles!bookings_guest_id_fkey (full_name)
        `)
        .order('created_at', { ascending: false });

      if (filter !== 'all') {
        query = query.eq('status', filter);
      }

      const { data, error } = await query;
      if (error) throw error;
      setBookings(data || []);
    } catch (e) {
      console.error('Error fetching bookings:', e);
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    if (status === 'confirmed') return <CheckCircle2 size={12} strokeWidth={1.5} />;
    if (status === 'cancelled') return <XCircle size={12} strokeWidth={1.5} />;
    return <Clock size={12} strokeWidth={1.5} />;
  };

  return (
    <div className="flex-1 overflow-y-auto px-8 py-8 bg-[#FAFAFA]">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">Bookings Hub</h2>
          <p className="text-[#737373] text-[13px]">Manage and audit reservation records.</p>
        </div>
      </div>

      <div className="card-minimal overflow-hidden">
        {/* Toolbar */}
        <div className="px-5 py-4 bg-white border-b border-[#E5E5E5] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="relative">
              <Search size={14} strokeWidth={1.5} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#A3A3A3]" />
              <input 
                type="text" 
                placeholder="Search rentals..." 
                className="pl-9 pr-3 py-[7px] bg-[#FAFAFA] border border-[#E5E5E5] rounded-lg text-[13px] font-medium outline-none focus:border-[#A3A3A3] w-64 transition-all"
              />
            </div>
            <div className="flex items-center bg-[#F5F5F5] p-0.5 rounded-lg border border-[#E5E5E5]">
              {['pending', 'confirmed', 'cancelled', 'all'].map(f => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-3.5 py-1.5 text-[11px] font-semibold rounded-md capitalize transition-all ${filter === f ? 'bg-white text-[#171717] shadow-xs border border-[#E5E5E5]' : 'text-[#737373] hover:text-[#171717]'}`}
                >
                  {f}
                </button>
              ))}
            </div>
          </div>
          <button className="flex items-center gap-2 px-3 py-1.5 text-[12px] font-semibold text-[#525252] border border-[#E5E5E5] rounded-lg hover:bg-[#FAFAFA] transition-all shadow-xs">
            <Filter size={14} strokeWidth={1.5} /> Advanced
          </button>
        </div>

        {/* Table */}
        <div className="bg-white">
          <table className="w-full text-left">
            <thead className="bg-[#FAFAFA] border-b border-[#E5E5E5] text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider">
              <tr>
                <th className="py-4 px-6">Guest & UUID</th>
                <th className="py-4 px-6">Property Context</th>
                <th className="py-4 px-6">Duration</th>
                <th className="py-4 px-6">Status</th>
                <th className="py-4 px-6 text-right">Ledger Total</th>
                <th className="py-4 px-6 text-center"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F5F5F5]">
              {bookings.map(b => (
                <tr key={b.id} className="hover:bg-[#FAFAFA] transition-colors group">
                  <td className="py-4 px-6">
                    <p className="text-[13px] font-semibold text-[#171717]">{b.guest?.full_name || 'Anonymous'}</p>
                    <p className="text-[11px] text-[#A3A3A3] mt-0.5 font-mono truncate w-24" title={b.id}>{b.id.substring(0, 8)}</p>
                  </td>
                  <td className="py-4 px-6">
                    <p className="text-[13px] font-medium text-[#171717]">{b.properties?.title || 'Unknown Asset'}</p>
                    <div className="flex items-center gap-1 text-[11px] text-[#A3A3A3] mt-0.5">
                      <MapPin size={10} strokeWidth={1.5} /> {b.properties?.location || 'Digital Asset'}
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    <div className="flex flex-col gap-0.5">
                      <div className="flex items-center gap-2 text-[12px] font-medium text-[#171717]">
                        <span className="w-1.5 h-1.5 rounded-full bg-[#171717]/10 border border-[#171717]/20"></span>
                        {new Date(b.check_in).toLocaleDateString()}
                      </div>
                      <div className="flex items-center gap-2 text-[11px] text-[#737373]">
                        <span className="w-1.5 h-1.5 rounded-full bg-rose-400/20 border border-rose-400/30"></span>
                        {new Date(b.check_out).toLocaleDateString()}
                      </div>
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md text-[10px] font-semibold uppercase tracking-wider border ${
                      b.status === 'pending' || b.status === 'awaiting_payment' ? 'bg-orange-50 text-orange-600 border-orange-100' :
                      b.status === 'confirmed' ? 'bg-emerald-50 text-emerald-600 border-emerald-100' :
                      'bg-rose-50 text-rose-600 border-rose-100'
                    }`}>
                      {getStatusIcon(b.status)}
                      {b.status.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-right">
                    <p className="text-[14px] font-semibold text-[#171717]">NPR {b.total_price.toLocaleString()}</p>
                  </td>
                  <td className="py-4 px-6 text-center">
                    <button className="w-8 h-8 rounded-lg bg-white border border-[#E5E5E5] shadow-xs flex items-center justify-center text-[#A3A3A3] hover:text-[#171717] hover:border-[#A3A3A3] transition-all mx-auto opacity-0 group-hover:opacity-100">
                      <ArrowUpRight size={14} strokeWidth={1.5} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          
          {loading && (
            <div className="py-20 flex flex-col items-center justify-center gap-3">
              <div className="w-5 h-5 border-2 border-[#E5E5E5] border-t-[#171717] rounded-full animate-spin" />
              <p className="text-[12px] text-[#A3A3A3] font-medium">Fetching register...</p>
            </div>
          )}

          {!loading && bookings.length === 0 && (
            <div className="empty-state">
              <div className="empty-state-icon">
                <CalendarDays size={20} strokeWidth={1.5} />
              </div>
              <p className="empty-state-title">No bookings found</p>
              <p className="empty-state-desc">Try adjusting filters or search terms.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
