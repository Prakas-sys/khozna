import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Users, UserCheck, ShieldAlert,
  Settings, LogOut, Bell, TrendingUp, Building2,
  Search, Globe, Wallet, ChevronRight,
  Play, BarChart3, PieChart, ArrowUpRight
} from 'lucide-react';
import { motion } from 'framer-motion';
import { supabase } from './lib/supabase';
import { KycReview } from './KycReview';
import { PropertyModeration } from './PropertyModeration';
import { UserManagement } from './UserManagement';
import { Reports } from './Reports';
import { Login } from './Login';

// ─── Business Sidebar ──────────────────────────────────────────────────────────
const Sidebar = ({ onLock }: { onLock: () => void }) => {
  const location = useLocation();
  const isActive = (path: string) => location.pathname === path;

  const links = [
    { name: 'Overview', path: '/', icon: <LayoutDashboard size={20} /> },
    { name: 'Verifications', path: '/kyc', icon: <UserCheck size={20} /> },
    { name: 'Properties', path: '/properties', icon: <Building2 size={20} /> },
    { name: 'Users', path: '/users', icon: <Users size={20} /> },
    { name: 'Safety', path: '/reports', icon: <ShieldAlert size={20} /> },
    { name: 'Settings', path: '/settings', icon: <Settings size={20} /> },
  ];

  return (
    <div className="w-24 h-full bg-white border-r border-[#E8E6E1]/60 flex flex-col items-center py-10 flex-shrink-0 z-30">
      <div className="w-12 h-12 rounded-2xl bg-[#2563EB] flex items-center justify-center shadow-lg shadow-blue-500/30 mb-16 group cursor-pointer overflow-hidden relative">
        <Globe size={24} className="text-white z-10" />
        <div className="absolute inset-0 bg-white/20 translate-y-full group-hover:translate-y-0 transition-transform duration-500" />
      </div>

      <nav className="flex flex-col gap-8 flex-1">
        {links.map(link => (
          <Link key={link.name} to={link.path} className="relative group">
            <div className={`w-14 h-14 flex flex-col items-center justify-center rounded-2xl transition-all duration-500 ${
              isActive(link.path)
                ? 'bg-[#2563EB] text-white shadow-[var(--shadow-brand)]'
                : 'text-[#A1A1A1] hover:bg-[#F4F2EE] hover:text-[#1A1A1A]'
            }`}>
              {link.icon}
              <span className="text-[7px] font-bold uppercase tracking-widest mt-1 opacity-0 group-hover:opacity-100 transition-opacity absolute -bottom-4 text-[#1A1A1A]">
                {link.name}
              </span>
            </div>
            {isActive(link.path) && (
              <motion.div layoutId="navDot" className="absolute -left-12 w-2 h-8 bg-[#2563EB] rounded-r-full" />
            )}
          </Link>
        ))}
      </nav>

      <button
        onClick={onLock}
        className="w-14 h-14 flex items-center justify-center rounded-2xl text-[#EF4444] hover:bg-[#FFF1F1] transition-all group relative"
      >
        <LogOut size={20} />
      </button>
    </div>
  );
};

// ─── Business Header ─────────────────────────────────────────────────────────────
const Header = () => {
  const location = useLocation();
  const getSubNavLinks = (): { name: string; path: string; icon?: React.ReactNode }[] => {
    switch (location.pathname) {
      case '/': return [{ name: 'Dashboard Overview', path: '/', icon: <LayoutDashboard size={14} /> }, { name: 'Platform Insights', path: '/perf', icon: <TrendingUp size={14} /> }];
      case '/kyc': return [{ name: 'KYC Queue', path: '/kyc' }, { name: 'Approved', path: '/approved' }];
      default: return [{ name: 'Management Console', path: location.pathname }];
    }
  };

  return (
    <header className="h-24 px-12 flex items-center justify-between z-20 sticky top-0 glass-header">
      <div className="flex bg-white/50 border border-[#E8E6E1]/60 rounded-full p-1.5 shadow-sm">
        {getSubNavLinks().map(link => (
          <button
            key={link.name}
            className={`nav-pill ${location.pathname === link.path ? 'nav-pill-active' : 'nav-pill-inactive'}`}
          >
            {link.icon} {link.name}
          </button>
        ))}
      </div>

      <div className="flex items-center gap-8">
        <div className="relative group hidden lg:block">
          <Search size={16} className="absolute left-5 top-1/2 -translate-y-1/2 text-[#A1A1A1] group-focus-within:text-[#2563EB] transition-colors" />
          <input
            type="text"
            placeholder="Search platform data..."
            className="w-80 bg-white border border-[#E8E6E1]/80 rounded-2xl py-3 pl-14 pr-6 focus:outline-none focus:ring-8 focus:ring-[#2563EB]/5 focus:border-[#2563EB] font-bold text-[11px] transition-all shadow-sm"
          />
        </div>

        <div className="flex items-center gap-6 pl-6 border-l border-[#E8E6E1]/60">
          <button className="relative w-12 h-12 flex items-center justify-center bg-white border border-[#E8E6E1]/80 rounded-2xl text-[#666666] hover:bg-[#F4F2EE] transition-all shadow-sm">
            <Bell size={20} />
            <span className="absolute top-3.5 right-3.5 w-2 h-2 bg-[#EF4444] rounded-full border-2 border-white" />
          </button>

          <div className="flex items-center gap-4">
            <div className="text-right">
              <p className="text-[#1A1A1A] text-xs font-black tracking-tight">Prakash</p>
               <p className="text-[#2563EB] text-[9px] font-black uppercase tracking-[0.2em]">Platform Admin</p>
            </div>
            <div className="w-12 h-12 rounded-2xl overflow-hidden bg-[#F4F2EE] border border-[#E8E6E1]/80 shadow-md">
              <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Admin" className="w-full h-full object-cover" alt="Admin" />
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

// ─── Enterprise Dashboard Home ───────────────────────────────────────────────────
const DashboardHome = () => {
  const [stats, setStats] = useState({ users: 0, kyc: 0, properties: 0, engagement: 12450 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      try {
        const [u, k, p] = await Promise.all([
          supabase.from('profiles').select('*', { count: 'exact', head: true }),
          supabase.from('kyc_verifications').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
          supabase.from('properties').select('*', { count: 'exact', head: true }),
        ]);
        setStats(prev => ({ 
          ...prev, 
          users: u.count || 0, 
          kyc: k.count || 0, 
          properties: p.count || 0,
          engagement: Math.floor(Math.random() * 5000) + 10000 // Mocking engagement growth
        }));
      } catch (e) {
        console.error("Stats fetch failed:", e);
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, []);

  return (
    <div className="flex-1 overflow-y-auto px-12 py-10 bg-[#FBFBF9]">
      {/* Business Header */}
      <div className="mb-16 flex items-end justify-between">
        <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
          <div className="flex items-center gap-3 mb-4">
            <div className="w-8 h-[2px] bg-[#2563EB]" />
            <p className="text-[10px] font-black text-[#2563EB] uppercase tracking-[0.3em]">Platform Intelligence Center</p>
          </div>
          <h2 className="text-5xl font-black text-[#1A1A1A] tracking-tighter leading-none mb-4">
            Khozna <span className="text-[#2563EB]">Platform</span>
          </h2>
          <p className="text-[#666666] text-sm font-semibold max-w-lg leading-relaxed">System performance is optimal. High user engagement detected in the Kathmandu Valley region.</p>
        </motion.div>

        <div className="flex gap-4">
           <button className="h-14 px-8 bg-[#1A1A1A] text-white rounded-2xl font-bold text-xs uppercase tracking-widest hover:bg-black transition-all shadow-xl shadow-black/10 flex items-center gap-3">
             <BarChart3 size={18} /> Platform Analytics
           </button>
        </div>
      </div>

      <div className="grid grid-cols-12 gap-8">
        {/* Main Section */}
        <div className="col-span-12 lg:col-span-8 space-y-8">
          <div className="grid grid-cols-1 md:grid-cols-5 gap-8">
            {/* Revenue Card */}
            <motion.div 
              initial={{ opacity: 0, scale: 0.98 }} 
              animate={{ opacity: 1, scale: 1 }} 
              className="col-span-1 md:col-span-3 card-pro p-10 bg-gradient-to-br from-[#1A1A1A] to-[#333333] text-white relative overflow-hidden flex flex-col justify-between"
            >
              <div className="absolute top-0 right-0 w-64 h-64 bg-[#2563EB]/20 rounded-full -mr-32 -mt-32 blur-[80px]" />
              <div className="z-10">
                <div className="flex items-center justify-between mb-12">
                  <p className="text-[10px] font-black uppercase tracking-[0.2em] opacity-70">Active Platform Engagement</p>
                  <div className="w-10 h-10 rounded-xl bg-white/10 flex items-center justify-center border border-white/20">
                    <TrendingUp size={20} className="text-[#2563EB]" />
                  </div>
                </div>
                <div className="flex items-baseline gap-2 mb-4">
                  <span className="text-2xl font-bold opacity-50">#</span>
                  <p className="text-6xl font-black tracking-tighter">{stats.engagement.toLocaleString()}</p>
                </div>
                <div className="flex items-center gap-3 text-[10px] font-black bg-white/10 w-fit px-4 py-1.5 rounded-full border border-white/20 uppercase tracking-widest">
                  <ArrowUpRight size={12} className="text-green-400" /> +18.2% Growth Streak
                </div>
              </div>
              <div className="z-10 pt-12 flex justify-between items-center border-t border-white/10">
                 <p className="text-[9px] font-bold uppercase tracking-[0.3em]">Next Market Review: May 15, 2026</p>
                 <button className="text-[10px] font-black text-[#2563EB] hover:underline uppercase tracking-widest">View Engagement</button>
              </div>
            </motion.div>

            {/* Quick Stats */}
            <div className="col-span-1 md:col-span-2 grid grid-rows-2 gap-8">
              {[
                { title: 'Properties', val: stats.properties, label: 'Active Listings', icon: <Building2 size={20} />, color: 'text-blue-600', bg: 'bg-blue-50' },
                { title: 'Verifications', val: stats.kyc, label: 'Pending Audits', icon: <UserCheck size={20} />, color: 'text-amber-600', bg: 'bg-amber-50' },
              ].map((s, i) => (
                <motion.div key={i} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.1 }} className="card-pro p-8 flex flex-col justify-between">
                  <div className="flex items-center justify-between">
                    <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${s.bg} ${s.color}`}>
                      {s.icon}
                    </div>
                    <ChevronRight size={16} className="text-[#E8E6E1]" />
                  </div>
                  <div>
                    <p className="text-3xl font-black text-[#1A1A1A] mb-1">{loading ? '—' : s.val}</p>
                    <p className="text-[10px] font-black text-[#666666] uppercase tracking-widest">{s.label}</p>
                  </div>
                </motion.div>
              ))}
            </div>
          </div>

          {/* Activity Feed */}
          <div className="card-pro p-10">
            <div className="flex items-center justify-between mb-10">
              <div>
                <h3 className="text-xl font-black text-[#1A1A1A] tracking-tight">Recent Platform Activity</h3>
                <p className="text-[#A1A1A1] text-xs font-semibold">Live updates from Khozna operations</p>
              </div>
              <button className="px-5 py-2.5 bg-white border border-[#E8E6E1] rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-[#F4F2EE] transition-all">View All</button>
            </div>
            <div className="space-y-2">
              {[
                { user: 'Prakash', action: 'Approved 4 New Properties', time: '2m ago', type: 'Property', color: 'text-blue-500' },
                { user: 'System', action: 'KYC Verification Completed for Sunil K.', time: '15m ago', type: 'KYC', color: 'text-green-500' },
                { user: 'Safety', action: 'Flagged Report in Bagmati District', time: '1h ago', type: 'Safety', color: 'text-red-500' },
              ].map((log, i) => (
                <div key={i} className="flex items-center justify-between p-5 rounded-2xl hover:bg-[#FBFBF9] transition-all border border-transparent hover:border-[#E8E6E1]/40 group">
                  <div className="flex items-center gap-5">
                    <div className="w-10 h-10 rounded-xl bg-[#F4F2EE] flex items-center justify-center text-[#1A1A1A]">
                      {log.type === 'Property' ? <Building2 size={18} /> : log.type === 'KYC' ? <UserCheck size={18} /> : <ShieldAlert size={18} />}
                    </div>
                    <div>
                      <p className="text-xs font-black text-[#1A1A1A] mb-1">{log.action}</p>
                      <p className="text-[10px] font-bold text-[#A1A1A1] uppercase tracking-widest">{log.user} · {log.time}</p>
                    </div>
                  </div>
                  <div className={`text-[9px] font-black uppercase tracking-[0.2em] px-3 py-1 rounded-full bg-[#F4F2EE] ${log.color}`}>
                    {log.type}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right Insights */}
        <div className="col-span-12 lg:col-span-4 space-y-8">
          <div className="card-pro p-10">
             <div className="flex items-center justify-between mb-12">
               <h3 className="text-xl font-black text-[#1A1A1A] tracking-tight">Platform Health</h3>
               <div className="w-8 h-8 rounded-full bg-green-500/10 flex items-center justify-center border border-green-500/20">
                 <TrendingUp size={14} className="text-green-500" />
               </div>
             </div>

             <div className="space-y-6">
                <div>
                  <div className="flex justify-between items-end mb-2">
                    <p className="text-[10px] font-black text-[#666666] uppercase tracking-widest">User Engagement</p>
                    <p className="text-sm font-black">94%</p>
                  </div>
                  <div className="h-2 w-full bg-[#F4F2EE] rounded-full overflow-hidden">
                    <motion.div initial={{ width: 0 }} animate={{ width: '94%' }} className="h-full bg-[#2563EB]" />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between items-end mb-2">
                    <p className="text-[10px] font-black text-[#666666] uppercase tracking-widest">Property Conversion</p>
                    <p className="text-sm font-black">68%</p>
                  </div>
                  <div className="h-2 w-full bg-[#F4F2EE] rounded-full overflow-hidden">
                    <motion.div initial={{ width: 0 }} animate={{ width: '68%' }} className="h-full bg-amber-500" />
                  </div>
                </div>
             </div>

             <div className="mt-12 p-6 bg-blue-50/50 rounded-[2rem] border border-blue-100">
                <p className="text-xs font-bold text-[#2563EB] mb-1">Growth Insight</p>
                <p className="text-[#1E40AF] text-[11px] font-semibold leading-relaxed">Listings with Reels have 4.5x higher engagement. Encourage agents to upload more videos.</p>
             </div>
          </div>

          {/* Reels Center */}
          <div className="card-pro p-10 bg-[#2563EB] text-white relative overflow-hidden">
             <div className="relative z-10">
                <div className="flex items-center gap-3 mb-8">
                   <Play size={20} fill="currentColor" />
                   <h3 className="text-xl font-black tracking-tighter">Reels Center</h3>
                </div>
                <div className="space-y-6">
                  <div className="flex items-center justify-between border-b border-white/10 pb-4">
                    <p className="text-[10px] font-black uppercase tracking-widest opacity-60">Total Views</p>
                    <p className="text-lg font-black">1.2M</p>
                  </div>
                  <div className="flex items-center justify-between border-b border-white/10 pb-4">
                    <p className="text-[10px] font-black uppercase tracking-widest opacity-60">Engagement</p>
                    <p className="text-lg font-black">12.5%</p>
                  </div>
                  <button className="w-full py-4 bg-white text-[#2563EB] rounded-2xl font-black text-[10px] uppercase tracking-[0.2em] shadow-xl hover:bg-blue-50 transition-all">Manage Content</button>
                </div>
             </div>
             <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -mr-16 -mt-16 blur-2xl" />
          </div>
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
            <Route path="/properties" element={<PropertyModeration />} />
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
