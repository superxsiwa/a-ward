import React from 'react';
import { PlayerSettings, UserProfile } from '../types/game';
import { Icon } from '../components/SvgIcons';

interface SettingsPageProps {
  user: UserProfile | null;
  settings: PlayerSettings;
  onToggleSetting: (key: 'sound' | 'haptics') => void;
  onOpenCaseMgmt: () => void;
  onExportCases: () => void;
  onResetAll: () => void;
  onLogout: () => void;
  onSwitchRoleDemo: (role: 'NURSE' | 'INSTRUCTOR') => void;
}

export const SettingsPage: React.FC<SettingsPageProps> = ({
  user,
  settings,
  onToggleSetting,
  onOpenCaseMgmt,
  onExportCases,
  onResetAll,
  onLogout,
  onSwitchRoleDemo,
}) => {
  return (
    <section className="page">
      <h2 className="page-h">ตั้งค่า & บัญชีผู้ใช้</h2>

      {user && (
        <div className="card" style={{ borderColor: '#bae6fd', background: '#fff' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div className="avatar" style={{ width: 42, height: 42, fontSize: 22 }}>
                {user.avatar || '👩‍⚕️'}
              </div>
              <div>
                <b style={{ font: '700 14.5px var(--font-display)', color: 'var(--ink)' }}>
                  {user.displayName}
                </b>
                <div style={{ fontSize: 11.5, color: 'var(--ink-3)' }}>
                  {user.email} · บทบาท:{' '}
                  <b style={{ color: user.role === 'INSTRUCTOR' ? '#b45309' : '#0284c7' }}>
                    {user.role === 'INSTRUCTOR' ? 'อาจารย์ (INSTRUCTOR)' : 'พยาบาล (NURSE)'}
                  </b>
                </div>
              </div>
            </div>
            <button type="button" className="btn btn-sm btn-ghost" onClick={onLogout}>
              ออกจากระบบ
            </button>
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 6 }}>
            <button
              type="button"
              className="btn btn-sm btn-outline"
              onClick={() =>
                onSwitchRoleDemo(user.role === 'INSTRUCTOR' ? 'NURSE' : 'INSTRUCTOR')
              }
            >
              🔄 สลับบัญชีสาธิตเป็น {user.role === 'INSTRUCTOR' ? '👩‍⚕️ พยาบาล (Nurse)' : '👨‍⚕️ อาจารย์ (Instructor)'}
            </button>
          </div>
        </div>
      )}

      <div className="card">
        <div className="setting">
          <div className="s-t">
            <b>🔊 เสียงเอฟเฟกต์</b>
            <small>เสียงตอนหยิบ วาง และผ่านด่าน</small>
          </div>
          <button
            type="button"
            className="switch"
            role="switch"
            aria-checked={settings.sound}
            onClick={() => onToggleSetting('sound')}
          />
        </div>
        <div className="setting">
          <div className="s-t">
            <b>📳 การสั่น</b>
            <small>สั่นเบาๆ เมื่อตอบถูก/ผิด (มือถือ)</small>
          </div>
          <button
            type="button"
            className="switch"
            role="switch"
            aria-checked={settings.haptics}
            onClick={() => onToggleSetting('haptics')}
          />
        </div>
      </div>

      <div className="card" style={{ borderColor: '#bae6fd', background: '#f0f9ff' }}>
        <div className="s-t">
          <b style={{ font: '700 15px var(--font-display)', color: '#0369a1' }}>
            📁 จัดการเคสหัตถการ & ตารางคะแนน (Instructor Portal)
          </b>
          <small className="hint" style={{ display: 'block', marginTop: 2 }}>
            เพิ่ม ลบ หรือแก้ไขเคสหัตถการในวอร์ด 6 ขั้นตอน นำเข้า/ส่งออกเคส และดูสถิตินักศึกษา
          </small>
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 6 }}>
          <button type="button" className="btn btn-sm btn-primary" onClick={onOpenCaseMgmt}>
            <Icon name="sliders" />
            <span>เปิดตัวจัดการเคส</span>
          </button>
          <button type="button" className="btn btn-sm btn-outline" onClick={onExportCases}>
            <Icon name="share" />
            <span>ส่งออก JSON</span>
          </button>
        </div>
      </div>

      <div className="card">
        <div className="s-t">
          <b style={{ font: '600 14px var(--font-display)' }}>ล้างความก้าวหน้า</b>
          <small className="hint" style={{ display: 'block', marginTop: 2 }}>
            ดาวและเตียงที่ผ่านแล้วจะถูกรีเซ็ตทั้งหมด
          </small>
        </div>
        <button type="button" className="btn btn-danger btn-sm" onClick={onResetAll}>
          ล้างข้อมูลทั้งหมด
        </button>
      </div>
      <p className="about">
        A-WARD CCU · Full-Stack Clinical Simulation
        <br />
        ซิงค์ข้อมูลอัตโนมัติกับฐานข้อมูลและรองรับการทำงานแบบออฟไลน์
      </p>
    </section>
  );
};
