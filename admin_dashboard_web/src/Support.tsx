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
  Loader2
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

      // There is no native status field in the schema, simulating filter
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
    <div className="flex-1 overflow-hidden flex bg-[#F8FAFC]">
      {/* Main List */}
      <div className={`flex-1 overflow-y-auto px-12 py-12 ${selectedTicket ? 'hidden lg:block lg:w-1/2' : 'w-full'}`}>
        <div className="flex items-center justify-between mb-10">
          <div>
            <h2 className="text-3xl font-bold text-[#0F172A] tracking-tight mb-2">Support & Disputes</h2>
            <p className="text-[#64748B] text-sm font-medium">Manage user inquiries, technical issues, and booking disputes.</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div className="card-pro p-6 bg-red-50/30 border-red-200">
            <div className="flex items-center justify-between mb-4 text-red-600">
              <span className="text-[11px] font-bold uppercase tracking-wider">High Priority Open</span>
              <AlertTriangle size={18} />
            </div>
            <p className="text-3xl font-black text-[#0F172A]">8</p>
            <p className="text-[12px] font-medium text-[#64748B] mt-2">Requires immediate attention</p>
          </div>
          <div className="card-pro p-6">
            <div className="flex items-center justify-between mb-4 text-[#2563EB]">
              <span className="text-[11px] font-bold uppercase tracking-wider">Avg Response Time</span>
              <Clock size={18} />
            </div>
            <p className="text-3xl font-black text-[#0F172A]">2.4 hrs</p>
            <p className="text-[12px] font-medium text-[#64748B] mt-2">Trailing 7 days performance</p>
          </div>
        </div>

        <div className="card-pro overflow-hidden">
          <div className="px-6 py-4 border-b border-[#E2E8F0] bg-white flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="relative">
                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
                <input 
                  type="text" 
                  placeholder="Search tickets..." 
                  className="pl-10 pr-4 py-2 bg-[#F8FAFC] border border-[#E2E8F0] rounded-lg text-[13px] font-medium outline-none focus:border-[#2563EB] w-56 transition-all"
                />
              </div>
              <div className="flex items-center bg-[#F8FAFC] p-1 rounded-lg border border-[#E2E8F0]">
                {['open', 'in-progress', 'resolved', 'all'].map(f => (
                  <button
                    key={f}
                    onClick={() => setFilter(f)}
                    className={`px-4 py-1.5 text-[11px] font-bold rounded-md capitalize transition-colors ${filter === f ? 'bg-white text-[#2563EB] shadow-sm border border-[#E2E8F0]' : 'text-[#64748B] hover:text-[#0F172A]'}`}
                  >
                    {f}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="bg-white divide-y divide-[#E2E8F0]">
            {loading ? (
              <div className="py-20 flex flex-col items-center justify-center">
                <Loader2 className="animate-spin text-[#2563EB] mb-4" size={32} />
                <p className="text-[#94A3B8] text-[12px] font-bold uppercase tracking-wider">Loading Tickets</p>
              </div>
            ) : tickets.length === 0 ? (
              <div className="py-16 text-center text-[#64748B] text-sm font-medium">No tickets found.</div>
            ) : (
              tickets.map(t => (
                <div 
                  key={t.id} 
                  onClick={() => setSelectedTicket(t)}
                  className={`p-6 cursor-pointer transition-colors ${selectedTicket?.id === t.id ? 'bg-[#EFF6FF] border-l-4 border-l-[#2563EB]' : 'hover:bg-[#F8FAFC] border-l-4 border-l-transparent'}`}
                >
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <span className={`w-2 h-2 rounded-full bg-orange-500`}></span>
                      <h4 className="text-[14px] font-bold text-[#0F172A]">{t.reason || 'General Inquiry'}</h4>
                    </div>
                    <span className="text-[11px] font-bold text-[#64748B]">{new Date(t.created_at).toLocaleDateString()}</span>
                  </div>
                  <div className="flex items-center gap-4 text-[12px]">
                    <span className="font-semibold text-[#475569]">{t.reporter?.full_name || 'System User'}</span>
                    <span className="text-[#94A3B8]">|</span>
                    <span className="font-medium text-[#64748B]" title={t.id}>{t.id.substring(0, 8)}...</span>
                    <span className="text-[#94A3B8]">|</span>
                    <span className="font-bold text-[#2563EB]">Safety</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Detail Panel */}
      {selectedTicket && (
        <div className="w-full lg:w-[500px] border-l border-[#E2E8F0] bg-white flex flex-col h-full shadow-lg z-20 absolute lg:relative right-0">
          <div className="px-8 py-6 border-b border-[#E2E8F0] flex items-center justify-between bg-[#F8FAFC]">
            <div>
              <p className="text-[11px] font-bold text-[#2563EB] uppercase tracking-wider mb-1" title={selectedTicket.id}>{selectedTicket.id.substring(0, 8)}...</p>
              <h3 className="text-xl font-bold text-[#0F172A]">{selectedTicket.reporter?.full_name || 'System User'}</h3>
            </div>
            <button 
              onClick={() => setSelectedTicket(null)}
              className="w-8 h-8 rounded-full bg-white border border-[#E2E8F0] flex items-center justify-center text-[#64748B] hover:text-[#0F172A] hover:bg-gray-50 transition-colors"
            >
              <X size={16} />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-8 bg-white">
            <div className="mb-8">
              <h4 className="text-[14px] font-black text-[#0F172A] mb-2">{selectedTicket.reason || 'General Safety Issue'}</h4>
              <div className="flex items-center gap-2 mb-4">
                <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-orange-100 text-orange-700`}>
                  Medium priority
                </span>
                <span className="px-2 py-0.5 rounded bg-[#F1F5F9] text-[#64748B] text-[10px] font-bold uppercase tracking-wider">
                  Safety
                </span>
              </div>
              
              <div className="p-4 bg-[#F8FAFC] rounded-lg border border-[#E2E8F0] text-[13px] text-[#475569] leading-relaxed">
                Reported User: {selectedTicket.reported?.full_name || 'Unknown'} <br/>
                No additional description provided in the system.
              </div>
            </div>

            <div className="space-y-6 relative before:absolute before:inset-0 before:ml-4 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-[#E2E8F0] before:to-transparent">
               
               <div className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active">
                  <div className="flex items-center justify-center w-8 h-8 rounded-full border-2 border-white bg-[#EFF6FF] text-[#2563EB] shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2">
                    <MessageSquare size={14} />
                  </div>
                  <div className="w-[calc(100%-4rem)] md:w-[calc(50%-2.5rem)] p-4 rounded-xl border border-[#E2E8F0] bg-white shadow-sm">
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-bold text-[#0F172A] text-[12px]">System Auto-Reply</span>
                      <span className="text-[10px] font-medium text-[#94A3B8]">10 mins ago</span>
                    </div>
                    <p className="text-[12px] text-[#475569]">Ticket created and assigned to Payments queue.</p>
                  </div>
               </div>

            </div>
          </div>

          <div className="p-6 border-t border-[#E2E8F0] bg-[#F8FAFC]">
            <div className="relative">
              <textarea 
                placeholder="Type your reply here..." 
                className="w-full bg-white border border-[#E2E8F0] rounded-xl p-4 pr-12 text-[13px] outline-none focus:border-[#2563EB] resize-none h-24 shadow-sm"
              />
              <button className="absolute right-3 bottom-3 w-8 h-8 bg-[#2563EB] text-white rounded-lg flex items-center justify-center hover:bg-blue-700 transition-colors">
                <Send size={14} />
              </button>
            </div>
            <div className="flex gap-2 mt-4">
              <button className="flex-1 bg-white border border-[#E2E8F0] text-[#0F172A] text-[12px] font-bold py-2 rounded-lg hover:bg-gray-50 transition-colors flex justify-center items-center gap-2">
                <CornerDownRight size={14} /> Refund
              </button>
              <button className="flex-1 bg-[#10B981] text-white text-[12px] font-bold py-2 rounded-lg hover:bg-emerald-600 transition-colors flex justify-center items-center gap-2">
                <CheckCircle2 size={14} /> Mark Resolved
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
