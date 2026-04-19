import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { Shield, Loader2, ArrowRight } from 'lucide-react';

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
      <div className="min-h-screen bg-bg flex items-center justify-center">
        <Loader2 className="animate-spin text-brand" size={32} strokeWidth={2.5} />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-6 selection:bg-brand/10">
      <div className="w-full max-w-lg">
        {/* Professional Header */}
        <div className="flex flex-col items-center mb-10">
          <img src="/logo.png" alt="Khozna Logo" className="h-14 mb-4 object-contain" />
          <div className="h-0.5 w-12 bg-brand rounded-full mb-4 animate-pulse" />
          <p className="text-gray-400 font-medium tracking-widest text-[10px] uppercase">Administrative Control Center</p>
        </div>

        <div className="bg-white rounded-2xl border border-gray-100 shadow-premium overflow-hidden">
          <div className="p-10">
            {!session ? (
              <div className="space-y-8">
                <div className="space-y-2">
                  <h1 className="text-2xl font-bold tracking-tight">Identity Authentication</h1>
                  <p className="text-sm text-gray-500 font-medium leading-relaxed">
                    Welcome to the Khozna Operations Portal. Access is strictly limited to authorized personnel.
                  </p>
                </div>
                
                <button 
                  onClick={handleGoogleLogin}
                  disabled={checkingAuth}
                  className="w-full bg-obsidian hover:bg-black text-white font-bold py-4 px-6 rounded-xl flex items-center justify-center gap-3 transition-all active:scale-[0.98] disabled:opacity-50 group"
                >
                  {checkingAuth ? <Loader2 className="animate-spin h-5 w-5" /> : (
                    <>
                      <img src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" className="w-5 h-5 brightness-200 contrast-200" alt="G" />
                      Authenticate with Google
                      <ArrowRight size={18} className="translate-x-0 group-hover:translate-x-1 transition-transform opacity-50" />
                    </>
                  )}
                </button>
                
                <div className="flex items-center gap-4 text-gray-200">
                  <div className="h-[1px] flex-1 bg-current" />
                  <span className="text-[10px] font-bold tracking-widest uppercase opacity-40">Security Active</span>
                  <div className="h-[1px] flex-1 bg-current" />
                </div>
              </div>
            ) : (
              <div className="flex flex-col items-center animate-in fade-in slide-in-from-bottom-4 duration-500">
                <div className="flex items-center gap-3 bg-brand-light text-brand px-4 py-2 rounded-full text-xs font-bold mb-8 border border-brand/10">
                  <Shield size={14} fill="currentColor" className="opacity-20" />
                  Operator: {session.user.email}
                </div>

                <div className="text-center mb-8">
                  <h2 className="text-xl font-bold tracking-tight mb-2">Internal Clearance Needed</h2>
                  <p className="text-sm text-gray-400 font-medium">Please enter your secondary physical-access PIN.</p>
                </div>

                <div className={`flex gap-3 mb-8 ${pinError ? 'animate-[shake_0.4s_ease-in-out]' : ''}`}>
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
                      className={`w-12 h-16 text-center text-3xl font-black rounded-xl border-2 transition-all outline-none ${
                        pinError ? 'border-red-500 bg-red-50 text-red-600' 
                                 : 'border-gray-50 bg-gray-50/50 focus:border-brand focus:bg-white focus:shadow-lg focus:shadow-brand/5'
                      }`}
                    />
                  ))}
                </div>

                <div className="flex flex-col items-center gap-4">
                  {pinError && <p className="text-red-500 text-xs font-bold flex items-center gap-1.5"><Shield size={12} strokeWidth={3} /> Invalid Security Key</p>}
                  
                  <button 
                    onClick={handleSignOut}
                    className="text-gray-400 text-xs font-bold hover:text-red-500 hover:bg-red-50 px-4 py-2 rounded-lg transition-all"
                  >
                    Switch Identity
                  </button>
                </div>
              </div>
            )}
          </div>
          
          <div className="bg-gray-50 border-t border-gray-100 p-4 text-center">
            <p className="text-[9px] text-gray-400 font-bold tracking-widest uppercase leading-tight">
              Cloud Instance: Khozna-V5-Production <br /> 
              Authorized Access Only © {new Date().getFullYear()}
            </p>
          </div>
        </div>
      </div>
      
      <style>{`
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-4px); }
          75% { transform: translateX(4px); }
        }
      `}</style>
    </div>
  );
};
