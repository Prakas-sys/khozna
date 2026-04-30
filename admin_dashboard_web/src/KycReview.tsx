import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import {
  XCircle, Trash2, Loader2, Zap, ShieldCheck, ShieldAlert,
  Phone, CreditCard, RefreshCcw, ZoomIn, X, ChevronLeft, ChevronRight,
  Clock, Calendar, User, Eye, ArrowRight
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
      className="fixed inset-0 z-[100] flex items-center justify-center bg-[#0F172A]/95 backdrop-blur-xl"
      onClick={onClose}
    >
      <button
        className="absolute top-8 right-8 w-12 h-12 rounded-2xl bg-white/10 border border-white/20 flex items-center justify-center text-white hover:bg-white/20 transition-all z-10"
        onClick={onClose}
      >
        <X size={20} />
      </button>

      <div className="absolute top-8 left-1/2 -translate-x-1/2 px-5 py-2 rounded-full bg-white/10 border border-white/20 text-white text-[10px] font-bold uppercase tracking-widest backdrop-blur-md">
        {img.label} · {idx + 1} / {images.length}
      </div>

      <motion.div
        key={idx}
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="relative max-w-5xl max-h-[80vh] w-full mx-16"
        onClick={e => e.stopPropagation()}
      >
        <img
          src={img.url}
          alt={img.label}
          className="w-full h-full object-contain rounded-[2rem] shadow-2xl"
          style={{ maxHeight: '80vh' }}
        />
      </motion.div>

      {images.length > 1 && (
        <>
          <button
            className="absolute left-8 top-1/2 -translate-y-1/2 w-14 h-14 rounded-full bg-white/10 border border-white/20 flex items-center justify-center text-white hover:bg-white/20 transition-all"
            onClick={e => { e.stopPropagation(); prev(); }}
          >
            <ChevronLeft size={24} />
          </button>
          <button
            className="absolute right-8 top-1/2 -translate-y-1/2 w-14 h-14 rounded-full bg-white/10 border border-white/20 flex items-center justify-center text-white hover:bg-white/20 transition-all"
            onClick={e => { e.stopPropagation(); next(); }}
          >
            <ChevronRight size={24} />
          </button>
        </>
      )}
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
      className="fixed inset-0 z-[90] flex items-center justify-center bg-[#0F172A]/40 backdrop-blur-sm"
      onClick={onCancel}
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: 20 }}
        className="bg-white border border-[#E2E8F0] rounded-[2rem] p-10 w-full max-w-lg mx-4 shadow-2xl shadow-black/10"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center gap-4 mb-8">
          <div className="w-12 h-12 rounded-2xl bg-red-50 flex items-center justify-center">
            <XCircle size={24} className="text-red-500" />
          </div>
          <div>
            <h3 className="text-[#0F172A] font-extrabold text-lg tracking-tight">Reject Submission</h3>
            <p className="text-[#64748B] text-sm font-medium">Select or type a rejection reason</p>
          </div>
        </div>

        <div className="space-y-2 mb-6">
          {presets.map((p, i) => (
            <button
              key={i}
              onClick={() => setReason(p)}
              className={`w-full text-left px-5 py-4 rounded-2xl text-xs font-bold transition-all border ${reason === p ? 'bg-red-50 border-red-200 text-red-600' : 'bg-white border-[#E2E8F0] text-[#64748B] hover:bg-[#F8FAFC]'}`}
            >
              {p}
            </button>
          ))}
        </div>

        <textarea
          value={reason}
          onChange={e => setReason(e.target.value)}
          placeholder="Detailed custom reason..."
          rows={3}
          className="w-full bg-[#F8FAFC] border border-[#E2E8F0] rounded-2xl px-5 py-4 text-xs text-[#0F172A] placeholder-[#94A3B8] resize-none outline-none focus:border-red-500/40 mb-8 font-medium transition-all"
        />

        <div className="flex gap-4">
          <button
            onClick={onCancel}
            className="flex-1 py-4 rounded-2xl bg-[#F8FAFC] text-[#64748B] text-xs font-bold hover:bg-[#F1F5F9] transition-all"
          >
            Cancel
          </button>
          <button
            onClick={() => reason.trim() && onConfirm(reason.trim())}
            disabled={!reason.trim()}
            className="flex-1 py-4 rounded-2xl bg-[#EF4444] text-white text-xs font-bold shadow-lg shadow-red-500/20 hover:bg-[#DC2626] transition-all disabled:opacity-30"
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
        className="card-platinum rounded-[2.5rem] overflow-hidden"
      >
        <div className="p-10">
          {/* Header */}
          <div className="flex items-start justify-between mb-10">
            <div className="flex items-center gap-6">
              <div className="w-16 h-16 rounded-[1.25rem] bg-[#F1F5F9] flex items-center justify-center border border-[#E2E8F0]">
                <User size={28} className="text-[#2563EB]" />
              </div>
              <div>
                <h3 className="text-[#0F172A] font-extrabold text-2xl tracking-tight leading-none mb-2">{kyc.full_name || 'Unknown Applicant'}</h3>
                <div className="flex items-center gap-5">
                  <div className="flex items-center gap-1.5 text-[#64748B] text-xs font-bold">
                    <CreditCard size={14} className="text-[#94A3B8]" />
                    {kyc.citizenship_number}
                  </div>
                  <div className="flex items-center gap-1.5 text-[#64748B] text-xs font-bold">
                    <Phone size={14} className="text-[#94A3B8]" />
                    {kyc.phone_number}
                  </div>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#F8FAFC] border border-[#E2E8F0] text-[#64748B] text-[10px] font-bold uppercase tracking-wider">
                <Clock size={12} />
                {timeAgo}
              </div>
              <div className="px-3 py-1.5 rounded-xl bg-amber-50 border border-amber-100 text-amber-600 text-[10px] font-bold uppercase tracking-wider flex items-center gap-1.5">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                Pending Review
              </div>
              <button
                onClick={() => onDelete(kyc.id)}
                className="w-10 h-10 rounded-xl flex items-center justify-center text-[#94A3B8] hover:text-[#EF4444] hover:bg-red-50 transition-all border border-[#E2E8F0]"
              >
                <Trash2 size={18} />
              </button>
            </div>
          </div>

          {/* Grid */}
          <div className="grid grid-cols-1 xl:grid-cols-[1fr_300px] gap-12">
            <div>
              <div className="flex items-center justify-between mb-4">
                <p className="text-[11px] font-bold text-[#94A3B8] uppercase tracking-[0.15em]">Identity Documents</p>
                <p className="text-[10px] text-[#CBD5E1] font-medium italic">Double-click to expand</p>
              </div>
              <div className="grid grid-cols-3 gap-5">
                {images.map((img, i) => (
                  <div
                    key={i}
                    className="relative aspect-[4/3] rounded-3xl overflow-hidden bg-[#F8FAFC] border border-[#E2E8F0] cursor-zoom-in group"
                    onDoubleClick={() => setLightbox({ open: true, idx: i })}
                  >
                    <div className="absolute top-4 left-4 z-10 px-3 py-1.5 rounded-xl bg-white/80 backdrop-blur-md text-[10px] font-bold text-[#0F172A] uppercase tracking-wider shadow-sm">
                      {img.label}
                    </div>
                    <img
                      src={img.url}
                      alt={img.label}
                      className="w-full h-full object-cover transition-all duration-500 group-hover:scale-105"
                    />
                    <div className="absolute inset-0 bg-[#2563EB]/5 opacity-0 group-hover:opacity-100 transition-all flex items-center justify-center">
                      <div className="w-10 h-10 rounded-full bg-white shadow-xl flex items-center justify-center scale-75 group-hover:scale-100 transition-all">
                        <ZoomIn size={18} className="text-[#2563EB]" />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="flex flex-col justify-between pt-8 border-t xl:border-t-0 xl:border-l xl:pt-0 xl:pl-12 border-[#F1F5F9]">
              <div className="mb-8">
                <div className="flex items-center gap-2 text-[#2563EB] text-[11px] font-bold uppercase tracking-wider mb-3">
                  <Zap size={14} fill="currentColor" />
                  AI Verification
                </div>
                <div className="p-5 rounded-2xl bg-blue-50/50 border border-blue-100/50">
                  <p className="text-[#1E40AF] text-xs leading-relaxed font-medium">
                    Face-matching and ID authenticity checks passed. Human confirmation required for final activation.
                  </p>
                </div>
              </div>

              <div className="space-y-3">
                <button
                  onClick={() => onUpdate(kyc.id, kyc.user_id, 'verified')}
                  disabled={isProcessing}
                  className="w-full py-4 rounded-2xl bg-[#2563EB] text-white font-bold text-sm flex items-center justify-center gap-2 shadow-lg shadow-blue-500/20 hover:bg-[#1E40AF] active:scale-[0.98] transition-all disabled:opacity-50"
                >
                  {isProcessing ? <Loader2 size={18} className="animate-spin" /> : <ShieldCheck size={18} />}
                  Approve User
                </button>
                <button
                  onClick={() => setShowReject(true)}
                  disabled={isProcessing}
                  className="w-full py-4 rounded-2xl bg-white border border-[#E2E8F0] text-[#64748B] font-bold text-sm flex items-center justify-center gap-2 hover:bg-[#FEF2F2] hover:text-[#EF4444] hover:border-red-100 transition-all disabled:opacity-50"
                >
                  {isProcessing ? <Loader2 size={18} className="animate-spin" /> : <XCircle size={18} />}
                  Reject Access
                </button>
              </div>
            </div>
          </div>
        </div>
      </motion.div>

      <AnimatePresence>
        {lightbox.open && images.length > 0 && (
          <Lightbox
            images={images}
            initialIndex={lightbox.idx}
            onClose={() => setLightbox({ open: false, idx: 0 })}
          />
        )}
      </AnimatePresence>

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

// ─── Main Page ────────────────────────────────────────────────────────────────
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
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchKycs(); }, [filter]);

  useEffect(() => {
    const channel = supabase.channel('kyc_realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'kyc_verifications' }, () => fetchKycs())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [filter]);

  const handleUpdate = async (kycId: string, userId: string, status: 'verified' | 'rejected', reason?: string) => {
    setProcessingId(kycId);
    try {
      await supabase.from('kyc_verifications').update({ status, rejection_reason: reason ?? null }).eq('id', kycId);
      await supabase.from('profiles').update({ kyc_status: status }).eq('id', userId);
    } finally {
      setProcessingId(null);
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm('Delete this record?')) await supabase.from('kyc_verifications').delete().eq('id', id);
  };

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="max-w-[1400px] mx-auto px-10 py-12">
        <div className="flex items-end justify-between mb-12">
          <div>
            <div className="flex items-center gap-3 mb-3">
              <h2 className="text-3xl font-extrabold text-[#0F172A] tracking-tight">Identity Verification</h2>
              <span className="px-3 py-1 rounded-full bg-[#2563EB]/10 text-[#2563EB] text-[10px] font-bold uppercase tracking-wider">
                {kycs.filter(k => k.status === 'pending').length} Action Required
              </span>
            </div>
            <p className="text-[#64748B] text-sm font-medium">Reviewing user identification documents for platform security.</p>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex p-1 bg-white border border-[#E2E8F0] rounded-2xl">
              {(['pending', 'all'] as const).map(f => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-6 py-2 rounded-xl text-xs font-bold transition-all ${filter === f ? 'bg-[#2563EB] text-white' : 'text-[#64748B] hover:text-[#0F172A]'}`}
                >
                  {f.charAt(0).toUpperCase() + f.slice(1)}
                </button>
              ))}
            </div>
            <button
              onClick={fetchKycs}
              className="w-11 h-11 rounded-2xl flex items-center justify-center bg-white border border-[#E2E8F0] text-[#64748B] hover:bg-[#F8FAFC] transition-all"
            >
              <RefreshCcw size={18} />
            </button>
          </div>
        </div>

        {loading ? (
          <div className="flex flex-col items-center justify-center py-40 gap-4">
            <Loader2 className="animate-spin text-[#2563EB]" size={32} />
            <p className="text-[#94A3B8] text-xs font-bold uppercase tracking-widest">Fetching records</p>
          </div>
        ) : kycs.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-40 rounded-[2.5rem] bg-white border border-[#E2E8F0] border-dashed">
            <div className="w-20 h-20 rounded-[2rem] bg-blue-50 flex items-center justify-center mb-6">
              <ShieldCheck size={40} className="text-[#2563EB]/40" />
            </div>
            <h3 className="text-[#0F172A] text-xl font-extrabold mb-2">No Pending Tasks</h3>
            <p className="text-[#64748B] text-sm font-medium">All identification records have been processed.</p>
          </div>
        ) : (
          <div className="space-y-8">
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
