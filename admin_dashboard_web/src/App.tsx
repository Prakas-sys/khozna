import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Users, UserCheck, ShieldAlert, CheckSquare, Settings, LogOut, Loader2 } from 'lucide-react';
import { supabase } from './lib/supabase';
import { KycReview } from './KycReview';
import { PropertyModeration } from './PropertyModeration';
import { UserManagement } from './UserManagement';
import { Reports } from './Reports';
import { Login } from './Login';

const Sidebar = ({ onLock }: { onLock: () => void }) => {
  const location = useLocation();
  const isActive = (path: string) => location.pathname === path;

  const links = [
    { name: 'Command Center', path: '/', icon: <LayoutDashboard size={18} /> },
    { name: 'KYC Verification', path: '/kyc', icon: <UserCheck size={18} /> },
    { name: 'Properties', path: '/properties', icon: <CheckSquare size={18} /> },
    { name: 'Users', path: '/users', icon: <Users size={18} /> },
    { name: 'Reports', path: '/reports', icon: <ShieldAlert size={18} /> },
    { name: 'Settings', path: '/settings', icon: <Settings size={18} /> },
  ];

  return (
    <div className="w-72 h-full sidebar-gradient p-8 flex flex-col justify-between text-white/70">
      <div>
        <div className="flex items-center gap-4 mb-12">
          <img src="/logo.png" alt="Khozna" className="h-10 object-contain brightness-0 invert" />
          <div className="h-4 w-[1px] bg-white/20" />
          <span className="font-brand font-black tracking-[0.2em] text-xs text-white">OP-CENTER</span>
        </div>

        <nav className="flex flex-col gap-1">
          <p className="text-[10px] font-black text-white/30 uppercase tracking-[0.2em] mb-4 pl-4">Operations</p>
          {links.map((link) => (
            <Link
              key={link.name}
              to={link.path}
              className={`flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all text-sm font-semibold border border-transparent ${
                isActive(link.path) 
                  ? 'bg-brand/10 text-brand border-brand/20 shadow-lg shadow-brand/5' 
                  : 'hover:bg-white/5 hover:text-white'
              }`}
            >
              <span className={isActive(link.path) ? 'text-brand' : 'opacity-50'}>{link.icon}</span>
              {link.name}
            </Link>
          ))}
        </nav>
      </div>

      <div className="space-y-4">
        <div className="p-4 bg-white/5 rounded-2xl border border-white/10">
          <p className="text-[10px] font-bold text-white/40 uppercase tracking-widest mb-1">Status</p>
          <div className="flex items-center gap-2 text-xs font-bold text-green-400">
            <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
            Live Production
          </div>
        </div>
        
        <button 
          onClick={onLock}
          className="w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-red-400 hover:bg-red-500/10 font-bold transition-all text-sm group"
        >
          <LogOut size={18} className="opacity-50 group-hover:opacity-100" />
          Terminating Session
        </button>
      </div>
    </div>
  );
};

const Header = ({ title }: { title: string }) => {
  return (
    <header className="h-20 px-10 flex items-center justify-between border-b border-gray-100 bg-white/70 backdrop-blur-xl z-20 sticky top-0">
      <div className="flex flex-col">
        <h1 className="text-xl font-brand font-black tracking-tight text-obsidian">{title}</h1>
        <div className="flex items-center gap-2 mt-0.5">
          <div className="w-1.5 h-1.5 rounded-full bg-brand" />
          <span className="text-[10px] font-black text-gray-400 uppercase tracking-widest">Administrative Layer</span>
        </div>
      </div>
      
      <div className="flex items-center gap-4 group cursor-pointer p-2 hover:bg-gray-50 rounded-2xl transition-all">
        <div className="text-right">
          <p className="text-sm font-black text-obsidian">Master Operator</p>
          <p className="text-[11px] text-gray-400 font-bold">khoznaapp@gmail.com</p>
        </div>
        <div className="w-10 h-10 bg-brand-light text-brand rounded-xl flex items-center justify-center font-bold shadow-inner border border-brand/10 group-hover:scale-110 transition-transform">
          <Settings size={18} />
        </div>
      </div>
    </header>
  );
};

const DashboardHome = () => {
  const [stats, setStats] = useState({ users: 0, kyc: 0, properties: 0, bookings: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      try {
        const [usersReq, kycReq, propReq, bookReq] = await Promise.all([
          supabase.from('profiles').select('*', { count: 'exact', head: true }),
          supabase.from('kyc_verifications').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
          supabase.from('properties').select('*', { count: 'exact', head: true }),
          supabase.from('properties').select('*', { count: 'exact', head: true }).eq('status', 'booked')
        ]);

        setStats({
          users: usersReq.count || 0,
          kyc: kycReq.count || 0,
          properties: propReq.count || 0,
          bookings: bookReq.count || 0
        });
      } catch (e) {
        console.error("Error fetching stats:", e);
      } finally {
        setLoading(false);
      }
    }
    
    fetchStats();
  }, []);

  return (
    <div className="p-8 max-w-7xl mx-auto w-full flex-1 overflow-y-auto">
      <div className="bg-white rounded-[2rem] p-10 shadow-premium border border-gray-100 mb-10 overflow-hidden relative group">
        <div className="absolute top-0 right-0 w-96 h-96 bg-brand/5 rounded-full -mr-32 -mt-32 blur-3xl group-hover:bg-brand/10 transition-colors" />
        
        <div className="relative z-10">
          <div className="flex items-center gap-3 mb-6">
            <div className="px-3 py-1 bg-brand-light text-brand text-[10px] font-black uppercase tracking-widest rounded-full border border-brand/10">
              Live Operations
            </div>
            <div className="w-1 h-1 rounded-full bg-gray-300" />
            <span className="text-xs font-bold text-gray-400">{new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}</span>
          </div>
          
          <h2 className="text-4xl font-brand font-black tracking-tighter text-obsidian mb-4">
            Command Dashboard <span className="text-brand">V5</span>
          </h2>
          <p className="text-gray-500 font-medium max-w-lg leading-relaxed">
            Welcome back to the Khozna Administrative Core. Monitoring real-time verification traffic and platform health.
          </p>
        </div>
      </div>

      <div className="flex items-center justify-between mb-8">
        <h3 className="text-sm font-black text-obsidian uppercase tracking-[0.2em] flex items-center gap-3">
          Key Performance Indicators
          <div className="h-0.5 w-8 bg-brand rounded-full" />
        </h3>
        {loading && <Loader2 className="animate-spin text-brand" size={16} strokeWidth={3} />}
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Total Users', value: stats.users, icon: <Users size={20} />, color: 'brand', path: '/users' },
          { title: 'Pending KYC', value: stats.kyc, icon: <UserCheck size={20} />, color: 'orange-500', path: '/kyc' },
          { title: 'Active Listings', value: stats.properties, icon: <LayoutDashboard size={20} />, color: 'indigo-500', path: '/properties' },
          { title: 'Alerts', value: stats.bookings, icon: <ShieldAlert size={20} />, color: 'red-500', path: '/reports' },
        ].map((stat, i) => (
          <Link to={stat.path} key={i} className="bg-white p-6 rounded-[2rem] border border-gray-50 shadow-sm flex flex-col justify-between h-44 hover:shadow-premium hover:border-brand/10 transition-all group">
            <div className={`w-12 h-12 rounded-2xl flex items-center justify-center bg-gray-50 text-gray-400 group-hover:bg-brand-light group-hover:text-brand transition-all shadow-inner`}>
              {stat.icon}
            </div>
            <div>
              <h4 className="text-4xl font-brand font-black text-obsidian tracking-tighter group-hover:text-brand transition-colors">
                {loading ? '---' : stat.value}
              </h4>
              <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest mt-1 group-hover:text-gray-600">
                {stat.title}
              </p>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
};

const App = () => {
  const [isUnlocked, setIsUnlocked] = useState(false);

  if (!isUnlocked) {
    return <Login onPinSuccess={() => setIsUnlocked(true)} />;
  }

  return (
    <Router>
      <div className="flex h-screen bg-[#F8F9FB] font-sans selection:bg-[#00A3E1]/20">
        <Sidebar onLock={() => setIsUnlocked(false)} />
        <div className="flex-1 flex flex-col h-screen overflow-hidden">
          <Routes>
            <Route path="/" element={
              <>
                <Header title="Command Center" />
                <DashboardHome />
              </>
            } />
            <Route path="/kyc" element={
              <>
                <Header title="KYC Verification Dashboard" />
                <KycReview />
              </>
            } />
            <Route path="/properties" element={
               <>
                 <Header title="Property Moderation Dashboard" />
                 <PropertyModeration />
               </>
            } />
            <Route path="/users" element={
              <>
                 <Header title="User Management" />
                 <UserManagement />
              </>
            } />
            <Route path="/reports" element={
              <>
                 <Header title="Community Reports" />
                 <Reports />
              </>
            } />
            <Route path="/settings" element={
              <>
                 <Header title="Platform Settings" />
                 <div className="p-10 text-center py-20 text-gray-400"><h2 className="text-xl font-bold">Settings Panel Coming Soon</h2></div>
              </>
            } />
          </Routes>
        </div>
      </div>
    </Router>
  );
};

export default App;
