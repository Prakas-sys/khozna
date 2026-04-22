import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { Users, Search, Loader2, UserX, UserCheck, Trash2, Mail, Phone, Calendar, Shield, Filter } from 'lucide-react';

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
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-green-500/5 text-green-500 rounded-lg text-[10px] font-black uppercase tracking-widest border border-green-500/10">
            <UserCheck size={12} fill="currentColor" className="opacity-30" /> Verified
          </div>
        );
      case 'pending':
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-orange-500/5 text-orange-500 rounded-lg text-[10px] font-black uppercase tracking-widest border border-orange-500/10">
             Audit Required
          </div>
        );
      case 'rejected':
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-red-500/5 text-red-500 rounded-lg text-[10px] font-black uppercase tracking-widest border border-red-500/10">
            <UserX size={12} /> Access Revoked
          </div>
        );
      default:
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-gray-500/5 text-gray-400 rounded-lg text-[10px] font-black uppercase tracking-widest border border-gray-500/10">
            Standard
          </div>
        );
    }
  };

  return (
    <div className="p-10 max-w-[1600px] mx-auto w-full flex-1 flex flex-col min-h-screen pb-24 selection:bg-brand/10 bg-[#F9FAFB]/50">
      <motion.div 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col md:flex-row md:items-center justify-between mb-12 gap-8"
      >
        <div>
          <div className="flex items-center gap-3 mb-2">
            <h2 className="text-4xl font-brand font-black text-obsidian tracking-tighter">User Registry</h2>
            <div className="px-3 py-1 bg-obsidian text-white text-[9px] font-black uppercase tracking-[0.2em] rounded-md">Total: {users.length}</div>
          </div>
          <p className="text-gray-400 font-medium text-sm">Managing the Khozna identity layer and administrative access controls.</p>
        </div>
        
        <div className="flex items-center gap-4">
          <div className="relative group">
            <input 
              type="text" 
              placeholder="Filter identity database..." 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full md:w-96 bg-white border border-gray-100 rounded-2xl py-4 pl-12 pr-4 focus:outline-none focus:ring-4 focus:ring-brand/5 focus:border-brand font-bold text-sm shadow-sm transition-all"
            />
            <Search size={18} className="absolute left-4 top-4 text-gray-300 group-focus-within:text-brand transition-colors" />
          </div>
          <button className="p-4 bg-white border border-gray-100 rounded-2xl text-gray-400 hover:text-obsidian hover:bg-gray-50 transition-all shadow-sm">
            <Filter size={18} />
          </button>
        </div>
      </motion.div>

      <motion.div 
        initial={{ opacity: 0, scale: 0.98 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white rounded-[3rem] border border-gray-100 shadow-2xl shadow-gray-200/50 flex-1 overflow-hidden flex flex-col"
      >
        {loading ? (
          <div className="flex justify-center items-center h-full py-48">
            <div className="relative">
              <div className="w-12 h-12 border-4 border-brand/10 border-t-brand rounded-full animate-spin" />
              <Loader2 className="absolute inset-0 m-auto text-brand animate-pulse" size={16} />
            </div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="text-[10px] font-black uppercase tracking-[0.25em] text-gray-400 bg-gray-50/50 border-b border-gray-100">
                  <th className="px-12 py-8">Citizen Identity</th>
                  <th className="px-8 py-8">Contact Matrix</th>
                  <th className="px-8 py-8 text-center">Compliance Status</th>
                  <th className="px-12 py-8 text-right">Operations</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                <AnimatePresence mode="popLayout">
                  {users.map((user, idx) => (
                    <motion.tr 
                      key={user.id} 
                      layout
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      transition={{ delay: idx * 0.03 }}
                      className="group hover:bg-gray-50/80 transition-colors"
                    >
                      <td className="px-12 py-6">
                        <div className="flex items-center gap-6">
                          <div className="relative">
                            <div className="w-14 h-14 rounded-2xl bg-gray-50 overflow-hidden border-2 border-white shadow-md transition-transform group-hover:scale-110">
                              {user.avatar_url ? (
                                <img src={user.avatar_url} className="w-full h-full object-cover" alt="Avatar" />
                              ) : (
                                <div className="w-full h-full bg-gradient-to-br from-brand/5 to-brand/20 flex items-center justify-center font-brand font-black text-xl text-brand">
                                  {(user.full_name || '?')[0].toUpperCase()}
                                </div>
                              )}
                            </div>
                            <div className={`absolute -bottom-1 -right-1 w-4 h-4 rounded-full border-2 border-white shadow-sm ${user.kyc_status === 'verified' ? 'bg-green-500' : 'bg-gray-300'}`} />
                          </div>
                          <div>
                            <p className="font-brand font-black text-obsidian tracking-tight text-lg leading-tight mb-1">{user.full_name || 'Unknown Operator'}</p>
                            <div className="flex items-center gap-2 text-gray-400 font-bold text-[10px] uppercase tracking-widest">
                              <Mail size={12} className="opacity-40" /> {user.email || 'NO_AUTH_EMAIL'}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-8 py-6">
                        <div className="space-y-1.5">
                          <div className="flex items-center gap-2 text-obsidian font-black text-[11px] tracking-tight">
                             <Phone size={12} className="text-brand opacity-60" /> {user.phone_number || 'N/A'}
                          </div>
                          <div className="flex items-center gap-2 text-gray-400 font-bold text-[10px] uppercase tracking-widest">
                             <Calendar size={12} className="opacity-40" /> {new Date(user.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
                          </div>
                        </div>
                      </td>
                      <td className="px-8 py-6 text-center">
                        {getStatusBadge(user.kyc_status)}
                      </td>
                      <td className="px-12 py-6 text-right">
                        <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button 
                            onClick={() => handleDelete(user.id)}
                            disabled={processingId === user.id}
                            className="w-11 h-11 inline-flex items-center justify-center text-gray-300 hover:text-red-500 bg-white border border-gray-100 hover:bg-red-50 hover:border-red-200 rounded-xl shadow-sm transition-all disabled:opacity-50 group/btn"
                          >
                            {processingId === user.id ? <Loader2 size={16} className="animate-spin text-brand" /> : <Trash2 size={18} className="group-hover/btn:scale-110 transition-transform" />}
                          </button>
                        </div>
                      </td>
                    </motion.tr>
                  ))}
                </AnimatePresence>
              </tbody>
            </table>
          </div>
        )}
      </motion.div>

      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.5 }}
        className="mt-12 p-8 bg-obsidian rounded-[3rem] border border-white/5 flex flex-col md:flex-row items-center justify-between gap-8 relative overflow-hidden"
      >
        <div className="absolute top-0 right-0 w-64 h-64 bg-brand/10 rounded-full -mr-32 -mt-32 blur-[100px]" />
        
        <div className="flex items-center gap-6 relative z-10">
          <div className="w-16 h-16 bg-white/5 rounded-[1.5rem] flex items-center justify-center border border-white/10 shadow-inner">
            <Shield size={32} className="text-brand" />
          </div>
          <div>
            <p className="text-lg font-brand font-black text-white tracking-tight mb-1">Governance & Audit Protocol</p>
            <p className="text-xs text-white/40 font-bold max-w-md">Identity purges are permanent and synchronized across the cloud infrastructure. Exercise extreme caution.</p>
          </div>
        </div>

        <button className="px-8 py-4 bg-white/5 text-white border border-white/10 rounded-2xl font-black text-[10px] uppercase tracking-[0.2em] hover:bg-white/10 transition-all relative z-10">
           Review Policy
        </button>
      </motion.div>
    </div>
  );
};
