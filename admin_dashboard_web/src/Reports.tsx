import { useState, useEffect } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { supabase } from './lib/supabase';
import { ShieldAlert, Loader2, RefreshCcw, User, Clock, ShieldCheck, Mail, ArrowUpRight } from 'lucide-react';

export const Reports = () => {
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [processingId, setProcessingId] = useState<string | null>(null);

  const fetchReports = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('user_reports')
        .select(`
          *,
          reported:reported_user_id(full_name, avatar_url, email),
          reporter:reporter_id(full_name)
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

  useEffect(() => {
    fetchReports();
  }, []);

  const handleDelete = async (id: string) => {
    setProcessingId(id);
    try {
      await supabase.from('user_reports').delete().eq('id', id);
      setReports(prev => prev.filter(r => r.id !== id));
    } catch (e) {
      console.error(e);
    } finally {
      setProcessingId(null);
    }
  };

  return (
    <div className="flex-1 overflow-y-auto bg-[#FAFAFA]">
      <div className="max-w-4xl mx-auto px-8 py-8">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-10 gap-6">
          <div>
            <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">Safety Center</h2>
            <p className="text-[#737373] text-[13px]">Community flags and safety protocol enforcement.</p>
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
          <div className="flex flex-col justify-center items-center py-40 gap-3">
            <div className="w-5 h-5 border-2 border-[#E5E5E5] border-t-[#171717] rounded-full animate-spin" />
            <p className="text-[#A3A3A3] text-[12px] font-medium uppercase tracking-widest">Scanning Community</p>
          </div>
        ) : reports.length === 0 ? (
          <div className="empty-state border border-dashed border-[#E5E5E5] rounded-xl">
            <div className="empty-state-icon">
              <ShieldCheck size={20} strokeWidth={1.5} />
            </div>
            <h3 className="empty-state-title">Queue Clear</h3>
            <p className="empty-state-desc">No community reports or platform flags are currently active.</p>
          </div>
        ) : (
          <div className="space-y-3">
            <AnimatePresence mode="popLayout">
              {reports.map((report) => (
                <motion.div 
                  layout
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.98 }}
                  key={report.id} 
                  className="card-minimal p-5 bg-white flex flex-col md:flex-row md:items-center justify-between gap-6 group hover:border-[#A3A3A3] transition-all"
                >
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-lg bg-rose-50 border border-rose-100 flex items-center justify-center text-rose-500">
                      <ShieldAlert size={18} strokeWidth={1.5} />
                    </div>
                    <div>
                      <h3 className="text-[14px] font-semibold text-[#171717] mb-1 leading-tight">{report.reason || 'General Safety Flag'}</h3>
                      <div className="flex items-center gap-3 text-[11px] font-medium text-[#737373]">
                        <span className="flex items-center gap-1"><User size={12} strokeWidth={1.5} /> By: {report.reporter?.full_name || 'Anonymous'}</span>
                        <span className="w-1 h-1 rounded-full bg-[#E5E5E5]"></span>
                        <span className="flex items-center gap-1"><Clock size={12} strokeWidth={1.5} /> {new Date(report.created_at).toLocaleDateString()}</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    <div className="px-4 py-2 bg-[#FAFAFA] border border-[#E5E5E5] rounded-lg">
                      <p className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest mb-0.5">Target</p>
                      <div className="flex items-center gap-2">
                         <p className="text-[12px] font-semibold text-[#171717]">{report.reported?.full_name || 'N/A'}</p>
                         {report.reported?.email && <Mail size={12} strokeWidth={1.5} className="text-[#A3A3A3]" title={report.reported.email} />}
                      </div>
                    </div>
                    <div className="flex gap-2">
                       <button className="w-9 h-9 flex items-center justify-center rounded-lg bg-white border border-[#E5E5E5] text-[#A3A3A3] hover:text-[#171717] transition-all shadow-xs opacity-0 group-hover:opacity-100">
                          <ArrowUpRight size={14} strokeWidth={1.5} />
                       </button>
                       <button 
                        onClick={() => handleDelete(report.id)}
                        disabled={processingId === report.id}
                        className="h-9 px-4 bg-[#171717] text-white rounded-lg text-[12px] font-semibold hover:bg-[#0A0A0A] transition-all flex items-center justify-center gap-2 shadow-sm disabled:opacity-40"
                      >
                        {processingId === report.id ? <Loader2 size={14} className="animate-spin" /> : 'Resolve Flag'}
                      </button>
                    </div>
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
        )}
      </div>
    </div>
  );
};
