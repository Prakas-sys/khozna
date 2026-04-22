import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Users, UserCheck, ShieldAlert, CheckSquare, Settings, LogOut, Loader2, Activity, Globe, Bell } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
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
    <div className="w-72 h-full sidebar-gradient p-8 flex flex-col justify-between text-white/50 relative overflow-hidden">
      <div className="absolute top-0 left-0 w-full h-full opacity-5 pointer-events-none bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')]" />
      
      <div className="relative z-10">
        <div className="flex items-center gap-4 mb-12">
          <div className="w-10 h-10 bg-brand rounded-xl flex items-center justify-center shadow-lg shadow-brand/20">
            <img src="/logo.png" alt="K" className="h-6 object-contain brightness-0 invert" />
          </div>
          <div className="h-4 w-[1px] bg-white/10" />
          <span className="font-brand font-black tracking-[0.3em] text-[10px] text-white">CORE-X</span>
        </div>

        <nav className="flex flex-col gap-1.5">
          <p className="text-[10px] font-black text-white/20 uppercase tracking-[0.25em] mb-4 pl-4">System Grid</p>
          {links.map((link) => (
            <Link
              key={link.name}
              to={link.path}
              className="relative group"
            >
              <div
                className={`flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all text-sm font-bold border border-transparent ${
                  isActive(link.path) 
                    ? 'text-white border-white/5 bg-white/5' 
                    : 'hover:text-white/80'
                }`}
              >
                {isActive(link.path) && (
                  <motion.div 
                    layoutId="activeNav"
                    className="absolute inset-0 bg-brand/10 border border-brand/20 rounded-xl"
                    transition={{ type: 'spring', bounce: 0.2, duration: 0.6 }}
                  />
                )}
                <span className={`relative z-10 ${isActive(link.path) ? 'text-brand' : 'opacity-40 group-hover:opacity-100'}`}>{link.icon}</span>
                <span className="relative z-10">{link.name}</span>
              </div>
            </Link>
          ))}
        </nav>
      </div>

      <div className="relative z-10 space-y-6">
        <div className="p-5 bg-white/[0.03] rounded-[2rem] border border-white/5 backdrop-blur-sm">
          <div className="flex items-center justify-between mb-3">
            <p className="text-[9px] font-black text-white/30 uppercase tracking-widest">Environment</p>
            <div className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)] animate-pulse" />
              <span className="text-[9px] font-black text-green-400 uppercase">Live</span>
            </div>
          </div>
          <div className="space-y-3">
             <div className="h-1 bg-white/5 rounded-full overflow-hidden">
                <motion.div 
                  initial={{ width: "0%" }}
                  animate={{ width: "78%" }}
                  className="h-full bg-brand"
                />
             </div>
             <p className="text-[10px] text-white/40 font-bold">Network Stability: 99.9%</p>
          </div>
        </div>
        
        <div className="flex flex-col gap-2">
          <button 
            onClick={onLock}
            className="w-full flex items-center gap-3 px-4 py-4 rounded-xl text-red-400/60 hover:text-red-400 hover:bg-red-500/5 font-black transition-all text-[11px] uppercase tracking-widest group border border-transparent hover:border-red-500/10"
          >
            <LogOut size={16} className="opacity-40 group-hover:opacity-100" />
            Decommission Session
          </button>
        </div>
      </div>
    </div>
  );
};

const Header = ({ title, notificationCount }: { title: string, notificationCount: number }) => {
  const [showNotifications, setShowNotifications] = useState(false);
  
  return (
    <header className="h-20 px-10 flex items-center justify-between border-b border-gray-100/50 bg-white/60 backdrop-blur-2xl z-20 sticky top-0">
      <div className="flex flex-col">
        <div className="flex items-center gap-2 mb-0.5">
          <div className="w-1.5 h-1.5 rounded-full bg-brand shadow-[0_0_8px_#00A3E1]" />
          <span className="text-[9px] font-black text-gray-400 uppercase tracking-[0.2em]">Administrative Layer</span>
        </div>
        <h1 className="text-xl font-brand font-black tracking-tight text-obsidian">{title}</h1>
      </div>
      
      <div className="flex items-center gap-6">
        <div className="flex items-center gap-2 relative">
           {[Activity, Globe, Bell].map((Icon, i) => (
             <div key={i} className="relative">
               <button 
                 onClick={() => Icon === Bell && setShowNotifications(!showNotifications)}
                 className="w-10 h-10 rounded-xl flex items-center justify-center text-gray-400 hover:text-obsidian hover:bg-gray-50 transition-all border border-transparent hover:border-gray-100 group relative"
               >
                 <Icon size={18} className="group-hover:scale-110 transition-transform" />
                 {Icon === Bell && notificationCount > 0 && (
                   <motion.div 
                     initial={{ scale: 0 }}
                     animate={{ scale: 1 }}
                     className="absolute -top-1 -right-1 w-5 h-5 bg-[#FF0000] border-2 border-white rounded-full flex items-center justify-center shadow-lg shadow-red-500/40"
                   >
                     <span className="text-[10px] font-black text-white">{notificationCount}</span>
                   </motion.div>
                 )}
               </button>

               {Icon === Bell && showNotifications && (
                 <AnimatePresence>
                   <motion.div 
                     initial={{ opacity: 0, y: 10, scale: 0.95 }}
                     animate={{ opacity: 1, y: 0, scale: 1 }}
                     exit={{ opacity: 0, y: 10, scale: 0.95 }}
                     className="absolute right-0 mt-4 w-80 bg-white rounded-3xl shadow-2xl border border-gray-100 p-6 z-50 overflow-hidden"
                   >
                     <div className="flex items-center justify-between mb-6">
                       <h4 className="text-[10px] font-black text-obsidian uppercase tracking-widest">Pending Alerts</h4>
                       <span className="px-2 py-0.5 bg-brand/10 text-brand text-[9px] font-black rounded-full uppercase">Live Update</span>
                     </div>

                     <div className="space-y-4">
                       {notificationCount === 0 ? (
                         <p className="text-xs text-gray-400 text-center py-4 font-medium">All protocols are clear. No pending alerts.</p>
                       ) : (
                         <>
                           <Link 
                            to="/kyc" 
                            onClick={() => setShowNotifications(false)}
                            className="flex items-center justify-between p-4 bg-gray-50 rounded-2xl border border-transparent hover:border-brand/20 transition-all group"
                           >
                             <div className="flex items-center gap-3">
                               <div className="w-8 h-8 rounded-lg bg-orange-100 text-orange-600 flex items-center justify-center"><UserCheck size={14} /></div>
                               <span className="text-xs font-bold text-obsidian">Identity Audits</span>
                             </div>
                             <span className="text-[10px] font-black text-orange-600">PENDING</span>
                           </Link>

                           <Link 
                            to="/reports" 
                            onClick={() => setShowNotifications(false)}
                            className="flex items-center justify-between p-4 bg-gray-50 rounded-2xl border border-transparent hover:border-brand/20 transition-all group"
                           >
                             <div className="flex items-center gap-3">
                               <div className="w-8 h-8 rounded-lg bg-red-100 text-red-600 flex items-center justify-center"><ShieldAlert size={14} /></div>
                               <span className="text-xs font-bold text-obsidian">Threat Monitor</span>
                             </div>
                             <span className="text-[10px] font-black text-red-600">ACTION REQ</span>
                           </Link>
                         </>
                       )}
                     </div>

                     <button 
                        onClick={() => setShowNotifications(false)}
                        className="w-full mt-6 py-3 bg-obsidian text-white rounded-xl text-[9px] font-black uppercase tracking-widest hover:bg-brand transition-all"
                     >
                       Close Comms
                     </button>
                   </motion.div>
                 </AnimatePresence>
               )}
             </div>
           ))}
        </div>

        <div className="h-8 w-[1px] bg-gray-100" />

        <div className="flex items-center gap-4 group cursor-pointer p-1.5 pr-4 hover:bg-gray-50 rounded-2xl transition-all border border-transparent hover:border-gray-100">
          <div className="w-10 h-10 bg-obsidian text-white rounded-xl flex items-center justify-center font-bold shadow-lg overflow-hidden relative">
            <img src="https://api.dicebear.com/7.x/bottts/svg?seed=Khozna" className="w-full h-full object-cover" alt="Profile" />
          </div>
          <div className="text-left">
            <p className="text-xs font-black text-obsidian uppercase tracking-wider">Master Ops</p>
            <p className="text-[10px] text-gray-400 font-bold">Session: 04:12:01</p>
          </div>
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
    <div className="p-8 max-w-[1600px] mx-auto w-full flex-1 overflow-y-auto bg-[#F9FAFB]/50">
      <div className="grid grid-cols-12 gap-8">
        <div className="col-span-12 lg:col-span-8 space-y-8">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-obsidian rounded-[2.5rem] p-12 shadow-2xl shadow-obsidian/20 relative overflow-hidden group"
          >
            <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-brand/10 rounded-full -mr-40 -mt-40 blur-[120px] group-hover:bg-brand/20 transition-all duration-1000" />
            <div className="absolute bottom-0 left-0 w-64 h-64 bg-indigo-500/5 rounded-full -ml-32 -mb-32 blur-[80px]" />
            
            <div className="relative z-10">
              <div className="flex items-center gap-4 mb-8">
                <div className="px-4 py-1.5 bg-white/5 border border-white/10 text-brand text-[10px] font-black uppercase tracking-[0.2em] rounded-full backdrop-blur-md">
                  System Protocol v5.2.0
                </div>
                <div className="w-1.5 h-1.5 rounded-full bg-white/20" />
                <span className="text-[11px] font-bold text-white/40 uppercase tracking-widest">{new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}</span>
              </div>
              
              <h2 className="text-5xl font-brand font-black tracking-tighter text-white mb-6 leading-[1.1]">
                Welcome to the <br />
                <span className="text-brand">Command Nexus</span>
              </h2>
              <p className="text-white/40 font-medium max-w-md leading-relaxed text-sm mb-10">
                Orchestrating real-time asset flows and identity validation across the Khozna property ecosystem.
              </p>

              <div className="flex items-center gap-4">
                 <button className="px-8 py-3.5 bg-brand text-white rounded-2xl font-black text-xs uppercase tracking-widest shadow-xl shadow-brand/20 hover:scale-105 active:scale-95 transition-all">
                    System Audit
                 </button>
                 <button className="px-8 py-3.5 bg-white/5 text-white/60 border border-white/10 rounded-2xl font-black text-xs uppercase tracking-widest hover:bg-white/10 transition-all">
                    Network Map
                 </button>
              </div>
            </div>
          </motion.div>

          <div className="flex items-center justify-between">
            <h3 className="text-xs font-black text-obsidian uppercase tracking-[0.3em] flex items-center gap-4">
              Operational Metrics
              <div className="h-[2px] w-12 bg-brand/30 rounded-full" />
            </h3>
            {loading && <Loader2 className="animate-spin text-brand" size={16} strokeWidth={3} />}
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {[
              { title: 'Identity Pipeline', value: stats.kyc, label: 'Pending Verification', icon: <UserCheck size={24} />, color: 'from-orange-400 to-orange-600', path: '/kyc' },
              { title: 'Asset Inventory', value: stats.properties, label: 'Active Listings', icon: <LayoutDashboard size={24} />, color: 'from-brand to-brand-dark', path: '/properties' },
              { title: 'Citizen Registry', value: stats.users, label: 'Registered Operators', icon: <Users size={24} />, color: 'from-indigo-500 to-purple-600', path: '/users' },
              { title: 'Security Alerts', value: stats.bookings, label: 'Critical Reports', icon: <ShieldAlert size={24} />, color: 'from-red-500 to-red-700', path: '/reports' },
            ].map((stat, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: i * 0.1 }}
              >
                <Link to={stat.path} className="bg-white p-8 rounded-[2.5rem] border border-gray-100 shadow-sm flex items-center gap-8 group hover:shadow-2xl hover:shadow-brand/5 hover:border-brand/10 transition-all">
                  <div className={`w-16 h-16 rounded-2xl flex items-center justify-center bg-gray-50 text-gray-400 group-hover:bg-brand-light group-hover:text-brand transition-all shadow-inner relative overflow-hidden`}>
                    <div className={`absolute inset-0 bg-gradient-to-br ${stat.color} opacity-0 group-hover:opacity-10 transition-opacity`} />
                    {stat.icon}
                  </div>
                  <div>
                    <h4 className="text-3xl font-brand font-black text-obsidian tracking-tighter mb-1">
                      {loading ? '---' : stat.value}
                    </h4>
                    <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest">
                      {stat.title}
                    </p>
                    <p className="text-[9px] font-bold text-gray-300 mt-0.5">{stat.label}</p>
                  </div>
                </Link>
              </motion.div>
            ))}
          </div>
        </div>

        <div className="col-span-12 lg:col-span-4 space-y-8">
           <div className="bg-white rounded-[2.5rem] p-8 border border-gray-100 shadow-sm h-full flex flex-col">
              <div className="flex items-center justify-between mb-8">
                <h3 className="text-[10px] font-black text-obsidian uppercase tracking-widest">System Events</h3>
                <div className="w-8 h-8 rounded-lg bg-gray-50 flex items-center justify-center text-gray-400"><Activity size={14} /></div>
              </div>

              <div className="flex-1 space-y-6">
                {[
                  { user: "Operator-X", action: "Validated KYC ID #8291", time: "2m ago", status: "success" },
                  { user: "System", action: "Refreshed Property Cache", time: "14m ago", status: "info" },
                  { user: "Master", action: "Updated Auth Protocols", time: "1h ago", status: "warning" },
                  { user: "Operator-Z", action: "Flagged Listing #1022", time: "3h ago", status: "error" },
                ].map((event, i) => (
                  <div key={i} className="flex gap-4 group cursor-default">
                    <div className="relative">
                      <div className={`w-2 h-2 rounded-full mt-2 ${
                        event.status === 'success' ? 'bg-green-500' :
                        event.status === 'error' ? 'bg-red-500' :
                        event.status === 'warning' ? 'bg-orange-500' : 'bg-brand'
                      }`} />
                      {i !== 3 && <div className="absolute top-4 left-[3px] w-[2px] h-10 bg-gray-100" />}
                    </div>
                    <div>
                      <p className="text-xs font-bold text-obsidian">{event.action}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-[9px] font-black text-gray-400 uppercase">{event.user}</span>
                        <span className="text-[9px] text-gray-300 font-medium">•</span>
                        <span className="text-[9px] text-gray-300 font-medium">{event.time}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <button className="w-full mt-10 py-4 bg-gray-50 rounded-2xl text-[10px] font-black text-gray-400 uppercase tracking-[0.2em] hover:bg-gray-100 hover:text-obsidian transition-all">
                Full Activity Log
              </button>
           </div>
        </div>
      </div>
    </div>
  );
};

const App = () => {
  const [isUnlocked, setIsUnlocked] = useState(false);
  const [notificationCount, setNotificationCount] = useState(0);

  useEffect(() => {
    if (!isUnlocked) return;

    const fetchCounts = async () => {
      const [kyc, reports] = await Promise.all([
        supabase.from('kyc_verifications').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
        supabase.from('user_reports').select('*', { count: 'exact', head: true }).eq('status', 'pending')
      ]);
      setNotificationCount((kyc.count || 0) + (reports.count || 0));
    };

    fetchCounts();

    // Subscribe to changes
    const kycSub = supabase.channel('kyc-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'kyc_verifications' }, fetchCounts)
      .subscribe();
      
    const reportSub = supabase.channel('report-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'user_reports' }, fetchCounts)
      .subscribe();

    return () => {
      kycSub.unsubscribe();
      reportSub.unsubscribe();
    };
  }, [isUnlocked]);

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
                <Header title="Command Center" notificationCount={notificationCount} />
                <DashboardHome />
              </>
            } />
            <Route path="/kyc" element={
              <>
                <Header title="KYC Verification Dashboard" notificationCount={notificationCount} />
                <KycReview />
              </>
            } />
            <Route path="/properties" element={
               <>
                 <Header title="Property Moderation Dashboard" notificationCount={notificationCount} />
                 <PropertyModeration />
               </>
            } />
            <Route path="/users" element={
              <>
                 <Header title="User Management" notificationCount={notificationCount} />
                 <UserManagement />
              </>
            } />
            <Route path="/reports" element={
              <>
                 <Header title="Community Reports" notificationCount={notificationCount} />
                 <Reports />
              </>
            } />
            <Route path="/settings" element={
              <>
                 <Header title="Platform Settings" notificationCount={notificationCount} />
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
