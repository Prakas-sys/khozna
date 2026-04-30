import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { ShieldAlert, Loader2, RefreshCcw, User, Clock, AlertTriangle, ShieldCheck } from 'lucide-react';

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
          reported:reported_user_id(full_name, avatar_url),
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
    <div className="flex-1 overflow-y-auto">
      <div className="max-w-[1200px] mx-auto px-10 py-12">
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-8"
        >
          <div>
            <div className="flex items-center gap-4 mb-3">
              <h2 className="text-3xl font-extrabold text-[#0F172A] tracking-tight">Threat Monitor</h2>
              <span className="px-3 py-1 bg-red-50 text-red-600 text-[10px] font-bold uppercase tracking-wider rounded-full border border-red-100">
                {reports.length} Active Issues
              </span>
            </div>
            <p className="text-[#64748B] text-sm font-medium">Managing community flags, behavioral violations, and security reports.</p>
          </div>
          
          <button onClick={fetchReports} className="h-11 px-6 bg-white border border-[#E2E8F0] rounded-2xl hover:bg-[#F8FAFC] flex items-center gap-2.5 font-bold transition-all text-xs text-[#64748B] group">
             <RefreshCcw size={16} className={`group-hover:rotate-180 transition-transform duration-700 ${loading ? 'animate-spin' : ''}`} /> 
             Refresh Intel
          </button>
        </motion.div>

        {loading ? (
          <div className="flex flex-col justify-center items-center py-40 gap-4">
            <Loader2 className="animate-spin text-[#2563EB]" size={32} />
            <p className="text-[#94A3B8] text-xs font-bold uppercase tracking-widest">Scanning network</p>
          </div>
        ) : reports.length === 0 ? (
          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center py-40 rounded-[2.5rem] bg-white border border-[#E2E8F0] border-dashed"
          >
            <div className="w-20 h-20 bg-green-50 text-green-500 rounded-[1.5rem] flex items-center justify-center mx-auto mb-6 border border-green-100">
              <ShieldCheck size={36} />
            </div>
            <h3 className="text-[#0F172A] text-xl font-extrabold mb-2">Platform Secure</h3>
            <p className="text-[#64748B] text-sm font-medium">No critical threats or user reports detected in the current cycle.</p>
          </motion.div>
        ) : (
          <div className="space-y-6">
            <AnimatePresence mode="popLayout">
              {reports.map((report, idx) => (
                <motion.div 
                  key={report.id} 
                  layout
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  transition={{ delay: idx * 0.05 }}
                  className="card-platinum p-8 rounded-[2.5rem] relative overflow-hidden group"
                >
                  <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
                    <div className="flex items-center gap-6 flex-1">
                      <div className="relative">
                        <div className="w-16 h-16 rounded-2xl bg-[#F1F5F9] border-2 border-white shadow-sm flex items-center justify-center overflow-hidden">
                          {report.reported?.avatar_url ? (
                            <img src={report.reported.avatar_url} className="w-full h-full object-cover" alt=""/>
                          ) : (
                            <User size={24} className="text-[#94A3B8]" />
                          )}
                        </div>
                        <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-red-500 rounded-full flex items-center justify-center border-2 border-white shadow-sm">
                          <AlertTriangle size={10} className="text-white" />
                        </div>
                      </div>
                      <div>
                        <h3 className="font-extrabold text-[#0F172A] text-xl tracking-tight mb-1">Subject: {report.reported?.full_name || 'Anonymous User'}</h3>
                        <div className="flex flex-wrap items-center gap-4">
                          <div className="flex items-center gap-2 text-[10px] font-bold text-[#64748B] uppercase tracking-wider">
                             <User size={12} className="text-[#2563EB]/40" /> Reported by: <span className="text-[#0F172A]">{report.reporter?.full_name || 'Anonymous'}</span>
                          </div>
                          <div className="flex items-center gap-2 text-[10px] font-bold text-[#64748B] uppercase tracking-wider">
                             <Clock size={12} className="text-[#2563EB]/40" /> {new Date(report.created_at).toLocaleDateString()} at {new Date(report.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    <button 
                      onClick={() => handleDelete(report.id)}
                      disabled={processingId === report.id}
                      className="h-11 px-6 bg-white border border-[#E2E8F0] text-[#64748B] font-bold rounded-2xl hover:bg-green-50 hover:text-green-600 hover:border-green-100 transition-all disabled:opacity-50 active:scale-95 text-xs shadow-sm"
                    >
                      {processingId === report.id ? <Loader2 size={16} className="animate-spin" /> : 'Dismiss Case'}
                    </button>
                  </div>

                  <div className="mt-8 p-6 bg-red-50/50 text-[#991B1B] rounded-2xl border border-red-100 relative">
                    <div className="flex items-center gap-2 text-[10px] font-bold text-red-500 uppercase tracking-wider mb-2">
                      <ShieldAlert size={14} /> Reported Violation
                    </div>
                    <p className="font-medium text-sm leading-relaxed opacity-90">"{report.reason || 'No violation narrative provided.'}"</p>
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
