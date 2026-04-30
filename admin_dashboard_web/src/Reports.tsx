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
    <div className="flex-1 overflow-y-auto bg-[#F8FAFC]">
      <div className="max-w-[1200px] mx-auto px-12 py-12">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-10 gap-6">
          <div>
            <h2 className="text-2xl font-bold text-[#0F172A] tracking-tight mb-2">Safety Center</h2>
            <p className="text-[#64748B] text-sm font-medium">Manage community flags and safety reports.</p>
          </div>
          
          <button onClick={fetchReports} className="h-10 px-4 bg-white border border-[#E2E8F0] rounded-lg hover:bg-gray-50 flex items-center gap-2 text-[12px] font-bold text-[#475569] transition-all shadow-sm">
             <RefreshCcw size={14} className={loading ? 'animate-spin' : ''} /> 
             Refresh
          </button>
        </div>

        {loading ? (
          <div className="flex flex-col justify-center items-center py-40 gap-4">
            <Loader2 className="animate-spin text-[#2563EB]" size={32} />
            <p className="text-[#A1A1A1] text-xs font-bold uppercase tracking-widest">Checking reports</p>
          </div>
        ) : reports.length === 0 ? (
          <div className="text-center py-32 rounded-xl bg-white border border-[#E2E8F0] border-dashed">
            <div className="w-16 h-16 bg-emerald-50 text-emerald-500 rounded-lg flex items-center justify-center mx-auto mb-4 border border-emerald-100">
              <ShieldCheck size={28} />
            </div>
            <h3 className="text-[#0F172A] text-lg font-bold mb-1">Queue Clear</h3>
            <p className="text-[#64748B] text-sm font-medium">No community reports or flags pending review.</p>
          </div>
        ) : (
          <div className="space-y-6">
            <AnimatePresence mode="popLayout">
              {reports.map((report) => (
                <div 
                  key={report.id} 
                  className="card-pro p-6 bg-white border border-[#E2E8F0] rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-6"
                >
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
