import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { Search, Loader2, UserX, UserCheck, Trash2, Phone, Calendar, Shield, Filter, User } from 'lucide-react';

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
             Pending Review
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
    <div className="flex-1 overflow-y-auto bg-[#F8FAFC]">
      <div className="max-w-[1400px] mx-auto px-12 py-12">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-10 gap-6">
          <div>
            <h2 className="text-2xl font-bold text-[#0F172A] tracking-tight mb-2">User Directory</h2>
            <p className="text-[#64748B] text-sm font-medium">Manage and audit platform user profiles.</p>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="relative">
              <Search size={14} className="absolute left-4 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
              <input 
                type="text" 
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search users..." 
                className="w-72 h-10 bg-white border border-[#E2E8F0] rounded-lg py-2 pl-10 pr-4 focus:outline-none focus:border-[#2563EB] font-medium text-[12px] transition-all"
              />
            </div>
            <button className="h-10 px-4 bg-white border border-[#E2E8F0] rounded-lg hover:bg-gray-50 flex items-center gap-2 text-[12px] font-bold text-[#475569] transition-all shadow-sm">
              <Filter size={14} /> Filter
            </button>
          </div>
        </div>

        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          {loading ? (
            <div className="col-span-full flex flex-col justify-center items-center py-40 gap-4">
              <Loader2 className="animate-spin text-[#2563EB]" size={32} />
              <p className="text-[#94A3B8] text-xs font-bold uppercase tracking-widest">Querying user database</p>
            </div>
          ) : (
            <AnimatePresence mode="popLayout">
              {users.map((user) => (
                <div 
                  key={user.id}
                  className="card-pro p-6 bg-white flex flex-col group border border-[#E2E8F0] rounded-xl"
                >
                  <div className="flex items-start justify-between mb-6">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-lg bg-[#F8FAFC] border border-[#E2E8F0] flex items-center justify-center overflow-hidden">
                        {user.avatar_url ? (
                          <img src={user.avatar_url} alt="" className="w-full h-full object-cover" />
                        ) : (
                          <User size={24} className="text-[#94A3B8]" />
                        )}
                      </div>
                      <div>
                        <h3 className="text-sm font-bold text-[#0F172A]">{user.full_name || 'No Name'}</h3>
                        <p className="text-[11px] font-medium text-[#64748B]">{user.email || 'No Email'}</p>
                      </div>
                    </div>
                    {getStatusBadge(user.status)}
                  </div>

                  <div className="space-y-3 mb-6 flex-1">
                    <div className="flex items-center gap-3 text-[#64748B]">
                      <Phone size={14} className="text-[#94A3B8]" />
                      <span className="text-[12px] font-medium">{user.phone_number || 'No Phone'}</span>
                    </div>
                    <div className="flex items-center gap-3 text-[#64748B]">
                      <Calendar size={14} className="text-[#94A3B8]" />
                      <span className="text-[12px] font-medium">Joined {new Date(user.created_at).toLocaleDateString()}</span>
                    </div>
                    <div className="flex items-center gap-3 text-[#64748B]">
                      <Shield size={14} className="text-[#94A3B8]" />
                      <span className="text-[12px] font-medium capitalize">{user.role || 'User'}</span>
                    </div>
                  </div>

                  <div className="pt-4 border-t border-[#E2E8F0] flex gap-2">
                    <button 
                      onClick={() => handleDelete(user.id)}
                      disabled={processingId === user.id}
                      className="flex-1 h-9 bg-white border border-[#E2E8F0] text-[#EF4444] rounded-lg text-[11px] font-bold hover:bg-[#FEF2F2] hover:border-[#FCA5A5] transition-all flex items-center justify-center gap-2"
                    >
                      {processingId === user.id ? <Loader2 size={12} className="animate-spin" /> : <Trash2 size={12} />} Delete Profile
                    </button>
                  </div>
                </div>
              ))}
            </AnimatePresence>
          )}
        </motion.div>

        <div className="mt-12 p-8 bg-white border border-[#E2E8F0] rounded-xl flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-5">
            <div className="w-12 h-12 bg-[#F8FAFC] rounded-lg flex items-center justify-center border border-[#E2E8F0]">
              <Shield size={24} className="text-[#2563EB]" />
            </div>
            <div>
              <p className="text-lg font-bold text-[#0F172A] tracking-tight mb-1">User & Privacy Policy</p>
              <p className="text-sm text-[#64748B] font-medium max-w-md">Deletions are permanent. Ensure you are following platform governance guidelines before removal.</p>
            </div>
          </div>

          <button className="h-10 px-6 bg-[#F8FAFC] text-[#0F172A] border border-[#E2E8F0] rounded-lg font-bold text-[12px] hover:bg-white transition-all shadow-sm">
             Review Governance
          </button>
        </div>
      </div>
    </div>
  );
};
