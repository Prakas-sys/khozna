import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Users, UserCheck, ShieldAlert, Settings, LogOut, Search, CreditCard, Landmark, CalendarDays, Building2, HelpCircle, Map as MapIcon, Package } from 'lucide-react';
import { supabase } from './lib/supabase';
import { KycReview } from './KycReview';
import { UserManagement } from './UserManagement';
import { Reports } from './Reports';
import { Login } from './Login';
import { Payments } from './Payments';
import { Payouts } from './Payouts';
import { Settings as SettingsScreen } from './Settings';
import { Bookings } from './Bookings';
import { Escrow } from './Escrow';
import { Support } from './Support';
import { Journey } from './Journey';

// ─── Minimalist Sidebar ──────────────────────────────────────────────────────
const Sidebar = ({ onLock }: { onLock: () => void }) => {
  const location = useLocation();
  const isActive = (path: string) => location.pathname === path;

  const links = [
    { name: 'Dashboard', path: '/', icon: <LayoutDashboard size={18} strokeWidth={1.5} /> },
    { name: 'Verifications', path: '/kyc', icon: <UserCheck size={18} strokeWidth={1.5} /> },
    { name: 'Users', path: '/users', icon: <Users size={18} strokeWidth={1.5} /> },
    { name: 'Bookings', path: '/bookings', icon: <CalendarDays size={18} strokeWidth={1.5} /> },
    { name: 'Payments', path: '/payments', icon: <CreditCard size={18} strokeWidth={1.5} /> },
    { name: 'Payouts', path: '/payouts', icon: <Landmark size={18} strokeWidth={1.5} /> },
    { name: 'Escrow', path: '/escrow', icon: <Building2 size={18} strokeWidth={1.5} /> },
    { name: 'Support', path: '/support', icon: <HelpCircle size={18} strokeWidth={1.5} /> },
    { name: 'Journey', path: '/journey', icon: <MapIcon size={18} strokeWidth={1.5} /> },
    { name: 'Safety', path: '/reports', icon: <ShieldAlert size={18} strokeWidth={1.5} /> },
    { name: 'Settings', path: '/settings', icon: <Settings size={18} strokeWidth={1.5} /> },
  ];

  return (
    <div className="w-[68px] h-full bg-white border-r border-[#E5E5E5] flex flex-col items-center py-6 flex-shrink-0 z-30">
      <div className="w-9 h-9 rounded-lg bg-[#171717] flex items-center justify-center mb-10">
        <span className="text-white font-bold text-[13px] tracking-tight">K</span>
      </div>

      <nav className="flex flex-col gap-1 flex-1">
        {links.map(link => (
          <Link key={link.name} to={link.path} title={link.name}>
            <div className={`w-10 h-10 flex items-center justify-center rounded-lg transition-all duration-150 ${
              isActive(link.path)
                ? 'bg-[#F5F5F5] text-[#171717]'
                : 'text-[#A3A3A3] hover:text-[#525252] hover:bg-[#FAFAFA]'
            }`}>
              {link.icon}
            </div>
          </Link>
        ))}
      </nav>

      <button
        onClick={onLock}
        className="w-10 h-10 flex items-center justify-center rounded-lg text-[#A3A3A3] hover:text-[#EF4444] hover:bg-[#FEF2F2] transition-all duration-150"
      >
        <LogOut size={18} strokeWidth={1.5} />
      </button>
    </div>
  );
};

// ─── Minimal Header ─────────────────────────────────────────────────────────
const Header = () => {
  const location = useLocation();
  
  const getPageTitle = (): string => {
    switch (location.pathname) {
      case '/': return 'Overview';
      case '/kyc': return 'Verifications';
      case '/users': return 'Users';
      case '/bookings': return 'Bookings';
      case '/payments': return 'Payments';
      case '/payouts': return 'Payouts';
      case '/escrow': return 'Escrow';
      case '/support': return 'Support';
      case '/journey': return 'Journey';
      case '/reports': return 'Safety';
      case '/settings': return 'Settings';
      default: return 'Console';
    }
  };

  return (
    <header className="h-14 px-8 flex items-center justify-between bg-white border-b border-[#E5E5E5] sticky top-0 z-20">
      <div className="flex items-center gap-3">
        <span className="text-[13px] font-medium text-[#A3A3A3]">Admin</span>
        <span className="text-[#D4D4D4]">/</span>
        <span className="text-[13px] font-semibold text-[#171717]">{getPageTitle()}</span>
      </div>

      <div className="flex items-center gap-5">
        <div className="relative hidden lg:block">
          <Search size={14} strokeWidth={1.5} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#A3A3A3]" />
          <input
            type="text"
            placeholder="Search..."
            className="w-52 bg-[#FAFAFA] border border-[#E5E5E5] rounded-lg py-[7px] pl-9 pr-3 focus:outline-none focus:border-[#A3A3A3] text-[13px] transition-colors placeholder:text-[#D4D4D4]"
          />
        </div>

        <div className="flex items-center gap-3 pl-5 border-l border-[#E5E5E5]">
          <div className="text-right">
            <p className="text-[13px] font-medium text-[#171717] leading-tight">Prakash</p>
            <p className="text-[11px] text-[#A3A3A3] leading-tight">Admin</p>
          </div>
          <div className="w-8 h-8 rounded-full bg-[#F5F5F5] flex items-center justify-center overflow-hidden border border-[#E5E5E5]">
             <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Prakash" alt="Avatar" className="w-full h-full object-cover" />
          </div>
        </div>
      </div>
    </header>
  );
};

// ─── Dashboard Home ─────────────────────────────────────────────────────────
const DashboardHome = () => {
  const [stats, setStats] = useState({ users: 0, kyc: 0, reports: 0, payments: 0 });
  const [activities, setActivities] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      try {
        const [usersRes, kycRes, reportsRes, paymentsRes, latestK] = await Promise.all([
          supabase.from('profiles').select('*', { count: 'exact', head: true }),
          supabase.from('kyc_verifications').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
          supabase.from('user_reports').select('*', { count: 'exact', head: true }),
          supabase.from('payments').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
          supabase.from('kyc_verifications').select('*').order('updated_at', { ascending: false }).limit(5),
        ]);
        
        setStats({ 
          users: usersRes.count || 0, 
          kyc: kycRes.count || 0, 
          reports: reportsRes.count || 0,
          payments: paymentsRes.count || 0
        });

        const combined = [
          ...(latestK.data || []).map(item => ({ 
            user: 'System', 
            action: `KYC Status Update: ${item.status}`, 
            time: new Date(item.updated_at).toLocaleDateString(), 
            type: 'KYC', 
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

  const statCards = [
    { title: 'Users', val: stats.users, label: 'Registered profiles', icon: <Users size={16} strokeWidth={1.5} /> },
    { title: 'Pending KYC', val: stats.kyc, label: 'Awaiting review', icon: <UserCheck size={16} strokeWidth={1.5} /> },
    { title: 'Reports', val: stats.reports, label: 'Safety flags', icon: <ShieldAlert size={16} strokeWidth={1.5} /> },
    { title: 'Payments', val: stats.payments, label: 'Pending verification', icon: <CreditCard size={16} strokeWidth={1.5} /> },
  ];

  return (
    <div className="flex-1 overflow-y-auto px-8 py-8 bg-[#FAFAFA]">
      <div className="mb-8">
        <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">Platform Overview</h2>
        <p className="text-[#737373] text-[13px]">Real-time operational data for Khozna.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {statCards.map((s, i) => (
          <div key={i} className="card-minimal p-5">
            <div className="flex items-center justify-between mb-4">
              <span className="text-[#A3A3A3]">{s.icon}</span>
              <span className="text-[11px] font-medium text-[#A3A3A3]">{s.title}</span>
            </div>
            <p className="text-[28px] font-semibold text-[#171717] tracking-tight leading-none">
              {loading ? <span className="inline-block w-8 h-7 bg-[#F5F5F5] rounded animate-pulse" /> : s.val}
            </p>
            <p className="text-[12px] text-[#A3A3A3] mt-1.5">{s.label}</p>
          </div>
        ))}
      </div>

      <div className="card-minimal overflow-hidden">
        <div className="px-6 py-4 border-b border-[#E5E5E5] flex items-center justify-between">
          <h3 className="text-[13px] font-semibold text-[#171717]">Recent Activity</h3>
        </div>
        <div>
          {loading ? (
            <div className="empty-state">
              <div className="w-5 h-5 border-2 border-[#E5E5E5] border-t-[#737373] rounded-full animate-spin mb-3" />
              <p className="text-[13px] text-[#A3A3A3]">Loading...</p>
            </div>
          ) : activities.length > 0 ? (
            <div className="divide-y divide-[#F5F5F5]">
              {activities.map((log, i) => (
                <div key={i} className="px-6 py-4 flex items-center justify-between hover:bg-[#FAFAFA] transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="w-7 h-7 rounded-lg bg-[#F5F5F5] flex items-center justify-center text-[#A3A3A3]">
                      {log.type === 'KYC' ? <UserCheck size={14} strokeWidth={1.5} /> : <ShieldAlert size={14} strokeWidth={1.5} />}
                    </div>
                    <div>
                      <p className="text-[13px] font-medium text-[#171717]">{log.action}</p>
                      <p className="text-[11px] text-[#A3A3A3]">{log.time}</p>
                    </div>
                  </div>
                  <span className="text-[11px] font-medium text-[#A3A3A3] bg-[#F5F5F5] px-2 py-0.5 rounded-full">
                    {log.type}
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <div className="empty-state">
              <div className="empty-state-icon">
                <Package size={20} strokeWidth={1.5} />
              </div>
              <p className="empty-state-title">No recent activity</p>
              <p className="empty-state-desc">Activity will appear here as events happen on the platform.</p>
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
      <div className="flex h-screen bg-[#FAFAFA] overflow-hidden text-[#171717]">
        <Sidebar onLock={() => setIsUnlocked(false)} />
        <div className="flex-1 flex flex-col h-screen overflow-hidden">
          <Header />
          <Routes>
            <Route path="/" element={<DashboardHome />} />
            <Route path="/kyc" element={<KycReview />} />
            <Route path="/users" element={<UserManagement />} />
            <Route path="/bookings" element={<Bookings />} />
            <Route path="/reports" element={<Reports />} />
            <Route path="/payments" element={<Payments />} />
            <Route path="/payouts" element={<Payouts />} />
            <Route path="/escrow" element={<Escrow />} />
            <Route path="/support" element={<Support />} />
            <Route path="/journey" element={<Journey />} />
            <Route path="/settings" element={<SettingsScreen />} />
          </Routes>
        </div>
      </div>
    </Router>
  );
};

export default App;
