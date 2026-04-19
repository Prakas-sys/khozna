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
    { name: 'Command Center', path: '/', icon: <LayoutDashboard size={20} /> },
    { name: 'KYC Verification', path: '/kyc', icon: <UserCheck size={20} /> },
    { name: 'Properties', path: '/properties', icon: <CheckSquare size={20} /> },
    { name: 'Users', path: '/users', icon: <Users size={20} /> },
    { name: 'Reports', path: '/reports', icon: <ShieldAlert size={20} /> },
    { name: 'Settings', path: '/settings', icon: <Settings size={20} /> },
  ];

  return (
    <div className="w-64 h-full bg-white border-r border-gray-100 p-6 flex flex-col justify-between">
      <div>
        <div className="flex items-center gap-3 mb-12">
          <div className="bg-[#00A3E1] text-white w-10 h-10 rounded-xl flex items-center justify-center font-bold text-xl shadow-lg shadow-[#00A3E1]/20">K</div>
          <span className="font-extrabold tracking-widest text-lg text-gray-900">KHOZNA</span>
        </div>

        <nav className="flex flex-col gap-2">
          <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2 pl-2">Admin Tools</p>
          {links.map((link) => (
            <Link
              key={link.name}
              to={link.path}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all font-medium ${
                isActive(link.path) 
                  ? 'bg-[#00A3E1]/10 text-[#00A3E1] font-bold' 
                  : 'text-gray-500 hover:bg-gray-50 hover:text-gray-900'
              }`}
            >
              {link.icon}
              {link.name}
            </Link>
          ))}
        </nav>
      </div>

      <button 
        onClick={onLock}
        className="flex items-center gap-3 px-4 py-3 rounded-xl text-red-500 hover:bg-red-50 font-bold transition-all"
      >
        <LogOut size={20} />
        Lock Dashboard
      </button>
    </div>
  );
};

const Header = ({ title }: { title: string }) => {
  return (
    <header className="h-24 px-10 flex items-center justify-between border-b border-gray-100 bg-white/50 backdrop-blur-md z-10">
      <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
      <div className="flex items-center gap-4">
        <div className="w-10 h-10 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full flex items-center justify-center text-xl shadow-md border-2 border-white">👑</div>
        <div>
          <p className="text-sm font-extrabold text-gray-900">Admin Boss</p>
          <p className="text-xs text-gray-400 font-medium">khoznaapp@gmail.com</p>
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
    <div className="p-10 max-w-7xl mx-auto w-full flex-1 h-full overflow-y-auto">
      <div className="w-full bg-gradient-to-br from-[#00A3E1] to-[#0079B1] rounded-3xl p-8 shadow-xl shadow-[#00A3E1]/20 mb-10 text-white relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-white opacity-5 rounded-full -mr-10 -mt-20 blur-2xl"></div>
        <h2 className="text-lg font-medium opacity-90 mb-2">Hello, Boss! 👋</h2>
        <p className="text-4xl font-black tracking-tight">Live Data Dashboard</p>
      </div>

      <h3 className="text-xl font-bold text-gray-800 mb-6 flex items-center gap-3">
        Business Overview 
        {loading && <Loader2 className="animate-spin text-[#00A3E1]" size={20} />}
      </h3>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Total Users', value: stats.users, icon: '👥', color: 'bg-blue-500', text: 'text-blue-500', path: '/users' },
          { title: 'Pending KYC', value: stats.kyc, icon: '🛡️', color: 'bg-orange-500', text: 'text-orange-500', path: '/kyc' },
          { title: 'Properties', value: stats.properties, icon: '🏠', color: 'bg-indigo-500', text: 'text-indigo-500', path: '/properties' },
          { title: 'Active Reports', value: stats.bookings, icon: '⚠️', color: 'bg-red-500', text: 'text-red-500', path: '/reports' },
        ].map((stat, i) => (
          <Link to={stat.path} key={i} className="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm flex flex-col justify-between h-40 hover:shadow-xl hover:shadow-gray-200/50 transition-all hover:-translate-y-1 transform cursor-pointer group">
            <div className="flex justify-between items-start">
              <div className={`w-12 h-12 rounded-2xl flex items-center justify-center text-2xl bg-opacity-10 shadow-inner group-hover:scale-110 transition-transform ${stat.text} ${stat.color.replace('bg-', 'bg-opacity-10 text-')}`} style={{ background: 'var(--color-bg)'}}>
                {stat.icon}
              </div>
            </div>
            <div>
              <h4 className="text-3xl font-black text-gray-900 group-hover:text-[#00A3E1] transition-colors">{loading ? '-' : stat.value}</h4>
              <p className="text-sm font-bold text-gray-400 uppercase tracking-widest mt-1 group-hover:text-gray-600 transition-colors">{stat.title}</p>
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
