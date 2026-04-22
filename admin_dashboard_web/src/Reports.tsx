import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { ShieldAlert, Loader2, RefreshCcw, User, Clock, AlertTriangle } from 'lucide-react';

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
      alert("Failed to delete report.");
    } finally {
      setProcessingId(null);
    }
  };

  return (
    <div className="p-10 max-w-[1200px] mx-auto w-full flex-1 h-full overflow-y-auto bg-[#F9FAFB]/50">
      <motion.div 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col md:flex-row md:items-center justify-between mb-12 gap-8"
      >
        <div>
          <div className="flex items-center gap-4 mb-2">
            <h2 className="text-4xl font-brand font-black text-obsidian tracking-tighter flex items-center gap-4">
              <ShieldAlert className="text-red-500" size={36} /> 
              Threat Monitor
            </h2>
            <div className="px-3 py-1 bg-red-500 text-white text-[9px] font-black uppercase tracking-[0.2em] rounded-md shadow-lg shadow-red-500/20">Active: {reports.length}</div>
          </div>
          <p className="text-gray-400 font-medium text-sm">Managing community flags, behavioral violations, and security reports.</p>
        </div>
        
        <button onClick={fetchReports} className="px-8 py-3.5 bg-white border border-gray-100 rounded-2xl hover:bg-gray-50 flex items-center gap-3 font-black shadow-sm transition-all text-xs uppercase tracking-widest group">
           {loading ? <Loader2 className="animate-spin text-brand" size={16} /> : <RefreshCcw size={16} className="text-gray-400 group-hover:rotate-180 transition-transform duration-700" />} 
           Refresh Intel
        </button>
      </motion.div>

      {loading ? (
        <div className="flex justify-center items-center py-48">
          <div className="w-12 h-12 border-4 border-brand/10 border-t-brand rounded-full animate-spin" />
        </div>
      ) : reports.length === 0 ? (
        <motion.div 
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center py-48 bg-white border border-gray-100 rounded-[3rem] shadow-xl shadow-gray-100/50"
        >
          <div className="w-24 h-24 bg-green-500/10 text-green-500 rounded-full flex items-center justify-center mx-auto mb-8 shadow-inner">
            <ShieldAlert size={40} />
          </div>
          <h3 className="text-2xl font-brand font-black text-obsidian uppercase tracking-widest">Sector Clear</h3>
          <p className="text-gray-400 mt-3 font-medium max-w-sm mx-auto">No critical threats or user reports detected in the current cycle.</p>
        </motion.div>
      ) : (
        <div className="grid gap-6">
          <AnimatePresence mode="popLayout">
            {reports.map((report, idx) => (
              <motion.div 
                key={report.id} 
                layout
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, scale: 0.95 }}
                transition={{ delay: idx * 0.05 }}
                className="bg-white border border-red-100 p-8 rounded-[2.5rem] shadow-sm hover:shadow-2xl hover:shadow-red-500/5 transition-all relative overflow-hidden group"
              >
                <div className="absolute top-0 left-0 w-1.5 h-full bg-red-500" />
                
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
                  <div className="flex items-center gap-6 flex-1">
                    <div className="relative">
                      {report.reported?.avatar_url ? (
                        <img src={report.reported.avatar_url} className="w-16 h-16 rounded-2xl border-2 border-white shadow-lg object-cover" alt="Avatar"/>
                      ) : (
                        <div className="w-16 h-16 rounded-2xl bg-red-50 text-red-400 flex items-center justify-center border border-red-100 shadow-inner">
                          <User size={24} />
                        </div>
                      )}
                      <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-red-500 rounded-full flex items-center justify-center border-2 border-white shadow-sm">
                        <AlertTriangle size={10} className="text-white" />
                      </div>
                    </div>
                    <div>
                      <h3 className="font-brand font-black text-obsidian text-xl tracking-tight mb-1">Target: {report.reported?.full_name || 'Unknown Subject'}</h3>
                      <div className="flex flex-wrap items-center gap-4">
                        <div className="flex items-center gap-2 text-[10px] font-black text-gray-400 uppercase tracking-widest">
                           <User size={12} className="text-brand opacity-40" /> Reporter: <span className="text-obsidian">{report.reporter?.full_name || 'Anonymous'}</span>
                        </div>
                        <div className="flex items-center gap-2 text-[10px] font-black text-gray-400 uppercase tracking-widest">
                           <Clock size={12} className="text-brand opacity-40" /> {new Date(report.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} • {new Date(report.created_at).toLocaleDateString()}
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <button 
                    onClick={() => handleDelete(report.id)}
                    disabled={processingId === report.id}
                    className="px-6 py-3 bg-red-500/5 text-red-500 font-black rounded-xl hover:bg-green-500 hover:text-white transition-all disabled:opacity-50 active:scale-95 text-[10px] uppercase tracking-widest border border-red-500/10 hover:border-green-500 shadow-sm"
                  >
                    {processingId === report.id ? <Loader2 size={16} className="animate-spin" /> : 'Dismiss Case'}
                  </button>
                </div>

                <div className="mt-8 p-6 bg-red-500/[0.03] text-red-900 rounded-2xl border border-red-500/5 relative">
                  <div className="flex items-center gap-2 text-[9px] font-black text-red-500/60 uppercase tracking-widest mb-2">
                    <ShieldAlert size={12} /> Violation Narrative
                  </div>
                  <p className="font-medium text-sm leading-relaxed text-red-900/80 italic">"{report.reason || 'No violation data provided.'}"</p>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}
    </div>
  );
};
