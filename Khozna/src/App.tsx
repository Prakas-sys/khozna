import React, { useEffect, useState } from 'react';
import { motion, useScroll, useSpring } from 'framer-motion';
import type { Easing } from 'framer-motion';
import { Shield, ArrowUpRight, Play, Heart, Target, Lightbulb, Mail, Instagram, Facebook, Twitter, ChevronDown } from 'lucide-react';

function App() {
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  const [isHovering, setIsHovering] = useState(false);
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30, restDelta: 0.001 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setMousePos({ x: e.clientX, y: e.clientY });
    };
    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  const cinematicEase = [0.19, 1, 0.22, 1] as unknown as Easing[];

  const fadeIn = {
    initial: { opacity: 0, y: 60 },
    whileInView: { opacity: 1, y: 0 },
    viewport: { once: true },
    transition: { duration: 0.8, ease: cinematicEase }
  };

  const staggerContainer = {
    whileInView: { transition: { staggerChildren: 0.1 } }
  };

  return (
    <div className="app-container" style={{ background: 'var(--bg)', color: 'var(--text)' }}>
      {/* Scroll Progress Journey Bar */}
      <motion.div style={{ scaleX, position: 'fixed', top: 0, left: 0, right: 0, height: '4px', background: 'var(--primary)', zIndex: 2000, transformOrigin: '0%' }} />

      {/* Custom 2026 Cursor */}
      <motion.div
        className="custom-cursor"
        animate={{
          x: mousePos.x - 10,
          y: mousePos.y - 10,
          scale: isHovering ? 3 : 1,
        }}
        transition={{ type: 'spring', stiffness: 400, damping: 28, mass: 0.2 }}
      />

      {/* Cinematic Navigation */}
      <motion.nav
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        className="glass-card"
        style={{
          position: 'fixed',
          top: '1.5rem',
          left: '50%',
          transform: 'translateX(-50%)',
          width: 'min(95%, 1200px)',
          padding: '0.8rem 2rem',
          borderRadius: '100px',
          zIndex: 1000,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          background: 'rgba(255, 255, 255, 0.95)'
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '1.2rem' }}>
          <div className="logo-container">
            <img src="/logo.png" style={{ height: '30px', filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.05))' }} alt="Khozna Logo" />
          </div>
          <span style={{ fontWeight: 800, fontSize: '1.1rem', letterSpacing: '2px', color: 'var(--text)', fontFamily: 'var(--font-heading)' }}>KHOZNA</span>
        </div>
        <div style={{ display: 'flex', gap: '2.5rem', fontSize: '0.85rem', fontWeight: 700, color: 'var(--text)', textTransform: 'uppercase', letterSpacing: '1px' }}>
          <a href="#about" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>Our Journey</a>
          <a href="#mission" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>Philosophy</a>
          <a href="#app" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>Experience</a>
        </div>
        <button className="glow-btn" style={{ padding: '0.8rem 2rem', fontSize: '0.7rem' }} onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>
          Join Now
        </button>
      </motion.nav>

      {/* Cinematic Hero Section */}
      <section style={{ height: '110vh', background: 'var(--bg)' }}>
        <div className="culture-overlay" />
        <div className="container">
          <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', alignItems: 'center', gap: '4rem' }}>
            <motion.div
              initial={{ opacity: 0, x: -80 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 1.2, ease: cinematicEase }}
            >
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
                style={{
                  background: 'var(--primary)',
                  display: 'inline-block',
                  padding: '0.6rem 1.4rem',
                  borderRadius: '100px',
                  marginBottom: '2.5rem',
                  fontSize: '0.75rem',
                  fontWeight: 800,
                  color: 'white',
                  letterSpacing: '2px',
                  boxShadow: '0 10px 20px var(--primary-glow)'
                }}
              >
                NEPAL'S PREMIER DIRECT RENTAL ECOSYSTEM
              </motion.div>
              <h1 style={{ fontSize: 'clamp(4rem, 10vw, 8rem)', marginBottom: '2rem' }}>
                Rent <br />
                <span className="text-gradient">Purely.</span>
              </h1>
              <p style={{ fontSize: '1.4rem', color: 'var(--text-dim)', maxWidth: '580px', marginBottom: '4rem', lineHeight: '1.5', fontWeight: 300 }}>
                A cinematic approach to modern living. Finding your space in Nepal is no longer a search—it's a journey.
              </p>
              <div style={{ display: 'flex', gap: '2rem', alignItems: 'center' }}>
                <button className="glow-btn" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>
                  Start the Journey <ArrowUpRight size={20} style={{ marginLeft: '10px' }} />
                </button>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1.2rem', cursor: 'pointer' }} onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>
                  <div style={{ width: '60px', height: '60px', borderRadius: '50%', background: 'white', border: '1px solid #E2E8F0', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 10px 30px rgba(0,0,0,0.05)' }}>
                    <Play size={24} fill="var(--primary)" color="var(--primary)" />
                  </div>
                  <span style={{ fontSize: '0.9rem', fontWeight: 700, letterSpacing: '1px' }}>SEE THE STORY</span>
                </div>
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, scale: 0.9, rotate: 5 }}
              animate={{ opacity: 1, scale: 1, rotate: 0 }}
              transition={{ duration: 1.5, ease: cinematicEase }}
              style={{ position: 'relative' }}
            >
              <div className="glass-card" style={{ padding: '1rem', borderRadius: '40px', background: 'white', overflow: 'hidden' }}>
                <motion.img 
                  animate={{ scale: [1, 1.05, 1] }}
                  transition={{ duration: 10, repeat: Infinity, ease: "linear" }}
                  src="/rental_hero.png" 
                  style={{ width: '100%', borderRadius: '30px', display: 'block' }} 
                />
              </div>
              {/* Floating Realistic Badge */}
              <motion.div
                animate={{ y: [0, -20, 0] }}
                transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
                style={{ position: 'absolute', bottom: '-20px', right: '-20px', background: 'white', padding: '1.5rem 2rem', borderRadius: '24px', boxShadow: '0 30px 60px rgba(0,0,0,0.1)', border: '1px solid #E2E8F0' }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                   <Shield size={28} color="var(--primary)" />
                   <div>
                     <div style={{ fontSize: '0.7rem', fontWeight: 900, opacity: 0.4, letterSpacing: '1px' }}>VERIFIED</div>
                     <div style={{ fontWeight: 800, fontSize: '1rem' }}>Nepal Standard</div>
                   </div>
                </div>
              </motion.div>
            </motion.div>
          </div>
        </div>
        <motion.div 
          animate={{ y: [0, 10, 0] }}
          transition={{ duration: 2, repeat: Infinity }}
          style={{ position: 'absolute', bottom: '4rem', left: '50%', transform: 'translateX(-50%)', opacity: 0.3 }}
        >
          <ChevronDown size={32} />
        </motion.div>
      </section>

      {/* The Journey Section - Cinematic storytelling */}
      <section id="about" style={{ padding: 'var(--spacing-section) 0', background: 'white' }}>
        <div className="container">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', alignItems: 'center', gap: '10rem' }}>
            <motion.div {...fadeIn}>
              <h2 style={{ fontSize: '5rem', marginBottom: '3rem' }}>Our <br/><span className="text-gradient">Heritage.</span></h2>
              <p style={{ fontSize: '1.4rem', color: 'var(--text-dim)', lineHeight: '1.6', fontWeight: 300, marginBottom: '3rem' }}>
                In a world of noise, Khozna brings silence. We believe finding a home is a sacred act—a bridge between your past and your future. 
              </p>
              <p style={{ fontSize: '1.4rem', color: 'var(--text-dim)', lineHeight: '1.6', fontWeight: 300 }}>
                We removed the middlemen not just to save money, but to restore the human connection that defines Nepali hospitality.
              </p>
            </motion.div>
            <motion.div 
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 1 }}
              style={{ position: 'relative' }}
            >
              <img src="/man_illustrate.png" style={{ width: '100%', borderRadius: '40px', boxShadow: 'var(--shadow-deep)' }} />
              <div style={{ position: 'absolute', top: '20%', left: '-10%', width: '100%', height: '100%', border: '2px solid var(--primary)', borderRadius: '40px', zIndex: -1, opacity: 0.2 }} />
            </motion.div>
          </div>
        </div>
      </section>

      {/* Philosophical Grid - Nepal High Culture */}
      <section id="mission" style={{ padding: 'var(--spacing-section) 0', background: 'var(--surface)' }}>
        <div className="culture-overlay" />
        <div className="container">
          <motion.div variants={staggerContainer} initial="initial" whileInView="whileInView" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '4rem' }}>
            {[
              { icon: <Target />, title: 'Mission', text: 'To redefine Nepal’s rental landscape through absolute transparency and direct human connection.' },
              { icon: <Lightbulb />, title: 'Vision', text: 'To be the heartbeat of every Nepali home search, powered by trust and local heritage.' },
              { icon: <Heart />, title: 'Soul', text: 'At our core, we are about people. No commissions, no barriers, just the warmth of home.' }
            ].map((item, i) => (
              <motion.div key={i} variants={fadeIn} className="glass-card" style={{ padding: '5rem 3rem', borderRadius: '48px', background: 'white', textAlign: 'center' }}>
                <div style={{ width: '80px', height: '80px', background: 'var(--surface)', borderRadius: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 3rem', color: 'var(--primary)' }}>
                  {React.cloneElement(item.icon as React.ReactElement<{ size: number }>, { size: 36 })}
                </div>
                <h3 style={{ fontSize: '2rem', marginBottom: '1.5rem' }}>{item.title}</h3>
                <p style={{ color: 'var(--text-dim)', fontSize: '1.1rem', fontWeight: 300, lineHeight: '1.7' }}>{item.text}</p>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* The App Experience - Advanced UI */}
      <section id="app" style={{ padding: 'var(--spacing-section) 0', background: 'white' }}>
        <div className="container">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', alignItems: 'center', gap: '10rem' }}>
             <motion.div initial={{ x: -100, opacity: 0 }} whileInView={{ x: 0, opacity: 1 }} transition={{ duration: 1 }}>
                <div style={{ position: 'relative', width: '320px', height: '650px', background: '#020617', borderRadius: '54px', border: '12px solid #1E293B', boxShadow: '0 60px 120px rgba(0,0,0,0.2)', margin: '0 auto' }}>
                   <div style={{ position: 'absolute', top: '20px', left: '50%', transform: 'translateX(-50%)', width: '100px', height: '30px', background: '#1E293B', borderRadius: '20px' }} />
                   <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                      <motion.img 
                        animate={{ y: [0, -10, 0] }}
                        transition={{ duration: 4, repeat: Infinity }}
                        src="/logo.png" 
                        style={{ width: '100px', filter: 'brightness(0) invert(1)' }} 
                      />
                   </div>
                </div>
             </motion.div>
             <motion.div {...fadeIn}>
                <h2 style={{ fontSize: '5rem', marginBottom: '3rem' }}>Pure <br/><span className="text-gradient">Experience.</span></h2>
                <p style={{ fontSize: '1.3rem', color: 'var(--text-dim)', fontWeight: 300, marginBottom: '4rem', lineHeight: '1.6' }}>
                  Our mobile ecosystem is designed with the precision of a high-end timepiece. Every interaction is fluid, every verified listing is a promise kept. 
                </p>
                <div style={{ display: 'flex', gap: '4rem' }}>
                   <div>
                      <div style={{ fontSize: '2.5rem', fontWeight: 800 }}>Coming</div>
                      <div style={{ fontSize: '0.8rem', fontWeight: 900, color: 'var(--primary)', letterSpacing: '3px' }}>IOS APP</div>
                   </div>
                   <div>
                      <div style={{ fontSize: '2.5rem', fontWeight: 800 }}>Soon</div>
                      <div style={{ fontSize: '0.8rem', fontWeight: 900, color: 'var(--primary)', letterSpacing: '3px' }}>ANDROID</div>
                   </div>
                </div>
             </motion.div>
          </div>
        </div>
      </section>

      {/* Final Cinematic Contact */}
      <section id="contact" style={{ padding: 'var(--spacing-section) 0', background: 'var(--surface)' }}>
        <div className="culture-overlay" />
        <div className="container">
          <motion.div className="glass-card" style={{ background: '#020617', padding: '8rem 6rem', borderRadius: '64px', color: 'white', display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '6rem', alignItems: 'center' }}>
             <div>
                <h2 style={{ color: 'white', fontSize: '5rem', marginBottom: '2rem' }}>Let's <span style={{ color: 'var(--primary)' }}>Connect.</span></h2>
                <p style={{ fontSize: '1.4rem', color: 'rgba(255,255,255,0.6)', fontWeight: 300, marginBottom: '5rem' }}>Join the elite community of owners and seekers in Nepal.</p>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '3rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '2rem' }}>
                       <div style={{ width: '70px', height: '70px', borderRadius: '24px', background: 'rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Mail size={32} /></div>
                       <div style={{ fontSize: '1.4rem', fontWeight: 500 }}>hello@khozna.com</div>
                    </div>
                </div>
             </div>
             <div>
                <button className="glow-btn" style={{ width: '100%', background: 'var(--primary)', padding: '2rem', fontSize: '1rem' }}>Message Our Team</button>
                <div style={{ display: 'flex', justifyContent: 'center', gap: '3rem', marginTop: '4rem' }}>
                   <Facebook size={24} />
                   <Instagram size={24} />
                   <Twitter size={24} />
                </div>
             </div>
          </motion.div>
        </div>
      </section>

      {/* Minimalist Footer */}
      <footer style={{ padding: '8rem 0', background: 'white', textAlign: 'center' }}>
        <div className="container">
           <img src="/logo.png" style={{ height: '40px', marginBottom: '3rem', opacity: 0.8 }} />
           <p style={{ fontSize: '0.8rem', fontWeight: 900, letterSpacing: '4px', textTransform: 'uppercase', opacity: 0.3 }}>
             © 2026 KHOZNA BRAND. NEPAL'S PREMIER RENTAL ECOSYSTEM.
           </p>
        </div>
      </footer>
    </div>
  );
}

export default App;
