import React, { useEffect, useState, useRef } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';

// --- Text Reveal Component (Nike/Apple Style) ---
const TextReveal = ({ children, delay = 0 }: { children: React.ReactNode, delay?: number }) => {
  return (
    <span className="text-mask">
      <motion.span
        initial={{ y: "120%" }}
        whileInView={{ y: 0 }}
        viewport={{ once: true, margin: "-10%" }}
        transition={{ duration: 1, ease: [0.19, 1, 0.22, 1], delay }}
        style={{ display: 'inline-block' }}
      >
        {children}
      </motion.span>
    </span>
  );
};

function App() {
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  const [isHovering, setIsHovering] = useState(false);
  
  // For the sticky phone section
  const targetRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: targetRef,
    offset: ["start start", "end end"]
  });

  // Parallax effects for the sticky phone features
  const opacity1 = useTransform(scrollYProgress, [0, 0.2, 0.3], [1, 1, 0]);
  const y1 = useTransform(scrollYProgress, [0, 0.3], [0, -50]);

  const opacity2 = useTransform(scrollYProgress, [0.3, 0.5, 0.6], [0, 1, 0]);
  const y2 = useTransform(scrollYProgress, [0.3, 0.6], [50, -50]);

  const opacity3 = useTransform(scrollYProgress, [0.6, 0.8, 1], [0, 1, 1]);
  const y3 = useTransform(scrollYProgress, [0.6, 1], [50, 0]);

  // Image parallax inside the phone
  const phoneImgScale = useTransform(scrollYProgress, [0, 1], [1, 1.15]);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setMousePos({ x: e.clientX, y: e.clientY });
    };
    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return (
    <div style={{ background: 'var(--bg)', color: 'var(--text)' }}>
      {/* Magnetic Cursor */}
      <motion.div
        className="custom-cursor"
        animate={{
          x: mousePos.x,
          y: mousePos.y,
          scale: isHovering ? 4 : 1,
        }}
        transition={{ type: 'tween', ease: 'backOut', duration: 0.15 }}
      />

      {/* Ultra-Minimal Nav */}
      <nav className="glass-nav" style={{ position: 'fixed', top: 0, left: 0, width: '100%', padding: '1.5rem 3rem', zIndex: 1000, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div className="logo-box">
          <img src="/logo.png" style={{ height: '24px' }} alt="Khozna Logo" />
        </div>
        <div style={{ display: 'flex', gap: '3rem', fontSize: '0.8rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '2px' }}>
          <a href="#about" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)} style={{ color: 'white', textDecoration: 'none' }}>The Movement</a>
          <a href="#app" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)} style={{ color: 'white', textDecoration: 'none' }}>App</a>
        </div>
      </nav>

      {/* Hero Section - Massive Typography */}
      <section style={{ height: '100vh', display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '0 4rem', position: 'relative' }}>
        <div style={{ zIndex: 10 }}>
          <h1 className="hero-title">
            <TextReveal delay={0}>RENT</TextReveal><br />
            <TextReveal delay={0.1}>DIRECT.</TextReveal><br />
            <span style={{ color: 'var(--primary)' }}><TextReveal delay={0.2}>NO LIMITS.</TextReveal></span>
          </h1>
          <motion.div 
            initial={{ opacity: 0 }} 
            animate={{ opacity: 1 }} 
            transition={{ delay: 1, duration: 1 }}
            style={{ marginTop: '3rem', maxWidth: '500px' }}
          >
            <p style={{ fontSize: '1.2rem', color: 'var(--text-dim)', lineHeight: '1.6', fontWeight: 400, marginBottom: '2rem' }}>
              Nepal's first zero-commission ecosystem. We removed the middlemen to bring landlords and tenants face-to-face. Welcome to the future of living.
            </p>
            <button className="nike-btn" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>
              Explore App
            </button>
          </motion.div>
        </div>
        
        {/* Abstract Dark Hero Image/Texture */}
        <motion.div 
          initial={{ opacity: 0, scale: 1.1 }}
          animate={{ opacity: 0.4, scale: 1 }}
          transition={{ duration: 2, ease: "easeOut" }}
          style={{ position: 'absolute', top: 0, right: 0, width: '50%', height: '100%', zIndex: 1 }}
        >
           <img src="/rental_hero.png" style={{ width: '100%', height: '100%', objectFit: 'cover', filter: 'grayscale(100%) contrast(1.2)' }} alt="Hero Texture" />
           <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', background: 'linear-gradient(to right, #000, transparent, #000)' }} />
        </motion.div>
      </section>

      {/* Infinite Marquee Strip */}
      <div style={{ overflow: 'hidden', padding: '2rem 0', borderTop: '1px solid #333', borderBottom: '1px solid #333', background: '#050505', whiteSpace: 'nowrap', display: 'flex' }}>
         <motion.div 
           animate={{ x: [0, -1035] }}
           transition={{ ease: "linear", duration: 15, repeat: Infinity }}
           style={{ display: 'flex', gap: '3rem', fontSize: '1.5rem', fontWeight: 900, letterSpacing: '4px', textTransform: 'uppercase', color: 'var(--text-dim)' }}
         >
            <span>KHOZNA BRAND</span> • <span>ZERO COMMISSION</span> • <span>VERIFIED OWNERS</span> • <span>DIRECT CHAT</span> • <span>NEPAL STANDARD</span> • 
            <span>KHOZNA BRAND</span> • <span>ZERO COMMISSION</span> • <span>VERIFIED OWNERS</span> • <span>DIRECT CHAT</span> • <span>NEPAL STANDARD</span> •
         </motion.div>
      </div>

      {/* Sticky Scroll Section - Apple/Zomato Vibe */}
      <section ref={targetRef} id="app" style={{ height: '300vh', position: 'relative' }}>
         <div style={{ position: 'sticky', top: 0, height: '100vh', display: 'flex', alignItems: 'center', overflow: 'hidden' }}>
            <div className="container" style={{ width: '100%', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '4rem', alignItems: 'center' }}>
               
               {/* Left Side - Scrolling Features */}
               <div style={{ position: 'relative', height: '60vh', display: 'flex', alignItems: 'center' }}>
                  {/* Feature 1 */}
                  <motion.div style={{ position: 'absolute', opacity: opacity1, y: y1 }}>
                     <h2 className="section-title"><span style={{ color: 'var(--primary)' }}>01.</span><br/>Pure Trust.</h2>
                     <p style={{ fontSize: '1.5rem', color: 'var(--text-dim)', marginTop: '2rem', maxWidth: '400px' }}>Every property and owner is strictly verified. We filter the noise so you find reality.</p>
                  </motion.div>

                  {/* Feature 2 */}
                  <motion.div style={{ position: 'absolute', opacity: opacity2, y: y2 }}>
                     <h2 className="section-title"><span style={{ color: 'var(--primary)' }}>02.</span><br/>Direct Connect.</h2>
                     <p style={{ fontSize: '1.5rem', color: 'var(--text-dim)', marginTop: '2rem', maxWidth: '400px' }}>Cut the brokers. Chat instantly with landlords directly inside the Khozna app.</p>
                  </motion.div>

                  {/* Feature 3 */}
                  <motion.div style={{ position: 'absolute', opacity: opacity3, y: y3 }}>
                     <h2 className="section-title"><span style={{ color: 'var(--primary)' }}>03.</span><br/>Zero Fees.</h2>
                     <p style={{ fontSize: '1.5rem', color: 'var(--text-dim)', marginTop: '2rem', maxWidth: '400px' }}>100% Commission free forever. Your money belongs to you, not the middlemen.</p>
                  </motion.div>
               </div>

               {/* Right Side - Sticky Phone Mockup */}
               <div style={{ display: 'flex', justifyContent: 'center' }}>
                  <div className="phone-frame">
                     <div className="phone-notch" />
                     <motion.div style={{ width: '100%', height: '100%', background: '#111', display: 'flex', flexDirection: 'column' }}>
                        <motion.img 
                           src="/rental_hero.png" 
                           style={{ width: '100%', height: '50%', objectFit: 'cover', scale: phoneImgScale }} 
                        />
                        <div style={{ padding: '2rem' }}>
                           <div style={{ width: '40px', height: '40px', background: 'var(--primary)', borderRadius: '10px', marginBottom: '1rem' }} />
                           <div style={{ width: '100%', height: '20px', background: '#333', borderRadius: '4px', marginBottom: '0.5rem' }} />
                           <div style={{ width: '70%', height: '20px', background: '#333', borderRadius: '4px' }} />
                        </div>
                        <div style={{ marginTop: 'auto', padding: '1rem', background: '#000', display: 'flex', justifyContent: 'space-around', borderTop: '1px solid #333' }}>
                           {[1,2,3,4].map(i => <div key={i} style={{ width: '24px', height: '24px', background: '#333', borderRadius: '50%' }} />)}
                        </div>
                     </motion.div>
                  </div>
               </div>

            </div>
         </div>
      </section>

      {/* Massive Call to Action */}
      <section style={{ height: '80vh', display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center', background: 'var(--primary)' }}>
         <div className="container">
            <h2 style={{ fontSize: 'clamp(3rem, 10vw, 8rem)', fontWeight: 900, textTransform: 'uppercase', color: 'white', lineHeight: 0.9, marginBottom: '3rem' }}>
               The Wait <br/> is Over.
            </h2>
            <button className="nike-btn" style={{ background: 'black', color: 'white' }} onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>
               Download Soon
            </button>
         </div>
      </section>

      {/* Minimal Footer */}
      <footer style={{ padding: '6rem 4rem', background: '#000', borderTop: '1px solid #222', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
         <div>
            <img src="/logo.png" style={{ height: '30px', marginBottom: '1rem' }} alt="Logo" />
            <div style={{ color: 'var(--text-dim)', fontSize: '0.8rem', fontWeight: 600, letterSpacing: '2px' }}>NEPAL'S #1 PLATFORM</div>
         </div>
         <div style={{ display: 'flex', gap: '3rem', fontSize: '0.9rem', fontWeight: 600, textTransform: 'uppercase' }}>
            <a href="#" style={{ color: 'white', textDecoration: 'none' }}>Instagram</a>
            <a href="#" style={{ color: 'white', textDecoration: 'none' }}>Facebook</a>
            <a href="#" style={{ color: 'white', textDecoration: 'none' }}>Contact</a>
         </div>
      </footer>
    </div>
  );
}

export default App;
