import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { ShieldAlert, Loader2, RefreshCcw, User, Clock, ShieldCheck } from 'lucide-react';

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
    <div className="flex-1 overflow-y-auto bg-[#FBFBF9]">
      <div className="max-w-[1200px] mx-auto px-10 py-12">
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-8"
        >
          <div>
            <div className="flex items-center gap-4 mb-3">
              <h2 className="text-3xl font-extrabold text-[#1A1A1A] tracking-tight">Safety Center</h2>
              <span className="px-3 py-1 bg-red-50 text-red-600 text-[10px] font-bold uppercase tracking-wider rounded-full border border-red-100">
                {reports.length} Open Reports
              </span>
            </div>
            <p className="text-[#666666] text-sm font-medium">Managing community flags, listing violations, and user feedback.</p>
          </div>
          
          <button onClick={fetchReports} className="h-11 px-6 bg-white border border-[#E8E6E1] rounded-2xl hover:bg-[#FBFBF9] flex items-center gap-2.5 font-bold transition-all text-xs text-[#666666] group">
             <RefreshCcw size={16} className={`group-hover:rotate-180 transition-transform duration-700 ${loading ? 'animate-spin' : ''}`} /> 
             Refresh Reports
          </button>
        </motion.div>

        {loading ? (
          <div className="flex flex-col justify-center items-center py-40 gap-4">
            <Loader2 className="animate-spin text-[#2563EB]" size={32} />
            <p className="text-[#A1A1A1] text-xs font-bold uppercase tracking-widest">Checking reports</p>
          </div>
        ) : reports.length === 0 ? (
          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center py-40 rounded-[2.5rem] bg-white border border-[#E8E6E1] border-dashed"
          >
            <div className="w-20 h-20 bg-green-50 text-green-500 rounded-[1.5rem] flex items-center justify-center mx-auto mb-6 border border-green-100">
              <ShieldCheck size={36} />
            </div>
            <h3 className="text-[#1A1A1A] text-xl font-extrabold mb-2">Platform Clear</h3>
            <p className="text-[#666666] text-sm font-medium">No community reports or flags detected in the current queue.</p>
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
                  className="card-platinum p-8 rounded-[2.5rem] relative overflow-hidden group bg-white border border-[#E8E6E1]"
                >
                  <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
                    <div className="flex items-center gap-5">
                      <div className="w-14 h-14 rounded-2xl bg-[#F4F2EE] overflow-hidden border border-[#E8E6E1]">
                        <img src={report.reported?.avatar_url || `https://api.dicebear.com/7.x/avataaars/svg?seed=${report.reported?.full_name}`} className="w-full h-full object-cover" alt="" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2 mb-1">
                          <p className="font-extrabold text-[#1A1A1A] text-lg tracking-tight leading-none">{report.reported?.full_name}</p>
                          <span className="px-2 py-0.5 bg-red-50 text-red-600 text-[9px] font-bold uppercase tracking-wider rounded border border-red-100">Reported</span>
                        </div>
                        <p className="text-[10px] text-[#A1A1A1] font-bold font-mono uppercase tracking-widest">{report.reported_user_id.split('-')[0]}</p>
                      </div>
                    </div>

                    <div className="flex items-center gap-6">
                      <div className="flex items-center gap-2 text-[#666666] font-bold text-[10px] uppercase tracking-wider bg-[#FBFBF9] px-3 py-2 rounded-xl border border-[#E8E6E1]">
                        <Clock size={12} className="text-[#A1A1A1]" /> {new Date(report.created_at).toLocaleDateString()}
                      </div>
                      <div className="flex items-center gap-2 text-[#A1A1A1] font-bold text-[10px] uppercase tracking-wider">
                        <User size={12} /> Reported by <span className="text-[#1A1A1A]">{report.reporter?.full_name}</span>
                      </div>
                    </div>
                    
                    <button 
                      onClick={() => handleDelete(report.id)}
                      disabled={processingId === report.id}
                      className="h-11 px-6 bg-white border border-[#E8E6E1] text-[#666666] font-bold rounded-xl hover:bg-[#FBFBF9] transition-all disabled:opacity-50 active:scale-95 text-xs"
                    >
                      {processingId === report.id ? <Loader2 size={16} className="animate-spin" /> : 'Dismiss Case'}
                    </button>
                  </div>

                  <div className="mt-8 p-6 bg-red-50/50 text-[#991B1B] rounded-2xl border border-red-100 relative">
                    <div className="flex items-center gap-2 text-[10px] font-bold text-red-500 uppercase tracking-wider mb-2">
                      <ShieldAlert size={14} /> Reported Issue
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
