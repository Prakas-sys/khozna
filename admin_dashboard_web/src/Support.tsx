import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { 
  MessageSquare, 
  Clock, 
  AlertTriangle,
  Search,
  CheckCircle2,
  X,
  Send,
  CornerDownRight,
  Loader2,
  Paperclip,
  Activity,
  History
} from 'lucide-react';

export const Support = () => {
  const [filter, setFilter] = useState('open');
  const [selectedTicket, setSelectedTicket] = useState<any>(null);
  const [tickets, setTickets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchTickets();
  }, [filter]);

  const fetchTickets = async () => {
    setLoading(true);
    try {
      let query = supabase
        .from('user_reports')
        .select(`
          *,
          reporter:reporter_id(full_name),
          reported:reported_user_id(full_name)
        `)
        .order('created_at', { ascending: false });

      const { data, error } = await query;
      if (error) throw error;
      setTickets(data || []);
    } catch (e) {
      console.error('Error fetching support tickets:', e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex-1 overflow-hidden flex bg-[#FAFAFA]">
      {/* Main List */}
      <div className={`flex-1 overflow-y-auto px-8 py-8 ${selectedTicket ? 'hidden lg:block lg:w-1/2' : 'w-full'}`}>
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">Support & Security</h2>
            <p className="text-[#737373] text-[13px]">Manage community reports and platform inquiries.</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
          <div className="card-minimal p-6 border-b-2 border-b-rose-400">
            <div className="flex items-center justify-between mb-4">
              <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Active Reports</span>
              <AlertTriangle size={16} strokeWidth={1.5} className="text-[#A3A3A3]" />
            </div>
            <p className="text-[24px] font-semibold text-[#171717]">{loading ? '--' : tickets.length}</p>
            <p className="text-[11px] text-[#A3A3A3] mt-1.5 flex items-center gap-1">
               Awaiting moderation action
            </p>
          </div>
          <div className="card-minimal p-6">
            <div className="flex items-center justify-between mb-4">
              <span className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest">Mean Resolve Time</span>
              <Clock size={16} strokeWidth={1.5} className="text-[#A3A3A3]" />
            </div>
            <p className="text-[24px] font-semibold text-[#171717]">0.0h</p>
            <p className="text-[11px] text-[#A3A3A3] mt-1.5 font-medium">Telemetry pending</p>
          </div>
        </div>

        <div className="card-minimal overflow-hidden shadow-xs bg-white">
          <div className="px-5 py-4 border-b border-[#E5E5E5] flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="relative">
                <Search size={14} strokeWidth={1.5} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#A3A3A3]" />
                <input 
                  type="text" 
                  placeholder="Filter tickets..." 
                  className="pl-9 pr-3 py-[7px] bg-[#FAFAFA] border border-[#E5E5E5] rounded-lg text-[13px] font-medium outline-none focus:border-[#A3A3A3] w-56 transition-all"
                />
              </div>
              <div className="flex items-center bg-[#F5F5F5] p-0.5 rounded-lg border border-[#E5E5E5]">
                {['open', 'resolved', 'all'].map(f => (
                  <button
                    key={f}
                    onClick={() => setFilter(f)}
                    className={`px-3.5 py-1.5 text-[11px] font-semibold rounded-md capitalize transition-all ${filter === f ? 'bg-white text-[#171717] shadow-xs border border-[#E5E5E5]' : 'text-[#737373] hover:text-[#171717]'}`}
                  >
                    {f}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="divide-y divide-[#F5F5F5]">
            {loading ? (
              <div className="py-20 flex flex-col items-center justify-center gap-3">
                <div className="w-5 h-5 border-2 border-[#E5E5E5] border-t-[#171717] rounded-full animate-spin" />
                <p className="text-[12px] text-[#A3A3A3] font-medium">Loading threads...</p>
              </div>
            ) : tickets.length === 0 ? (
              <div className="empty-state">
                  <div className="empty-state-icon">
                    <MessageSquare size={20} strokeWidth={1.5} />
                  </div>
                  <p className="empty-state-title">No support tickets</p>
                  <p className="empty-state-desc">The queue is currently clear of reports.</p>
              </div>
            ) : (
              tickets.map(t => (
                <div 
                  key={t.id} 
                  onClick={() => setSelectedTicket(t)}
                  className={`p-6 cursor-pointer transition-all border-l-2 ${selectedTicket?.id === t.id ? 'bg-[#FAFAFA] border-l-[#171717]' : 'hover:bg-[#FAFAFA] border-l-transparent text-[#737373]'}`}
                >
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 rounded-full bg-orange-400"></div>
                      <h4 className="text-[13px] font-semibold text-[#171717]">{t.reason || 'General Inquiry'}</h4>
                    </div>
                    <span className="text-[11px] font-medium text-[#A3A3A3] uppercase tracking-wider">{new Date(t.created_at).toLocaleDateString()}</span>
                  </div>
                  <div className="flex items-center gap-4 text-[11px]">
                    <span className="font-semibold text-[#525252]">{t.reporter?.full_name || 'Anonymous User'}</span>
                    <span className="text-[#E5E5E5]">/</span>
                    <span className="font-mono text-[#A3A3A3]" title={t.id}>{t.id.substring(0, 8)}</span>
                    <span className="text-[#E5E5E5]">/</span>
                    <span className="font-semibold text-[#171717] uppercase tracking-widest text-[9px]">Community Report</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Detail Panel */}
      {selectedTicket && (
        <div className="w-full lg:w-[500px] border-l border-[#E5E5E5] bg-white flex flex-col h-full shadow-2xl z-20 absolute lg:relative right-0">
          <div className="px-8 py-6 border-b border-[#E5E5E5] flex items-center justify-between bg-[#FAFAFA]">
            <div>
              <p className="text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-widest mb-1">REF_{selectedTicket.id.substring(0, 8)}</p>
              <h3 className="text-[16px] font-semibold text-[#171717]">{selectedTicket.reporter?.full_name || 'System User'}</h3>
            </div>
            <button 
              onClick={() => setSelectedTicket(null)}
              className="w-8 h-8 rounded-lg bg-white border border-[#E5E5E5] flex items-center justify-center text-[#A3A3A3] hover:text-[#171717] hover:bg-[#FAFAFA] transition-colors shadow-xs"
            >
              <X size={14} strokeWidth={1.5} />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-8 relative">
            <div className="mb-10">
              <div className="flex items-center gap-2 mb-4">
                <span className="px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider bg-orange-50 text-orange-600 border border-orange-100">
                  Moderation Required
                </span>
                <span className="px-2 py-0.5 rounded bg-[#F5F5F5] text-[#737373] text-[10px] font-semibold uppercase tracking-wider border border-[#E5E5E5]">
                  Public Flag
                </span>
              </div>
              
              <div className="p-5 bg-[#FAFAFA] rounded-xl border border-[#E5E5E5] text-[13px] text-[#525252] leading-relaxed mb-8">
                <p className="font-semibold text-[#171717] mb-2">Subject: {selectedTicket.reason || 'Safety Violation'}</p>
                Targeted Profile: {selectedTicket.reported?.full_name || 'Unknown Participant'} <br/>
                No supplementary description was provided by the reporter.
              </div>

              <div className="border-l border-[#E5E5E5] ml-4 pl-8 space-y-8 relative">
                 <div className="relative">
                    <div className="absolute -left-[41px] top-0 w-4 h-4 rounded-full border border-[#E5E5E5] bg-white flex items-center justify-center">
                       <div className="w-1.5 h-1.5 rounded-full bg-[#171717]"></div>
                    </div>
                    <div>
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="text-[12px] font-semibold text-[#171717]">Protocol Hook</span>
                        <span className="text-[10px] font-medium text-[#A3A3A3]">Auto-generated</span>
                      </div>
                      <div className="p-3.5 rounded-xl bg-[#FAFAFA] border border-[#E5E5E5] text-[12px] text-[#525252]">
                        Ticket initialized via community reporting API. Assigned to manual moderation queue.
                      </div>
                    </div>
                 </div>
              </div>
            </div>
          </div>

          <div className="p-6 border-t border-[#E5E5E5] bg-[#FAFAFA]">
            <div className="relative mb-4">
              <textarea 
                placeholder="Draft a response..." 
                className="w-full bg-white border border-[#E5E5E5] rounded-xl p-4 pr-12 text-[13px] outline-none focus:border-[#171717] resize-none h-28 shadow-xs placeholder:text-[#D4D4D4] font-medium"
              />
              <div className="absolute right-3 bottom-3 flex items-center gap-2">
                 <button className="w-8 h-8 flex items-center justify-center text-[#A3A3A3] hover:text-[#171717] transition-colors">
                    <Paperclip size={14} strokeWidth={1.5} />
                 </button>
                 <button className="w-8 h-8 bg-[#171717] text-white rounded-lg flex items-center justify-center hover:bg-[#0A0A0A] transition-colors shadow-sm">
                    <Send size={14} strokeWidth={1.5} />
                 </button>
              </div>
            </div>
            <div className="flex gap-2">
              <button className="flex-1 h-10 bg-white border border-[#E5E5E5] text-[#525252] text-[12px] font-semibold rounded-lg hover:bg-[#FAFAFA] transition-all shadow-xs flex justify-center items-center gap-2">
                <History size={14} strokeWidth={1.5} /> Audit Log
              </button>
              <button className="flex-1 h-10 bg-[#171717] text-white text-[12px] font-semibold rounded-lg hover:bg-[#0A0A0A] transition-all shadow-sm flex justify-center items-center gap-2">
                <CheckCircle2 size={14} strokeWidth={1.5} /> Resolve
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
