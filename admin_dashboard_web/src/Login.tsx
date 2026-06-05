import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { Loader2, Lock, Smartphone, Shield } from 'lucide-react';

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
      <div className="min-h-screen bg-[#FAFAFA] flex flex-col items-center justify-center gap-3">
        <div className="w-5 h-5 border-2 border-[#E5E5E5] border-t-[#171717] rounded-full animate-spin" />
        <p className="text-[12px] text-[#A3A3A3]">Verifying session...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#FAFAFA] flex items-center justify-center p-8">
      <div className="w-full max-w-[380px]">
        <div className="text-center mb-8">
          <div className="w-10 h-10 bg-[#171717] rounded-lg flex items-center justify-center mx-auto mb-5">
            <span className="text-white font-semibold text-[14px]">K</span>
          </div>
          <h1 className="text-[20px] font-semibold text-[#171717] tracking-tight mb-1">Khozna Admin</h1>
          <p className="text-[13px] text-[#737373]">Platform management console</p>
        </div>

        <div className="bg-white border border-[#E5E5E5] rounded-xl p-8">
          {!session ? (
            <div className="space-y-5">
              <div className="text-center">
                <div className="w-10 h-10 bg-[#F5F5F5] rounded-full flex items-center justify-center mx-auto mb-3 text-[#737373]">
                  <Lock size={18} strokeWidth={1.5} />
                </div>
                <h2 className="text-[15px] font-semibold text-[#171717]">Sign in</h2>
                <p className="text-[12px] text-[#A3A3A3] mt-1">Authenticate with your admin account.</p>
              </div>

              <button
                onClick={handleGoogleLogin}
                disabled={checkingAuth}
                className="w-full h-11 bg-[#171717] text-white rounded-lg flex items-center justify-center gap-2.5 hover:bg-[#0A0A0A] active:scale-[0.98] transition-all font-medium text-[13px] disabled:opacity-40"
              >
                {checkingAuth ? <Loader2 className="animate-spin" size={16} /> : (
                  <>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
                    Continue with Google
                  </>
                )}
              </button>

              <div className="grid grid-cols-2 gap-2.5 pt-3">
                <div className="p-3 bg-[#FAFAFA] rounded-lg border border-[#E5E5E5]">
                  <p className="text-[11px] font-medium text-[#171717] mb-0.5">Identity</p>
                  <p className="text-[10px] text-[#A3A3A3] leading-tight">Corporate credentials only.</p>
                </div>
                <div className="p-3 bg-[#FAFAFA] rounded-lg border border-[#E5E5E5]">
                  <p className="text-[11px] font-medium text-[#171717] mb-0.5">Protected</p>
                  <p className="text-[10px] text-[#A3A3A3] leading-tight">PIN required after login.</p>
                </div>
              </div>
            </div>
          ) : (
            <div className="space-y-6">
              <div className="text-center">
                <div className="w-10 h-10 bg-[#F5F5F5] rounded-full flex items-center justify-center mx-auto mb-3 text-[#737373]">
                  <Smartphone size={18} strokeWidth={1.5} />
                </div>
                <h2 className="text-[15px] font-semibold text-[#171717]">Enter PIN</h2>
                <p className="text-[12px] text-[#A3A3A3] mt-1">6-digit administrative PIN.</p>
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
                    className={`w-full aspect-square text-center text-lg font-medium rounded-lg border transition-all outline-none focus:ring-2 focus:ring-[#171717]/5 ${
                      pinError ? 'border-red-400 bg-red-50' : 'border-[#E5E5E5] bg-[#FAFAFA] focus:border-[#171717] text-[#171717]'
                    }`}
                  />
                ))}
              </div>

              <div className="pt-5 border-t border-[#F5F5F5] flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-full overflow-hidden border border-[#E5E5E5]">
                    <img src={session.user?.user_metadata?.avatar_url} alt="" className="w-full h-full object-cover" />
                  </div>
                  <div>
                    <p className="text-[11px] text-[#A3A3A3]">Signed in as</p>
                    <p className="text-[12px] font-medium text-[#171717] truncate w-36">{session.user?.email}</p>
                  </div>
                </div>
                <button onClick={handleSignOut} className="text-[11px] font-medium text-[#EF4444] hover:underline">Switch</button>
              </div>
            </div>
          )}
        </div>

        <div className="mt-8 flex items-center justify-center gap-1.5 text-[#A3A3A3]">
          <Shield size={12} strokeWidth={1.5} />
          <p className="text-[11px]">Khozna Security Protocol</p>
        </div>
      </div>
    </div>
  );
};
