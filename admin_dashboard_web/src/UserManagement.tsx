import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { Search, Loader2, Trash2, Phone, Calendar, Shield, Filter, User } from 'lucide-react';

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
    if (!confirm("Are you sure you want to delete this profile? This action is permanent.")) return;
    
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

  const getStatusBadge = (user: any) => {
    const isFullyVerified = user.phone_number && (user.kyc_status === 'verified');

    if (isFullyVerified) {
      return (
        <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 bg-emerald-50 text-emerald-600 rounded-full text-[10px] font-semibold border border-emerald-100">
           Verified
        </div>
      );
    }

    switch (user.kyc_status) {
      case 'pending':
        return (
          <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 bg-orange-50 text-orange-600 rounded-full text-[10px] font-semibold border border-orange-100">
             Reviewing
          </div>
        );
      case 'rejected':
        return (
          <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 bg-rose-50 text-rose-600 rounded-full text-[10px] font-semibold border border-rose-100">
             Revoked
          </div>
        );
      default:
        return (
          <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 bg-[#F5F5F5] text-[#737373] rounded-full text-[10px] font-semibold border border-[#E5E5E5]">
            Standard
          </div>
        );
    }
  };

  const verifiedUsers = users.filter(u => u.kyc_status === 'verified');
  const otherUsers = users.filter(u => u.kyc_status !== 'verified');

  const renderUserCard = (user: any) => (
    <motion.div 
      layout
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.98 }}
      key={user.id}
      className="card-minimal p-5 bg-white flex flex-col group"
    >
      <div className="flex items-start justify-between mb-5">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-[#FAFAFA] border border-[#E5E5E5] flex items-center justify-center overflow-hidden">
            {user.avatar_url ? (
              <img src={user.avatar_url} alt="" className="w-full h-full object-cover" />
            ) : (
              <User size={18} strokeWidth={1.5} className="text-[#A3A3A3]" />
            )}
          </div>
          <div>
            <h3 className="text-[13px] font-semibold text-[#171717]">{user.full_name || 'Anonymous User'}</h3>
            <p className="text-[11px] text-[#737373] truncate w-32" title={user.email}>{user.email || 'No email'}</p>
          </div>
        </div>
        {getStatusBadge(user)}
      </div>

      <div className="space-y-2.5 mb-5 flex-1">
        <div className="flex items-center gap-2.5 text-[#737373]">
          <Phone size={13} strokeWidth={1.5} className="text-[#A3A3A3]" />
          <span className="text-[12px]">{user.phone_number || 'No contact'}</span>
        </div>
        <div className="flex items-center gap-2.5 text-[#737373]">
          <Calendar size={13} strokeWidth={1.5} className="text-[#A3A3A3]" />
          <span className="text-[12px]">Joined {new Date(user.created_at).toLocaleDateString()}</span>
        </div>
        <div className="flex items-center gap-2.5 text-[#737373]">
          <Shield size={13} strokeWidth={1.5} className="text-[#A3A3A3]" />
          <span className="text-[12px] capitalize">{user.is_owner ? 'Service Provider' : (user.role || 'Member')}</span>
        </div>
      </div>

      <div className="pt-4 border-t border-[#F5F5F5]">
        <button 
          onClick={() => handleDelete(user.id)}
          disabled={processingId === user.id}
          className="w-full h-9 bg-white border border-[#E5E5E5] text-rose-500 rounded-lg text-[11px] font-medium hover:bg-rose-50 hover:border-rose-100 transition-all flex items-center justify-center gap-2"
        >
          {processingId === user.id ? <Loader2 size={12} className="animate-spin" /> : <Trash2 size={12} strokeWidth={1.5} />} 
          Remove Profile
        </button>
      </div>
    </motion.div>
  );

  return (
    <div className="flex-1 overflow-y-auto px-8 py-8 bg-[#FAFAFA]">
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-8 gap-6">
        <div>
          <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">User Directory</h2>
          <p className="text-[#737373] text-[13px]">Manage and audit platform participants.</p>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search size={14} strokeWidth={1.5} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#A3A3A3]" />
            <input 
              type="text" 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search directory..." 
              className="w-64 h-9 bg-white border border-[#E5E5E5] rounded-lg py-2 pl-9 pr-3 focus:outline-none focus:border-[#A3A3A3] text-[13px] transition-colors"
            />
          </div>
          <button className="h-9 px-3 bg-white border border-[#E5E5E5] rounded-lg hover:bg-[#FAFAFA] flex items-center gap-2 text-[12px] font-medium text-[#525252] transition-colors shadow-xs">
            <Filter size={14} strokeWidth={1.5} /> Filter
          </button>
        </div>
      </div>

      {loading ? (
        <div className="py-40 flex flex-col items-center justify-center gap-3">
          <div className="w-5 h-5 border-2 border-[#E5E5E5] border-t-[#171717] rounded-full animate-spin" />
          <p className="text-[12px] text-[#A3A3A3] font-medium">Syncing directory...</p>
        </div>
      ) : (
        <div className="space-y-12">
          {verifiedUsers.length > 0 && (
            <section>
              <div className="flex items-center gap-2 mb-6">
                <span className="text-[11px] font-semibold text-[#171717] uppercase tracking-wider">Verified Identity</span>
                <div className="flex-1 h-[1px] bg-[#F5F5F5]" />
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                <AnimatePresence mode="popLayout">
                  {verifiedUsers.map(renderUserCard)}
                </AnimatePresence>
              </div>
            </section>
          )}

          {otherUsers.length > 0 && (
            <section>
              <div className="flex items-center gap-2 mb-6">
                <span className="text-[11px] font-semibold text-[#A3A3A3] uppercase tracking-wider">Standard Access</span>
                <div className="flex-1 h-[1px] bg-[#F5F5F5]" />
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                <AnimatePresence mode="popLayout">
                  {otherUsers.map(renderUserCard)}
                </AnimatePresence>
              </div>
            </section>
          )}

          {users.length === 0 && (
            <div className="empty-state border border-dashed border-[#E5E5E5] rounded-xl">
               <div className="empty-state-icon">
                <User size={20} strokeWidth={1.5} />
              </div>
              <p className="empty-state-title">No users found</p>
              <p className="empty-state-desc">Try search terms or adjust filters to find the right profile.</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
