import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Users, UserCheck, ShieldAlert,
  Settings, LogOut,
  Search, Globe
} from 'lucide-react';
import { supabase } from './lib/supabase';
import { KycReview } from './KycReview';
import { UserManagement } from './UserManagement';
import { Reports } from './Reports';
import { Login } from './Login';

// ─── Minimalist Sidebar ──────────────────────────────────────────────────────────
const Sidebar = ({ onLock }: { onLock: () => void }) => {
  const location = useLocation();
  const isActive = (path: string) => location.pathname === path;

  const links = [
    { name: 'Dashboard', path: '/', icon: <LayoutDashboard size={18} /> },
    { name: 'Verifications', path: '/kyc', icon: <UserCheck size={18} /> },
    { name: 'Users', path: '/users', icon: <Users size={18} /> },
    { name: 'Safety', path: '/reports', icon: <ShieldAlert size={18} /> },
    { name: 'Settings', path: '/settings', icon: <Settings size={18} /> },
  ];

  return (
    <div className="w-20 h-full bg-white border-r border-[#E2E8F0] flex flex-col items-center py-8 flex-shrink-0 z-30">
      <div className="w-10 h-10 rounded-lg bg-[#2563EB] flex items-center justify-center mb-12 shadow-sm">
        <Globe size={20} className="text-white" />
      </div>

      <nav className="flex flex-col gap-4 flex-1">
        {links.map(link => (
          <Link key={link.name} to={link.path} title={link.name}>
            <div className={`w-12 h-12 flex items-center justify-center rounded-lg transition-all ${
              isActive(link.path)
                ? 'bg-[#F1F5F9] text-[#2563EB] border border-[#E2E8F0]'
                : 'text-[#64748B] hover:text-[#0F172A] hover:bg-[#F8FAFC]'
            }`}>
              {link.icon}
            </div>
          </Link>
        ))}
      </nav>

      <button
        onClick={onLock}
        className="w-12 h-12 flex items-center justify-center rounded-lg text-[#64748B] hover:text-[#EF4444] hover:bg-[#FEF2F2] transition-all"
      >
        <LogOut size={18} />
      </button>
    </div>
  );
};

// ─── Minimalist Header ─────────────────────────────────────────────────────────────
const Header = () => {
  const location = useLocation();
  const getSubNavLinks = (): { name: string; path: string; icon?: React.ReactNode }[] => {
    switch (location.pathname) {
      case '/': return [{ name: 'Overview', path: '/', icon: <LayoutDashboard size={14} /> }];
      case '/kyc': return [{ name: 'Verifications', path: '/kyc' }];
      case '/users': return [{ name: 'Directory', path: '/users' }];
      case '/reports': return [{ name: 'Safety', path: '/reports' }];
      default: return [{ name: 'Console', path: location.pathname }];
    }
  };

  return (
    <header className="h-16 px-12 flex items-center justify-between bg-white border-b border-[#E2E8F0] sticky top-0 z-20">
      <div className="flex gap-1 bg-[#F8FAFC] p-1 rounded-lg border border-[#E2E8F0]">
        {getSubNavLinks().map(link => (
          <button
            key={link.name}
            className={`px-4 py-1.5 text-[12px] font-bold rounded-md transition-all flex items-center gap-2 ${location.pathname === link.path ? 'bg-white text-[#2563EB] shadow-sm' : 'text-[#64748B]'}`}
          >
            {link.icon} {link.name}
          </button>
        ))}
      </div>

      <div className="flex items-center gap-6">
        <div className="relative group hidden lg:block">
          <Search size={14} className="absolute left-4 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
          <input
            type="text"
            placeholder="Search platform..."
            className="w-64 bg-[#F8FAFC] border border-[#E2E8F0] rounded-lg py-2 pl-10 pr-4 focus:outline-none focus:border-[#2563EB] font-medium text-[12px] transition-all"
          />
        </div>

        <div className="flex items-center gap-4 pl-6 border-l border-[#E2E8F0]">
          <div className="text-right">
            <p className="text-[12px] font-bold text-[#0F172A]">Prakash</p>
            <p className="text-[10px] font-medium text-[#64748B]">Platform Admin</p>
          </div>
          <div className="w-9 h-9 rounded-full bg-[#F1F5F9] border border-[#E2E8F0] flex items-center justify-center overflow-hidden">
             <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Prakash" alt="Avatar" className="w-full h-full object-cover" />
          </div>
        </div>
      </div>
    </header>
  );
};

// ─── Enterprise Dashboard Home ───────────────────────────────────────────────────
const DashboardHome = () => {
  const [stats, setStats] = useState({ users: 0, kyc: 0, reports: 0 });
  const [activities, setActivities] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      try {
        const [u, k, r, latestK] = await Promise.all([
          supabase.from('profiles').select('*', { count: 'exact', head: true }),
          supabase.from('kyc_verifications').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
          supabase.from('user_reports').select('*', { count: 'exact', head: true }),
          supabase.from('kyc_verifications').select('*').order('updated_at', { ascending: false }).limit(5),
        ]);
        
        setStats({ 
          users: u.count || 0, 
          kyc: k.count || 0, 
          reports: r.count || 0
        });

        const combined = [
          ...(latestK.data || []).map(item => ({ 
            user: 'System', 
            action: `KYC Status Update: ${item.status}`, 
            time: new Date(item.updated_at).toLocaleDateString(), 
            type: 'KYC', 
            color: 'text-green-500' 
          }))
        ].sort((a, b) => new Date(b.time).getTime() - new Date(a.time).getTime()).slice(0, 5);

        setActivities(combined);
      } catch (e) {
        console.error("Stats fetch failed:", e);
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, []);

  return (
    <div className="flex-1 overflow-y-auto px-12 py-12 bg-[#F8FAFC]">
      <div className="mb-12">
        <h2 className="text-3xl font-bold text-[#0F172A] tracking-tight mb-2">Platform Overview</h2>
        <p className="text-[#64748B] text-sm font-medium">Real-time status and operational data for Khozna.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        {[
          { title: 'Total Users', val: stats.users, label: 'Registered Profiles', color: 'text-blue-600', icon: <Users size={20} /> },
          { title: 'Verifications', val: stats.kyc, label: 'Pending Review', color: 'text-orange-600', icon: <UserCheck size={20} /> },
          { title: 'Safety', val: stats.reports, label: 'Unresolved Flags', color: 'text-rose-600', icon: <ShieldAlert size={20} /> },
        ].map((s, i) => (
          <div key={i} className="card-pro p-6">
            <div className="flex items-center justify-between mb-4">
              <span className={`p-2 rounded-lg bg-gray-50 ${s.color}`}>{s.icon}</span>
              <span className="text-[11px] font-bold text-[#94A3B8] uppercase tracking-wider">{s.title}</span>
            </div>
            <p className="text-3xl font-bold text-[#0F172A]">{loading ? '...' : s.val}</p>
            <p className="text-[11px] font-medium text-[#64748B] mt-1">{s.label}</p>
          </div>
        ))}
      </div>

      <div className="card-pro overflow-hidden">
        <div className="px-8 py-6 border-b border-[#E2E8F0] flex items-center justify-between bg-white">
          <h3 className="text-sm font-bold text-[#0F172A]">Recent Safety & Security Activity</h3>
        </div>
        <div className="bg-white">
          {activities.length > 0 ? (
            <div className="divide-y divide-[#E2E8F0]">
              {activities.map((log, i) => (
                <div key={i} className="px-8 py-5 flex items-center justify-between hover:bg-[#F8FAFC] transition-colors">
                  <div className="flex items-center gap-4">
                    <div className="w-8 h-8 rounded-lg bg-gray-50 flex items-center justify-center text-gray-400">
                      {log.type === 'KYC' ? <UserCheck size={16} /> : <ShieldAlert size={16} />}
                    </div>
                    <div>
                      <p className="text-[13px] font-semibold text-[#0F172A]">{log.action}</p>
                      <p className="text-[11px] font-medium text-[#94A3B8]">{log.user} · {log.time}</p>
                    </div>
                  </div>
                  <span className={`text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-md bg-gray-50 ${log.color}`}>
                    {log.type}
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <div className="py-20 text-center">
               <p className="text-[#94A3B8] text-[12px] font-medium">No recent security activity detected</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// ─── Root App ─────────────────────────────────────────────────────────────────
const App = () => {
  const [isUnlocked, setIsUnlocked] = useState(false);

  if (!isUnlocked) return <Login onPinSuccess={() => setIsUnlocked(true)} />;

  return (
    <Router>
      <div className="flex h-screen bg-[#FBFBF9] font-sans overflow-hidden text-[#1A1A1A]">
        <Sidebar onLock={() => setIsUnlocked(false)} />
        <div className="flex-1 flex flex-col h-screen overflow-hidden">
          <Header />
          <Routes>
            <Route path="/" element={<DashboardHome />} />
            <Route path="/kyc" element={<KycReview />} />
            <Route path="/users" element={<UserManagement />} />
            <Route path="/reports" element={<Reports />} />
            <Route path="/settings" element={
              <div className="flex-1 flex items-center justify-center">
                <div className="text-center max-w-sm">
                  <div className="w-24 h-24 rounded-[3rem] bg-white border border-[#E8E6E1]/80 shadow-lg flex items-center justify-center mx-auto mb-8">
                    <Settings size={36} className="text-[#2563EB]" />
                  </div>
                  <h2 className="text-[#1A1A1A] text-2xl font-black mb-3 tracking-tight">System Configuration</h2>
                  <p className="text-[#666666] text-sm font-semibold leading-relaxed">Enterprise-level settings and global parameters are currently being updated.</p>
                </div>
              </div>
            } />
          </Routes>
        </div>
      </div>
    </Router>
  );
};

export default App;
