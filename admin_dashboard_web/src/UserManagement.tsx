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
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-[#FBFBF9] text-[#666666] rounded-lg text-[10px] font-bold uppercase tracking-wider border border-[#E8E6E1]">
            Standard
          </div>
        );
    }
  };

  return (
    <div className="flex-1 overflow-y-auto bg-[#FBFBF9]">
      <div className="max-w-[1400px] mx-auto px-10 py-12">
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-8"
        >
          <div>
            <div className="flex items-center gap-4 mb-3">
              <h2 className="text-3xl font-extrabold text-[#1A1A1A] tracking-tight">User Registry</h2>
              <span className="px-3 py-1 bg-[#2563EB]/10 text-[#2563EB] text-[10px] font-bold uppercase tracking-wider rounded-full">
                {users.length} Identities
              </span>
            </div>
            <p className="text-[#666666] text-sm font-medium">Managing the platform identity layer and administrative access controls.</p>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="relative group">
              <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-[#A1A1A1] group-focus-within:text-[#2563EB] transition-colors" />
              <input
                type="text"
                placeholder="Find users..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-72 bg-white border border-[#E8E6E1] rounded-2xl py-2.5 pl-12 pr-4 focus:outline-none focus:ring-4 focus:ring-[#2563EB]/5 focus:border-[#2563EB] font-semibold text-sm transition-all"
              />
            </div>
            <button className="w-11 h-11 flex items-center justify-center bg-white border border-[#E8E6E1] rounded-xl text-[#666666] hover:bg-[#FBFBF9] transition-all">
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
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[#F4F2EE]">
                    <th className="text-left py-6 px-8 text-[10px] font-bold text-[#A1A1A1] uppercase tracking-[0.2em]">Profile</th>
                    <th className="text-left py-6 px-8 text-[10px] font-bold text-[#A1A1A1] uppercase tracking-[0.2em]">Contact</th>
                    <th className="text-left py-6 px-8 text-[10px] font-bold text-[#A1A1A1] uppercase tracking-[0.2em]">Security</th>
                    <th className="text-left py-6 px-8 text-[10px] font-bold text-[#A1A1A1] uppercase tracking-[0.2em]">Activity</th>
                    <th className="text-right py-6 px-8 text-[10px] font-bold text-[#A1A1A1] uppercase tracking-[0.2em]">Ops</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F1F5F9]">
                  <AnimatePresence mode="popLayout">
                    {users.map((user, idx) => (
                      <motion.tr 
                        key={user.id}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: idx * 0.03 }}
                        className="border-b border-[#F4F2EE] last:border-0 group hover:bg-[#FBFBF9] transition-all"
                      >
                        <td className="py-6 px-8">
                          <div className="flex items-center gap-4">
                            <div className="w-12 h-12 rounded-2xl bg-[#F4F2EE] overflow-hidden border border-[#E8E6E1]">
                              {user.avatar_url ? (
                                <img src={user.avatar_url} className="w-full h-full object-cover" alt="" />
                              ) : (
                                <div className="w-full h-full flex items-center justify-center bg-[#E8E6E1]">
                                  <User size={20} className="text-[#A1A1A1]" />
                                </div>
                              )}
                            </div>
                            <div>
                              <p className="font-bold text-[#1A1A1A] group-hover:text-[#2563EB] transition-colors">{user.full_name || 'Anonymous'}</p>
                              <p className="text-[10px] text-[#A1A1A1] font-bold font-mono truncate w-32">{user.id}</p>
                            </div>
                          </div>
                        </td>
                        <td className="py-6 px-8">
                          <div className="flex flex-col gap-1.5">
                            <div className="flex items-center gap-2 text-xs font-bold text-[#1A1A1A]">
                              <Mail size={12} className="text-[#A1A1A1]" /> {user.email || 'No email'}
                            </div>
                            <div className="flex items-center gap-2 text-[10px] font-bold text-[#666666]">
                              <Phone size={12} className="text-[#A1A1A1]" /> {user.phone_number || 'N/A'}
                            </div>
                            <div className="flex items-center gap-2 text-[10px] font-bold text-[#666666]">
                              <Calendar size={12} className="text-[#A1A1A1]" /> Since {new Date(user.created_at).toLocaleDateString()}
                            </div>
                          </div>
                        </td>
                        <td className="py-6 px-8">
                          {getStatusBadge(user.kyc_status || 'verified')}
                        </td>
                        <td className="py-6 px-8">
                          <div className="flex items-center gap-2 text-[10px] font-bold text-[#666666]">
                            <Shield size={12} className="text-[#10B981]" /> High Trust
                          </div>
                        </td>
                        <td className="py-6 px-8 text-right">
                          <button 
                            onClick={() => handleDelete(user.id)}
                            disabled={processingId === user.id}
                            className="w-10 h-10 rounded-xl flex items-center justify-center text-[#A1A1A1] hover:text-[#EF4444] hover:bg-[#FFF1F1] transition-all ml-auto"
                          >
                            {processingId === user.id ? <Loader2 className="animate-spin" size={16} /> : <Trash2 size={16} />}
                          </button>
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
