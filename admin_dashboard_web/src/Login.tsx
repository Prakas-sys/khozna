import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from './lib/supabase';
import { Shield, Loader2, Lock, UserCheck, Smartphone, AlertTriangle, Globe } from 'lucide-react';

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
      <div className="min-h-screen bg-[#FBFBF9] flex flex-col items-center justify-center gap-4">
        <div className="relative">
          <div className="w-16 h-16 border-4 border-[#2563EB]/10 border-t-[#2563EB] rounded-full animate-spin" />
          <div className="absolute inset-0 flex items-center justify-center">
            <Lock size={16} className="text-[#2563EB]" />
          </div>
        </div>
        <p className="text-[10px] font-bold text-[#A1A1A1] uppercase tracking-[0.2em]">Verifying Gateway</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#FBFBF9] flex items-center justify-center p-8 selection:bg-[#2563EB]/10 relative overflow-hidden">
      {/* Background Decor */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-[-20%] left-[-10%] w-[60%] h-[60%] bg-[#2563EB]/5 rounded-full blur-[120px]" />
        <div className="absolute bottom-[-20%] right-[-10%] w-[60%] h-[60%] bg-blue-400/5 rounded-full blur-[120px]" />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 40 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-[480px] bg-white rounded-[3rem] p-12 shadow-2xl border border-[#E8E6E1] relative z-10"
      >
        {/* Header */}
        <div className="text-center mb-10">
          <div className="w-16 h-16 rounded-[1.5rem] bg-[#2563EB] flex items-center justify-center mx-auto mb-6 shadow-xl shadow-blue-500/20">
            <Shield size={32} className="text-white" />
          </div>
          <h2 className="text-3xl font-extrabold text-[#1A1A1A] tracking-tight mb-2">Khozna Core</h2>
          <p className="text-[#666666] text-sm font-medium">Administrative Security Gateway</p>
        </div>

        <AnimatePresence mode="wait">
          {!session ? (
            <motion.div
              key="login"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="space-y-4"
            >
              <button
                onClick={handleGoogleLogin}
                disabled={checkingAuth}
                className="w-full h-14 bg-[#1A1A1A] text-white rounded-2xl font-bold flex items-center justify-center gap-3 hover:bg-black active:scale-[0.98] transition-all shadow-xl shadow-black/10 disabled:opacity-50"
              >
                {checkingAuth ? <Loader2 className="animate-spin" size={20} /> : (
                  <>
                    <Globe size={20} />
                    Continue with Google
                  </>
                )}
              </button>

              <div className="grid grid-cols-2 gap-3 mt-8">
                <div className="p-4 bg-[#FBFBF9] rounded-2xl border border-[#E8E6E1]">
                  <UserCheck size={18} className="text-[#2563EB] mb-2" />
                  <p className="text-[10px] font-bold text-[#1A1A1A] uppercase tracking-wider">Identified</p>
                  <p className="text-[9px] text-[#A1A1A1] font-medium leading-tight mt-1">Authorized corporate credentials only.</p>
                </div>
                <div className="p-4 bg-[#FBFBF9] rounded-2xl border border-[#E8E6E1]">
                  <Smartphone size={18} className="text-[#2563EB] mb-2" />
                  <p className="text-[10px] font-bold text-[#1A1A1A] uppercase tracking-wider">Protected</p>
                  <p className="text-[9px] text-[#A1A1A1] font-medium leading-tight mt-1">Multi-factor Master PIN validation required.</p>
                </div>
              </div>
            </motion.div>
          ) : (
            <motion.div
              key="pin"
              initial={{ opacity: 0, scale: 0.98 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.98 }}
              className="flex flex-col"
            >
              <div className="text-center mb-10 space-y-2">
                <h2 className="text-2xl font-extrabold text-[#1A1A1A] tracking-tight uppercase">MFA Authorization</h2>
                <p className="text-[#666666] font-medium text-xs flex items-center justify-center gap-2">
                  <Smartphone size={14} className="text-[#2563EB]" /> Secure PIN Verification Required
                </p>
              </div>

              <div className="flex justify-between gap-3 mb-10">
                {pin.map((digit, i) => (
                  <input
                    key={i}
                    id={`pin-${i}`}
                    type="password"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handlePinChange(i, e.target.value)}
                    className={`w-full aspect-square text-center text-xl font-bold rounded-2xl border-2 transition-all outline-none focus:ring-4 focus:ring-blue-500/10 ${
                      pinError ? 'border-red-400 bg-red-50' : 'border-[#E8E6E1] bg-[#FBFBF9] focus:border-[#2563EB] text-[#1A1A1A]'
                    }`}
                  />
                ))}
              </div>

              {pinError && (
                <motion.div
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="flex items-center justify-center gap-2 text-red-500 text-xs font-bold mb-6"
                >
                  <AlertTriangle size={14} /> Master PIN Mismatch
                </motion.div>
              )}

              <div className="pt-6 border-t border-[#F4F2EE] flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full overflow-hidden border border-[#E8E6E1]">
                    <img src={session.user?.user_metadata?.avatar_url} alt="" className="w-full h-full object-cover" />
                  </div>
                  <div>
                    <p className="text-[10px] font-bold text-[#A1A1A1] uppercase tracking-wider">Session Identified</p>
                    <p className="text-xs font-bold text-[#1A1A1A]">{session.user?.email}</p>
                  </div>
                </div>
                <button onClick={handleSignOut} className="text-[10px] font-extrabold text-[#EF4444] uppercase tracking-widest hover:underline">Switch</button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
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
