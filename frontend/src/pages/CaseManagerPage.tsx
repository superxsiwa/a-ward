import React, { useEffect, useRef, useState } from 'react';
import { BedCase, StageData, StudentLeaderboardEntry } from '../types/game';
import { Icon } from '../components/SvgIcons';
import { StepBuilderModal } from '../components/StepBuilderModal';
import { instructorApi } from '../api/client';
import { SFX } from '../engine/SFXEngine';

interface CaseManagerPageProps {
  beds: BedCase[];
  onOpenBed: (index: number) => void;
  onCreateCase: (payload: Partial<BedCase>) => Promise<void>;
  onUpdateCase: (bedNum: number, payload: Partial<BedCase>) => Promise<void>;
  onUpdateStep: (bedNum: number, stepIdx: number, stage: StageData) => Promise<void>;
  onDeleteCase: (bedNum: number) => Promise<void>;
  onImportCases: (cases: BedCase[]) => Promise<void>;
  onResetDefaultCases: () => Promise<void>;
  onExportCases: () => void;
  onToast: (msg: string) => void;
}

export const CaseManagerPage: React.FC<CaseManagerPageProps> = ({
  beds,
  onOpenBed,
  onCreateCase,
  onUpdateCase,
  onUpdateStep,
  onDeleteCase,
  onImportCases,
  onResetDefaultCases,
  onExportCases,
  onToast,
}) => {
  const [subTab, setSubTab] = useState<'cases' | 'leaderboard'>('cases');
  const [students, setStudents] = useState<StudentLeaderboardEntry[]>([]);
  const [loadingStudents, setLoadingStudents] = useState(false);

  // Case Editor Modal state
  const [editingCaseIdx, setEditingCaseIdx] = useState<number | null>(null);
  const [edBedNum, setEdBedNum] = useState(1);
  const [edStatus, setEdStatus] = useState<'stable' | 'alert' | 'critical'>('alert');
  const [edCaseTitle, setEdCaseTitle] = useState('');
  const [edPatientName, setEdPatientName] = useState('');
  const [edDxBadge, setEdDxBadge] = useState('');
  const [edDoctorName, setEdDoctorName] = useState('');
  const [edStatusText, setEdStatusText] = useState('');

  // Step Builder Modal state
  const [stepMgrBedIdx, setStepMgrBedIdx] = useState<number | null>(null);

  // Confirm Dialog state
  const [confirmState, setConfirmState] = useState<{
    title: string;
    text: string;
    yesLabel: string;
    onConfirm: () => Promise<void>;
  } | null>(null);

  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const fetchLeaderboard = async () => {
    setLoadingStudents(true);
    try {
      const res = await instructorApi.getStudents();
      setStudents(res.students || []);
    } catch {
      // ignore if offline
    } finally {
      setLoadingStudents(false);
    }
  };

  useEffect(() => {
    if (subTab === 'leaderboard') {
      fetchLeaderboard();
    }
  }, [subTab]);

  const openCaseEditor = (idx: number) => {
    SFX.pick();
    setEditingCaseIdx(idx);
    if (idx >= 0 && beds[idx]) {
      const b = beds[idx];
      setEdBedNum(b.bedNum);
      setEdStatus(b.status);
      setEdCaseTitle(b.caseTitle);
      setEdPatientName(b.patientName);
      setEdDxBadge(b.dxBadge);
      setEdDoctorName(b.doctorName);
      setEdStatusText(b.statusText);
    } else {
      setEdBedNum(beds.length + 1);
      setEdStatus('alert');
      setEdCaseTitle('หัตถการจำลองใหม่ CCU');
      setEdPatientName('นายใจดี มีสุข (65 ปี)');
      setEdDxBadge('Cardiogenic Assessment');
      setEdDoctorName('นพ. วิทยา (แพทย์ประจำบ้าน CCU)');
      setEdStatusText('เฝ้าระวังอาการ');
    }
  };

  const handleSaveCase = async () => {
    if (editingCaseIdx === null) return;
    SFX.pick();
    const payload: Partial<BedCase> = {
      bedNum: Number(edBedNum) || beds.length + 1,
      bedCode: `เตียง ${String(Number(edBedNum) || beds.length + 1).padStart(2, '0')} CCU`,
      caseTitle: edCaseTitle.trim() || 'เคสหัตถการใหม่',
      patientName: edPatientName.trim() || 'ผู้ป่วย CCU',
      dxBadge: edDxBadge.trim() || 'CCU Patient',
      doctorName: edDoctorName.trim() || 'แพทย์ CCU',
      status: edStatus,
      statusText: edStatusText.trim() || 'ดูแลตามแผนการรักษา',
    };

    try {
      if (editingCaseIdx >= 0 && beds[editingCaseIdx]) {
        await onUpdateCase(beds[editingCaseIdx].bedNum, payload);
      } else {
        await onCreateCase(payload);
      }
      setEditingCaseIdx(null);
      onToast('บันทึกข้อมูลเคสเรียบร้อยแล้ว ✨');
    } catch (err: any) {
      onToast(err.message || 'บันทึกเคสไม่สำเร็จ');
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = async (evt) => {
      try {
        const imported = JSON.parse(String(evt.target?.result || '[]'));
        if (Array.isArray(imported) && imported.length > 0 && imported[0].caseTitle) {
          await onImportCases(imported);
          onToast(`นำเข้าเคสสำเร็จทั้งหมด ${imported.length} เคส 🎉`);
        } else {
          onToast('รูปแบบไฟล์ JSON ไม่ถูกต้อง');
        }
      } catch {
        onToast('เกิดข้อผิดพลาดในการอ่านไฟล์ JSON');
      }
    };
    reader.readAsText(file);
    e.target.value = '';
  };

  return (
    <section className="page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
        <h2 className="page-h">📁 ระบบจัดการเคสคนไข้ & ผลการเรียน (Instructor Portal)</h2>
        <div style={{ display: 'flex', gap: 6 }}>
          <button
            type="button"
            className={`step-nav-pill ${subTab === 'cases' ? 'on' : ''}`}
            onClick={() => { SFX.pick(); setSubTab('cases'); }}
          >
            🛏️ จัดการเคส ({beds.length})
          </button>
          <button
            type="button"
            className={`step-nav-pill ${subTab === 'leaderboard' ? 'on' : ''}`}
            onClick={() => { SFX.pick(); setSubTab('leaderboard'); }}
          >
            🏆 ตารางคะแนนนักศึกษา
          </button>
        </div>
      </div>

      {subTab === 'leaderboard' ? (
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <b style={{ font: '700 15px var(--font-display)', color: 'var(--ink)' }}>
                🏆 ตารางความก้าวหน้านักศึกษาพยาบาล (Student Leaderboard)
              </b>
              <p className="hint" style={{ marginTop: 2 }}>
                ติดตามจำนวนดาว เคสที่ผ่าน และชั่วโมงบิน CCU ของผู้เรียนแบบ Real-time
              </p>
            </div>
            <button type="button" className="btn btn-sm btn-outline" onClick={fetchLeaderboard}>
              🔄 รีเฟรช
            </button>
          </div>

          <div className="leaderboard-wrap" style={{ marginTop: 8 }}>
            <table className="leaderboard-table">
              <thead>
                <tr>
                  <th>อันดับ</th>
                  <th>ชื่อ-นามสกุล</th>
                  <th>ระดับยศ</th>
                  <th>ดาวสะสม</th>
                  <th>เตียงที่ผ่าน</th>
                  <th>เคสสำเร็จ (3⭐)</th>
                  <th>เวรที่ผ่าน</th>
                  <th>เวลาเรียน</th>
                </tr>
              </thead>
              <tbody>
                {loadingStudents ? (
                  <tr><td colSpan={8} style={{ textAlign: 'center', padding: 18 }}>กำลังโหลดข้อมูลนักศึกษา...</td></tr>
                ) : students.length === 0 ? (
                  <tr><td colSpan={8} style={{ textAlign: 'center', padding: 18 }}>ยังไม่มีข้อมูลผู้เรียน</td></tr>
                ) : (
                  students.map((st, idx) => (
                    <tr key={st.id}>
                      <td><b>#{idx + 1}</b></td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <span>{st.avatar}</span>
                          <div>
                            <b>{st.displayName}</b>
                            <div style={{ fontSize: 10.5, color: 'var(--ink-3)' }}>{st.email}</div>
                          </div>
                        </div>
                      </td>
                      <td><span className="status-badge s-stable">Lv.{st.level} · {st.rankTitle}</span></td>
                      <td><b style={{ color: '#b45309' }}>⭐ {st.totalStars}</b></td>
                      <td>{st.passedBedsCount}/{beds.length} เตียง</td>
                      <td>{st.totalCompletedCases} ครั้ง ({st.perfectCases} Perfect)</td>
                      <td>{st.shiftsCompleted} เวร</td>
                      <td>{Math.max(1, Math.round(st.totalPlaySeconds / 60))} นาที</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <>
          <p className="hint" style={{ marginTop: -6, marginBottom: 4 }}>
            เพิ่ม แก้ไข หรือลบเคสหัตถการจำลองในวอร์ด CCU พร้อมแก้ไขโจทย์ 6 ขั้นตอนและส่งออก/นำเข้า JSON
          </p>

          <input
            ref={fileInputRef}
            type="file"
            accept=".json,application/json"
            style={{ display: 'none' }}
            onChange={handleFileChange}
          />

          <div className="case-mgr-toolbar">
            <button type="button" className="btn btn-sm btn-gold" onClick={() => openCaseEditor(-1)}>
              <Icon name="plus" />
              <span>เพิ่มเคสคนไข้ใหม่</span>
            </button>
            <button type="button" className="btn btn-sm btn-primary" onClick={onExportCases}>
              <Icon name="share" />
              <span>ส่งออกไฟล์ JSON</span>
            </button>
            <button type="button" className="btn btn-sm btn-outline" onClick={() => fileInputRef.current?.click()}>
              📥 นำเข้าไฟล์ JSON
            </button>
            <button
              type="button"
              className="btn btn-sm btn-outline"
              onClick={() =>
                setConfirmState({
                  title: 'คืนค่าเคสตั้งต้น?',
                  text: 'เคสทั้งหมดจะถูกรีเซ็ตกลับเป็น 8 เตียงมาตรฐานของ CCU',
                  yesLabel: 'คืนค่าเริ่มต้น',
                  onConfirm: async () => {
                    await onResetDefaultCases();
                    onToast('คืนค่าเคสมาตรฐาน CCU เรียบร้อย 🔄');
                  },
                })
              }
            >
              🔄 คืนค่าเคสตั้งต้น
            </button>
          </div>

          <div className="list case-list-grid">
            {beds.map((b, i) => (
              <div key={b.bedNum} className="case-item-card">
                <div className="case-item-top">
                  <div className="case-item-title">
                    <span style={{ fontSize: 18 }}>🛏️</span>
                    <b>เตียง {String(b.bedNum).padStart(2, '0')}: {b.caseTitle}</b>
                  </div>
                  <span className={`status-badge s-${b.status}`}>{b.statusText}</span>
                </div>
                <div className="case-item-meta">
                  <b>ผู้ป่วย:</b> {b.patientName} · <b>โรค:</b> {b.dxBadge}
                  <br />
                  <b>แพทย์:</b> {b.doctorName} · <b>จำนวนขั้นตอน:</b> {b.stageData?.length || 6} ขั้นตอน
                </div>
                <div className="case-item-actions">
                  <button type="button" className="btn btn-sm btn-ghost" onClick={() => onOpenBed(i)} title="ทดสอบเล่น">
                    <Icon name="play" />
                    <span>ทดสอบ</span>
                  </button>
                  <button
                    type="button"
                    className="btn btn-sm btn-gold"
                    onClick={() => { SFX.pick(); setStepMgrBedIdx(i); }}
                  >
                    <span>📝</span>
                    <span>จัดการขั้นตอน & คำตอบ</span>
                  </button>
                  <button type="button" className="btn btn-sm btn-primary" onClick={() => openCaseEditor(i)}>
                    <Icon name="edit" />
                    <span>ข้อมูลเคส</span>
                  </button>
                  {beds.length > 1 && (
                    <button
                      type="button"
                      className="btn btn-sm btn-danger"
                      onClick={() =>
                        setConfirmState({
                          title: 'ยืนยันการลบเคสนี้?',
                          text: `เคส "${b.caseTitle}" จะถูกนำออกจากวอร์ด CCU`,
                          yesLabel: 'ลบเคส',
                          onConfirm: async () => {
                            await onDeleteCase(b.bedNum);
                            onToast('ลบเคสเรียบร้อยแล้ว 🗑️');
                          },
                        })
                      }
                    >
                      <Icon name="trash" />
                      <span>ลบ</span>
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      {editingCaseIdx !== null && (
        <div
          className="modal show"
          role="dialog"
          aria-modal="true"
          onClick={(e) => {
            if (e.target === e.currentTarget) setEditingCaseIdx(null);
          }}
        >
          <div className="modal-card modal-card-lg">
            <div style={{ textAlign: 'left', maxHeight: '75vh', overflowY: 'auto', paddingRight: 4 }}>
              <h2 style={{ font: '700 17px var(--font-display)', marginTop: 0 }}>
                {editingCaseIdx >= 0 ? '✏️ แก้ไขเคสหัตถการ' : '➕ เพิ่มเคสหัตถการใหม่'}
              </h2>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 10 }}>
                <div className="form-row">
                  <div className="form-group">
                    <label>หมายเลขเตียง</label>
                    <input className="form-input" id="ed-bedNum" type="number" value={edBedNum} onChange={(e) => setEdBedNum(Number(e.target.value))} />
                  </div>
                  <div className="form-group">
                    <label>สถานะเตียง</label>
                    <select className="form-input" id="ed-status" value={edStatus} onChange={(e) => setEdStatus(e.target.value as 'stable' | 'alert' | 'critical')}>
                      <option value="alert">Alert (เฝ้าระวัง)</option>
                      <option value="critical">Critical (วิกฤต)</option>
                      <option value="stable">Stable (คงที่)</option>
                    </select>
                  </div>
                </div>

                <div className="form-group">
                  <label>ชื่อเคสหัตถการ</label>
                  <input className="form-input" id="ed-caseTitle" value={edCaseTitle} onChange={(e) => setEdCaseTitle(e.target.value)} />
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>ชื่อคนไข้ (และอายุ)</label>
                    <input className="form-input" id="ed-patientName" value={edPatientName} onChange={(e) => setEdPatientName(e.target.value)} />
                  </div>
                  <div className="form-group">
                    <label>ป้ายการวินิจฉัยโรค</label>
                    <input className="form-input" id="ed-dxBadge" value={edDxBadge} onChange={(e) => setEdDxBadge(e.target.value)} />
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>ชื่อแพทย์ผู้สั่งการ</label>
                    <input className="form-input" id="ed-doctorName" value={edDoctorName} onChange={(e) => setEdDoctorName(e.target.value)} />
                  </div>
                  <div className="form-group">
                    <label>ข้อความสถานะ</label>
                    <input className="form-input" id="ed-statusText" value={edStatusText} onChange={(e) => setEdStatusText(e.target.value)} />
                  </div>
                </div>

                <div className="hint" style={{ background: '#f8fafc', padding: '8px 10px', borderRadius: 10, border: '1px solid #e2e8f0' }}>
                  ℹ️ เคสใหม่จะได้รับชุดขั้นตอนพื้นฐาน 6 ขั้นตอนของ CCU โดยอัตโนมัติ ซึ่งสามารถนำไปใช้ฝึกการพยาบาลได้ทันที
                </div>
              </div>

              <div className="modal-actions" style={{ marginTop: 16, display: 'flex', gap: 8 }}>
                <button type="button" className="btn btn-primary" onClick={handleSaveCase}>
                  💾 บันทึกเคส
                </button>
                <button type="button" className="btn btn-ghost" onClick={() => setEditingCaseIdx(null)}>
                  ยกเลิก
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {stepMgrBedIdx !== null && beds[stepMgrBedIdx] && (
        <div
          className="modal show"
          role="dialog"
          aria-modal="true"
          onClick={(e) => {
            if (e.target === e.currentTarget) setStepMgrBedIdx(null);
          }}
        >
          <div className="modal-card modal-card-lg">
            <StepBuilderModal
              bed={beds[stepMgrBedIdx]}
              initialStepIdx={0}
              onSaveStep={onUpdateStep}
              onClose={() => setStepMgrBedIdx(null)}
              onToast={onToast}
            />
          </div>
        </div>
      )}

      {confirmState && (
        <div
          className="modal show"
          role="dialog"
          aria-modal="true"
          onClick={(e) => {
            if (e.target === e.currentTarget) setConfirmState(null);
          }}
        >
          <div className="modal-card">
            <h2 className="dialog-t" style={{ marginTop: 0 }}>
              {confirmState.title}
            </h2>
            <p className="dialog-p">{confirmState.text}</p>
            <div className="modal-actions">
              <button
                type="button"
                className="btn btn-danger"
                onClick={async () => {
                  const fn = confirmState.onConfirm;
                  setConfirmState(null);
                  await fn();
                }}
              >
                {confirmState.yesLabel}
              </button>
              <button type="button" className="btn btn-ghost" onClick={() => setConfirmState(null)}>
                ยกเลิก
              </button>
            </div>
          </div>
        </div>
      )}
    </section>
  );
};

