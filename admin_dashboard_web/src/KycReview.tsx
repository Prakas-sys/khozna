import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import {
  XCircle, Trash2, Loader2, Zap, ShieldCheck,
  Phone, CreditCard, RefreshCcw, ZoomIn, X, ChevronLeft, ChevronRight,
  Clock, User
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
      className="fixed inset-0 z-[100] flex items-center justify-center bg-[#111111]/95 backdrop-blur-xl"
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
      className="fixed inset-0 z-[110] flex items-center justify-center bg-[#111111]/40 backdrop-blur-sm p-6"
      onClick={onCancel}
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: 20 }}
        className="w-full max-w-lg bg-white rounded-[2.5rem] p-10 shadow-2xl border border-[#E8E6E1]"
        onClick={e => e.stopPropagation()}
      >
        <h3 className="text-2xl font-extrabold text-[#1A1A1A] tracking-tight mb-2">Specify Rejection</h3>
        <p className="text-[#666666] text-sm font-medium mb-8">Please provide a narrative or select a preset for the operator.</p>
        
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
              className="text-left px-4 py-3 rounded-xl bg-[#FBFBF9] border border-[#E8E6E1] text-[#666666] text-xs font-bold hover:border-[#2563EB] hover:text-[#2563EB] transition-all w-full"
            >
              {p}
            </button>
          ))}
        </div>

        <textarea
          value={reason}
          onChange={e => setReason(e.target.value)}
          placeholder="Enter detailed reason..."
          className="w-full h-32 bg-[#FBFBF9] border border-[#E8E6E1] rounded-2xl p-4 text-sm font-semibold focus:outline-none focus:ring-4 focus:ring-[#2563EB]/5 focus:border-[#2563EB] transition-all resize-none mb-8"
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

  const isProcessing = processingId === kyc.id;

  return (
    <>
      <motion.div
        layout
        initial={{ opacity: 0, y: 32 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, x: 60, scale: 0.96 }}
        className="card-platinum rounded-[2.5rem] overflow-hidden p-10"
      >
        <div className="flex items-start justify-between mb-10">
          <div className="flex items-center gap-6">
            <div className="w-16 h-16 rounded-[1.25rem] bg-[#F1F5F9] flex items-center justify-center border border-[#E2E8F0]">
              <User size={28} className="text-[#2563EB]" />
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
    <div className="flex-1 overflow-y-auto bg-[#FBFBF9]">
      <div className="max-w-[1400px] mx-auto px-10 py-12">
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-8"
        >
          <div>
            <div className="flex items-center gap-4 mb-3">
              <h2 className="text-3xl font-extrabold text-[#1A1A1A] tracking-tight">KYC Operations</h2>
              <span className="px-3 py-1 bg-[#2563EB]/10 text-[#2563EB] text-[10px] font-bold uppercase tracking-wider rounded-full">
                {kycs.filter(k => k.status === 'pending').length} Pending
              </span>
            </div>
            <p className="text-[#666666] text-sm font-medium">Verify citizen identities and biometric credentials for platform security.</p>
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
