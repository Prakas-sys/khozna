import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Users, UserCheck, ShieldAlert, CheckSquare,
  Settings, LogOut, Loader2, Activity, Bell, TrendingUp, Building2, Zap
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
    { name: 'Command Center', path: '/', icon: <LayoutDashboard size={16} /> },
    { name: 'KYC Verification', path: '/kyc', icon: <UserCheck size={16} /> },
    { name: 'Properties', path: '/properties', icon: <Building2 size={16} /> },
    { name: 'Users', path: '/users', icon: <Users size={16} /> },
    { name: 'Reports', path: '/reports', icon: <ShieldAlert size={16} /> },
    { name: 'Settings', path: '/settings', icon: <Settings size={16} /> },
  ];

  return (
    <div className="w-64 h-full sidebar-gradient flex flex-col justify-between relative overflow-hidden flex-shrink-0">
      {/* Subtle noise texture */}
      <div className="absolute inset-0 opacity-[0.015] pointer-events-none bg-[url('data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIzMDAiIGhlaWdodD0iMzAwIj48ZmlsdGVyIGlkPSJub2lzZSI+PGZlVHVyYnVsZW5jZSB0eXBlPSJmcmFjdGFsTm9pc2UiIGJhc2VGcmVxdWVuY3k9IjAuNjUiIG51bU9jdGF2ZXM9IjMiIHN0aXRjaFRpbGVzPSJzdGl0Y2giLz48L2ZpbHRlcj48cmVjdCB3aWR0aD0iMzAwIiBoZWlnaHQ9IjMwMCIgZmlsdGVyPSJ1cmwoI25vaXNlKSIgb3BhY2l0eT0iMSIvPjwvc3ZnPg==')]" />

      <div className="relative z-10 flex flex-col h-full p-6">
        {/* Logo */}
        <div className="flex items-center gap-3 mb-10 px-2">
          <div className="w-8 h-8 rounded-xl bg-[#00A3E1] flex items-center justify-center shadow-lg shadow-[#00A3E1]/30 flex-shrink-0">
            <img src="/logo.png" alt="K" className="h-5 object-contain brightness-0 invert" onError={e => (e.currentTarget.style.display = 'none')} />
          </div>
          <div>
            <p className="text-white font-black text-sm tracking-tight">Khozna</p>
            <p className="text-white/25 text-[10px] font-bold uppercase tracking-[0.2em]">Admin Core</p>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex flex-col gap-0.5 flex-1">
          <p className="text-[10px] font-black text-white/15 uppercase tracking-[0.25em] mb-3 px-3">Navigation</p>
          {links.map(link => (
            <Link key={link.name} to={link.path} className="relative group">
              {isActive(link.path) && (
                <motion.div
                  layoutId="activeNav"
                  className="absolute inset-0 bg-[#00A3E1]/10 border border-[#00A3E1]/20 rounded-xl"
                  transition={{ type: 'spring', bounce: 0.15, duration: 0.5 }}
                />
              )}
              <div className={`relative flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all text-sm font-semibold ${
                isActive(link.path)
                  ? 'text-white'
                  : 'text-white/30 hover:text-white/70 hover:bg-white/[0.04]'
              }`}>
                <span className={isActive(link.path) ? 'text-[#00A3E1]' : ''}>{link.icon}</span>
                <span>{link.name}</span>
                {isActive(link.path) && (
                  <span className="ml-auto w-1.5 h-1.5 rounded-full bg-[#00A3E1] pulse-brand" />
                )}
              </div>
            </Link>
          ))}
        </nav>

        {/* Bottom */}
        <div className="space-y-4">
          {/* System status */}
          <div className="p-4 rounded-2xl bg-white/[0.02] border border-white/[0.05]">
            <div className="flex items-center justify-between mb-3">
              <p className="text-[10px] font-black text-white/20 uppercase tracking-widest">System</p>
              <div className="flex items-center gap-1.5">
                <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
                <span className="text-[10px] font-black text-green-400">Online</span>
              </div>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between text-[10px]">
                <span className="text-white/20 font-semibold">Uptime</span>
                <span className="text-white/40 font-black">99.9%</span>
              </div>
              <div className="h-1 bg-white/[0.05] rounded-full overflow-hidden">
                <motion.div
                  initial={{ width: 0 }}
                  animate={{ width: '99%' }}
                  transition={{ duration: 1.5, delay: 0.5 }}
                  className="h-full bg-gradient-to-r from-[#00A3E1] to-[#0079B1] rounded-full"
                />
              </div>
            </div>
          </div>

          <button
            onClick={onLock}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-red-400/40 hover:text-red-400 hover:bg-red-500/[0.06] font-bold transition-all text-xs group border border-transparent hover:border-red-500/10"
          >
            <LogOut size={15} className="opacity-60 group-hover:opacity-100" />
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
    <header className="h-16 px-8 flex items-center justify-between border-b border-white/[0.05] bg-[#0C0E14]/80 backdrop-blur-2xl z-20 sticky top-0 flex-shrink-0">
      <div>
        <p className="text-[10px] font-black text-white/20 uppercase tracking-[0.2em] mb-0.5">Admin Dashboard</p>
        <h1 className="text-base font-black text-white tracking-tight">{title}</h1>
      </div>

      <div className="flex items-center gap-3">
        {/* Activity */}
        <button className="w-9 h-9 rounded-xl flex items-center justify-center text-white/25 hover:text-white/70 hover:bg-white/[0.05] transition-all">
          <Activity size={16} />
        </button>

        {/* Notifications */}
        <div className="relative">
          <button
            onClick={() => setShowNotif(!showNotif)}
            className="w-9 h-9 rounded-xl flex items-center justify-center text-white/25 hover:text-white/70 hover:bg-white/[0.05] transition-all relative"
          >
            <Bell size={16} />
            {notificationCount > 0 && (
              <motion.span
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                className="absolute -top-0.5 -right-0.5 w-4 h-4 bg-[#00A3E1] text-white text-[9px] font-black rounded-full flex items-center justify-center shadow-lg shadow-[#00A3E1]/40"
              >
                {notificationCount}
              </motion.span>
            )}
          </button>

          <AnimatePresence>
            {showNotif && (
              <motion.div
                initial={{ opacity: 0, y: 8, scale: 0.96 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 8, scale: 0.96 }}
                className="absolute right-0 top-12 w-72 glass-pro rounded-2xl p-5 shadow-2xl shadow-black/40 z-50 border border-white/[0.06]"
              >
                <div className="flex items-center justify-between mb-4">
                  <h4 className="text-xs font-black text-white uppercase tracking-widest">Alerts</h4>
                  {notificationCount > 0 && (
                    <span className="px-2 py-0.5 bg-[#00A3E1]/10 text-[#00A3E1] text-[9px] font-black rounded-full uppercase">
                      {notificationCount} Active
                    </span>
                  )}
                </div>
                {notificationCount === 0 ? (
                  <p className="text-white/25 text-xs text-center py-4 font-medium">All clear. No pending alerts.</p>
                ) : (
                  <div className="space-y-2">
                    <Link
                      to="/kyc"
                      onClick={() => setShowNotif(false)}
                      className="flex items-center gap-3 p-3 rounded-xl bg-white/[0.03] hover:bg-white/[0.06] border border-white/[0.05] transition-all"
                    >
                      <div className="w-7 h-7 rounded-lg bg-amber-500/10 flex items-center justify-center">
                        <UserCheck size={13} className="text-amber-400" />
                      </div>
                      <div>
                        <p className="text-white/70 text-xs font-bold">KYC Reviews Pending</p>
                        <p className="text-white/25 text-[10px] font-semibold">Awaiting authorization</p>
                      </div>
                    </Link>
                  </div>
                )}
                <button onClick={() => setShowNotif(false)} className="w-full mt-4 py-2.5 bg-white/[0.04] text-white/30 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-white/[0.08] transition-all">
                  Dismiss
                </button>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <div className="w-px h-6 bg-white/[0.06]" />

        {/* Profile */}
        <div className="flex items-center gap-3 px-3 py-1.5 rounded-xl hover:bg-white/[0.04] transition-all cursor-pointer">
          <div className="w-8 h-8 rounded-xl overflow-hidden border border-white/10">
            <img src="https://api.dicebear.com/7.x/bottts/svg?seed=KhoznaAdmin" className="w-full h-full object-cover" alt="Admin" />
          </div>
          <div>
            <p className="text-white text-xs font-black">Master Ops</p>
            <p className="text-white/25 text-[10px] font-semibold">Administrator</p>
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
      title: 'KYC Pending', value: stats.kyc, label: 'Awaiting review', icon: <UserCheck size={20} />,
      color: 'text-amber-400', bg: 'bg-amber-500/5', border: 'border-amber-500/10', path: '/kyc',
      badge: stats.kyc > 0 ? 'Action Required' : null, badgeColor: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
    },
    {
      title: 'Total Listings', value: stats.properties, label: 'Active properties', icon: <Building2 size={20} />,
      color: 'text-[#00A3E1]', bg: 'bg-[#00A3E1]/5', border: 'border-[#00A3E1]/10', path: '/properties',
      badge: null, badgeColor: '',
    },
    {
      title: 'Registered Users', value: stats.users, label: 'Platform members', icon: <Users size={20} />,
      color: 'text-indigo-400', bg: 'bg-indigo-500/5', border: 'border-indigo-500/10', path: '/users',
      badge: null, badgeColor: '',
    },
    {
      title: 'Active Bookings', value: stats.bookings, label: 'Booked properties', icon: <CheckSquare size={20} />,
      color: 'text-emerald-400', bg: 'bg-emerald-500/5', border: 'border-emerald-500/10', path: '/reports',
      badge: null, badgeColor: '',
    },
  ];

  const events = [
    { action: 'KYC Validated', user: 'AI Autopilot', time: '2m ago', dot: 'bg-green-400' },
    { action: 'New property listed', user: 'System', time: '18m ago', dot: 'bg-[#00A3E1]' },
    { action: 'Auth protocols updated', user: 'Master Ops', time: '1h ago', dot: 'bg-amber-400' },
    { action: 'Report flagged #1022', user: 'Operator', time: '3h ago', dot: 'bg-red-400' },
    { action: 'Database sync complete', user: 'System', time: '5h ago', dot: 'bg-white/20' },
  ];

  return (
    <div className="flex-1 overflow-y-auto bg-[#0C0E14]">
      <div className="max-w-[1400px] mx-auto px-8 py-10">

        {/* Hero card */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          className="relative rounded-3xl overflow-hidden bg-[#14161E] border border-white/[0.06] p-10 mb-8 shadow-2xl shadow-black/40"
        >
          {/* Background glow */}
          <div className="absolute top-0 right-0 w-96 h-96 bg-[#00A3E1]/8 rounded-full -mr-48 -mt-48 blur-[80px] pointer-events-none" />
          <div className="absolute bottom-0 left-0 w-64 h-64 bg-indigo-500/5 rounded-full -ml-32 -mb-32 blur-[60px] pointer-events-none" />

          <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-8">
            <div>
              <div className="flex items-center gap-3 mb-4">
                <div className="px-3 py-1 rounded-full bg-[#00A3E1]/10 border border-[#00A3E1]/20 text-[#00A3E1] text-[10px] font-black uppercase tracking-widest flex items-center gap-1.5">
                  <Zap size={10} fill="currentColor" />
                  Live System
                </div>
                <span className="text-white/20 text-[11px] font-semibold">
                  {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })}
                </span>
              </div>
              <h2 className="text-4xl font-black text-white tracking-tight leading-[1.1] mb-3">
                Command <span className="text-[#00A3E1]">Center</span>
              </h2>
              <p className="text-white/30 text-sm font-medium max-w-md leading-relaxed">
                Real-time oversight of identity verification, property listings, and user management across the Khozna platform.
              </p>
            </div>

            {loading ? (
              <Loader2 className="animate-spin text-white/20 flex-shrink-0" size={24} />
            ) : (
              <div className="flex items-center gap-6 flex-shrink-0">
                <div className="text-right">
                  <p className="text-4xl font-black text-white">{stats.users}</p>
                  <p className="text-white/30 text-xs font-bold uppercase tracking-wider mt-1">Total Users</p>
                </div>
                <div className="w-px h-12 bg-white/[0.06]" />
                <div className="text-right">
                  <p className="text-4xl font-black text-white">{stats.properties}</p>
                  <p className="text-white/30 text-xs font-bold uppercase tracking-wider mt-1">Properties</p>
                </div>
              </div>
            )}
          </div>
        </motion.div>

        {/* Main grid */}
        <div className="grid grid-cols-12 gap-6">
          {/* Stat cards */}
          <div className="col-span-12 lg:col-span-8 space-y-6">
            <div className="flex items-center justify-between">
              <h3 className="text-[11px] font-black text-white/30 uppercase tracking-[0.25em] flex items-center gap-3">
                <TrendingUp size={12} className="text-[#00A3E1]" />
                Platform Metrics
              </h3>
              {loading && <Loader2 className="animate-spin text-[#00A3E1]/40" size={14} strokeWidth={3} />}
            </div>

            <div className="grid grid-cols-2 gap-4">
              {statCards.map((s, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 16 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.08 }}
                >
                  <Link
                    to={s.path}
                    className={`block p-6 rounded-2xl border ${s.border} ${s.bg} hover:scale-[1.02] active:scale-[0.99] transition-all group relative overflow-hidden`}
                  >
                    <div className="flex items-start justify-between mb-4">
                      <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${s.bg} border ${s.border} ${s.color}`}>
                        {s.icon}
                      </div>
                      {s.badge && (
                        <span className={`px-2 py-0.5 rounded-full text-[9px] font-black uppercase border ${s.badgeColor}`}>
                          {s.badge}
                        </span>
                      )}
                    </div>
                    <p className={`text-3xl font-black ${s.color} mb-1`}>
                      {loading ? '—' : s.value}
                    </p>
                    <p className="text-white/50 text-xs font-black uppercase tracking-wider">{s.title}</p>
                    <p className="text-white/20 text-[10px] font-semibold mt-0.5">{s.label}</p>
                  </Link>
                </motion.div>
              ))}
            </div>
          </div>

          {/* Activity feed */}
          <div className="col-span-12 lg:col-span-4">
            <div className="h-full rounded-2xl bg-[#14161E] border border-white/[0.05] p-6 flex flex-col">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-[11px] font-black text-white/30 uppercase tracking-[0.25em] flex items-center gap-2">
                  <Activity size={12} className="text-[#00A3E1]" />
                  Activity Feed
                </h3>
                <div className="flex items-center gap-1.5">
                  <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
                  <span className="text-[10px] font-black text-green-400">Live</span>
                </div>
              </div>

              <div className="flex-1 space-y-5">
                {events.map((e, i) => (
                  <div key={i} className="flex gap-3">
                    <div className="relative flex-shrink-0 mt-1">
                      <div className={`w-2 h-2 rounded-full ${e.dot}`} />
                      {i < events.length - 1 && (
                        <div className="absolute top-3 left-[3px] w-[1px] h-8 bg-white/[0.05]" />
                      )}
                    </div>
                    <div>
                      <p className="text-white/60 text-xs font-semibold">{e.action}</p>
                      <div className="flex items-center gap-2 mt-0.5">
                        <span className="text-[10px] font-black text-white/20 uppercase tracking-wider">{e.user}</span>
                        <span className="text-white/10 text-[10px]">·</span>
                        <span className="text-[10px] text-white/15 font-medium">{e.time}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <button className="w-full mt-6 py-3 rounded-xl bg-white/[0.03] border border-white/[0.05] text-white/25 text-[10px] font-black uppercase tracking-widest hover:bg-white/[0.06] hover:text-white/50 transition-all">
                View All Events
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
      <div className="flex h-screen bg-[#0C0E14] font-sans overflow-hidden">
        <Sidebar onLock={() => setIsUnlocked(false)} />
        <div className="flex-1 flex flex-col h-screen overflow-hidden">
          <Routes>
            <Route path="/" element={<><Header title="Command Center" notificationCount={notificationCount} /><DashboardHome /></>} />
            <Route path="/kyc" element={<><Header title="KYC Verification" notificationCount={notificationCount} /><KycReview /></>} />
            <Route path="/properties" element={<><Header title="Property Moderation" notificationCount={notificationCount} /><PropertyModeration /></>} />
            <Route path="/users" element={<><Header title="User Management" notificationCount={notificationCount} /><UserManagement /></>} />
            <Route path="/reports" element={<><Header title="Community Reports" notificationCount={notificationCount} /><Reports /></>} />
            <Route path="/settings" element={
              <>
                <Header title="Platform Settings" notificationCount={notificationCount} />
                <div className="flex-1 flex items-center justify-center bg-[#0C0E14]">
                  <div className="text-center">
                    <div className="w-16 h-16 rounded-2xl bg-white/[0.03] border border-white/[0.05] flex items-center justify-center mx-auto mb-4">
                      <Settings size={28} className="text-white/20" />
                    </div>
                    <h2 className="text-white text-lg font-black mb-2">Settings</h2>
                    <p className="text-white/25 text-sm font-medium">Coming soon</p>
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
