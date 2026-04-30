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
      <div className="min-h-screen bg-[#F8FAFC] flex flex-col items-center justify-center gap-4">
        <div className="relative">
          <div className="w-16 h-16 border-4 border-[#2563EB]/10 border-t-[#2563EB] rounded-full animate-spin" />
          <div className="absolute inset-0 flex items-center justify-center">
            <Lock size={16} className="text-[#2563EB]" />
          </div>
        </div>
        <p className="text-[10px] font-bold text-[#94A3B8] uppercase tracking-[0.2em]">Verifying Gateway</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F8FAFC] flex items-center justify-center p-8 selection:bg-[#2563EB]/10 relative overflow-hidden">
      {/* Background Decor */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-[-20%] left-[-10%] w-[60%] h-[60%] bg-[#2563EB]/5 rounded-full blur-[120px]" />
        <div className="absolute bottom-[-20%] right-[-10%] w-[60%] h-[60%] bg-blue-400/5 rounded-full blur-[120px]" />
      </div>

      <motion.div 
        initial={{ opacity: 0, scale: 0.98 }}
        animate={{ opacity: 1, scale: 1 }}
        className="w-full max-w-xl relative z-10"
      >
        <div className="flex flex-col items-center mb-12">
          <motion.img 
            initial={{ y: -20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            src="/logo.png" 
            alt="Khozna" 
            className="h-14 mb-8 object-contain" 
          />
          <div className="flex items-center gap-4">
            <div className="h-[1px] w-8 bg-[#E2E8F0]" />
            <p className="text-[#2563EB] font-bold tracking-[0.3em] text-[10px] uppercase">Nexus Command Center</p>
            <div className="h-[1px] w-8 bg-[#E2E8F0]" />
          </div>
        </div>

        <div className="bg-white rounded-[3rem] border border-[#E2E8F0] shadow-2xl shadow-black/[0.03] overflow-hidden">
          <div className="p-14">
            <AnimatePresence mode="wait">
              {!session ? (
                <motion.div 
                  key="login"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="space-y-12"
                >
                  <div className="text-center space-y-3">
                    <h1 className="text-3xl font-extrabold text-[#0F172A] tracking-tight">Portal Access</h1>
                    <p className="text-[#64748B] font-medium text-sm leading-relaxed max-w-xs mx-auto">
                      Administrative credentials required for secure system interaction.
                    </p>
                  </div>
                  
                  <button 
                    onClick={handleGoogleLogin}
                    disabled={checkingAuth}
                    className="w-full bg-[#0F172A] text-white font-bold py-5 px-8 rounded-2xl flex items-center justify-center gap-4 transition-all hover:bg-[#2563EB] active:scale-[0.98] disabled:opacity-50 group shadow-lg shadow-black/5"
                  >
                    {checkingAuth ? <Loader2 className="animate-spin h-5 w-5" /> : (
                      <>
                        <img src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" className="w-6 h-6" alt="" />
                        <span className="uppercase tracking-widest text-[11px] font-extrabold">Authorize with Corporate ID</span>
                        <ArrowRight size={18} className="ml-2 group-hover:translate-x-1 transition-transform opacity-50" />
                      </>
                    )}
                  </button>
                  
                  <div className="flex flex-col items-center gap-4 opacity-40">
                    <div className="flex items-center gap-4 w-full">
                      <div className="h-[1px] flex-1 bg-[#E2E8F0]" />
                      <Shield size={16} className="text-[#94A3B8]" />
                      <div className="h-[1px] flex-1 bg-[#E2E8F0]" />
                    </div>
                    <span className="text-[9px] font-bold text-[#94A3B8] uppercase tracking-[0.4em]">Zero Trust Encryption Active</span>
                  </div>
                </motion.div>
              ) : (
                <motion.div 
                  key="pin"
                  initial={{ opacity: 0, scale: 0.98 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="flex flex-col items-center"
                >
                  <div className="flex items-center gap-3 bg-[#F1F5F9] text-[#0F172A] px-5 py-2.5 rounded-full text-[10px] font-bold uppercase tracking-widest mb-10 border border-[#E2E8F0]">
                    <UserCheck size={14} className="text-[#2563EB]" />
                    Operator: {session.user.email?.split('@')[0]}
                  </div>

                  <div className="text-center mb-10 space-y-2">
                    <h2 className="text-2xl font-extrabold text-[#0F172A] tracking-tight uppercase">MFA Authorization</h2>
                    <p className="text-[#64748B] font-medium text-xs flex items-center justify-center gap-2">
                      <Smartphone size={14} className="text-[#2563EB]" /> Secure PIN Verification Required
                    </p>
                  </div>

                  <div className={`flex gap-3 mb-12 ${pinError ? 'animate-[shake_0.4s_ease-in-out]' : ''}`}>
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
                        className={`w-14 h-20 text-center text-3xl font-extrabold rounded-2xl border-2 transition-all outline-none ${
                          pinError ? 'border-red-500 bg-red-50 text-red-600' 
                                   : 'border-[#E2E8F0] bg-[#F8FAFC] text-[#0F172A] focus:border-[#2563EB] focus:bg-white focus:shadow-lg focus:shadow-[#2563EB]/5'
                        }`}
                      />
                    ))}
                  </div>

                  <AnimatePresence>
                    {pinError && (
                      <motion.p 
                        initial={{ opacity: 0, y: -10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="text-red-500 text-[10px] font-bold uppercase tracking-[0.2em] flex items-center gap-2 mb-8"
                      >
                        <AlertTriangle size={14} /> Security Alert: Invalid Authorization Pin
                      </motion.p>
                    )}
                  </AnimatePresence>
                  
                  <button 
                    onClick={handleSignOut}
                    className="text-[#94A3B8] text-[10px] font-bold uppercase tracking-[0.25em] hover:text-[#0F172A] transition-all py-3 px-6 rounded-xl"
                  >
                    Terminate Session
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
          
          <div className="bg-[#F8FAFC] border-t border-[#E2E8F0] p-8 text-center">
            <p className="text-[9px] text-[#94A3B8] font-bold tracking-[0.3em] uppercase leading-relaxed">
              System Core: Khozna-v6.0.0-Platinum <br /> 
              Restricted Administrative Domain
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
