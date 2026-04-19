import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { Users, Search, Loader2, UserX, UserCheck, Trash2, Mail, Phone, Calendar, Shield } from 'lucide-react';

export const UserManagement = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [processingId, setProcessingId] = useState<string | null>(null);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      let query = supabase.from('profiles').select('*').order('created_at', { ascending: false });
      
      if (search) {
        query = query.or(`full_name.ilike.%${search}%,phone_number.ilike.%${search}%`);
      }

      const { data, error } = await query;
      
      if (error) throw error;
      setUsers(data || []);
    } catch (e) {
      console.error("Error fetching users:", e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const timer = setTimeout(() => {
      fetchUsers();
    }, 500);
    return () => clearTimeout(timer);
  }, [search]);

  const handleDelete = async (id: string) => {
    if (!confirm("CRITICAL ACTION: Permanently purge this user identity? All linked data will be lost.")) return;
    
    setProcessingId(id);
    try {
      await supabase.from('kyc_verifications').delete().eq('user_id', id);
      await supabase.from('notifications').delete().eq('user_id', id);
      await supabase.from('saved_properties').delete().eq('user_id', id);
      
      const { error } = await supabase.from('profiles').delete().eq('id', id);
      if (error) throw error;
      
      setUsers(prev => prev.filter(u => u.id !== id));
    } catch (e) {
      console.error(e);
      alert("Purge failed. Constraint violation likely.");
    } finally {
      setProcessingId(null);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'verified':
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-green-50 text-green-600 rounded-lg text-[10px] font-black uppercase tracking-widest border border-green-100">
            <UserCheck size={12} fill="currentColor" className="opacity-30" /> Verified
          </div>
        );
      case 'pending':
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-orange-50 text-orange-600 rounded-lg text-[10px] font-black uppercase tracking-widest border border-orange-100">
             Compliance Audit
          </div>
        );
      case 'rejected':
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-red-50 text-red-600 rounded-lg text-[10px] font-black uppercase tracking-widest border border-red-100">
            <UserX size={12} /> Access Denied
          </div>
        );
      default:
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-gray-50 text-gray-400 rounded-lg text-[10px] font-black uppercase tracking-widest border border-gray-100">
            Standard Entry
          </div>
        );
    }
  };

  return (
    <div className="p-8 max-w-7xl mx-auto w-full flex-1 flex flex-col min-h-screen pb-24 selection:bg-brand/10">
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-10 gap-6 animate-in fade-in slide-in-from-top-4 duration-500">
        <div>
          <h2 className="text-3xl font-brand font-black text-obsidian tracking-tight mb-2">User Directory</h2>
          <p className="text-gray-400 font-medium text-sm">Managing the Khozna ecosystem access control and identity validation.</p>
        </div>
        
        <div className="relative group">
          <input 
            type="text" 
            placeholder="Filter identity database..." 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full md:w-80 bg-white border border-gray-100 rounded-2xl py-3 pl-11 pr-4 focus:outline-none focus:ring-4 focus:ring-brand/5 focus:border-brand font-bold text-sm shadow-sm transition-all"
          />
          <Search size={18} className="absolute left-4 top-3.5 text-gray-300 group-focus-within:text-brand transition-colors" />
        </div>
      </div>

      <div className="bg-white rounded-[2.5rem] border border-gray-100 shadow-premium flex-1 overflow-hidden flex flex-col animate-in fade-in slide-in-from-bottom-6 duration-700">
        {loading ? (
          <div className="flex justify-center items-center h-full py-40">
            <Loader2 className="animate-spin text-brand" size={40} strokeWidth={2.5} />
          </div>
        ) : users.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-40 text-gray-400">
            <div className="w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center mb-6 shadow-inner">
              <Users size={40} className="opacity-20" />
            </div>
            <p className="font-brand font-black text-obsidian text-lg uppercase tracking-widest opacity-20">Zero Matches Found</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="text-[10px] font-black uppercase tracking-[0.2em] text-gray-400 bg-gray-50/50 border-b border-gray-100">
                  <th className="px-10 py-6">Operator Identity</th>
                  <th className="px-6 py-6 text-center">Contact Matrix</th>
                  <th className="px-6 py-6 text-center">Compliance</th>
                  <th className="px-10 py-6 text-right">System Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {users.map((user, idx) => (
                  <tr 
                    key={user.id} 
                    className="hover:bg-gray-50/50 transition-colors animate-in fade-in slide-in-from-left-4 duration-500 fill-mode-both"
                    style={{ animationDelay: `${idx * 50}ms` }}
                  >
                    <td className="px-10 py-5">
                      <div className="flex items-center gap-5">
                        <div className="relative">
                          {user.avatar_url ? (
                            <img src={user.avatar_url} className="w-12 h-12 rounded-2xl object-cover border-2 border-white shadow-md" alt="Avatar" />
                          ) : (
                            <div className="w-12 h-12 rounded-2xl bg-brand/5 text-brand flex items-center justify-center font-brand font-black text-xl shadow-inner border border-brand/10">
                              {(user.full_name || '?')[0].toUpperCase()}
                            </div>
                          )}
                          <div className={`absolute -bottom-1 -right-1 w-4 h-4 rounded-full border-2 border-white ${user.kyc_status === 'verified' ? 'bg-green-500' : 'bg-gray-300'}`} />
                        </div>
                        <div>
                          <p className="font-brand font-black text-obsidian tracking-tight group-hover:text-brand transition-colors">{user.full_name || 'Anonymous User'}</p>
                          <div className="flex items-center gap-1.5 text-gray-400 font-bold text-[10px] uppercase tracking-widest mt-0.5">
                            <Mail size={12} className="opacity-40" /> {user.email || 'N/A'}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-5">
                      <div className="flex flex-col items-center gap-1">
                        <div className="flex items-center gap-1.5 text-obsidian font-black text-[11px] tracking-tight">
                           <Phone size={12} className="text-brand opacity-60" /> {user.phone_number || 'UNDEFINED'}
                        </div>
                        <div className="flex items-center gap-1.5 text-gray-400 font-bold text-[10px] uppercase tracking-widest">
                           <Calendar size={12} className="opacity-40" /> {new Date(user.created_at).toLocaleDateString()}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-5 text-center">
                      {getStatusBadge(user.kyc_status)}
                    </td>
                    <td className="px-10 py-5 text-right">
                      <button 
                        onClick={() => handleDelete(user.id)}
                        disabled={processingId === user.id}
                        className="w-10 h-10 inline-flex items-center justify-center text-gray-300 hover:text-red-500 bg-white border border-gray-100 hover:bg-red-50 hover:border-red-200 rounded-xl shadow-sm transition-all disabled:opacity-50 group/btn"
                        title="Force Purge"
                      >
                        {processingId === user.id ? <Loader2 size={16} className="animate-spin text-brand" /> : <Trash2 size={16} className="group-hover/btn:scale-110 transition-transform" />}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="mt-8 flex items-center gap-4 bg-brand-light/20 p-6 rounded-[2rem] border border-brand/5 animate-in fade-in slide-in-from-bottom-4 duration-1000">
        <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center shadow-sm">
          <Shield size={24} className="text-brand" />
        </div>
        <div>
          <p className="text-sm font-brand font-black text-obsidian uppercase tracking-widest mb-1">Audit Protocol</p>
          <p className="text-xs text-brand/60 font-bold">Purging users is irreversible. Data integrity is maintained via PostgreSQL cascades.</p>
        </div>
      </div>
    </div>
  );
};
