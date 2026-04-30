import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { Search, Loader2, UserX, UserCheck, Trash2, Mail, Phone, Calendar, Shield, Filter, User } from 'lucide-react';

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
    if (!confirm("CRITICAL: Permanently delete this user? This action cannot be undone.")) return;
    
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
    } finally {
      setProcessingId(null);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'verified':
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-green-50 text-green-600 rounded-lg text-[10px] font-bold uppercase tracking-wider border border-green-100">
            <UserCheck size={12} /> Verified
          </div>
        );
      case 'pending':
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-amber-50 text-amber-600 rounded-lg text-[10px] font-bold uppercase tracking-wider border border-amber-100">
             Audit Required
          </div>
        );
      case 'rejected':
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-red-50 text-red-600 rounded-lg text-[10px] font-bold uppercase tracking-wider border border-red-100">
            <UserX size={12} /> Revoked
          </div>
        );
      default:
        return (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-[#F8FAFC] text-[#64748B] rounded-lg text-[10px] font-bold uppercase tracking-wider border border-[#E2E8F0]">
            Standard
          </div>
        );
    }
  };

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="max-w-[1400px] mx-auto px-10 py-12">
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-8"
        >
          <div>
            <div className="flex items-center gap-4 mb-3">
              <h2 className="text-3xl font-extrabold text-[#0F172A] tracking-tight">User Registry</h2>
              <span className="px-3 py-1 bg-[#2563EB]/10 text-[#2563EB] text-[10px] font-bold uppercase tracking-wider rounded-full">
                {users.length} Identities
              </span>
            </div>
            <p className="text-[#64748B] text-sm font-medium">Managing the platform identity layer and administrative access controls.</p>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="relative group">
              <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-[#94A3B8] group-focus-within:text-[#2563EB] transition-colors" />
              <input 
                type="text" 
                placeholder="Search database..." 
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full md:w-80 bg-white border border-[#E2E8F0] rounded-2xl py-3 pl-12 pr-4 focus:outline-none focus:ring-4 focus:ring-[#2563EB]/5 focus:border-[#2563EB] font-bold text-sm shadow-sm transition-all text-[#0F172A] placeholder-[#94A3B8]"
              />
            </div>
            <button className="w-12 h-12 flex items-center justify-center bg-white border border-[#E2E8F0] rounded-2xl text-[#64748B] hover:bg-[#F8FAFC] transition-all">
              <Filter size={18} />
            </button>
          </div>
        </motion.div>

        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="card-platinum rounded-[2.5rem] overflow-hidden"
        >
          {loading ? (
            <div className="flex flex-col justify-center items-center py-40 gap-4">
              <Loader2 className="animate-spin text-[#2563EB]" size={32} />
              <p className="text-[#94A3B8] text-xs font-bold uppercase tracking-widest">Querying identity layer</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="text-[10px] font-bold uppercase tracking-wider text-[#94A3B8] bg-[#F8FAFC] border-b border-[#E2E8F0]">
                    <th className="px-10 py-6">Identity</th>
                    <th className="px-8 py-6">Contact Matrix</th>
                    <th className="px-8 py-6">Compliance</th>
                    <th className="px-10 py-6 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F1F5F9]">
                  <AnimatePresence mode="popLayout">
                    {users.map((user, idx) => (
                      <motion.tr 
                        key={user.id} 
                        layout
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        transition={{ delay: idx * 0.02 }}
                        className="group hover:bg-[#F8FAFC] transition-colors"
                      >
                        <td className="px-10 py-6">
                          <div className="flex items-center gap-5">
                            <div className="relative">
                              <div className="w-14 h-14 rounded-2xl bg-[#F1F5F9] overflow-hidden border-2 border-white shadow-sm flex items-center justify-center">
                                {user.avatar_url ? (
                                  <img src={user.avatar_url} className="w-full h-full object-cover" alt="" />
                                ) : (
                                  <User size={24} className="text-[#2563EB]/40" />
                                )}
                              </div>
                              <div className={`absolute -bottom-1 -right-1 w-4 h-4 rounded-full border-2 border-white ${user.kyc_status === 'verified' ? 'bg-green-500' : 'bg-[#CBD5E1]'}`} />
                            </div>
                            <div>
                              <p className="font-extrabold text-[#0F172A] tracking-tight text-base mb-1">{user.full_name || 'Anonymous User'}</p>
                              <div className="flex items-center gap-2 text-[#94A3B8] font-bold text-[10px] uppercase tracking-wider">
                                <Mail size={12} className="opacity-60" /> {user.email || 'No Email Linked'}
                              </div>
                            </div>
                          </div>
                        </td>
                        <td className="px-8 py-6">
                          <div className="space-y-1.5">
                            <div className="flex items-center gap-2 text-[#0F172A] font-bold text-xs">
                               <Phone size={12} className="text-[#2563EB]/60" /> {user.phone_number || 'No Phone'}
                            </div>
                            <div className="flex items-center gap-2 text-[#94A3B8] font-bold text-[10px] uppercase tracking-wider">
                               <Calendar size={12} className="opacity-60" /> {new Date(user.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
                            </div>
                          </div>
                        </td>
                        <td className="px-8 py-6">
                          {getStatusBadge(user.kyc_status)}
                        </td>
                        <td className="px-10 py-6 text-right">
                          <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-all">
                            <button 
                              onClick={() => handleDelete(user.id)}
                              disabled={processingId === user.id}
                              className="w-10 h-10 flex items-center justify-center text-[#94A3B8] hover:text-[#EF4444] bg-white border border-[#E2E8F0] hover:bg-red-50 hover:border-red-100 rounded-xl transition-all disabled:opacity-50"
                            >
                              {processingId === user.id ? <Loader2 size={16} className="animate-spin text-[#2563EB]" /> : <Trash2 size={18} />}
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
          className="mt-12 p-10 bg-[#F8FAFC] border border-[#E2E8F0] rounded-[2.5rem] flex flex-col md:flex-row items-center justify-between gap-8 relative overflow-hidden"
        >
          <div className="flex items-center gap-6 relative z-10">
            <div className="w-16 h-16 bg-white rounded-2xl flex items-center justify-center border border-[#E2E8F0] shadow-sm">
              <Shield size={32} className="text-[#2563EB]" />
            </div>
            <div>
              <p className="text-xl font-extrabold text-[#0F172A] tracking-tight mb-1">Security & Data Policy</p>
              <p className="text-sm text-[#64748B] font-medium max-w-md">Identity deletions are permanent and synchronized across all nodes. Proceed with caution.</p>
            </div>
          </div>

          <button className="px-8 py-4 bg-white text-[#0F172A] border border-[#E2E8F0] rounded-2xl font-bold text-xs uppercase tracking-wider hover:bg-[#F8FAFC] transition-all shadow-sm">
             Review Governance
          </button>
        </motion.div>
      </div>
    </div>
  );
};
