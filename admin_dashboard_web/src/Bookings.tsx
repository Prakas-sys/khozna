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
  Loader2
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
    if (status === 'confirmed') return <CheckCircle2 size={12} />;
    if (status === 'cancelled') return <XCircle size={12} />;
    return <Clock size={12} />;
  };

  return (
    <div className="flex-1 overflow-y-auto px-12 py-12 bg-[#F8FAFC]">
      <div className="flex items-center justify-between mb-10">
        <div>
          <h2 className="text-3xl font-bold text-[#0F172A] tracking-tight mb-2">Bookings Directory</h2>
          <p className="text-[#64748B] text-sm font-medium">Manage and audit all platform property reservations across Nepal.</p>
        </div>
        <div className="flex gap-4">
          <button className="px-6 py-2.5 bg-[#2563EB] text-white rounded-lg text-[13px] font-bold hover:bg-blue-700 transition-all shadow-sm flex items-center gap-2">
            <Calendar size={16} />
            Add Extranet Booking
          </button>
        </div>
      </div>

      <div className="card-pro overflow-hidden">
        {/* Toolbar */}
        <div className="px-6 py-4 bg-white border-b border-[#E2E8F0] flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="relative">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
              <input 
                type="text" 
                placeholder="Search by ID or Guest..." 
                className="pl-10 pr-4 py-2 bg-[#F8FAFC] border border-[#E2E8F0] rounded-lg text-[13px] font-medium outline-none focus:border-[#2563EB] w-64 transition-all"
              />
            </div>
            <div className="flex items-center bg-[#F8FAFC] p-1 rounded-lg border border-[#E2E8F0]">
              {['pending', 'confirmed', 'cancelled', 'all'].map(f => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-4 py-1.5 text-[11px] font-bold rounded-md capitalize transition-colors ${filter === f ? 'bg-white text-[#2563EB] shadow-sm border border-[#E2E8F0]' : 'text-[#64748B] hover:text-[#0F172A]'}`}
                >
                  {f}
                </button>
              ))}
            </div>
          </div>
          <button className="flex items-center gap-2 px-4 py-2 text-[12px] font-bold text-[#64748B] border border-[#E2E8F0] rounded-lg hover:bg-[#F8FAFC] transition-all">
            <Filter size={14} /> Filters
          </button>
        </div>

        {/* Table */}
        <div className="bg-white">
          <table className="w-full text-left">
            <thead className="bg-[#F8FAFC] border-b border-[#E2E8F0] text-[11px] font-bold text-[#64748B] uppercase tracking-wider">
              <tr>
                <th className="py-4 px-6">Booking ID & Guest</th>
                <th className="py-4 px-6">Property / Location</th>
                <th className="py-4 px-6">Check In / Out</th>
                <th className="py-4 px-6">Status</th>
                <th className="py-4 px-6 text-right">Pricing</th>
                <th className="py-4 px-6 text-center">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E2E8F0]">
              {bookings.map(b => (
                <tr key={b.id} className="hover:bg-[#F8FAFC] transition-colors">
                  <td className="py-4 px-6">
                    <p className="text-[14px] font-bold text-[#0F172A]">{b.guest?.full_name || 'Guest User'}</p>
                    <p className="text-[12px] font-medium text-[#64748B] mt-1 pr-4 truncate w-32" title={b.id}>{b.id.substring(0, 8)}...</p>
                  </td>
                  <td className="py-4 px-6">
                    <p className="text-[13px] font-bold text-[#0F172A]">{b.properties?.title || 'Unknown Property'}</p>
                    <div className="flex items-center gap-1 text-[11px] font-semibold text-[#64748B] mt-1">
                      <MapPin size={12} /> {b.properties?.location || 'Nepal'}
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    <div className="flex flex-col gap-1">
                      <div className="flex items-center gap-2 text-[12px] font-semibold text-[#0F172A]">
                        <span className="w-2 h-2 rounded-full bg-green-500"></span>
                        {new Date(b.check_in).toLocaleDateString()}
                      </div>
                      <div className="flex items-center gap-2 text-[12px] font-semibold text-[#64748B]">
                        <span className="w-2 h-2 rounded-full bg-red-400"></span>
                        {new Date(b.check_out).toLocaleDateString()}
                      </div>
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[10px] font-bold uppercase tracking-wider ${
                      b.status === 'pending' || b.status === 'awaiting_payment' ? 'bg-blue-50 text-blue-700' :
                      b.status === 'confirmed' ? 'bg-emerald-50 text-emerald-700' :
                      'bg-red-50 text-red-700'
                    }`}>
                      {getStatusIcon(b.status)}
                      {b.status.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-right">
                    <p className="text-[14px] font-black text-[#0F172A]">Rs. {b.total_price}</p>
                  </td>
                  <td className="py-4 px-6 text-center">
                    <button className="w-8 h-8 rounded-full bg-white border border-[#E2E8F0] shadow-sm flex items-center justify-center text-[#64748B] hover:text-[#2563EB] hover:border-[#2563EB] transition-all mx-auto">
                      <Eye size={16} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          
          {loading && (
            <div className="py-16 flex justify-center items-center">
              <Loader2 className="animate-spin text-[#2563EB]" size={32} />
            </div>
          )}

          {!loading && bookings.length === 0 && (
            <div className="py-16 text-center flex flex-col items-center">
              <CalendarDays size={40} className="text-[#CBD5E1] mb-3" />
              <p className="text-[13px] font-bold text-[#0F172A]">No bookings found</p>
              <p className="text-[12px] text-[#64748B] mt-1">Try adjusting your filters or search query.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
