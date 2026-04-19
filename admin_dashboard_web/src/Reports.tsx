import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { ShieldAlert, Trash2, Loader2, RefreshCw } from 'lucide-react';

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
    <div className="p-10 max-w-5xl mx-auto w-full flex-1 h-full overflow-y-auto">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-3xl font-extrabold text-gray-900 flex items-center gap-3">
            <ShieldAlert className="text-red-500" size={32} /> User Reports
          </h2>
          <p className="text-gray-500 mt-1">Manage user flags and potential scams reported by the community.</p>
        </div>
        <button onClick={fetchReports} className="p-3 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 flex items-center gap-2 font-semibold shadow-sm">
          {loading ? <Loader2 className="animate-spin text-gray-400" /> : <RefreshCw size={20} className="text-gray-600" />} 
          Refresh List
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Loader2 className="animate-spin text-red-500" size={40} /></div>
      ) : reports.length === 0 ? (
        <div className="text-center py-20 bg-white border border-gray-100 rounded-3xl shadow-sm">
          <div className="w-20 h-20 bg-green-50 text-green-500 rounded-full flex items-center justify-center mx-auto mb-4">
            <ShieldAlert size={32} />
          </div>
          <p className="text-gray-900 font-bold text-xl">All Clear!</p>
          <p className="text-gray-400 mt-1">No pending reports to deal with right now.</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {reports.map((report) => (
            <div key={report.id} className="bg-white border border-red-100 p-6 rounded-3xl shadow-sm relative overflow-hidden group">
              <div className="absolute top-0 left-0 w-1 h-full bg-red-400" />
              <div className="flex justify-between items-start">
                <div className="flex items-center gap-4 mb-4">
                  {report.reported?.avatar_url ? (
                    <img src={report.reported.avatar_url} className="w-12 h-12 rounded-full border border-gray-200 object-cover" alt="Avatar"/>
                  ) : (
                    <div className="w-12 h-12 rounded-full bg-gray-100 text-gray-400 flex items-center justify-center">
                      <ShieldAlert size={20} />
                    </div>
                  )}
                  <div>
                    <h3 className="font-bold text-gray-900 text-lg">Report against {report.reported?.full_name || 'Unknown User'}</h3>
                    <p className="text-xs text-gray-500 font-medium">Submitted by: <span className="text-gray-800">{report.reporter?.full_name || 'System'}</span> • {new Date(report.created_at).toLocaleDateString()}</p>
                  </div>
                </div>
                
                <button 
                  onClick={() => handleDelete(report.id)}
                  disabled={processingId === report.id}
                  className="p-2 text-gray-400 hover:text-green-500 hover:bg-green-50 rounded-xl transition-colors disabled:opacity-50"
                  title="Dismiss Report"
                >
                  {processingId === report.id ? <Loader2 size={24} className="animate-spin" /> : <Trash2 size={24} />}
                </button>
              </div>

              <div className="bg-red-50 text-red-900 p-4 rounded-xl border border-red-100">
                <p className="font-medium">{report.reason || 'No reason provided.'}</p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
