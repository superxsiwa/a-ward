import React, { useState } from 'react';
import { authApi, setAuthToken } from '../api/client';
import { UserProfile } from '../types/game';
import { SFX } from '../engine/SFXEngine';

interface AuthPageProps {
  onAuthenticated: (user: UserProfile) => void;
  onToast: (msg: string) => void;
}

export const AuthPage: React.FC<AuthPageProps> = ({ onAuthenticated, onToast }) => {
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [email, setEmail] = useState('nurse@award.ccu');
  const [password, setPassword] = useState('password123');
  const [displayName, setDisplayName] = useState('พว. พิมพ์ชนก (พยาบาล CCU)');
  const [role, setRole] = useState<'NURSE' | 'INSTRUCTOR'>('NURSE');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (loading) return;
    setLoading(true);
    SFX.pick();
    try {
      const res =
        mode === 'login'
          ? await authApi.login(email, password)
          : await authApi.register({ email, password, displayName, role });
      setAuthToken(res.token);
      onToast(`ยินดีต้อนรับ ${res.user.displayName} ✨`);
      onAuthenticated(res.user);
    } catch (err: any) {
      SFX.bad();
      onToast(err.message || 'ไม่สามารถเข้าสู่ระบบได้');
    } finally {
      setLoading(false);
    }
  };

  const handleDemoLogin = async (demoEmail: string, demoPass: string) => {
    if (loading) return;
    setLoading(true);
    SFX.pick();
    try {
      const res = await authApi.login(demoEmail, demoPass);
      setAuthToken(res.token);
      onToast(`เข้าสู่ระบบสำเร็จ: ${res.user.displayName} ✨`);
      onAuthenticated(res.user);
    } catch (err: any) {
      SFX.bad();
      onToast(err.message || 'เข้าสู่ระบบสาธิตไม่สำเร็จ');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <div className="auth-card">
        <div className="auth-hero">
          <div style={{ fontSize: 32 }}>🩺🏥</div>
          <h1>Critical Care CCU</h1>
          <p>เกมจำลองการตัดสินใจทางคลินิกและการพยาบาลผู้ป่วยวิกฤตหัวใจ 8 เตียง</p>
        </div>

        <div>
          <label style={{ display: 'block', font: '700 12px var(--font-display)', color: 'var(--ink-2)', marginBottom: 6 }}>
            ⚡ เข้าใช้งานด่วน (1-Click Demo Login)
          </label>
          <div className="demo-login-grid">
            <button
              type="button"
              className="demo-btn"
              disabled={loading}
              onClick={() => handleDemoLogin('nurse@award.ccu', 'password123')}
              data-testid="demo-nurse-login"
            >
              <span style={{ fontSize: 22 }}>👩‍⚕️</span>
              <span>Demo พยาบาล (Nurse)</span>
              <small style={{ fontSize: 10, opacity: 0.75 }}>nurse@award.ccu</small>
            </button>
            <button
              type="button"
              className="demo-btn instructor"
              disabled={loading}
              onClick={() => handleDemoLogin('instructor@award.ccu', 'password123')}
              data-testid="demo-instructor-login"
            >
              <span style={{ fontSize: 22 }}>👨‍⚕️</span>
              <span>Demo อาจารย์ (Admin)</span>
              <small style={{ fontSize: 10, opacity: 0.75 }}>instructor@award.ccu</small>
            </button>
          </div>
        </div>

        <div style={{ display: 'flex', gap: 6, background: '#f1f5f9', padding: 4, borderRadius: 14 }}>
          <button type="button" className={`step-nav-pill ${mode === 'login' ? 'on' : ''}`} style={{ flex: 1 }} onClick={() => setMode('login')}>
            🔑 เข้าสู่ระบบ
          </button>
          <button type="button" className={`step-nav-pill ${mode === 'register' ? 'on' : ''}`} style={{ flex: 1 }} onClick={() => setMode('register')}>
            📝 สมัครสมาชิกใหม่
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {mode === 'register' && (
            <>
              <div className="form-group">
                <label>ชื่อ-นามสกุล / ชื่อที่แสดง</label>
                <input className="form-input" type="text" required value={displayName} onChange={(e) => setDisplayName(e.target.value)} />
              </div>
              <div className="form-group">
                <label>บทบาทผู้ใช้งาน (Role)</label>
                <select className="form-input" value={role} onChange={(e) => setRole(e.target.value as 'NURSE' | 'INSTRUCTOR')}>
                  <option value="NURSE">👩‍⚕️ พยาบาล / นักศึกษาพยาบาล (NURSE)</option>
                  <option value="INSTRUCTOR">👨‍⚕️ อาจารย์พยาบาล / ผู้ดูแลเคส (INSTRUCTOR)</option>
                </select>
              </div>
            </>
          )}

          <div className="form-group">
            <label>อีเมล (Email)</label>
            <input className="form-input" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>

          <div className="form-group">
            <label>รหัสผ่าน (Password)</label>
            <input className="form-input" type="password" required value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>

          <button type="submit" className="btn btn-primary btn-block" disabled={loading}>
            <span>{loading ? 'กำลังดำเนินการ...' : mode === 'login' ? 'เข้าสู่วอร์ด CCU ▶' : 'ยืนยันการสมัครสมาชิก ▶'}</span>
          </button>
        </form>
      </div>
    </div>
  );
};
