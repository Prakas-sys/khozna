import { useState, useEffect } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { supabase } from './lib/supabase';
import { ShieldAlert, Loader2, RefreshCcw, User, Clock, ShieldCheck, Mail, ShieldOff, CheckCircle2 } from 'lucide-react';

export const Reports = () => {
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [processingType, setProcessingType] = useState<'suspend' | 'resolve' | null>(null);

  const fetchReports = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('user_reports')
        .select(`
          *,
          reported:profiles!reported_user_id (id, full_name, avatar_url, email, is_suspended),
          reporter:profiles!reporter_id (full_name)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setReports(data || []);
    } catch (e) {
      console.error("Error fetching reports:", e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchReports(); }, []);

  // ─── Resolve (dismiss) the report ────────────────────────────────────────────
  const handleResolve = async (id: string) => {
    if (!confirm("Mark this report as resolved and dismiss it?")) return;
    setProcessingId(id);
    setProcessingType('resolve');
    try {
      const { error } = await supabase.from('user_reports').delete().eq('id', id);
      if (error) throw error;
      setReports(prev => prev.filter(r => r.id !== id));
    } catch (e: any) {
      console.error("Resolve failed:", e);
      alert(`Failed: ${e?.message}`);
    } finally {
      setProcessingId(null);
      setProcessingType(null);
    }
  };

  // ─── Suspend reported user + dismiss report ───────────────────────────────────
  const handleSuspend = async (report: any) => {
    const reportedId = report.reported_user_id || report.reported?.id;
    const name = report.reported?.full_name || 'this user';
    const isSuspended = report.reported?.is_suspended;

    if (isSuspended) {
      // Already suspended — just resolve the report
      await handleResolve(report.id);
      return;
    }

    if (!confirm(`🚫 Suspend "${name}" and dismiss this report?`)) return;

    setProcessingId(report.id);
    setProcessingType('suspend');
    try {
      // 1. Suspend the user
      const { error: suspendError } = await supabase
        .from('profiles')
        .update({ is_suspended: true })
        .eq('id', reportedId);
      if (suspendError) throw suspendError;

      // 2. Delete the report (resolved)
      const { error: deleteError } = await supabase
        .from('user_reports')
        .delete()
        .eq('id', report.id);
      if (deleteError) throw deleteError;

      setReports(prev => prev.filter(r => r.id !== report.id));
    } catch (e: any) {
      console.error("Suspend failed:", e);
      alert(`Failed: ${e?.message}`);
    } finally {
      setProcessingId(null);
      setProcessingType(null);
    }
  };

  const pendingCount = reports.length;

  return (
    <div className="flex-1 overflow-y-auto bg-[#FAFAFA]">
      <div className="max-w-4xl mx-auto px-8 py-8">

        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-10 gap-6">
          <div>
            <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">Safety Center</h2>
            <p className="text-[#737373] text-[13px]">
              Community flags and safety protocol enforcement.
              {pendingCount > 0 && (
                <span className="ml-2 inline-flex items-center px-2 py-0.5 bg-rose-50 text-rose-600 border border-rose-100 rounded-full text-[10px] font-bold">
                  {pendingCount} pending
                </span>
              )}
            </p>
          </div>
          <button
            onClick={fetchReports}
            disabled={loading}
            className="h-9 px-4 bg-white border border-[#E5E5E5] rounded-lg hover:bg-[#FAFAFA] flex items-center gap-2 text-[12px] font-semibold text-[#525252] transition-colors shadow-xs disabled:opacity-50"
          >
            <RefreshCcw size={14} strokeWidth={1.5} className={loading ? 'animate-spin' : ''} />
            Refresh Protocol
          </button>
        </div>

        {loading ? (
          <div key="loading" className="flex flex-col justify-center items-center py-40 gap-3">
            <div className="w-5 h-5 border-2 border-[#E5E5E5] border-t-[#171717] rounded-full animate-spin" />
            <p className="text-[#A3A3A3] text-[12px] font-medium uppercase tracking-widest">Scanning Community</p>
          </div>
        ) : reports.length === 0 ? (
          <div key="empty" className="empty-state border border-dashed border-[#E5E5E5] rounded-xl">
            <div className="empty-state-icon"><ShieldCheck size={20} strokeWidth={1.5} /></div>
            <h3 className="empty-state-title">Queue Clear</h3>
            <p className="empty-state-desc">No community reports or platform flags are currently active.</p>
          </div>
        ) : (
          <div key="list" className="space-y-3">
            <AnimatePresence mode="popLayout">
              {reports.map((report) => {
                const isProcessing = processingId === report.id;
                const isSuspended = report.reported?.is_suspended;

                return (
                  <motion.div
                    layout
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.98 }}
                    key={report.id}
                    className="card-minimal p-5 bg-white group hover:border-[#A3A3A3] transition-all"
                  >
                    {/* Top row: icon + reason + meta */}
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-5">
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 rounded-lg bg-rose-50 border border-rose-100 flex items-center justify-center text-rose-500 flex-shrink-0">
                          <ShieldAlert size={18} strokeWidth={1.5} />
                        </div>
                        <div>
                          <h3 className="text-[14px] font-semibold text-[#171717] mb-1 leading-tight">
                            {report.reason || 'General Safety Flag'}
                          </h3>
                          <div className="flex items-center gap-3 text-[11px] font-medium text-[#737373]">
                            <span className="flex items-center gap-1">
                              <User size={12} strokeWidth={1.5} />
                              By: {report.reporter?.full_name || 'Anonymous'}
                            </span>
                            <span className="w-1 h-1 rounded-full bg-[#E5E5E5]" />
                            <span className="flex items-center gap-1">
                              <Clock size={12} strokeWidth={1.5} />
                              {report.created_at ? new Date(report.created_at).toLocaleDateString() : '—'}
                            </span>
                          </div>
                        </div>
                      </div>

                      {/* Target user info + action buttons */}
                      <div className="flex items-center gap-3 flex-wrap">
                        {/* Target card */}
                        <div className="px-4 py-2 bg-[#FAFAFA] border border-[#E5E5E5] rounded-lg">
                          <p className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest mb-0.5">Target</p>
                          <div className="flex items-center gap-2">
                            <p className="text-[12px] font-semibold text-[#171717]">{report.reported?.full_name || 'N/A'}</p>
                            {report.reported?.email && (
                              <span title={report.reported.email}>
                                <Mail size={12} strokeWidth={1.5} className="text-[#A3A3A3]" />
                              </span>
                            )}
                            {isSuspended && (
                              <span className="inline-flex items-center px-1.5 py-0.5 bg-rose-50 text-rose-500 border border-rose-100 rounded text-[9px] font-bold">
                                SUSPENDED
                              </span>
                            )}
                          </div>
                        </div>

                        {/* Buttons */}
                        <div className="flex gap-2">
                          {/* Suspend user button */}
                          <button
                            onClick={() => handleSuspend(report)}
                            disabled={isProcessing}
                            className={`h-9 px-4 rounded-lg text-[12px] font-semibold transition-all flex items-center justify-center gap-2 disabled:opacity-40 ${
                              isSuspended
                                ? 'bg-white border border-[#E5E5E5] text-[#737373] hover:bg-[#FAFAFA]'
                                : 'bg-amber-500 text-white hover:bg-amber-600 shadow-sm'
                            }`}
                            title={isSuspended ? 'Already suspended — resolve report' : 'Suspend user and resolve report'}
                          >
                            {isProcessing && processingType === 'suspend' ? (
                              <Loader2 size={14} className="animate-spin" />
                            ) : isSuspended ? (
                              <><ShieldCheck size={14} strokeWidth={1.5} /> Already Suspended</>
                            ) : (
                              <><ShieldOff size={14} strokeWidth={1.5} /> Suspend User</>
                            )}
                          </button>

                          {/* Resolve / dismiss button */}
                          <button
                            onClick={() => handleResolve(report.id)}
                            disabled={isProcessing}
                            className="h-9 px-4 bg-[#171717] text-white rounded-lg text-[12px] font-semibold hover:bg-[#0A0A0A] transition-all flex items-center justify-center gap-2 shadow-sm disabled:opacity-40"
                            title="Dismiss this report without action"
                          >
                            {isProcessing && processingType === 'resolve' ? (
                              <Loader2 size={14} className="animate-spin" />
                            ) : (
                              <><CheckCircle2 size={14} strokeWidth={1.5} /> Dismiss</>
                            )}
                          </button>
                        </div>
                      </div>
                    </div>

                    {/* Description if exists */}
                    {report.description && (
                      <div className="mt-4 pt-4 border-t border-[#F5F5F5]">
                        <p className="text-[12px] text-[#737373] leading-relaxed">{report.description}</p>
                      </div>
                    )}
                  </motion.div>
                );
              })}
            </AnimatePresence>
          </div>
        )}
      </div>
    </div>
  );
};
