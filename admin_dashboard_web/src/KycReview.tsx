import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import {
  XCircle, Trash2, Loader2, Zap, ShieldCheck, ShieldAlert,
  Phone, CreditCard, RefreshCcw, ZoomIn, X, ChevronLeft, ChevronRight,
  Clock, Calendar, User, Eye
} from 'lucide-react';

// ─── Lightbox ────────────────────────────────────────────────────────────────
const Lightbox = ({
  images, initialIndex, onClose
}: {
  images: { label: string; url: string }[];
  initialIndex: number;
  onClose: () => void;
}) => {
  const [idx, setIdx] = useState(initialIndex);

  const prev = useCallback(() => setIdx(i => (i - 1 + images.length) % images.length), [images.length]);
  const next = useCallback(() => setIdx(i => (i + 1) % images.length), [images.length]);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      if (e.key === 'ArrowLeft') prev();
      if (e.key === 'ArrowRight') next();
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [onClose, prev, next]);

  const img = images[idx];

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-[100] flex items-center justify-center bg-black/90 backdrop-blur-xl"
      onClick={onClose}
    >
      {/* Close */}
      <button
        className="absolute top-6 right-6 w-12 h-12 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center text-white/60 hover:text-white hover:bg-white/10 transition-all z-10"
        onClick={onClose}
      >
        <X size={20} />
      </button>

      {/* Label */}
      <div className="absolute top-6 left-1/2 -translate-x-1/2 px-5 py-2 rounded-full bg-white/5 border border-white/10 text-white/60 text-xs font-bold uppercase tracking-widest backdrop-blur-md">
        {img.label} · {idx + 1} / {images.length}
      </div>

      {/* Image */}
      <motion.div
        key={idx}
        initial={{ opacity: 0, scale: 0.92 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ type: 'spring', damping: 20 }}
        className="relative max-w-5xl max-h-[80vh] w-full mx-16"
        onClick={e => e.stopPropagation()}
      >
        <img
          src={img.url}
          alt={img.label}
          className="w-full h-full object-contain rounded-3xl shadow-2xl shadow-black/60"
          style={{ maxHeight: '80vh' }}
        />
      </motion.div>

      {/* Nav arrows */}
      {images.length > 1 && (
        <>
          <button
            className="absolute left-6 top-1/2 -translate-y-1/2 w-12 h-12 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center text-white/60 hover:text-white hover:bg-white/10 transition-all"
            onClick={e => { e.stopPropagation(); prev(); }}
          >
            <ChevronLeft size={20} />
          </button>
          <button
            className="absolute right-6 top-1/2 -translate-y-1/2 w-12 h-12 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center text-white/60 hover:text-white hover:bg-white/10 transition-all"
            onClick={e => { e.stopPropagation(); next(); }}
          >
            <ChevronRight size={20} />
          </button>
        </>
      )}

      {/* Thumbnails */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex gap-3">
        {images.map((im, i) => (
          <button
            key={i}
            onClick={e => { e.stopPropagation(); setIdx(i); }}
            className={`w-16 h-12 rounded-xl overflow-hidden border-2 transition-all ${i === idx ? 'border-[#00A3E1] scale-110' : 'border-white/10 opacity-50 hover:opacity-80'}`}
          >
            <img src={im.url} alt={im.label} className="w-full h-full object-cover" />
          </button>
        ))}
      </div>
    </motion.div>
  );
};

// ─── Rejection Modal ──────────────────────────────────────────────────────────
const RejectionModal = ({ onConfirm, onCancel }: { onConfirm: (r: string) => void; onCancel: () => void }) => {
  const [reason, setReason] = useState('');
  const presets = [
    'Documents are blurry or unreadable',
    'ID number does not match the document',
    'Selfie does not match the ID photo',
    'Document appears to be expired',
    'Suspected fraudulent submission',
  ];

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-[90] flex items-center justify-center bg-black/60 backdrop-blur-sm"
      onClick={onCancel}
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: 20 }}
        className="bg-[#0F1117] border border-white/5 rounded-3xl p-8 w-full max-w-lg mx-4 shadow-2xl"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center gap-3 mb-6">
          <div className="w-10 h-10 rounded-xl bg-red-500/10 flex items-center justify-center">
            <XCircle size={20} className="text-red-400" />
          </div>
          <div>
            <h3 className="text-white font-black text-sm">Reject Identity Submission</h3>
            <p className="text-white/30 text-xs mt-0.5">Select or type a rejection reason</p>
          </div>
        </div>

        <div className="space-y-2 mb-4">
          {presets.map((p, i) => (
            <button
              key={i}
              onClick={() => setReason(p)}
              className={`w-full text-left px-4 py-3 rounded-xl text-xs font-bold transition-all border ${reason === p ? 'bg-red-500/10 border-red-500/30 text-red-400' : 'bg-white/[0.03] border-white/5 text-white/50 hover:text-white/80 hover:bg-white/[0.06]'}`}
            >
              {p}
            </button>
          ))}
        </div>

        <textarea
          value={reason}
          onChange={e => setReason(e.target.value)}
          placeholder="Or type a custom reason..."
          rows={3}
          className="w-full bg-white/[0.03] border border-white/10 rounded-xl px-4 py-3 text-xs text-white/80 placeholder-white/20 resize-none focus:outline-none focus:border-red-500/40 mb-6 font-medium"
        />

        <div className="flex gap-3">
          <button
            onClick={onCancel}
            className="flex-1 py-3 rounded-xl bg-white/5 text-white/50 text-xs font-black uppercase tracking-widest hover:bg-white/10 transition-all"
          >
            Cancel
          </button>
          <button
            onClick={() => reason.trim() && onConfirm(reason.trim())}
            disabled={!reason.trim()}
            className="flex-1 py-3 rounded-xl bg-red-500 text-white text-xs font-black uppercase tracking-widest hover:bg-red-600 transition-all disabled:opacity-30 disabled:cursor-not-allowed"
          >
            Confirm Rejection
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
};

// ─── KYC Card ────────────────────────────────────────────────────────────────
const KycCard = ({ kyc, onUpdate, onDelete, processingId }: {
  kyc: any;
  onUpdate: (id: string, userId: string, status: 'verified' | 'rejected', reason?: string) => void;
  onDelete: (id: string) => void;
  processingId: string | null;
}) => {
  const [lightbox, setLightbox] = useState<{ open: boolean; idx: number }>({ open: false, idx: 0 });
  const [showReject, setShowReject] = useState(false);

  const images = [
    { label: 'Front ID', url: kyc.front_image_url },
    { label: 'Back ID', url: kyc.back_image_url },
    { label: 'Live Selfie', url: kyc.selfie_image_url },
  ].filter(i => !!i.url);

  const submittedAt = new Date(kyc.created_at);
  const timeAgo = (() => {
    const diff = Date.now() - submittedAt.getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins}m ago`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs}h ago`;
    return `${Math.floor(hrs / 24)}d ago`;
  })();

  const isProcessing = processingId === kyc.id;

  return (
    <>
      <motion.div
        layout
        initial={{ opacity: 0, y: 32 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, x: 60, scale: 0.96 }}
        transition={{ type: 'spring', damping: 22, stiffness: 180 }}
        className="kyc-card rounded-3xl overflow-hidden border border-white/[0.06] bg-[#14161E] shadow-2xl shadow-black/30"
      >
        {/* Top accent bar */}
        <div className="h-[3px] w-full bg-gradient-to-r from-[#00A3E1] via-[#0079B1] to-transparent" />

        <div className="p-8">
          {/* Header Row */}
          <div className="flex items-start justify-between mb-8">
            <div className="flex items-center gap-5">
              {/* Avatar */}
              <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#00A3E1]/20 to-[#0079B1]/10 border border-[#00A3E1]/20 flex items-center justify-center">
                <User size={24} className="text-[#00A3E1]" />
              </div>
              <div>
                <h3 className="text-white font-black text-xl tracking-tight">{kyc.full_name || 'Unknown Applicant'}</h3>
                <div className="flex items-center gap-4 mt-1.5 flex-wrap">
                  {kyc.phone_number && (
                    <div className="flex items-center gap-1.5 text-white/30 text-xs font-semibold">
                      <Phone size={12} className="text-[#00A3E1]/60" />
                      {kyc.phone_number}
                    </div>
                  )}
                  <div className="flex items-center gap-1.5 text-white/30 text-xs font-semibold">
                    <CreditCard size={12} className="text-[#00A3E1]/60" />
                    ID: {kyc.citizenship_number}
                  </div>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              {/* Timestamp */}
              <div className="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-xl bg-white/[0.04] border border-white/[0.06] text-white/30 text-[11px] font-bold">
                <Clock size={12} />
                {timeAgo}
              </div>
              <div className="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-xl bg-white/[0.04] border border-white/[0.06] text-white/30 text-[11px] font-bold">
                <Calendar size={12} />
                {submittedAt.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
              </div>
              {/* Status badge */}
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400 text-[11px] font-black uppercase tracking-widest">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-pulse" />
                Pending
              </div>
              {/* Delete */}
              <button
                onClick={() => onDelete(kyc.id)}
                className="w-9 h-9 rounded-xl flex items-center justify-center text-white/20 hover:text-red-400 hover:bg-red-500/10 transition-all border border-transparent hover:border-red-500/20"
              >
                <Trash2 size={16} />
              </button>
            </div>
          </div>

          {/* Documents Grid + Actions */}
          <div className="grid grid-cols-1 xl:grid-cols-[1fr_280px] gap-8">
            {/* Images */}
            <div>
              <p className="text-[11px] font-black text-white/20 uppercase tracking-[0.2em] mb-3 flex items-center gap-2">
                <Eye size={11} />
                Identity Documents
                <span className="text-white/10 font-normal">· double-click to inspect</span>
              </p>
              <div className="grid grid-cols-3 gap-4">
                {[
                  { label: 'Front ID', url: kyc.front_image_url },
                  { label: 'Back ID', url: kyc.back_image_url },
                  { label: 'Live Selfie', url: kyc.selfie_image_url },
                ].map((img, i) => (
                  <div
                    key={i}
                    className="relative aspect-[4/3] rounded-2xl overflow-hidden bg-white/[0.03] border border-white/[0.06] cursor-zoom-in group/img"
                    onDoubleClick={() => img.url && setLightbox({ open: true, idx: i })}
                    title="Double-click to open full view"
                  >
                    {/* Label */}
                    <div className="absolute top-3 left-3 z-10 px-2.5 py-1 rounded-lg bg-black/60 backdrop-blur-md text-[10px] font-black text-white/80 uppercase tracking-wider">
                      {img.label}
                    </div>
                    {/* Zoom hint */}
                    <div className="absolute bottom-3 right-3 z-10 w-7 h-7 rounded-lg bg-black/50 backdrop-blur-md flex items-center justify-center opacity-0 group-hover/img:opacity-100 transition-all">
                      <ZoomIn size={14} className="text-white/70" />
                    </div>

                    {img.url ? (
                      <img
                        src={img.url}
                        alt={img.label}
                        className="w-full h-full object-cover transition-transform duration-700 group-hover/img:scale-105"
                        draggable={false}
                      />
                    ) : (
                      <div className="w-full h-full flex flex-col items-center justify-center gap-2">
                        <ShieldAlert size={28} className="text-white/10" />
                        <span className="text-[10px] text-white/20 font-bold uppercase tracking-wider">Not Uploaded</span>
                      </div>
                    )}
                    {/* Hover overlay */}
                    <div className="absolute inset-0 bg-[#00A3E1]/5 opacity-0 group-hover/img:opacity-100 transition-opacity pointer-events-none" />
                  </div>
                ))}
              </div>
            </div>

            {/* Actions Panel */}
            <div className="flex flex-col justify-between gap-4">
              <div className="p-5 rounded-2xl bg-[#00A3E1]/5 border border-[#00A3E1]/10">
                <div className="flex items-center gap-2 text-[#00A3E1] text-[11px] font-black uppercase tracking-widest mb-2">
                  <Zap size={12} fill="currentColor" />
                  AI Autopilot
                </div>
                <p className="text-white/30 text-[11px] leading-relaxed font-medium">
                  Automated biometric analysis detected. Awaiting final human authorization to complete onboarding.
                </p>
              </div>

              <div className="space-y-3">
                <button
                  onClick={() => onUpdate(kyc.id, kyc.user_id, 'verified')}
                  disabled={isProcessing}
                  className="w-full py-4 rounded-2xl bg-gradient-to-r from-[#00A3E1] to-[#0079B1] text-white font-black text-[11px] uppercase tracking-[0.15em] flex items-center justify-center gap-2 shadow-lg shadow-[#00A3E1]/20 hover:shadow-[#00A3E1]/40 hover:-translate-y-0.5 active:scale-[0.98] transition-all disabled:opacity-40"
                >
                  {isProcessing ? <Loader2 size={16} className="animate-spin" /> : <ShieldCheck size={16} strokeWidth={2.5} />}
                  Authorize Identity
                </button>

                <button
                  onClick={() => setShowReject(true)}
                  disabled={isProcessing}
                  className="w-full py-4 rounded-2xl bg-white/[0.04] border border-red-500/20 text-red-400 font-black text-[11px] uppercase tracking-[0.15em] flex items-center justify-center gap-2 hover:bg-red-500/10 hover:border-red-500/40 active:scale-[0.98] transition-all disabled:opacity-40"
                >
                  {isProcessing ? <Loader2 size={16} className="animate-spin" /> : <XCircle size={16} />}
                  Reject Access
                </button>
              </div>
            </div>
          </div>
        </div>
      </motion.div>

      {/* Lightbox */}
      <AnimatePresence>
        {lightbox.open && images.length > 0 && (
          <Lightbox
            images={images}
            initialIndex={Math.min(lightbox.idx, images.length - 1)}
            onClose={() => setLightbox({ open: false, idx: 0 })}
          />
        )}
      </AnimatePresence>

      {/* Rejection Modal */}
      <AnimatePresence>
        {showReject && (
          <RejectionModal
            onConfirm={reason => {
              setShowReject(false);
              onUpdate(kyc.id, kyc.user_id, 'rejected', reason);
            }}
            onCancel={() => setShowReject(false)}
          />
        )}
      </AnimatePresence>
    </>
  );
};

// ─── Main KycReview Page ──────────────────────────────────────────────────────
export const KycReview = () => {
  const [kycs, setKycs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [filter, setFilter] = useState<'pending' | 'all'>('pending');

  const fetchKycs = async () => {
    setLoading(true);
    try {
      let query = supabase.from('kyc_verifications').select('*').order('created_at', { ascending: false });
      if (filter === 'pending') query = query.eq('status', 'pending');
      const { data, error } = await query;
      if (error) throw error;
      setKycs(data || []);
    } catch (e) {
      console.error('Error fetching KYCs:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchKycs(); }, [filter]);

  useEffect(() => {
    const channel = supabase.channel('kyc_realtime_v2')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'kyc_verifications' }, () => fetchKycs())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [filter]);

  const handleUpdate = async (kycId: string, userId: string, status: 'verified' | 'rejected', reason?: string) => {
    setProcessingId(kycId);
    try {
      await supabase.from('kyc_verifications').update({ status, rejection_reason: reason ?? null }).eq('id', kycId);
      await supabase.from('profiles').update({ kyc_status: status }).eq('id', userId);
      await supabase.from('notifications').insert({
        user_id: userId,
        title: status === 'verified' ? 'KYC Approved ✅' : 'KYC Rejected ❌',
        message: status === 'verified'
          ? 'बधाई छ! तपाईंको पहिचान प्रमाणित भएको छ।'
          : `तपाईंको पहिचान पुष्टि हुन सकेन। कारण: ${reason}`,
        type: 'kyc_update',
      });
    } catch (error) {
      console.error('Update failed:', error);
    } finally {
      setProcessingId(null);
    }
  };

  const handleDelete = async (kycId: string) => {
    if (!confirm('Permanently delete this KYC record?')) return;
    await supabase.from('kyc_verifications').delete().eq('id', kycId);
  };

  const pendingCount = kycs.filter(k => k.status === 'pending').length;

  return (
    <div className="flex-1 overflow-y-auto bg-[#0C0E14] min-h-screen">
      <div className="max-w-[1400px] mx-auto px-8 py-10">

        {/* Page Header */}
        <motion.div
          initial={{ opacity: 0, y: -16 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex flex-col md:flex-row md:items-center justify-between mb-10 gap-6"
        >
          <div>
            <div className="flex items-center gap-3 mb-2">
              <h2 className="text-3xl font-black text-white tracking-tight">Identity Audit Queue</h2>
              {pendingCount > 0 && (
                <div className="px-3 py-1 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 text-xs font-black">
                  {pendingCount} pending
                </div>
              )}
            </div>
            <p className="text-white/30 text-sm font-medium">
              Review and authorize user identity submissions for platform access.
            </p>
          </div>

          <div className="flex items-center gap-3">
            {/* Filter tabs */}
            <div className="flex items-center p-1 rounded-xl bg-white/[0.04] border border-white/[0.06]">
              {(['pending', 'all'] as const).map(f => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-4 py-2 rounded-lg text-[11px] font-black uppercase tracking-wider transition-all ${filter === f ? 'bg-[#00A3E1] text-white shadow-lg shadow-[#00A3E1]/20' : 'text-white/30 hover:text-white/60'}`}
                >
                  {f}
                </button>
              ))}
            </div>

            <button
              onClick={fetchKycs}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white/[0.04] border border-white/[0.06] text-white/40 hover:text-white/80 hover:bg-white/[0.07] transition-all text-[11px] font-black uppercase tracking-widest group"
            >
              <RefreshCcw size={14} className="group-hover:rotate-180 transition-transform duration-500" />
              Refresh
            </button>
          </div>
        </motion.div>

        {/* Stats row */}
        <div className="grid grid-cols-3 gap-4 mb-10">
          {[
            { label: 'Pending Review', value: kycs.filter(k => k.status === 'pending').length, color: 'text-amber-400', bg: 'bg-amber-500/5 border-amber-500/10' },
            { label: 'Verified Today', value: kycs.filter(k => k.status === 'verified').length, color: 'text-green-400', bg: 'bg-green-500/5 border-green-500/10' },
            { label: 'Rejected', value: kycs.filter(k => k.status === 'rejected').length, color: 'text-red-400', bg: 'bg-red-500/5 border-red-500/10' },
          ].map((s, i) => (
            <div key={i} className={`rounded-2xl border p-5 ${s.bg}`}>
              <p className={`text-3xl font-black ${s.color}`}>{s.value}</p>
              <p className="text-white/30 text-xs font-bold mt-1 uppercase tracking-wider">{s.label}</p>
            </div>
          ))}
        </div>

        {/* Content */}
        {loading ? (
          <div className="flex flex-col items-center justify-center py-40 gap-4">
            <div className="w-10 h-10 border-2 border-[#00A3E1]/20 border-t-[#00A3E1] rounded-full animate-spin" />
            <p className="text-white/20 text-xs font-bold uppercase tracking-widest">Loading records...</p>
          </div>
        ) : kycs.length === 0 ? (
          <motion.div
            initial={{ opacity: 0, scale: 0.96 }}
            animate={{ opacity: 1, scale: 1 }}
            className="flex flex-col items-center justify-center py-40 rounded-3xl border border-white/[0.04] bg-white/[0.02]"
          >
            <div className="w-20 h-20 rounded-3xl bg-[#00A3E1]/5 border border-[#00A3E1]/10 flex items-center justify-center mb-6">
              <ShieldCheck size={36} className="text-[#00A3E1]/40" />
            </div>
            <h3 className="text-white text-xl font-black mb-2">All Clear</h3>
            <p className="text-white/25 text-sm font-medium max-w-xs text-center leading-relaxed">
              No {filter === 'pending' ? 'pending' : ''} submissions found. The queue is empty.
            </p>
          </motion.div>
        ) : (
          <div className="space-y-6">
            <AnimatePresence mode="popLayout">
              {kycs.map(kyc => (
                <KycCard
                  key={kyc.id}
                  kyc={kyc}
                  onUpdate={handleUpdate}
                  onDelete={handleDelete}
                  processingId={processingId}
                />
              ))}
            </AnimatePresence>
          </div>
        )}
      </div>
    </div>
  );
};
