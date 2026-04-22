import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { Shield, Loader2, ArrowRight, Lock, UserCheck, Smartphone, AlertTriangle } from 'lucide-react';

export const Login = ({ onPinSuccess }: { onPinSuccess: () => void }) => {
  const [session, setSession] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [pin, setPin] = useState(['', '', '', '', '', '']);
  const [pinError, setPinError] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(false);

  const MASTER_PIN = "889900";

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) verifyAdminSession(session);
      else setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session) verifyAdminSession(session);
      else {
        setSession(null);
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const verifyAdminSession = async (currentSession: any) => {
    const email = currentSession?.user?.email;
    if (email === 'khoznaapp@gmail.com') {
      setSession(currentSession);
    } else {
      await supabase.auth.signOut();
      alert("Unauthorized Access. This portal is strictly for Khozna Administration.");
      setSession(null);
    }
    setLoading(false);
  };

  const handleGoogleLogin = async () => {
    setCheckingAuth(true);
    await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin }
    });
  };

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    setSession(null);
    setPin(['', '', '', '', '', '']);
  };

  const handlePinChange = (index: number, value: string) => {
    if (value.length > 1) return;
    const newPin = [...pin];
    newPin[index] = value;
    setPin(newPin);
    setPinError(false);

    if (value !== '' && index < 5) {
      document.getElementById(`pin-${index + 1}`)?.focus();
    }

    if (index === 5 && value !== '') {
      if (newPin.join('') === MASTER_PIN) {
        onPinSuccess();
      } else {
        setPinError(true);
        setTimeout(() => {
           setPin(['', '', '', '', '', '']);
           document.getElementById(`pin-0`)?.focus();
        }, 500);
      }
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-obsidian flex items-center justify-center">
        <div className="relative">
          <div className="w-16 h-16 border-4 border-brand/20 border-t-brand rounded-full animate-spin" />
          <div className="absolute inset-0 flex items-center justify-center">
            <Lock size={16} className="text-brand animate-pulse" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-obsidian flex items-center justify-center p-8 selection:bg-brand/20 relative overflow-hidden font-inter">
      {/* Dynamic Background Elements */}
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-brand/5 rounded-full blur-[120px] animate-pulse" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-brand/5 rounded-full blur-[120px] animate-pulse delay-1000" />
      </div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-xl relative z-10"
      >
        <div className="flex flex-col items-center mb-12">
          <motion.img 
            initial={{ scale: 0.8 }}
            animate={{ scale: 1 }}
            src="/logo.png" 
            alt="Khozna" 
            className="h-16 mb-6 object-contain brightness-0 invert" 
          />
          <div className="flex items-center gap-4">
            <div className="h-[1px] w-8 bg-brand/30" />
            <p className="text-brand font-black tracking-[0.3em] text-[10px] uppercase">Nexus Command Center</p>
            <div className="h-[1px] w-8 bg-brand/30" />
          </div>
        </div>

        <div className="bg-[#161922] rounded-[3rem] border border-white/5 shadow-2xl shadow-black/50 overflow-hidden backdrop-blur-xl">
          <div className="p-12">
            <AnimatePresence mode="wait">
              {!session ? (
                <motion.div 
                  key="login"
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 20 }}
                  className="space-y-10"
                >
                  <div className="text-center space-y-3">
                    <h1 className="text-3xl font-brand font-black text-white tracking-tighter">System Access</h1>
                    <p className="text-gray-400 font-medium text-sm leading-relaxed max-w-xs mx-auto">
                      Biometric & Cryptographic authentication required for secure portal entry.
                    </p>
                  </div>
                  
                  <button 
                    onClick={handleGoogleLogin}
                    disabled={checkingAuth}
                    className="w-full bg-white text-obsidian font-black py-5 px-8 rounded-2xl flex items-center justify-center gap-4 transition-all hover:bg-brand hover:text-white active:scale-[0.98] disabled:opacity-50 group shadow-xl shadow-black/20"
                  >
                    {checkingAuth ? <Loader2 className="animate-spin h-5 w-5" /> : (
                      <>
                        <img src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" className="w-6 h-6" alt="G" />
                        <span className="uppercase tracking-widest text-xs">Verify Corporate ID</span>
                        <ArrowRight size={18} className="ml-2 group-hover:translate-x-1 transition-transform opacity-50" />
                      </>
                    )}
                  </button>
                  
                  <div className="flex flex-col items-center gap-4 opacity-30">
                    <div className="flex items-center gap-4 w-full">
                      <div className="h-[1px] flex-1 bg-white/10" />
                      <Shield size={16} className="text-white" />
                      <div className="h-[1px] flex-1 bg-white/10" />
                    </div>
                    <span className="text-[9px] font-black text-white uppercase tracking-[0.4em]">Zero Trust Protocol Active</span>
                  </div>
                </motion.div>
              ) : (
                <motion.div 
                  key="pin"
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="flex flex-col items-center"
                >
                  <div className="flex items-center gap-3 bg-brand/10 text-brand px-5 py-2.5 rounded-full text-[10px] font-black uppercase tracking-widest mb-10 border border-brand/20">
                    <UserCheck size={14} />
                    Operator: {session.user.email?.split('@')[0]}
                  </div>

                  <div className="text-center mb-10 space-y-2">
                    <h2 className="text-2xl font-brand font-black text-white tracking-tighter uppercase">Clearance Level 2</h2>
                    <p className="text-gray-400 font-medium text-xs flex items-center justify-center gap-2">
                      <Smartphone size={14} className="text-brand" /> Multi-Factor Pin Synchronization
                    </p>
                  </div>

                  <div className={`flex gap-3 mb-10 ${pinError ? 'animate-[shake_0.4s_ease-in-out]' : ''}`}>
                    {pin.map((digit, i) => (
                      <input
                        key={i}
                        id={`pin-${i}`}
                        type="password"
                        inputMode="numeric"
                        autoComplete="one-time-code"
                        maxLength={1}
                        value={digit}
                        onChange={(e) => handlePinChange(i, e.target.value)}
                        className={`w-14 h-20 text-center text-3xl font-black rounded-2xl border-2 transition-all outline-none ${
                          pinError ? 'border-red-500 bg-red-500/10 text-red-500 shadow-[0_0_20px_rgba(239,68,68,0.2)]' 
                                   : 'border-white/5 bg-white/[0.02] text-white focus:border-brand focus:bg-brand/5 focus:shadow-[0_0_30px_rgba(0,163,225,0.15)]'
                        }`}
                      />
                    ))}
                  </div>

                  <AnimatePresence>
                    {pinError && (
                      <motion.p 
                        initial={{ opacity: 0, y: -10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="text-red-500 text-[10px] font-black uppercase tracking-[0.2em] flex items-center gap-2 mb-6"
                      >
                        <AlertTriangle size={14} strokeWidth={3} /> Integrity Violation: Invalid Key
                      </motion.p>
                    )}
                  </AnimatePresence>
                  
                  <button 
                    onClick={handleSignOut}
                    className="text-gray-500 text-[10px] font-black uppercase tracking-[0.25em] hover:text-white transition-all py-3 px-6 rounded-xl border border-transparent hover:border-white/5"
                  >
                    Terminate Session
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
          
          <div className="bg-black/20 border-t border-white/5 p-6 text-center">
            <p className="text-[9px] text-gray-500 font-black tracking-[0.3em] uppercase leading-relaxed">
              System Core: Khozna-v5.2.0-Prod <br /> 
              Authorized Operational Territory Only
            </p>
          </div>
        </div>
      </motion.div>
      
      <style>{`
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          20% { transform: translateX(-8px); }
          40% { transform: translateX(8px); }
          60% { transform: translateX(-8px); }
          80% { transform: translateX(8px); }
        }
      `}</style>
    </div>
  );
};
