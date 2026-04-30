import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Users, UserCheck, ShieldAlert,
  Settings, LogOut, Activity, Bell, TrendingUp, Building2,
  Search, Globe, Wallet, Filter
} from 'lucide-react';
import { motion } from 'framer-motion';
import { supabase } from './lib/supabase';
import { KycReview } from './KycReview';
import { PropertyModeration } from './PropertyModeration';
import { UserManagement } from './UserManagement';
import { Reports } from './Reports';
import { Login } from './Login';

// ─── Slim Sidebar ─────────────────────────────────────────────────────────────
const Sidebar = ({ onLock }: { onLock: () => void }) => {
  const location = useLocation();
  const isActive = (path: string) => location.pathname === path;

  const links = [
    { name: 'Dashboard', path: '/', icon: <LayoutDashboard size={20} /> },
    { name: 'KYC', path: '/kyc', icon: <UserCheck size={20} /> },
    { name: 'Properties', path: '/properties', icon: <Building2 size={20} /> },
    { name: 'Users', path: '/users', icon: <Users size={20} /> },
    { name: 'Safety', path: '/reports', icon: <ShieldAlert size={20} /> },
    { name: 'Settings', path: '/settings', icon: <Settings size={20} /> },
  ];

  return (
    <div className="w-20 h-full sidebar-clean flex flex-col items-center py-8 flex-shrink-0 z-30">
      <div className="w-10 h-10 rounded-xl bg-[#2563EB] flex items-center justify-center shadow-lg shadow-blue-500/20 mb-12">
        <Globe size={22} className="text-white" />
      </div>

      <nav className="flex flex-col gap-6 flex-1">
        {links.map(link => (
          <Link key={link.name} to={link.path} className="relative group">
            <div className={`w-12 h-12 flex items-center justify-center rounded-2xl transition-all duration-300 ${
              isActive(link.path)
                ? 'bg-[#2563EB] text-white shadow-lg shadow-blue-500/25'
                : 'text-[#A1A1A1] hover:bg-[#F4F2EE] hover:text-[#1A1A1A]'
            }`}>
              {link.icon}
            </div>
            <div className="absolute left-full ml-4 px-2 py-1 bg-[#1A1A1A] text-white text-[10px] font-bold rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none z-50">
              {link.name}
            </div>
          </Link>
        ))}
      </nav>

      <button
        onClick={onLock}
        className="w-12 h-12 flex items-center justify-center rounded-2xl text-[#EF4444] hover:bg-[#FFF1F1] transition-all group relative"
      >
        <LogOut size={20} />
        <div className="absolute left-full ml-4 px-2 py-1 bg-[#EF4444] text-white text-[10px] font-bold rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none z-50">
          Sign Out
        </div>
      </button>
    </div>
  );
};

// ─── Header ───────────────────────────────────────────────────────────────────
const Header = () => {
  const location = useLocation();
  const getSubNavLinks = () => {
    switch (location.pathname) {
      case '/': return [{ name: 'Overview', path: '/' }, { name: 'Activity', path: '/activity' }, { name: 'Insights', path: '/insights' }];
      case '/kyc': return [{ name: 'Pending', path: '/kyc' }, { name: 'History', path: '/kyc/history' }];
      default: return [{ name: 'Manage', path: location.pathname }, { name: 'Reports', path: '/reports' }];
    }
  };

  return (
    <header className="h-20 px-10 flex items-center justify-between z-20 sticky top-0 bg-[#FBFBF9]/80 backdrop-blur-md">
      {/* Sub-Nav Pills */}
      <div className="flex bg-white border border-[#E8E6E1] rounded-full p-1 shadow-sm">
        {getSubNavLinks().map(link => (
          <button
            key={link.name}
            className={`nav-pill ${location.pathname === link.path ? 'nav-pill-active' : 'nav-pill-inactive'}`}
          >
            {link.name}
          </button>
        ))}
      </div>

      <div className="flex items-center gap-6">
        <div className="relative group hidden md:block">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-[#A1A1A1] group-focus-within:text-[#2563EB] transition-colors" />
          <input
            type="text"
            placeholder="Search anything..."
            className="w-64 bg-white border border-[#E8E6E1] rounded-2xl py-2 pl-12 pr-4 focus:outline-none focus:ring-4 focus:ring-[#2563EB]/5 focus:border-[#2563EB] font-semibold text-xs transition-all shadow-sm"
          />
        </div>

        <button className="relative w-10 h-10 flex items-center justify-center bg-white border border-[#E8E6E1] rounded-xl text-[#666666] hover:bg-[#F4F2EE] transition-all shadow-sm">
          <Bell size={18} />
          <span className="absolute top-2.5 right-2.5 w-2 h-2 bg-[#EF4444] rounded-full border-2 border-white" />
        </button>

        <div className="flex items-center gap-3">
          <div className="text-right hidden lg:block">
            <p className="text-[#1A1A1A] text-xs font-extrabold">Master Ops</p>
            <p className="text-[#A1A1A1] text-[9px] font-bold uppercase tracking-wider">Super Admin</p>
          </div>
          <div className="w-10 h-10 rounded-xl overflow-hidden bg-[#F4F2EE] border border-[#E8E6E1] shadow-sm">
            <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Admin" className="w-full h-full object-cover" alt="Admin" />
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

  return (
    <div className="flex-1 overflow-y-auto px-10 py-8">
      {/* Hero Section */}
      <div className="mb-12">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <h2 className="text-4xl font-extrabold text-[#1A1A1A] tracking-tight mb-2">Good Morning, <span className="text-[#2563EB]">Atiqur</span></h2>
          <p className="text-[#666666] text-sm font-medium">Stay on top of your tasks, monitor progress, and track status.</p>
        </motion.div>
      </div>

      <div className="grid grid-cols-12 gap-6">
        {/* Left Column: Stats & Balance */}
        <div className="col-span-12 lg:col-span-8 space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="card-platinum p-8 rounded-[2.5rem] bg-[#2563EB] text-white overflow-hidden relative group">
              <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -mr-16 -mt-16 blur-3xl" />
              <div className="flex items-center justify-between mb-8">
                <p className="text-xs font-bold uppercase tracking-widest opacity-80">Platform Liquidity</p>
                <Wallet size={20} className="opacity-80" />
              </div>
              <p className="text-4xl font-black mb-2 tracking-tight">$876,654.00</p>
              <div className="flex items-center gap-2 text-[10px] font-bold bg-white/20 w-fit px-3 py-1 rounded-full border border-white/20">
                <TrendingUp size={12} /> 5% from last month
              </div>
            </motion.div>

            <div className="grid grid-cols-2 gap-6">
              {[
                { title: 'KYC Reviews', val: stats.kyc, trend: '+7%', color: 'text-blue-600', bg: 'bg-blue-50' },
                { title: 'Properties', val: stats.properties, trend: '-5%', color: 'text-red-600', bg: 'bg-red-50' },
                { title: 'Identities', val: stats.users, trend: '+10%', color: 'text-green-600', bg: 'bg-green-50' },
                { title: 'Secured', val: stats.bookings, trend: '+8%', color: 'text-indigo-600', bg: 'bg-indigo-50' },
              ].map((s, i) => (
                <motion.div key={i} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.1 }} className="card-platinum p-5 rounded-3xl">
                  <p className="text-[10px] font-bold text-[#A1A1A1] uppercase tracking-widest mb-3">{s.title}</p>
                  <p className="text-xl font-extrabold text-[#1A1A1A] mb-2">{loading ? '—' : s.val}</p>
                  <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${s.bg} ${s.color}`}>{s.trend}</span>
                </motion.div>
              ))}
            </div>
          </div>

          {/* Recent Activities Table */}
          <div className="card-platinum p-8 rounded-[2.5rem]">
            <div className="flex items-center justify-between mb-8">
              <h3 className="text-lg font-bold text-[#1A1A1A]">Recent Activity</h3>
              <div className="flex gap-4">
                <div className="relative">
                  <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#A1A1A1]" />
                  <input type="text" placeholder="Search..." className="pl-9 pr-4 py-1.5 bg-[#FBFBF9] border border-[#E8E6E1] rounded-xl text-[10px] focus:outline-none" />
                </div>
                <button className="p-2 border border-[#E8E6E1] rounded-xl text-[#666666]"><Filter size={14} /></button>
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[#F4F2EE]">
                    <th className="text-left py-4 text-[10px] font-bold text-[#A1A1A1] uppercase tracking-widest">Order ID</th>
                    <th className="text-left py-4 text-[10px] font-bold text-[#A1A1A1] uppercase tracking-widest">Activity</th>
                    <th className="text-left py-4 text-[10px] font-bold text-[#A1A1A1] uppercase tracking-widest">Price</th>
                    <th className="text-left py-4 text-[10px] font-bold text-[#A1A1A1] uppercase tracking-widest">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F4F2EE]">
                  {[
                    { id: 'INV_000076', activity: 'Mobile App Purchase', price: '$25,500', status: 'Completed', sColor: 'bg-green-50 text-green-600' },
                    { id: 'INV_000074', activity: 'Hotel Booking', price: '$32,700', status: 'Pending', sColor: 'bg-amber-50 text-amber-600' },
                    { id: 'INV_000073', activity: 'Flight Ticket Booking', price: '$40,200', status: 'Completed', sColor: 'bg-green-50 text-green-600' },
                  ].map((row, i) => (
                    <tr key={i} className="group hover:bg-[#FBFBF9] transition-all">
                      <td className="py-5 text-xs font-bold text-[#666666]">{row.id}</td>
                      <td className="py-5 text-xs font-extrabold text-[#1A1A1A]">{row.activity}</td>
                      <td className="py-5 text-xs font-bold text-[#1A1A1A]">{row.price}</td>
                      <td className="py-5">
                        <span className={`px-2 py-1 rounded-lg text-[9px] font-bold uppercase tracking-wider ${row.sColor}`}>{row.status}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right Column: Chart & Profile */}
        <div className="col-span-12 lg:col-span-4 space-y-6">
          <div className="card-platinum p-8 rounded-[2.5rem] h-fit">
            <div className="flex items-center justify-between mb-8">
              <h3 className="text-lg font-bold text-[#1A1A1A]">Financial Balance</h3>
              <button className="p-2 hover:bg-[#F4F2EE] rounded-xl"><Activity size={18} className="text-[#A1A1A1]" /></button>
            </div>
            
            <div className="relative flex flex-col items-center py-10">
               {/* Gauge Placeholder */}
               <div className="w-56 h-28 border-t-[12px] border-l-[12px] border-r-[12px] border-[#2563EB] rounded-t-full relative">
                 <div className="absolute inset-0 border-t-[12px] border-l-[12px] border-r-[12px] border-[#F4F2EE] rounded-t-full rotate-45 transform origin-bottom" />
                 <div className="absolute -bottom-4 left-1/2 -translate-x-1/2 text-center">
                   <p className="text-4xl font-black text-[#1A1A1A]">48%</p>
                   <p className="text-[10px] font-bold text-[#A1A1A1] uppercase tracking-widest mt-1">From yesterday</p>
                 </div>
               </div>
            </div>

            <div className="grid grid-cols-3 gap-2 mt-10">
              <div className="text-center">
                <div className="w-2 h-2 rounded-full bg-[#2563EB] mx-auto mb-2" />
                <p className="text-[9px] font-bold text-[#A1A1A1] uppercase">Profit</p>
              </div>
              <div className="text-center">
                <div className="w-2 h-2 rounded-full bg-indigo-400 mx-auto mb-2" />
                <p className="text-[9px] font-bold text-[#A1A1A1] uppercase">Today</p>
              </div>
              <div className="text-center">
                <div className="w-2 h-2 rounded-full bg-[#E8E6E1] mx-auto mb-2" />
                <p className="text-[9px] font-bold text-[#A1A1A1] uppercase">Week</p>
              </div>
            </div>
          </div>

          <div className="card-platinum p-8 rounded-[2.5rem] bg-indigo-900 text-white relative overflow-hidden">
             <div className="relative z-10">
               <h3 className="text-xl font-bold mb-4 tracking-tight">Khozna Card</h3>
               <p className="text-sm opacity-60 mb-10">Master Security Node</p>
               <div className="flex justify-between items-end">
                 <div>
                   <p className="text-xs font-mono opacity-80 mb-1">**** **** **** 8702</p>
                   <p className="text-[10px] font-bold uppercase tracking-widest">Active License</p>
                 </div>
                 <div className="flex -space-x-2">
                   <div className="w-8 h-8 rounded-full bg-red-500/80" />
                   <div className="w-8 h-8 rounded-full bg-amber-500/80" />
                 </div>
               </div>
             </div>
             <div className="absolute top-0 right-0 w-40 h-40 bg-white/5 rounded-full -mr-20 -mt-20 blur-2xl" />
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
                  <div className="w-20 h-20 rounded-[2.5rem] bg-white border border-[#E8E6E1] shadow-sm flex items-center justify-center mx-auto mb-6">
                    <Settings size={32} className="text-[#2563EB]" />
                  </div>
                  <h2 className="text-[#1A1A1A] text-xl font-extrabold mb-2 tracking-tight">System Configuration</h2>
                  <p className="text-[#666666] text-sm font-medium leading-relaxed">Platform settings are being migrated to the new Platinum core architecture.</p>
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
