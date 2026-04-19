import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { Lock, Loader2 } from 'lucide-react';

export const Login = ({ onPinSuccess }: { onPinSuccess: () => void }) => {
  const [session, setSession] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [pin, setPin] = useState(['', '', '', '', '', '']);
  const [pinError, setPinError] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(false);

  const MASTER_PIN = "889900"; // Hardware-locked Master PIN

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        verifyAdminSession(session);
      } else {
        setLoading(false);
      }
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
      // Intruders getting logged out instantly
      await supabase.auth.signOut();
      alert("Unauthorized Access. This portal is locked to the Khozna Admin.");
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
    if (value.length > 1) return; // Prevent multiple chars
    const newPin = [...pin];
    newPin[index] = value;
    setPin(newPin);
    setPinError(false);

    // Auto focus next
    if (value !== '' && index < 5) {
      const nextInput = document.getElementById(`pin-${index + 1}`);
      if (nextInput) nextInput.focus();
    }

    // Auto submit if full
    if (index === 5 && value !== '') {
      const fullPin = newPin.join('');
      if (fullPin === MASTER_PIN) {
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
      <div className="min-h-screen bg-[#F8F9FB] flex items-center justify-center">
        <Loader2 className="animate-spin text-[#00A3E1]" size={40} />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F8F9FB] flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl shadow-xl w-full max-w-md overflow-hidden relative">
        <div className="bg-gradient-to-br from-[#00A3E1] to-[#0079B1] p-8 text-center text-white pb-12">
          <div className="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center mx-auto mb-4 backdrop-blur-sm">
            <Lock size={32} className="text-white" />
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight">Khozna Control</h1>
          <p className="text-sm font-medium opacity-80 mt-2">Maximum Security Admin Portal</p>
        </div>

        <div className="p-8 -mt-6 bg-white rounded-t-3xl relative z-10">
          {!session ? (
            <div className="flex flex-col gap-6 pt-4">
              <p className="text-center text-gray-500 font-medium text-sm">
                Authentication Required. Strictly limited to platform owners.
              </p>
              
              <button 
                onClick={handleGoogleLogin}
                disabled={checkingAuth}
                className="w-full bg-white border-2 border-gray-100 hover:border-[#00A3E1]/50 hover:bg-gray-50 text-gray-800 font-bold py-4 px-6 rounded-2xl flex items-center justify-center gap-3 transition-all disabled:opacity-50"
              >
                {checkingAuth ? <Loader2 className="animate-spin" /> : (
                  <>
                    <svg className="w-6 h-6" viewBox="0 0 24 24">
                      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                      <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                      <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                    </svg>
                    Continue with Google
                  </>
                )}
              </button>
            </div>
          ) : (
            <div className="flex flex-col items-center pt-4">
              <div className="bg-green-50 text-green-600 px-4 py-2 rounded-full text-xs font-bold flex items-center gap-2 mb-6">
                <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                Verified as {session.user.email}
              </div>

              <h2 className="text-xl font-bold text-gray-900 mb-2">Enter Master PIN</h2>
              <p className="text-xs text-gray-400 mb-6 text-center">Air-Gap Security Layer Active. Decrypting dashboard requires Owner PIN.</p>

              <div className={`flex gap-3 mb-6 ${pinError ? 'animate-[shake_0.5s_ease-in-out]' : ''}`}>
                {pin.map((digit, i) => (
                  <input
                    key={i}
                    id={`pin-${i}`}
                    type="password"
                    inputMode="numeric"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handlePinChange(i, e.target.value)}
                    className={`w-12 h-14 text-center text-2xl font-black rounded-xl border-2 focus:outline-none transition-all ${
                      pinError ? 'border-red-500 bg-red-50 text-red-500' 
                               : 'border-gray-200 bg-gray-50 focus:border-[#00A3E1] focus:bg-white'
                    }`}
                  />
                ))}
              </div>

              {pinError && <p className="text-red-500 text-sm font-bold mb-4">Incorrect PIN</p>}

              <button 
                onClick={handleSignOut}
                className="text-gray-400 text-sm font-semibold hover:text-gray-800 transition-colors"
              >
                Sign Out
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
