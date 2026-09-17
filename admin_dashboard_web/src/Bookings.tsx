import { useState, useEffect, useCallback } from 'react';
import { supabase } from './lib/supabase';
import {
  CalendarDays, Search, CheckCircle2, Clock,
  Home, AlertTriangle, RefreshCw, X, MapPin,
  CreditCard, FileText, ChevronRight, TrendingUp, Banknote
} from 'lucide-react';

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

interface BookingRecord {
  id: string;
  property_id: string;
  guest_id: string;
  owner_id: string;
  check_in: string;
  check_out: string;
  total_price: number;
  status: string;
  booking_status: string;
  payment_status: string;
  payment_type: string | null;
  payment_reference: string | null;
  payment_proof_url: string | null;
  rejection_reason: string | null;
  created_at: string;
  updated_at: string;
  guests?: number;
  properties?: { title: string; location?: string; area_name?: string; images?: string[] } | null;
  guest?: { full_name: string; avatar_url?: string; phone_number?: string } | null;
  owner?: { full_name: string; avatar_url?: string } | null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const fmt = (n: number) => new Intl.NumberFormat('en-NP').format(n);
const fmtDate = (d: string) => new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
const fmtDateTime = (d: string) => new Date(d).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });

function nights(checkIn: string, checkOut: string) {
  const diff = new Date(checkOut).getTime() - new Date(checkIn).getTime();
  return Math.max(1, Math.round(diff / (1000 * 60 * 60 * 24)));
}

function formattedBookingId(id: string) {
  return `KZ-${id.replace(/-/g, '').substring(0, 6).toUpperCase()}`;
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge Components
// ─────────────────────────────────────────────────────────────────────────────

const BOOKING_STATUS_CONFIG: Record<string, { label: string; color: string; dot: string }> = {
  pending:   { label: 'Pending Owner',  color: 'bg-amber-50 text-amber-700 border-amber-200',    dot: 'bg-amber-500' },
  accepted:  { label: 'Accepted',       color: 'bg-blue-50 text-blue-700 border-blue-200',        dot: 'bg-blue-500' },
  confirmed: { label: 'Confirmed',      color: 'bg-emerald-50 text-emerald-700 border-emerald-200', dot: 'bg-emerald-500' },
  declined:  { label: 'Declined',       color: 'bg-rose-50 text-rose-700 border-rose-200',        dot: 'bg-rose-500' },
  cancelled: { label: 'Cancelled',      color: 'bg-gray-100 text-gray-600 border-gray-200',       dot: 'bg-gray-400' },
  completed: { label: 'Completed',      color: 'bg-teal-50 text-teal-700 border-teal-200',        dot: 'bg-teal-500' },
};

const PAYMENT_STATUS_CONFIG: Record<string, { label: string; color: string; dot: string }> = {
  not_required:       { label: 'Not Required',  color: 'bg-gray-50 text-gray-500 border-gray-200',        dot: 'bg-gray-300' },
  payment_pending:    { label: 'Awaiting Pymt', color: 'bg-orange-50 text-orange-700 border-orange-200',  dot: 'bg-orange-500' },
  payment_submitted:  { label: 'Pymt Submitted',color: 'bg-indigo-50 text-indigo-700 border-indigo-200',  dot: 'bg-indigo-500' },
  payment_confirmed:  { label: 'Pymt Confirmed',color: 'bg-emerald-50 text-emerald-700 border-emerald-200', dot: 'bg-emerald-500' },
  payment_issue:      { label: 'Pymt Issue',    color: 'bg-rose-50 text-rose-700 border-rose-200',        dot: 'bg-rose-500' },
};

function deriveBookingStatus(b: BookingRecord): string {
  if (b.booking_status) return b.booking_status;
  const s = b.status;
  if (s === 'confirmed') return 'confirmed';
  if (s === 'cancelled' || s === 'canceled') return 'cancelled';
  if (s === 'rejected' || s === 'visit_rejected') return 'declined';
  if (s === 'visit_accepted' || s === 'awaiting_payment' || s === 'paid' || s === 'payment_submitted') return 'accepted';
  return 'pending';
}

function derivePaymentStatus(b: BookingRecord): string {
  if (b.payment_status) return b.payment_status;
  const s = b.status;
  if (s === 'confirmed') return 'payment_confirmed';
  if (s === 'paid' || s === 'payment_submitted') return 'payment_submitted';
  if (s === 'awaiting_payment' || s === 'visit_accepted') return 'payment_pending';
  return 'not_required';
}

const StatusBadge = ({ config }: { config: { label: string; color: string; dot: string } }) => (
  <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md text-[10px] font-semibold uppercase tracking-wider border ${config.color}`}>
    <span className={`w-1.5 h-1.5 rounded-full ${config.dot}`} />
    {config.label}
  </span>
);

// ─────────────────────────────────────────────────────────────────────────────
// KPI Card
// ─────────────────────────────────────────────────────────────────────────────

interface KpiProps {
  label: string;
  value: number | string;
  icon: React.ReactNode;
  accent: string;
  sub?: string;
}

const KpiCard = ({ label, value, icon, accent, sub }: KpiProps) => (
  <div className="bg-white rounded-2xl border border-[#E5E5E5] p-5 flex items-start gap-4 hover:shadow-sm transition-shadow">
    <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${accent}`}>
      {icon}
    </div>
    <div>
      <p className="text-[11px] text-[#A3A3A3] font-semibold uppercase tracking-wider mb-1">{label}</p>
      <p className="text-[22px] font-black text-[#171717] leading-none">{value}</p>
      {sub && <p className="text-[11px] text-[#A3A3A3] mt-1">{sub}</p>}
    </div>
  </div>
);

// ─────────────────────────────────────────────────────────────────────────────
// Timeline event
// ─────────────────────────────────────────────────────────────────────────────

const TimelineEvent = ({ icon, label, time, done }: {
  icon: React.ReactNode; label: string; time?: string; done: boolean;
}) => (
  <div className="flex items-start gap-3">
    <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 border-2 ${
      done ? 'bg-[#00A3E1] border-[#00A3E1] text-white' : 'bg-white border-[#E5E5E5] text-[#A3A3A3]'
    }`}>
      {icon}
    </div>
    <div className="pt-1">
      <p className={`text-[13px] font-semibold ${done ? 'text-[#171717]' : 'text-[#A3A3A3]'}`}>{label}</p>
      {time && <p className="text-[11px] text-[#A3A3A3] mt-0.5">{time}</p>}
    </div>
  </div>
);

// ─────────────────────────────────────────────────────────────────────────────
// Detail Modal
// ─────────────────────────────────────────────────────────────────────────────

const DetailModal = ({ booking, onClose }: { booking: BookingRecord; onClose: () => void }) => {
  const bStatus = deriveBookingStatus(booking);
  const pStatus = derivePaymentStatus(booking);
  const n = nights(booking.check_in, booking.check_out);
  const bCfg = BOOKING_STATUS_CONFIG[bStatus] ?? BOOKING_STATUS_CONFIG['pending'];
  const pCfg = PAYMENT_STATUS_CONFIG[pStatus] ?? PAYMENT_STATUS_CONFIG['not_required'];

  const timelineSteps = [
    { label: 'Booking Requested',       done: true,                          time: fmtDateTime(booking.created_at), icon: <FileText size={14} /> },
    { label: 'Owner Accepted',          done: bStatus !== 'pending',          time: bStatus !== 'pending' ? fmtDateTime(booking.updated_at) : undefined, icon: <CheckCircle2 size={14} /> },
    { label: 'Payment Instructions Provided', done: pStatus !== 'not_required', time: undefined, icon: <CreditCard size={14} /> },
    { label: 'Guest Submitted Payment', done: ['payment_submitted','payment_confirmed'].includes(pStatus), time: undefined, icon: <Banknote size={14} /> },
    { label: 'Owner Confirmed Payment', done: pStatus === 'payment_confirmed', time: undefined, icon: <CheckCircle2 size={14} /> },
    { label: 'Booking Confirmed',       done: bStatus === 'confirmed' || bStatus === 'completed', time: undefined, icon: <Home size={14} /> },
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/40 backdrop-blur-sm" onClick={onClose}>
      <div
        className="bg-white rounded-t-3xl sm:rounded-2xl w-full sm:max-w-xl max-h-[90vh] overflow-y-auto shadow-2xl"
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="sticky top-0 bg-white border-b border-[#F0F0F0] px-6 py-5 flex items-start justify-between rounded-t-3xl sm:rounded-t-2xl">
          <div>
            <p className="text-[11px] text-[#A3A3A3] font-semibold uppercase tracking-wider mb-1">Booking Details</p>
            <p className="text-[20px] font-black text-[#171717] leading-tight">{formattedBookingId(booking.id)}</p>
          </div>
          <button onClick={onClose} className="w-8 h-8 rounded-full bg-[#F5F5F5] flex items-center justify-center hover:bg-[#E5E5E5] transition-colors">
            <X size={16} />
          </button>
        </div>

        <div className="px-6 py-5 space-y-6">
          {/* Dual status row */}
          <div className="flex gap-2 flex-wrap">
            <StatusBadge config={bCfg} />
            <StatusBadge config={pCfg} />
          </div>

          {/* Property & guests */}
          <div className="bg-[#FAFAFA] rounded-xl p-4 space-y-3">
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#00A3E1]/10 flex items-center justify-center flex-shrink-0">
                <Home size={16} className="text-[#00A3E1]" />
              </div>
              <div>
                <p className="text-[14px] font-bold text-[#171717]">{booking.properties?.title ?? 'Property'}</p>
                {(booking.properties?.area_name || booking.properties?.location) && (
                  <div className="flex items-center gap-1 text-[11px] text-[#A3A3A3] mt-0.5">
                    <MapPin size={10} />
                    {booking.properties?.area_name ?? booking.properties?.location}
                  </div>
                )}
              </div>
            </div>
            <div className="grid grid-cols-3 gap-3">
              <div className="bg-white rounded-lg p-3 border border-[#E5E5E5]">
                <p className="text-[10px] text-[#A3A3A3] font-semibold uppercase">Check-in</p>
                <p className="text-[12px] font-bold text-[#171717] mt-0.5">{fmtDate(booking.check_in)}</p>
              </div>
              <div className="bg-white rounded-lg p-3 border border-[#E5E5E5]">
                <p className="text-[10px] text-[#A3A3A3] font-semibold uppercase">Check-out</p>
                <p className="text-[12px] font-bold text-[#171717] mt-0.5">{fmtDate(booking.check_out)}</p>
              </div>
              <div className="bg-white rounded-lg p-3 border border-[#E5E5E5]">
                <p className="text-[10px] text-[#A3A3A3] font-semibold uppercase">Duration</p>
                <p className="text-[12px] font-bold text-[#171717] mt-0.5">{n} {n === 1 ? 'night' : 'nights'}</p>
              </div>
            </div>
          </div>

          {/* People */}
          <div className="grid grid-cols-2 gap-3">
            <div className="bg-[#FAFAFA] rounded-xl p-4">
              <p className="text-[10px] text-[#A3A3A3] font-semibold uppercase mb-2">Guest</p>
              <p className="text-[13px] font-bold text-[#171717]">{booking.guest?.full_name ?? '—'}</p>
            </div>
            <div className="bg-[#FAFAFA] rounded-xl p-4">
              <p className="text-[10px] text-[#A3A3A3] font-semibold uppercase mb-2">Property Owner</p>
              <p className="text-[13px] font-bold text-[#171717]">{booking.owner?.full_name ?? '—'}</p>
            </div>
          </div>

          {/* Amount */}
          <div className="bg-[#00A3E1]/05 border border-[#00A3E1]/20 rounded-xl p-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] text-[#00A3E1] font-semibold uppercase">Total Booking Value</p>
              <p className="text-[10px] text-[#A3A3A3] mt-0.5">Paid directly to property owner</p>
            </div>
            <p className="text-[22px] font-black text-[#00A3E1]">NPR {fmt(booking.total_price)}</p>
          </div>

          {/* Payment proof */}
          {booking.payment_reference && (
            <div className="bg-[#FAFAFA] rounded-xl p-4">
              <p className="text-[11px] text-[#A3A3A3] font-semibold uppercase mb-2">Payment Reference</p>
              <p className="text-[14px] font-bold text-[#171717] font-mono">{booking.payment_reference}</p>
              {booking.payment_type && (
                <p className="text-[11px] text-[#A3A3A3] mt-1 capitalize">via {booking.payment_type.replace('_', ' ')}</p>
              )}
            </div>
          )}
          {booking.payment_proof_url && (
            <div>
              <p className="text-[11px] text-[#A3A3A3] font-semibold uppercase mb-2">Payment Screenshot</p>
              <img src={booking.payment_proof_url} alt="Payment proof" className="w-full rounded-xl border border-[#E5E5E5] object-cover max-h-48" />
            </div>
          )}

          {/* Rejection reason */}
          {booking.rejection_reason && (
            <div className="bg-rose-50 border border-rose-100 rounded-xl p-4">
              <p className="text-[11px] text-rose-500 font-semibold uppercase mb-1">Rejection Reason</p>
              <p className="text-[13px] text-rose-700">{booking.rejection_reason}</p>
            </div>
          )}

          {/* Timeline */}
          <div>
            <p className="text-[12px] font-bold text-[#171717] uppercase tracking-wider mb-4">Booking Timeline</p>
            <div className="relative pl-4">
              {/* Vertical line */}
              <div className="absolute left-[19px] top-4 bottom-4 w-0.5 bg-[#E5E5E5]" />
              <div className="space-y-5">
                {timelineSteps.map((step, i) => (
                  <TimelineEvent key={i} icon={step.icon} label={step.label} time={step.time} done={step.done} />
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────────
// Main Bookings Component
// ─────────────────────────────────────────────────────────────────────────────

export const Bookings = () => {
  const [bookings, setBookings] = useState<BookingRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [bookingFilter, setBookingFilter] = useState('all');
  const [paymentFilter, setPaymentFilter] = useState('all');
  const [selectedBooking, setSelectedBooking] = useState<BookingRecord | null>(null);
  const [lastRefresh, setLastRefresh] = useState(new Date());

  const fetchBookings = useCallback(async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('bookings')
        .select(`
          *,
          properties(title, location, area_name, images),
          guest:profiles!bookings_guest_id_fkey(full_name, avatar_url, phone_number),
          owner:profiles!bookings_owner_id_fkey(full_name, avatar_url)
        `)
        .order('created_at', { ascending: false })
        .limit(500);

      if (error) throw error;
      setBookings(data || []);
      setLastRefresh(new Date());
    } catch (e) {
      console.error('Error fetching bookings:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchBookings(); }, [fetchBookings]);

  // ─── Filtering ─────────────────────────────────────────────────────────────
  const filtered = bookings.filter(b => {
    const bStatus = deriveBookingStatus(b);
    const pStatus = derivePaymentStatus(b);
    const q = search.toLowerCase();
    const matchSearch = !q ||
      b.guest?.full_name?.toLowerCase().includes(q) ||
      b.properties?.title?.toLowerCase().includes(q) ||
      b.owner?.full_name?.toLowerCase().includes(q) ||
      formattedBookingId(b.id).toLowerCase().includes(q);
    const matchBooking = bookingFilter === 'all' || bStatus === bookingFilter;
    const matchPayment = paymentFilter === 'all' || pStatus === paymentFilter;
    return matchSearch && matchBooking && matchPayment;
  });

  // ─── KPIs ─────────────────────────────────────────────────────────────────
  const totalRequests    = bookings.length;
  const pendingOwner     = bookings.filter(b => deriveBookingStatus(b) === 'pending').length;
  const paymentSubmitted = bookings.filter(b => derivePaymentStatus(b) === 'payment_submitted').length;
  const confirmed        = bookings.filter(b => deriveBookingStatus(b) === 'confirmed').length;
  const totalValue       = bookings.filter(b => deriveBookingStatus(b) === 'confirmed').reduce((s, b) => s + (b.total_price ?? 0), 0);

  const BOOKING_FILTERS = ['all', 'pending', 'accepted', 'confirmed', 'declined', 'cancelled'];
  const PAYMENT_FILTERS = ['all', 'payment_pending', 'payment_submitted', 'payment_confirmed', 'payment_issue'];

  return (
    <div className="flex-1 overflow-y-auto px-6 py-8 bg-[#FAFAFA]">

      {/* Header */}
      <div className="flex items-start justify-between mb-8">
        <div>
          <h2 className="text-[24px] font-black text-[#171717] tracking-tight mb-1">Bookings</h2>
          <p className="text-[#737373] text-[13px]">
            Monitor booking lifecycle · Direct owner payment tracking · Full audit trail
          </p>
        </div>
        <button
          onClick={fetchBookings}
          className="flex items-center gap-2 px-4 py-2 text-[12px] font-semibold text-[#525252] border border-[#E5E5E5] rounded-xl hover:bg-white transition-all shadow-sm"
        >
          <RefreshCw size={13} className={loading ? 'animate-spin' : ''} />
          Refresh
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
        <KpiCard label="Total Requests"    value={totalRequests}    icon={<CalendarDays size={18} className="text-[#00A3E1]" />}    accent="bg-[#00A3E1]/10"  />
        <KpiCard label="Pending Owner"     value={pendingOwner}     icon={<Clock size={18} className="text-amber-600" />}             accent="bg-amber-50"      />
        <KpiCard label="Awaiting Payment"  value={paymentSubmitted} icon={<AlertTriangle size={18} className="text-indigo-600" />}    accent="bg-indigo-50"     />
        <KpiCard label="Confirmed"         value={confirmed}        icon={<CheckCircle2 size={18} className="text-emerald-600" />}    accent="bg-emerald-50"    />
        <KpiCard label="Total Value"       value={`NPR ${fmt(totalValue)}`} icon={<TrendingUp size={18} className="text-teal-600" />} accent="bg-teal-50" sub="Confirmed bookings" />
      </div>

      {/* Notice */}
      <div className="bg-blue-50 border border-blue-100 rounded-xl px-5 py-3 flex items-center gap-3 mb-6">
        <Banknote size={16} className="text-blue-600 flex-shrink-0" />
        <p className="text-[12px] text-blue-700 font-medium">
          <strong>V1 Direct Payment Model:</strong> All payments are made directly from guests to property owners.
          KHOZNA does not collect or hold any funds. This table tracks booking value for analytics only.
        </p>
      </div>

      {/* Table card */}
      <div className="bg-white rounded-2xl border border-[#E5E5E5] overflow-hidden">

        {/* Toolbar */}
        <div className="px-6 py-4 border-b border-[#F0F0F0] flex flex-col sm:flex-row gap-3 items-start sm:items-center justify-between">
          <div className="relative">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#A3A3A3]" />
            <input
              type="text"
              placeholder="Search by guest, property, owner, or ID..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="pl-9 pr-3 py-[7px] bg-[#FAFAFA] border border-[#E5E5E5] rounded-xl text-[13px] font-medium outline-none focus:border-[#00A3E1] w-72 transition-all"
            />
          </div>
          <div className="flex gap-2 flex-wrap">
            {/* Booking status filters */}
            <div className="flex items-center bg-[#F5F5F5] p-0.5 rounded-lg border border-[#E5E5E5]">
              {BOOKING_FILTERS.map(f => (
                <button
                  key={f}
                  onClick={() => setBookingFilter(f)}
                  className={`px-2.5 py-1 text-[11px] font-semibold rounded-md capitalize transition-all ${
                    bookingFilter === f ? 'bg-white text-[#171717] shadow-sm border border-[#E5E5E5]' : 'text-[#737373] hover:text-[#171717]'
                  }`}
                >
                  {f === 'all' ? 'All Status' : f}
                </button>
              ))}
            </div>
            {/* Payment status filters */}
            <select
              value={paymentFilter}
              onChange={e => setPaymentFilter(e.target.value)}
              className="px-3 py-1.5 text-[11px] font-semibold bg-white border border-[#E5E5E5] rounded-lg text-[#525252] outline-none hover:border-[#A3A3A3] transition-all"
            >
              <option value="all">All Payments</option>
              {PAYMENT_FILTERS.filter(f => f !== 'all').map(f => (
                <option key={f} value={f}>{f.replace(/_/g, ' ')}</option>
              ))}
            </select>
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left min-w-[960px]">
            <thead className="bg-[#FAFAFA] border-b border-[#E5E5E5] text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider">
              <tr>
                <th className="py-3.5 px-5">Booking ID</th>
                <th className="py-3.5 px-5">Guest</th>
                <th className="py-3.5 px-5">Property</th>
                <th className="py-3.5 px-5">Owner</th>
                <th className="py-3.5 px-5">Dates / Nights</th>
                <th className="py-3.5 px-5">Booking Status</th>
                <th className="py-3.5 px-5">Payment Status</th>
                <th className="py-3.5 px-5 text-right">Amount</th>
                <th className="py-3.5 px-5 text-center">Detail</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F5F5F5]">
              {filtered.map(b => {
                const bStatus = deriveBookingStatus(b);
                const pStatus = derivePaymentStatus(b);
                const bCfg = BOOKING_STATUS_CONFIG[bStatus] ?? BOOKING_STATUS_CONFIG['pending'];
                const pCfg = PAYMENT_STATUS_CONFIG[pStatus] ?? PAYMENT_STATUS_CONFIG['not_required'];
                const n = nights(b.check_in, b.check_out);

                return (
                  <tr key={b.id} className="hover:bg-[#FAFAFA] transition-colors group cursor-pointer" onClick={() => setSelectedBooking(b)}>
                    <td className="py-4 px-5">
                      <p className="text-[12px] font-bold text-[#00A3E1] font-mono">{formattedBookingId(b.id)}</p>
                      <p className="text-[10px] text-[#A3A3A3] mt-0.5">{new Date(b.created_at).toLocaleDateString()}</p>
                    </td>
                    <td className="py-4 px-5">
                      <p className="text-[13px] font-semibold text-[#171717]">{b.guest?.full_name ?? '—'}</p>
                    </td>
                    <td className="py-4 px-5 max-w-[160px]">
                      <p className="text-[13px] font-medium text-[#171717] truncate">{b.properties?.title ?? '—'}</p>
                      {(b.properties?.area_name || b.properties?.location) && (
                        <div className="flex items-center gap-1 text-[10px] text-[#A3A3A3] mt-0.5">
                          <MapPin size={9} />
                          <span className="truncate">{b.properties?.area_name ?? b.properties?.location}</span>
                        </div>
                      )}
                    </td>
                    <td className="py-4 px-5">
                      <p className="text-[13px] font-medium text-[#171717]">{b.owner?.full_name ?? '—'}</p>
                    </td>
                    <td className="py-4 px-5">
                      <p className="text-[12px] font-semibold text-[#171717]">{fmtDate(b.check_in)}</p>
                      <p className="text-[11px] text-[#A3A3A3]">→ {fmtDate(b.check_out)}</p>
                      <p className="text-[10px] text-[#A3A3A3] mt-0.5">{n} {n === 1 ? 'night' : 'nights'}</p>
                    </td>
                    <td className="py-4 px-5">
                      <StatusBadge config={bCfg} />
                    </td>
                    <td className="py-4 px-5">
                      <StatusBadge config={pCfg} />
                    </td>
                    <td className="py-4 px-5 text-right">
                      <p className="text-[13px] font-bold text-[#171717]">NPR {fmt(b.total_price ?? 0)}</p>
                    </td>
                    <td className="py-4 px-5 text-center">
                      <button className="w-8 h-8 rounded-lg bg-white border border-[#E5E5E5] flex items-center justify-center text-[#A3A3A3] hover:text-[#00A3E1] hover:border-[#00A3E1]/40 transition-all mx-auto">
                        <ChevronRight size={14} />
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Empty / Loading states */}
        {loading && (
          <div className="py-20 flex flex-col items-center gap-3">
            <div className="w-6 h-6 border-2 border-[#E5E5E5] border-t-[#00A3E1] rounded-full animate-spin" />
            <p className="text-[13px] text-[#A3A3A3] font-medium">Loading bookings...</p>
          </div>
        )}
        {!loading && filtered.length === 0 && (
          <div className="py-20 flex flex-col items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-[#F5F5F5] flex items-center justify-center">
              <CalendarDays size={20} className="text-[#A3A3A3]" />
            </div>
            <p className="text-[14px] font-semibold text-[#171717]">No bookings found</p>
            <p className="text-[12px] text-[#A3A3A3]">Try adjusting your filters or search terms.</p>
          </div>
        )}

        {/* Footer */}
        {!loading && filtered.length > 0 && (
          <div className="px-6 py-3 border-t border-[#F0F0F0] flex items-center justify-between">
            <p className="text-[12px] text-[#A3A3A3]">
              Showing <strong>{filtered.length}</strong> of <strong>{bookings.length}</strong> bookings
            </p>
            <p className="text-[11px] text-[#A3A3A3]">
              Last updated: {lastRefresh.toLocaleTimeString()}
            </p>
          </div>
        )}
      </div>

      {/* Detail Modal */}
      {selectedBooking && (
        <DetailModal booking={selectedBooking} onClose={() => setSelectedBooking(null)} />
      )}
    </div>
  );
};
