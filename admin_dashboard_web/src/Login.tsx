import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { Loader2, Lock, UserCheck, Smartphone, Globe, Shield } from 'lucide-react';

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
      const nextInput = document.getElementById(`pin-${index + 1}`);
      if (nextInput) nextInput.focus();
    }

    if (index === 5 && value !== '') {
      if (newPin.join('') === MASTER_PIN) {
        onPinSuccess();
      } else {
        setPinError(true);
        setTimeout(() => {
           setPin(['', '', '', '', '', '']);
           const firstInput = document.getElementById(`pin-0`);
           if (firstInput) firstInput.focus();
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
    <div className="min-h-screen bg-[#F8FAFC] flex items-center justify-center p-8 selection:bg-[#2563EB]/10">
      <div className="w-full max-w-md">
        <div className="text-center mb-10">
          <div className="w-12 h-12 bg-[#2563EB] rounded-lg flex items-center justify-center mx-auto mb-6 shadow-sm">
            <Globe size={24} className="text-white" />
          </div>
          <h1 className="text-2xl font-bold text-[#0F172A] tracking-tight mb-2">Khozna Admin</h1>
          <p className="text-sm font-medium text-[#64748B]">Platform Management Console</p>
        </div>

        <div className="bg-white border border-[#E2E8F0] rounded-xl shadow-sm p-10">
          {!session ? (
            <div className="space-y-6">
              <div className="text-center">
                <div className="w-12 h-12 bg-[#F1F5F9] rounded-full flex items-center justify-center mx-auto mb-4 text-[#2563EB]">
                  <Lock size={20} />
                </div>
                <h2 className="text-lg font-bold text-[#0F172A]">Secure Entry</h2>
                <p className="text-xs font-medium text-[#64748B] mt-1">Authenticate with your Google admin account.</p>
              </div>

              <button
                onClick={handleGoogleLogin}
                disabled={checkingAuth}
                className="w-full h-12 bg-[#1A1A1A] text-white rounded-lg flex items-center justify-center gap-3 hover:bg-black active:scale-[0.98] transition-all font-bold text-[13px] shadow-sm disabled:opacity-50"
              >
                {checkingAuth ? <Loader2 className="animate-spin" size={18} /> : (
                  <>
                    <Globe size={18} />
                    Continue with Google
                  </>
                )}
              </button>

              <div className="grid grid-cols-2 gap-3 pt-4">
                <div className="p-4 bg-[#F8FAFC] rounded-lg border border-[#E2E8F0]">
                  <UserCheck size={16} className="text-[#2563EB] mb-2" />
                  <p className="text-[10px] font-bold text-[#0F172A] uppercase">Identity</p>
                  <p className="text-[9px] text-[#64748B] font-medium leading-tight mt-1">Corporate credentials only.</p>
                </div>
                <div className="p-4 bg-[#F8FAFC] rounded-lg border border-[#E2E8F0]">
                  <Smartphone size={16} className="text-[#2563EB] mb-2" />
                  <p className="text-[10px] font-bold text-[#0F172A] uppercase">Protected</p>
                  <p className="text-[9px] text-[#64748B] font-medium leading-tight mt-1">Master PIN required.</p>
                </div>
              </div>
            </div>
          ) : (
            <div className="space-y-8">
              <div className="text-center">
                <div className="w-12 h-12 bg-[#F1F5F9] rounded-full flex items-center justify-center mx-auto mb-4 text-[#2563EB]">
                  <Smartphone size={20} />
                </div>
                <h2 className="text-lg font-bold text-[#0F172A]">Security PIN</h2>
                <p className="text-xs font-medium text-[#64748B] mt-1">Enter your 6-digit administrative PIN.</p>
              </div>

              <div className="flex justify-between gap-2">
                {pin.map((digit, i) => (
                  <input
                    key={i}
                    id={`pin-${i}`}
                    type="password"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handlePinChange(i, e.target.value)}
                    className={`w-full aspect-square text-center text-xl font-bold rounded-lg border-2 transition-all outline-none focus:ring-4 focus:ring-blue-500/10 ${
                      pinError ? 'border-rose-500 bg-rose-50' : 'border-[#E2E8F0] bg-[#F8FAFC] focus:border-[#2563EB] text-[#0F172A]'
                    }`}
                  />
                ))}
              </div>

              <div className="pt-6 border-t border-[#F1F5F9] flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-full overflow-hidden border border-[#E2E8F0]">
                    <img src={session.user?.user_metadata?.avatar_url} alt="" className="w-full h-full object-cover" />
                  </div>
                  <div>
                    <p className="text-[10px] font-bold text-[#94A3B8] uppercase">Admin</p>
                    <p className="text-[11px] font-bold text-[#0F172A] truncate w-32">{session.user?.email}</p>
                  </div>
                </div>
                <button onClick={handleSignOut} className="text-[10px] font-bold text-[#EF4444] uppercase tracking-wider hover:underline">Switch</button>
              </div>
            </div>
          )}
        </div>

        <div className="mt-10 flex items-center justify-center gap-2 text-[#94A3B8]">
          <Shield size={14} />
          <p className="text-[10px] font-bold uppercase tracking-[0.2em]">Khozna Security Protocol</p>
        </div>
      </div>
    </div>
  );
};
