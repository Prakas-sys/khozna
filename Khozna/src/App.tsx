import React, { useEffect, useState, useRef } from 'react';
import { motion } from 'framer-motion';
import { Shield, MapPin, Users, ArrowUpRight, Play, Heart, Target, Lightbulb, Mail, MessageCircle, Instagram, Facebook, Twitter } from 'lucide-react';

function App() {
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  const [isHovering, setIsHovering] = useState(false);
  const heroRef = useRef(null);


  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setMousePos({ x: e.clientX, y: e.clientY });
    };
    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return (
    <div className="app-container" style={{ background: 'var(--bg)', color: 'var(--text)' }}>
      {/* Custom Cursor */}
      <motion.div
        className="custom-cursor"
        animate={{
          x: mousePos.x - 10,
          y: mousePos.y - 10,
          scale: isHovering ? 4 : 1,
        }}
        transition={{ type: 'spring', stiffness: 500, damping: 28, mass: 0.5 }}
      />

      {/* Navigation */}
      <motion.nav
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        className="glass-card"
        style={{
          position: 'fixed',
          top: '2rem',
          left: '50%',
          transform: 'translateX(-50%)',
          width: '90%',
          padding: '1rem 2rem',
          borderRadius: '100px',
          zIndex: 1000,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          backgroundColor: 'rgba(255, 255, 255, 0.9)'
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div className="logo-container">
            <img src="/logo.png" style={{ height: '32px' }} alt="Logo" />
          </div>
          <span style={{ fontWeight: 800, fontSize: '1.2rem', letterSpacing: '1px', color: 'var(--text)', fontFamily: 'var(--font-heading)' }}>KHOZNA</span>
        </div>
        <div style={{ display: 'flex', gap: '3rem', fontSize: '0.9rem', fontWeight: 600, color: 'var(--text)' }}>
          <a href="#about" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>Our Story</a>
          <a href="#mission" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>Mission</a>
          <a href="#vision" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>Vision</a>
          <a href="#app" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>The App</a>
        </div>
        <button className="glow-btn" style={{ padding: '0.6rem 1.5rem', fontSize: '0.8rem' }} onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>
          Download App
        </button>
      </motion.nav>

      {/* Hero Section */}
      <section ref={heroRef} style={{ height: '100vh', perspective: '1000px', background: 'var(--bg)' }}>
        <div className="parallax-bg" />
        <div className="container">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', alignItems: 'center', gap: '4rem' }}>
            <motion.div
              initial={{ opacity: 0, x: -50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 1, ease: "easeOut" }}
            >
              <motion.div
                style={{
                  background: 'rgba(0, 163, 225, 0.1)',
                  display: 'inline-block',
                  padding: '0.5rem 1rem',
                  borderRadius: '100px',
                  border: '1px solid rgba(0, 163, 225, 0.2)',
                  marginBottom: '2rem',
                  fontSize: '0.8rem',
                  fontWeight: 700,
                  color: 'var(--primary)',
                  letterSpacing: '1px'
                }}
              >
                #1 DIRECT RENTAL PLATFORM IN NEPAL 🇳🇵
              </motion.div>
              <h1 style={{ fontSize: 'clamp(3.5rem, 8vw, 6.5rem)', marginBottom: '1.5rem' }}>
                Rent <br />
                <span className="text-gradient">Direct.</span>
              </h1>
              <p style={{ fontSize: '1.3rem', color: 'var(--text-dim)', maxWidth: '530px', marginBottom: '3.5rem', lineHeight: '1.4' }}>
                Join the most trusted community finding rooms, flats, and houses directly from owners.
                No commissions. No middlemen. Just perfect matches.
              </p>
              <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'center' }}>
                <button className="glow-btn" onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>
                  Explore Listings <ArrowUpRight size={20} style={{ marginLeft: '8px' }} />
                </button>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', cursor: 'pointer', color: 'var(--text)' }} onMouseEnter={() => setIsHovering(true)} onMouseLeave={() => setIsHovering(false)}>
                  <div style={{
                    width: '50px',
                    height: '50px',
                    borderRadius: '50%',
                    background: 'var(--primary)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <Play size={20} fill="white" color="white" />
                  </div>
                  <span style={{ fontSize: '0.9rem', fontWeight: 600 }}>Watch How it Works</span>
                </div>
              </div>
            </motion.div>

            {/* 3D Floating Element */}
            <motion.div
              style={{
                position: 'relative',
                width: '100%',
                height: '550px',
              }}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 1.5, delay: 0.5 }}
            >
              <motion.div
                animate={{
                  y: [0, -15, 0],
                  rotateY: [0, 3, 0],
                  rotateX: [0, -3, 0]
                }}
                transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
                className="glass-card"
                style={{
                  width: '95%',
                  height: '100%',
                  borderRadius: '32px',
                  background: 'white',
                  padding: '2rem',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'flex-end',
                  overflow: 'hidden',
                  border: '8px solid white',
                  boxShadow: '0 40px 100px rgba(0, 163, 225, 0.15)'
                }}
              >
                <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', zIndex: -1 }}>
                  <img src="/rental_hero.png" style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="Traditional Nepali Rental Room" />
                </div>
                <div style={{
                  background: 'rgba(255, 255, 255, 0.95)',
                  padding: '1.5rem',
                  borderRadius: '20px',
                  backdropFilter: 'blur(10px)',
                  boxShadow: '0 10px 30px rgba(0,0,0,0.1)'
                }}>
                  <h2 style={{ fontSize: '1.8rem', marginBottom: '0.5rem', color: 'var(--text)' }}>Modern Tradition.</h2>
                  <p style={{ fontSize: '0.9rem', color: 'var(--text-dim)' }}>Premium living spaces verified by Khozna.</p>
                </div>
              </motion.div>

              {/* Floating Stat Bars */}
              <motion.div
                animate={{ y: [0, 10, 0] }}
                transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
                className="glass-card"
                style={{
                  position: 'absolute',
                  top: '10%',
                  right: '-2%',
                  padding: '1.2rem 2rem',
                  borderRadius: '20px',
                  background: 'white',
                  boxShadow: '0 20px 40px rgba(0, 163, 225, 0.12)',
                  border: '1px solid rgba(0, 163, 225, 0.1)'
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <Shield color="var(--primary)" size={24} />
                  <div>
                    <div style={{ fontSize: '0.7rem', opacity: 0.6, fontWeight: 800, letterSpacing: '1px' }}>VERIFIED</div>
                    <div style={{ fontWeight: 800, color: 'var(--text)' }}>OWNER LISTED</div>
                  </div>
                </div>
              </motion.div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* About Section - Our Story */}
      <section id="about" style={{ padding: 'var(--spacing-xl) 0', background: 'white' }}>
        <div className="container">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', alignItems: 'center', gap: '6rem' }}>
             <motion.div
              initial={{ opacity: 0, x: -30 }}
              whileInView={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.8 }}
            >
              <img src="/man_illustrate.png" style={{ width: '100%', borderRadius: '40px' }} alt="Our Story" />
            </motion.div>
            <div>
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
              >
                <h2 style={{ fontSize: '3.5rem', marginBottom: '2rem' }}>Our <span className="text-gradient">Story.</span></h2>
                <p style={{ fontSize: '1.2rem', color: 'var(--text-dim)', marginBottom: '2rem', lineHeight: '1.6' }}>
                  Khozna was born out of a simple observation: finding a home in Nepal should be a moment of joy, not a stressful ordeal of high commissions and unreliable middlemen.
                </p>
                <p style={{ fontSize: '1.2rem', color: 'var(--text-dim)', marginBottom: '2rem', lineHeight: '1.6' }}>
                  We built a bridge directly between property owners and seekers. By removing the barriers, we've created a community where trust and transparency are the standard, not the exception.
                </p>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', marginTop: '3rem' }}>
                   <div>
                      <div style={{ fontSize: '2.5rem', fontWeight: 800, color: 'var(--primary)' }}>100%</div>
                      <div style={{ fontSize: '0.9rem', fontWeight: 600, opacity: 0.7 }}>Commission Free</div>
                   </div>
                   <div>
                      <div style={{ fontSize: '2.5rem', fontWeight: 800, color: 'var(--primary)' }}>Verified</div>
                      <div style={{ fontSize: '0.9rem', fontWeight: 600, opacity: 0.7 }}>Property Listings</div>
                   </div>
                </div>
              </motion.div>
            </div>
          </div>
        </div>
      </section>

      {/* Mission & Vision Section */}
      <section style={{ padding: 'var(--spacing-xl) 0', background: 'var(--surface)' }}>
        <div className="container">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '4rem' }}>
            {/* Mission */}
            <motion.div
              id="mission"
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              className="glass-card"
              style={{ padding: '4rem', borderRadius: '40px', background: 'white' }}
            >
              <div style={{ width: '60px', height: '60px', background: 'var(--primary-glow)', borderRadius: '15px', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '2rem', color: 'var(--primary)' }}>
                <Target size={32} />
              </div>
              <h2 style={{ fontSize: '2.5rem', marginBottom: '1.5rem' }}>Our <span className="text-gradient">Mission.</span></h2>
              <p style={{ fontSize: '1.1rem', color: 'var(--text-dim)', lineHeight: '1.7' }}>
                To revolutionize the rental ecosystem in Nepal by providing a direct, transparent, and commission-free platform. We empower owners and tenants to connect with confidence and ease.
              </p>
            </motion.div>

            {/* Vision */}
            <motion.div
              id="vision"
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="glass-card"
              style={{ padding: '4rem', borderRadius: '40px', background: 'white' }}
            >
              <div style={{ width: '60px', height: '60px', background: 'var(--primary-glow)', borderRadius: '15px', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '2rem', color: 'var(--primary)' }}>
                <Lightbulb size={32} />
              </div>
              <h2 style={{ fontSize: '2.5rem', marginBottom: '1.5rem' }}>Our <span className="text-gradient">Vision.</span></h2>
              <p style={{ fontSize: '1.1rem', color: 'var(--text-dim)', lineHeight: '1.7' }}>
                To become Nepal's #1 trusted destination for finding homes. We envision a future where every Nepali can find their perfect living space through a click, backed by a community of verified users.
              </p>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Values Section */}
      <section style={{ padding: 'var(--spacing-xl) 0', background: 'white' }}>
        <div className="container">
           <div style={{ textAlign: 'center', marginBottom: '6rem' }}>
            <h2 style={{ fontSize: '3.5rem' }}>The Khozna <span className="text-gradient">Values.</span></h2>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '3rem' }}>
            {[
              { icon: <Shield />, title: 'Integrity', desc: 'We verify every listing to ensure what you see is what you get.' },
              { icon: <Heart />, title: 'Community', desc: 'Built for the people of Nepal, by the people who understand the local struggle.' },
              { icon: <Users />, title: 'Directness', desc: 'No middlemen, no hidden fees. Just direct communication between you and the owner.' }
            ].map((value, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, scale: 0.9 }}
                whileInView={{ opacity: 1, scale: 1 }}
                transition={{ delay: i * 0.1 }}
                style={{ textAlign: 'center', padding: '2rem' }}
              >
                <div style={{ color: 'var(--primary)', marginBottom: '1.5rem', display: 'flex', justifyContent: 'center' }}>
                  {React.cloneElement(value.icon as React.ReactElement<{ size: number }>, { size: 40 })}
                </div>
                <h3 style={{ fontSize: '1.5rem', marginBottom: '1rem' }}>{value.title}</h3>
                <p style={{ color: 'var(--text-dim)' }}>{value.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Contact & Support Section */}
      <section id="contact" style={{ padding: 'var(--spacing-xl) 0', background: 'var(--surface)' }}>
        <div className="container">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8rem', alignItems: 'center' }}>
            <div>
              <h2 style={{ fontSize: '3.5rem', marginBottom: '2rem' }}>Connect <br /><span className="text-gradient">With Us.</span></h2>
              <p style={{ fontSize: '1.2rem', color: 'var(--text-dim)', marginBottom: '3rem' }}>
                Have questions or need support? Our team is here to help you navigate your rental journey.
              </p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                 <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
                    <div style={{ width: '50px', height: '50px', borderRadius: '50%', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)', boxShadow: '0 10px 20px rgba(0,0,0,0.05)' }}>
                       <Mail size={24} />
                    </div>
                    <div>
                       <div style={{ fontSize: '0.8rem', fontWeight: 800, opacity: 0.5 }}>EMAIL US</div>
                       <div style={{ fontWeight: 700 }}>hello@khozna.com</div>
                    </div>
                 </div>
                 <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
                    <div style={{ width: '50px', height: '50px', borderRadius: '50%', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)', boxShadow: '0 10px 20px rgba(0,0,0,0.05)' }}>
                       <MessageCircle size={24} />
                    </div>
                    <div>
                       <div style={{ fontSize: '0.8rem', fontWeight: 800, opacity: 0.5 }}>SUPPORT</div>
                       <div style={{ fontWeight: 700 }}>Live Chat via App</div>
                    </div>
                 </div>
              </div>
            </div>
            <motion.div
               initial={{ opacity: 0, scale: 0.9 }}
               whileInView={{ opacity: 1, scale: 1 }}
               style={{ background: 'white', padding: '3rem', borderRadius: '40px', boxShadow: '0 30px 60px rgba(0,163,225,0.05)' }}
            >
               <h3 style={{ fontSize: '1.8rem', marginBottom: '2rem' }}>Send a Message</h3>
               <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                  <input type="text" placeholder="Your Name" style={{ width: '100%', padding: '1.2rem', borderRadius: '15px', border: '1px solid #E2E8F0', background: 'var(--surface)', fontFamily: 'inherit' }} />
                  <input type="email" placeholder="Your Email" style={{ width: '100%', padding: '1.2rem', borderRadius: '15px', border: '1px solid #E2E8F0', background: 'var(--surface)', fontFamily: 'inherit' }} />
                  <textarea placeholder="How can we help?" rows={4} style={{ width: '100%', padding: '1.2rem', borderRadius: '15px', border: '1px solid #E2E8F0', background: 'var(--surface)', fontFamily: 'inherit', resize: 'none' }}></textarea>
                  <button className="glow-btn" style={{ width: '100%' }}>Send Message</button>
               </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* App Coming Soon Section */}
      <section id="app" style={{ padding: 'var(--spacing-xl) 0', background: 'white' }}>
        <div className="container">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', alignItems: 'center', gap: '8rem' }}>
            <div style={{ perspective: '1000px' }}>
              <motion.div
                whileHover={{ rotateY: 10, rotateX: -5 }}
                transition={{ type: "spring", stiffness: 200, damping: 20 }}
                style={{
                  width: '300px',
                  height: '600px',
                  background: '#F8FAFC',
                  borderRadius: '44px',
                  border: '12px solid #E2E8F0',
                  boxShadow: '0 40px 80px rgba(0, 163, 225, 0.1)',
                  margin: '0 auto',
                  position: 'relative',
                  overflow: 'hidden'
                }}
              >
                <div style={{
                  position: 'absolute',
                  top: '0',
                  left: '0',
                  width: '100%',
                  height: '100%',
                  background: 'linear-gradient(rgba(0,163,225,0.05), transparent)',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <motion.img
                    animate={{ scale: [1, 1.05, 1] }}
                    transition={{ duration: 3, repeat: Infinity }}
                    src="/logo.png"
                    style={{ width: '80px' }}
                  />
                  <h3 style={{ marginTop: '2rem', letterSpacing: '4px', fontSize: '1.2rem', opacity: 0.6, color: 'var(--text)' }}>KHOZNA</h3>
                </div>
              </motion.div>
            </div>
            <div>
              <h2 style={{ fontSize: '4rem', marginBottom: '2rem' }}>Experience <br /><span className="text-gradient">The App.</span></h2>
              <p style={{ fontSize: '1.2rem', color: 'var(--text-dim)', marginBottom: '3.5rem' }}>
                Join the fast lane to finding your perfect home. The mobile
                experience is coming to give you verified freedom on the go.
              </p>
              <div style={{ display: 'flex', gap: '3rem' }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '2rem', fontWeight: 800, color: 'var(--primary)' }}>iOS</div>
                  <div style={{ fontSize: '0.7rem', fontWeight: 700, opacity: 0.5, letterSpacing: '1px' }}>SOON</div>
                </div>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '2rem', fontWeight: 800, color: 'var(--primary)' }}>Droid</div>
                  <div style={{ fontSize: '0.7rem', fontWeight: 700, opacity: 0.5, letterSpacing: '1px' }}>SOON</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer style={{ padding: '6rem 0', background: 'var(--surface)', borderTop: '1px solid rgba(0, 163, 225, 0.05)', textAlign: 'center' }}>
        <div className="container">
          <img src="/logo.png" style={{ height: '36px', marginBottom: '2rem' }} />
          <div style={{ display: 'flex', justifyContent: 'center', gap: '2rem', marginBottom: '2rem', fontSize: '0.9rem', fontWeight: 600, color: 'var(--text-dim)' }}>
            <a href="#about">About</a>
            <a href="#mission">Mission</a>
            <a href="#vision">Vision</a>
            <a href="#contact">Contact</a>
            <a href="#">Privacy</a>
            <a href="#">Terms</a>
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', gap: '1.5rem', marginBottom: '3rem' }}>
             <a href="#" style={{ color: 'var(--text-dim)' }}><Facebook size={20} /></a>
             <a href="#" style={{ color: 'var(--text-dim)' }}><Instagram size={20} /></a>
             <a href="#" style={{ color: 'var(--text-dim)' }}><Twitter size={20} /></a>
          </div>
          <p style={{ fontSize: '0.85rem', fontWeight: 600, letterSpacing: '1px', textTransform: 'uppercase', opacity: 0.5 }}>
            © 2026 KHOZNA BRAND. NEPAL'S PREMIER RENTAL ECOSYSTEM.
          </p>
        </div>
      </footer>
    </div>
  );
}

export default App;
