import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import {
  XCircle, Loader2, ShieldCheck,
  RefreshCcw, X, ChevronLeft, ChevronRight,
  User, MapPin, Phone, Mail, FileText
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
      className="fixed inset-0 z-[100] flex items-center justify-center bg-[#0A0A0A]/95 backdrop-blur-md"
      onClick={onClose}
    >
      <button
        className="absolute top-6 right-6 w-10 h-10 rounded-full bg-white/10 border border-white/20 flex items-center justify-center text-white hover:bg-white/20 transition-all z-10"
        onClick={onClose}
      >
        <X size={18} strokeWidth={1.5} />
      </button>

      <div className="absolute top-6 left-1/2 -translate-x-1/2 px-4 py-1.5 rounded-full bg-white/10 border border-white/20 text-white text-[11px] font-medium tracking-wide backdrop-blur-md">
        {img.label} · {idx + 1} / {images.length}
      </div>

      <motion.div
        key={idx}
        initial={{ opacity: 0, scale: 0.98 }}
        animate={{ opacity: 1, scale: 1 }}
        className="relative max-w-5xl max-h-[85vh] w-full mx-10"
        onClick={e => e.stopPropagation()}
      >
        <img
          src={img.url}
          alt={img.label}
          className="w-full h-full object-contain rounded-lg opacity-100 shadow-2xl"
          style={{ maxHeight: '85vh' }}
        />
      </motion.div>

      {images.length > 1 && (
        <>
          <button
            className="absolute left-6 top-1/2 -translate-y-1/2 w-12 h-12 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-white hover:bg-white/20 transition-all"
            onClick={e => { e.stopPropagation(); prev(); }}
          >
            <ChevronLeft size={24} strokeWidth={1.5} />
          </button>
          <button
            className="absolute right-6 top-1/2 -translate-y-1/2 w-12 h-12 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-white hover:bg-white/20 transition-all"
            onClick={e => { e.stopPropagation(); next(); }}
          >
            <ChevronRight size={24} strokeWidth={1.5} />
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
    'ID number does not match document',
    'Selfie does not match ID photo',
    'Document appears to be expired',
    'Suspected fraudulent submission',
  ];

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-[110] flex items-center justify-center bg-[#0A0A0A]/40 backdrop-blur-xs p-6"
      onClick={onCancel}
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.98, y: 10 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.98, y: 10 }}
        className="w-full max-w-md bg-white rounded-2xl p-8 shadow-lg border border-[#E5E5E5]"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center gap-3 mb-6">
          <div className="w-9 h-9 rounded-lg bg-rose-50 flex items-center justify-center text-rose-500">
            <XCircle size={20} strokeWidth={1.5} />
          </div>
          <div>
            <h3 className="text-[16px] font-semibold text-[#171717]">Reject Verification</h3>
            <p className="text-[#737373] text-[12px]">Please specify why this identity was denied.</p>
          </div>
        </div>

        <div className="space-y-1.5 mb-6">
          {presets.map((p, i) => (
            <button
              key={i}
              onClick={() => setReason(p)}
              className="text-left px-3.5 py-2.5 rounded-lg bg-[#FAFAFA] border border-[#E5E5E5] text-[#525252] text-[12px] font-medium hover:border-[#A3A3A3] hover:bg-white transition-all w-full"
            >
              {p}
            </button>
          ))}
        </div>

        <textarea
          value={reason}
          onChange={e => setReason(e.target.value)}
          placeholder="Enter custom reason..."
          className="w-full h-24 bg-[#FAFAFA] border border-[#E5E5E5] rounded-xl p-3.5 text-[13px] font-medium focus:outline-none focus:ring-2 focus:ring-[#171717]/5 focus:border-[#171717] transition-all resize-none mb-6 placeholder:text-[#D4D4D4]"
        />

        <div className="flex gap-3">
          <button
            onClick={onCancel}
            className="flex-1 h-10 rounded-lg bg-[#F5F5F5] text-[#525252] text-[12px] font-semibold hover:bg-[#E5E5E5] transition-all"
          >
            Cancel
          </button>
          <button
            onClick={() => reason.trim() && onConfirm(reason.trim())}
            disabled={!reason.trim()}
            className="flex-1 h-10 rounded-lg bg-[#171717] text-white text-[12px] font-semibold hover:bg-[#0A0A0A] transition-all disabled:opacity-40 shadow-sm"
          >
            Deny Verification
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
};

// ─── KYC Card ────────────────────────────────────────────────────────────────
const KycCard = ({ kyc, onUpdate, processingId }: {
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

  return (
    <>
      <motion.div
        layout
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.98 }}
        className="card-minimal p-8 bg-white"
      >
        <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6 mb-8 pb-6 border-b border-[#F5F5F5]">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-xl bg-[#FAFAFA] flex items-center justify-center border border-[#E5E5E5]">
              <User size={24} strokeWidth={1.5} className="text-[#A3A3A3]" />
            </div>
            <div>
              <div className="flex items-center gap-2.5 mb-1">
                <h3 className="text-[17px] font-semibold text-[#171717] tracking-tight">{kyc.full_name}</h3>
                <span className="px-2 py-0.5 bg-[#F5F5F5] text-[#737373] text-[10px] font-semibold rounded-md border border-[#E5E5E5] uppercase tracking-wider">Manual Review</span>
              </div>
              <p className="text-[11px] text-[#A3A3A3] font-mono tracking-wider">{kyc.user_id}</p>
            </div>
          </div>

          <div className="flex gap-2.5">
            <button 
              onClick={() => onUpdate(kyc.id, kyc.user_id, 'verified')}
              disabled={processingId === kyc.id}
              className="h-9 px-5 bg-[#171717] text-white rounded-lg text-[12px] font-semibold hover:bg-[#0A0A0A] transition-colors flex items-center gap-2 shadow-sm disabled:opacity-40"
            >
              {processingId === kyc.id ? <Loader2 size={14} className="animate-spin" /> : <ShieldCheck size={14} strokeWidth={1.5} />} Approve
            </button>
            <button 
              onClick={() => setShowReject(true)}
              className="h-9 px-4 bg-white border border-[#E5E5E5] text-rose-500 rounded-lg text-[12px] font-semibold hover:bg-rose-50 hover:border-rose-100 transition-all"
            >
              Reject
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-6 mb-8">
          <div>
            <p className="flex items-center gap-1.5 text-[11px] text-[#A3A3A3] font-semibold uppercase tracking-wider mb-1.5">
              <Mail size={12} strokeWidth={1.5} /> Email Access
            </p>
            <p className="text-[13px] font-medium text-[#171717]">{kyc.email || '—'}</p>
          </div>
          <div>
            <p className="flex items-center gap-1.5 text-[11px] text-[#A3A3A3] font-semibold uppercase tracking-wider mb-1.5">
              <Phone size={12} strokeWidth={1.5} /> Contact
            </p>
            <p className="text-[13px] font-medium text-[#171717]">{kyc.phone_number || '—'}</p>
          </div>
          <div>
            <p className="flex items-center gap-1.5 text-[11px] text-[#A3A3A3] font-semibold uppercase tracking-wider mb-1.5">
              <FileText size={12} strokeWidth={1.5} /> Document No.
            </p>
            <p className="text-[13px] font-medium text-[#171717]">{kyc.citizenship_number || '—'}</p>
          </div>
          <div>
            <p className="flex items-center gap-1.5 text-[11px] text-[#A3A3A3] font-semibold uppercase tracking-wider mb-1.5">
              <MapPin size={12} strokeWidth={1.5} /> GPS Location
            </p>
            {kyc.latitude ? (
              <a 
                href={`https://www.google.com/maps?q=${kyc.latitude},${kyc.longitude}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-[13px] font-semibold text-[#171717] hover:underline underline-offset-4"
              >
                {kyc.latitude.toFixed(4)}, {kyc.longitude.toFixed(4)}
              </a>
            ) : (
              <p className="text-[13px] font-medium text-rose-400">Not Verified</p>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {images.map((img, i) => (
            <div 
              key={i} 
              onClick={() => setLightbox({ open: true, idx: i })}
              className="group relative h-48 bg-[#FAFAFA] rounded-xl border border-[#E5E5E5] overflow-hidden cursor-zoom-in transition-all hover:border-[#A3A3A3]"
            >
              <img src={img.url} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" alt={img.label} />
              <div className="absolute inset-0 bg-[#0A0A0A]/0 group-hover:bg-[#0A0A0A]/2 transition-colors" />
              <div className="absolute top-4 left-4 px-2 py-1 bg-white/90 border border-white/20 rounded text-[10px] font-semibold text-[#171717] uppercase tracking-wider shadow-sm opacity-0 group-hover:opacity-100 transition-opacity">
                {img.label}
              </div>
            </div>
          ))}
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
    <div className="flex-1 overflow-y-auto bg-[#FAFAFA]">
      <div className="max-w-6xl mx-auto px-8 py-8">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-8 gap-6">
          <div>
            <div className="flex items-center gap-3 mb-1">
              <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight">Verification Center</h2>
              <span className="px-2 py-0.5 bg-[#F5F5F5] text-[#171717] text-[10px] font-semibold uppercase tracking-wider rounded border border-[#E5E5E5]">
                {kycs.filter(k => k.status === 'pending').length} In Queue
              </span>
            </div>
            <p className="text-[#737373] text-[13px]">Identity verification and document validation.</p>
          </div>
          
          <div className="flex items-center gap-3">
            <div className="flex p-0.5 bg-white border border-[#E5E5E5] rounded-lg shadow-xs">
              {(['pending', 'all'] as const).map(f => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-3.5 py-1.5 rounded-md text-[12px] font-medium transition-all ${filter === f ? 'bg-[#FAFAFA] text-[#171717] border border-[#E5E5E5] shadow-xs' : 'text-[#737373] hover:text-[#171717]'}`}
                >
                  {f === 'pending' ? 'Pending' : 'History'}
                </button>
              ))}
            </div>
            <button
              onClick={fetchKycs}
              className="w-9 h-9 rounded-lg flex items-center justify-center bg-white border border-[#E5E5E5] text-[#737373] hover:text-[#171717] hover:bg-[#FAFAFA] transition-all shadow-xs"
            >
              <RefreshCcw size={16} strokeWidth={1.5} className={loading ? 'animate-spin' : ''} />
            </button>
          </div>
        </div>

        {loading ? (
          <div className="py-40 flex flex-col items-center justify-center gap-3">
            <div className="w-5 h-5 border-2 border-[#E5E5E5] border-t-[#171717] rounded-full animate-spin" />
            <p className="text-[12px] text-[#A3A3A3] font-medium">Syncing verifications...</p>
          </div>
        ) : kycs.length === 0 ? (
          <div className="empty-state border border-dashed border-[#E5E5E5] rounded-xl">
            <div className="empty-state-icon">
              <ShieldCheck size={20} strokeWidth={1.5} />
            </div>
            <h3 className="empty-state-title">Verification queue clear</h3>
            <p className="empty-state-desc">All identity reviews have been processed for now.</p>
          </div>
        ) : (
          <div className="space-y-4">
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
