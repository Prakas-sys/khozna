import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { Users, Search, Loader2, UserX, UserCheck, Trash2 } from 'lucide-react';

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

  // Debounced search
  useEffect(() => {
    const timer = setTimeout(() => {
      fetchUsers();
    }, 500);
    return () => clearTimeout(timer);
  }, [search]);

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to permanently delete this user? ALL their data, properties, and KYCs will be wiped.")) return;
    
    setProcessingId(id);
    try {
      // Wiping related data manually to be safe (if no cascade)
      await supabase.from('kyc_verifications').delete().eq('user_id', id);
      await supabase.from('notifications').delete().eq('user_id', id);
      await supabase.from('saved_properties').delete().eq('user_id', id);
      
      const { error } = await supabase.from('profiles').delete().eq('id', id);
      if (error) throw error;
      
      setUsers(prev => prev.filter(u => u.id !== id));
    } catch (e) {
      console.error(e);
      alert("Failed to delete user. Check permissions or constraints.");
    } finally {
      setProcessingId(null);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'verified':
        return <span className="bg-green-100 text-green-700 border border-green-200 px-3 py-1 rounded-full text-xs font-bold flex items-center gap-1"><UserCheck size={14} /> Verified</span>;
      case 'pending':
        return <span className="bg-orange-100 text-orange-700 border border-orange-200 px-3 py-1 rounded-full text-xs font-bold">Pending KYC</span>;
      case 'rejected':
        return <span className="bg-red-100 text-red-700 border border-red-200 px-3 py-1 rounded-full text-xs font-bold flex items-center gap-1"><UserX size={14} /> Rejected</span>;
      default:
        return <span className="bg-gray-100 text-gray-700 border border-gray-200 px-3 py-1 rounded-full text-xs font-bold">Unverified</span>;
    }
  };

  return (
    <div className="p-10 max-w-7xl mx-auto w-full flex-1 h-full flex flex-col overflow-hidden">
      <div className="flex flex-col md:flex-row md:items-center justify-between mb-8 gap-4">
        <div>
          <h2 className="text-3xl font-extrabold text-gray-900">User Management</h2>
          <p className="text-gray-500 mt-1">Search, view, and manage all users on the platform.</p>
        </div>
        
        <div className="relative w-full md:w-96">
          <input 
            type="text" 
            placeholder="Search name or phone..." 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-white border border-gray-200 rounded-xl py-3 pl-10 pr-4 focus:outline-none focus:ring-2 focus:ring-[#00A3E1]/50 font-medium"
          />
          <Search size={20} className="absolute left-3 top-3.5 text-gray-400" />
        </div>
      </div>

      <div className="bg-white rounded-3xl border border-gray-200 shadow-sm flex-1 overflow-hidden flex flex-col">
        {loading ? (
          <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin text-[#00A3E1]" size={40} /></div>
        ) : users.length === 0 ? (
          <div className="flex flex-col items-center justify-center p-20 text-gray-400">
            <Users size={64} className="mb-4 opacity-50" />
            <p className="font-medium text-lg">No users found.</p>
          </div>
        ) : (
          <div className="overflow-y-auto flex-1 p-2">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="text-xs uppercase tracking-widest text-gray-400 border-b border-gray-100">
                  <th className="p-4 font-bold">User</th>
                  <th className="p-4 font-bold">Registration / Phone</th>
                  <th className="p-4 font-bold">KYC Status</th>
                  <th className="p-4 font-bold text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {users.map(user => (
                  <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        {user.avatar_url ? (
                          <img src={user.avatar_url} className="w-10 h-10 rounded-full object-cover border border-gray-200" alt="Avatar" />
                        ) : (
                          <div className="w-10 h-10 rounded-full bg-[#00A3E1]/10 text-[#00A3E1] flex items-center justify-center font-bold text-lg">
                            {(user.full_name || '?')[0].toUpperCase()}
                          </div>
                        )}
                        <div>
                          <p className="font-bold text-gray-900">{user.full_name || 'Unknown'}</p>
                          <p className="text-xs text-gray-500">{user.email || 'No email'}</p>
                        </div>
                      </div>
                    </td>
                    <td className="p-4">
                      <p className="font-medium text-gray-800">{user.phone_number || 'N/A'}</p>
                      <p className="text-xs text-gray-400">{new Date(user.created_at).toLocaleDateString()}</p>
                    </td>
                    <td className="p-4">
                      {getStatusBadge(user.kyc_status)}
                    </td>
                    <td className="p-4 text-right">
                      <button 
                        onClick={() => handleDelete(user.id)}
                        disabled={processingId === user.id}
                        className="p-2 text-gray-400 hover:text-red-500 bg-white border border-gray-200 hover:bg-red-50 hover:border-red-200 rounded-lg transition-all disabled:opacity-50"
                        title="Permanently Delete User"
                      >
                        {processingId === user.id ? <Loader2 size={18} className="animate-spin" /> : <Trash2 size={18} />}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};
