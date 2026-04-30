import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Users, UserCheck, ShieldAlert, CheckSquare,
  Settings, LogOut, Activity, Bell, TrendingUp, Building2,
  Search, Globe
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { KycReview } from './KycReview';
import { PropertyModeration } from './PropertyModeration';
import { UserManagement } from './UserManagement';
import { Reports } from './Reports';
import { Login } from './Login';

// ─── Sidebar ──────────────────────────────────────────────────────────────────
const Sidebar = ({ onLock }: { onLock: () => void }) => {
  const location = useLocation();
  const isActive = (path: string) => location.pathname === path;

  const links = [
    { name: 'Dashboard', path: '/', icon: <LayoutDashboard size={18} /> },
    { name: 'KYC Review', path: '/kyc', icon: <UserCheck size={18} /> },
    { name: 'Properties', path: '/properties', icon: <Building2 size={18} /> },
    { name: 'User Directory', path: '/users', icon: <Users size={18} /> },
    { name: 'Reports', path: '/reports', icon: <ShieldAlert size={18} /> },
    { name: 'Settings', path: '/settings', icon: <Settings size={18} /> },
  ];

  return (
    <div className="w-72 h-full sidebar-clean flex flex-col justify-between flex-shrink-0 z-30">
      <div className="flex flex-col h-full py-8 px-6">
        {/* Logo */}
        <div className="flex items-center gap-3 mb-12 px-2">
          <div className="w-10 h-10 rounded-2xl bg-[#2563EB] flex items-center justify-center shadow-lg shadow-blue-500/20">
            <Globe size={20} className="text-white" />
          </div>
          <div>
            <p className="text-[#1A1A1A] font-extrabold text-lg tracking-tight">Khozna</p>
            <p className="text-[#666666] text-[10px] font-bold uppercase tracking-[0.1em]">Admin Core</p>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex flex-col gap-1.5 flex-1">
          <p className="text-[11px] font-bold text-[#94A3B8] uppercase tracking-[0.15em] mb-4 px-3">Main Menu</p>
          {links.map(link => (
            <Link key={link.name} to={link.path} className="relative group">
              <div className={`relative flex items-center gap-3 px-4 py-3 rounded-2xl transition-all duration-200 text-sm font-semibold ${
                isActive(link.path)
                  ? 'bg-[#2563EB]/5 text-[#2563EB]'
                  : 'text-[#666666] hover:bg-[#F4F2EE] hover:text-[#1A1A1A]'
              }`}>
                <span className={isActive(link.path) ? 'text-[#2563EB]' : 'text-[#A1A1A1] group-hover:text-[#666666]'}>
                  {link.icon}
                </span>
                <span>{link.name}</span>
                {isActive(link.path) && (
                  <motion.div
                    layoutId="activeIndicator"
                    className="ml-auto w-1.5 h-1.5 rounded-full bg-[#2563EB]"
                  />
                )}
              </div>
            </Link>
          ))}
        </nav>

        {/* Bottom Section */}
        <div className="pt-6 border-t border-[#F4F2EE]">
          <button
            onClick={onLock}
            className="w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-[#EF4444] hover:bg-[#FFF1F1] font-bold transition-all text-sm group"
          >
            <LogOut size={18} className="opacity-70 group-hover:opacity-100" />
            Sign Out
          </button>
        </div>
      </div>
    </div>
  );
};

// ─── Header ───────────────────────────────────────────────────────────────────
const Header = ({ title, notificationCount }: { title: string; notificationCount: number }) => {
  const [showNotif, setShowNotif] = useState(false);

  return (
    <header className="h-20 px-10 flex items-center justify-between bg-white/80 backdrop-blur-md z-20 sticky top-0 border-b border-[#E8E6E1] flex-shrink-0">
      <div className="flex items-center gap-4">
        <h1 className="text-xl font-bold text-[#1A1A1A] tracking-tight">{title}</h1>
      </div>

      <div className="flex items-center gap-4">
        {/* Search */}
        <div className="relative group hidden md:block">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-[#A1A1A1] group-focus-within:text-[#2563EB] transition-colors" />
          <input
            type="text"
            placeholder="Search anything..."
            className="w-80 bg-[#FBFBF9] border border-[#E8E6E1] rounded-2xl py-2.5 pl-12 pr-4 focus:outline-none focus:ring-4 focus:ring-[#2563EB]/5 focus:border-[#2563EB] font-semibold text-sm transition-all"
          />
        </div>

        <div className="w-px h-8 bg-[#F4F2EE]" />

        {/* Notifications */}
        <div className="relative">
          <button
            onClick={() => setShowNotif(!showNotif)}
            className="relative w-11 h-11 flex items-center justify-center bg-white border border-[#E8E6E1] rounded-xl text-[#666666] hover:bg-[#FBFBF9] transition-all"
          >
            <Bell size={20} />
            {notificationCount > 0 && (
              <span className="absolute top-2 right-2 w-2 h-2 bg-[#EF4444] rounded-full border-2 border-white" />
            )}
          </button>

          <AnimatePresence>
            {showNotif && (
              <motion.div
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10, scale: 0.95 }}
                className="absolute top-full right-0 mt-3 w-80 card-platinum rounded-2xl p-6 shadow-xl z-50 border border-[#E8E6E1]"
              >
                <div className="flex items-center justify-between mb-4">
                  <h4 className="text-xs font-bold text-[#1A1A1A] uppercase tracking-wider">Alerts</h4>
                  <span className="text-[10px] font-bold text-[#2563EB] bg-[#2563EB]/5 px-2 py-1 rounded-md">{notificationCount} New</span>
                </div>
                {notificationCount === 0 ? (
                  <p className="text-[#A1A1A1] text-xs text-center py-8">No new notifications</p>
                ) : (
                  <div className="space-y-3">
                    <Link
                      to="/kyc"
                      onClick={() => setShowNotif(false)}
                      className="flex items-center gap-4 p-3 rounded-2xl hover:bg-[#F8FAFC] transition-all border border-transparent hover:border-[#F1F5F9]"
                    >
                      <div className="w-10 h-10 rounded-xl bg-amber-50 flex items-center justify-center">
                        <UserCheck size={18} className="text-amber-500" />
                      </div>
                      <div className="flex-1">
                        <p className="text-[#0F172A] text-xs font-bold">Pending KYC Review</p>
                        <p className="text-[#94A3B8] text-[10px]">Verify new platform members</p>
                      </div>
                    </Link>
                  </div>
                )}
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Profile */}
        <div className="flex items-center gap-3 pl-4 border-l border-[#F4F2EE]">
          <div className="w-10 h-10 rounded-2xl overflow-hidden bg-[#F4F2EE] border border-[#E8E6E1]">
            <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Admin" className="w-full h-full object-cover" alt="Admin" />
          </div>
          <div className="hidden lg:block">
            <p className="text-[#1A1A1A] text-sm font-extrabold">Master Ops</p>
            <p className="text-[#A1A1A1] text-[10px] font-bold uppercase tracking-wider">Super Admin</p>
          </div>
        </div>
      </div>
    </header>
  );
};

// ─── Dashboard Home ───────────────────────────────────────────────────────────
const DashboardHome = () => {
  const [stats, setStats] = useState({ users: 0, kyc: 0, properties: 0, bookings: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      try {
        const [u, k, p, b] = await Promise.all([
          supabase.from('profiles').select('*', { count: 'exact', head: true }),
          supabase.from('kyc_verifications').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
          supabase.from('properties').select('*', { count: 'exact', head: true }),
          supabase.from('properties').select('*', { count: 'exact', head: true }).eq('status', 'booked'),
        ]);
        setStats({ users: u.count || 0, kyc: k.count || 0, properties: p.count || 0, bookings: b.count || 0 });
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, []);

  const statCards = [
    {
      title: 'KYC Reviews', value: stats.kyc, label: 'Pending approval', icon: <UserCheck size={24} />,
      color: 'text-amber-600', bg: 'bg-amber-50', path: '/kyc', trend: '+12%'
    },
    {
      title: 'Properties', value: stats.properties, label: 'Active listings', icon: <Building2 size={24} />,
      color: 'text-blue-600', bg: 'bg-blue-50', path: '/properties', trend: '+5%'
    },
    {
      title: 'Total Users', value: stats.users, label: 'Registered members', icon: <Users size={24} />,
      color: 'text-indigo-600', bg: 'bg-indigo-50', path: '/users', trend: '+18%'
    },
    {
      title: 'Bookings', value: stats.bookings, label: 'Completed stays', icon: <CheckSquare size={24} />,
      color: 'text-emerald-600', bg: 'bg-emerald-50', path: '/reports', trend: '+2%'
    },
  ];

  return (
    <div className="flex-1 overflow-y-auto bg-[#FBFBF9]">
      <div className="max-w-[1600px] mx-auto px-10 py-12">
        
        {/* Welcome Header */}
        <div className="mb-12">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <div className="flex items-center gap-2 mb-2">
              <span className="w-2 h-2 rounded-full bg-[#2563EB] animate-pulse" />
              <p className="text-[10px] font-bold text-[#2563EB] uppercase tracking-[0.2em]">Platform Overview</p>
            </div>
            <h2 className="text-3xl font-extrabold text-[#1A1A1A] tracking-tight">Good morning, <span className="text-[#2563EB]">Master Ops!</span></h2>
            <p className="text-[#666666] text-sm font-medium mt-1">Here's what's happening with Khozna today.</p>
          </motion.div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
          {statCards.map((s, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
            >
              <Link to={s.path} className="card-platinum group block p-8 rounded-3xl h-full">
                <div className="flex items-start justify-between mb-6">
                  <div className={`w-14 h-14 rounded-2xl flex items-center justify-center ${s.bg} ${s.color}`}>
                    {s.icon}
                  </div>
                  <div className="flex items-center gap-1 px-2 py-1 rounded-lg bg-[#FBFBF9] text-[10px] font-bold text-[#10B981]">
                    <TrendingUp size={12} />
                    {s.trend}
                  </div>
                </div>
                <div>
                  <p className="text-4xl font-extrabold text-[#1A1A1A] mb-1">
                    {loading ? '—' : s.value}
                  </p>
                  <p className="text-[#666666] text-sm font-bold">{s.title}</p>
                  <p className="text-[#A1A1A1] text-xs mt-1">{s.label}</p>
                </div>
              </Link>
            </motion.div>
          ))}
        </div>

        {/* Secondary Grid */}
        <div className="grid grid-cols-12 gap-6">
          {/* Main Chart Area (Placeholder) */}
          <div className="col-span-12 lg:col-span-8">
            <div className="card-platinum p-8 rounded-3xl h-[400px] flex flex-col">
              <div className="flex items-center justify-between mb-8">
                <div>
                  <h3 className="text-lg font-bold text-[#1A1A1A]">Listing Performance</h3>
                  <p className="text-[#666666] text-xs">Total views and bookings over time</p>
                </div>
                <div className="flex gap-2">
                  <button className="px-4 py-2 text-xs font-bold text-[#2563EB] bg-[#2563EB]/5 rounded-xl">Weekly</button>
                  <button className="px-4 py-2 text-xs font-bold text-[#666666] hover:bg-[#FBFBF9] rounded-xl transition-all">Monthly</button>
                </div>
              </div>
              <div className="flex-1 bg-[#FBFBF9] rounded-2xl border border-dashed border-[#E8E6E1] flex items-center justify-center">
                <div className="text-center">
                  <Activity size={32} className="text-[#A1A1A1] mx-auto mb-3" />
                  <p className="text-[#A1A1A1] text-sm font-medium">Activity data visualization coming soon</p>
                </div>
              </div>
            </div>
          </div>

          {/* Activity Feed */}
          <div className="col-span-12 lg:col-span-4">
            <div className="card-platinum p-8 rounded-3xl h-full">
              <div className="flex items-center justify-between mb-8">
                <h3 className="text-lg font-bold text-[#1A1A1A]">Recent Activity</h3>
                <span className="text-[10px] font-bold text-[#2563EB] uppercase tracking-wider">Live Stream</span>
              </div>
              <div className="space-y-6">
                {[
                  { user: 'AI Autopilot', action: 'KYC Validated', time: '2m ago', color: 'bg-green-500' },
                  { user: 'System', action: 'New property listed', time: '18m ago', color: 'bg-[#2563EB]' },
                  { user: 'Master Ops', action: 'Settings modified', time: '1h ago', color: 'bg-amber-500' },
                  { user: 'Operator', action: 'Report flagged #1022', time: '3h ago', color: 'bg-red-500' },
                ].map((item, idx) => (
                  <div key={idx} className="flex gap-5 group cursor-pointer relative">
                    <div className="relative flex flex-col items-center">
                      <div className={`w-2.5 h-2.5 rounded-full ${item.color} z-10`} />
                      {idx < 3 && <div className="absolute top-2.5 w-[1px] h-[calc(100%+1.5rem)] bg-[#E8E6E1]" />}
                    </div>
                    <div className="flex-1 pb-1">
                      <p className="text-sm font-bold text-[#1A1A1A] group-hover:text-[#2563EB] transition-colors leading-none mb-1.5">{item.action}</p>
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] font-bold text-[#A1A1A1] uppercase tracking-wider">{item.user}</span>
                        <span className="w-1 h-1 rounded-full bg-[#E8E6E1]" />
                        <span className="text-[10px] font-medium text-[#A1A1A1]">{item.time}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
              <button className="w-full mt-8 py-3 rounded-2xl bg-[#FBFBF9] border border-[#E8E6E1] text-[#666666] text-xs font-bold hover:bg-[#F4F2EE] transition-all">
                View All Activity
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// ─── Root App ─────────────────────────────────────────────────────────────────
const App = () => {
  const [isUnlocked, setIsUnlocked] = useState(false);
  const [notificationCount, setNotificationCount] = useState(0);

  useEffect(() => {
    if (!isUnlocked) return;

    const fetchCounts = async () => {
      const [kyc, reports] = await Promise.all([
        supabase.from('kyc_verifications').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
        supabase.from('user_reports').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
      ]);
      setNotificationCount((kyc.count || 0) + (reports.count || 0));
    };

    fetchCounts();
    const kycSub = supabase.channel('kyc-notify').on('postgres_changes', { event: '*', schema: 'public', table: 'kyc_verifications' }, fetchCounts).subscribe();
    const repSub = supabase.channel('rep-notify').on('postgres_changes', { event: '*', schema: 'public', table: 'user_reports' }, fetchCounts).subscribe();
    return () => { kycSub.unsubscribe(); repSub.unsubscribe(); };
  }, [isUnlocked]);

  if (!isUnlocked) return <Login onPinSuccess={() => setIsUnlocked(true)} />;

  return (
    <Router>
      <div className="flex h-screen bg-[#F8FAFC] font-sans overflow-hidden text-[#0F172A]">
        <Sidebar onLock={() => setIsUnlocked(false)} />
        <div className="flex-1 flex flex-col h-screen overflow-hidden">
          <Routes>
            <Route path="/" element={<><Header title="Dashboard" notificationCount={notificationCount} /><DashboardHome /></>} />
            <Route path="/kyc" element={<><Header title="KYC Verification" notificationCount={notificationCount} /><KycReview /></>} />
            <Route path="/properties" element={<><Header title="Property Moderation" notificationCount={notificationCount} /><PropertyModeration /></>} />
            <Route path="/users" element={<><Header title="User Directory" notificationCount={notificationCount} /><UserManagement /></>} />
            <Route path="/reports" element={<><Header title="Community Safety" notificationCount={notificationCount} /><Reports /></>} />
            <Route path="/settings" element={
              <>
                <Header title="Settings" notificationCount={notificationCount} />
                <div className="flex-1 flex items-center justify-center bg-[#F8FAFC]">
                  <div className="text-center max-w-sm">
                    <div className="w-20 h-20 rounded-[2.5rem] bg-white border border-[#E2E8F0] shadow-sm flex items-center justify-center mx-auto mb-6">
                      <Settings size={32} className="text-[#2563EB]" />
                    </div>
                    <h2 className="text-[#0F172A] text-xl font-extrabold mb-2 tracking-tight">System Configuration</h2>
                    <p className="text-[#64748B] text-sm font-medium leading-relaxed">Platform settings are being migrated to the new Platinum core architecture.</p>
                  </div>
                </div>
              </>
            } />
          </Routes>
        </div>
      </div>
    </Router>
  );
};

export default App;
