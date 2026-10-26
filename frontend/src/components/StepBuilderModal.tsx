import React, { useEffect, useState } from 'react';
import { BedCase, StageData } from '../types/game';
import { EQUIPMENT_ICONS } from '../engine/MilestoneDefs';
import { SFX } from '../engine/SFXEngine';

interface StepBuilderModalProps {
  bed: BedCase;
  initialStepIdx: number;
  onSaveStep: (bedNum: number, stepIdx: number, updatedStage: StageData) => Promise<void>;
  onClose: () => void;
  onToast: (msg: string) => void;
}

type MechanicMode = 'choices_seq' | 'trays' | 'unordered' | 'sequence';

function detectMode(st: StageData): MechanicMode {
  if (st.choices1toN) return 'choices_seq';
  if (st.traysTask) return 'trays';
  if (st.unorderedDropTask) return 'unordered';
  return 'sequence';
}

export const StepBuilderModal: React.FC<StepBuilderModalProps> = ({
  bed,
  initialStepIdx,
  onSaveStep,
  onClose,
  onToast,
}) => {
  const [stepIdx, setStepIdx] = useState(initialStepIdx);
  const stages = bed.stageData || [];
  const currentStage = stages[stepIdx] || stages[0];

  const [name, setName] = useState('');
  const [mechanic, setMechanic] = useState('');
  const [mode, setMode] = useState<MechanicMode>('sequence');
  const [docSpeech, setDocSpeech] = useState('');
  const [reading, setReading] = useState('');
  const [hr, setHr] = useState(80);
  const [bp, setBp] = useState('120/80');
  const [spo2, setSpo2] = useState('99%');
  const [mapVal, setMapVal] = useState(93);
  const [prompt, setPrompt] = useState('');
  const [rows, setRows] = useState<
    Array<{ id: string; text: string; correct: boolean; trayId: string; order: number; img: string }>
  >([]);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!currentStage) return;
    setName(currentStage.name || '');
    setMechanic(currentStage.mechanic || 'ลาก-วาง เรียงลำดับ');
    const m = detectMode(currentStage);
    setMode(m);
    setDocSpeech((currentStage.doctorSpeech || '').replace(/^💬\s*"?|"?$/g, ''));
    setReading(currentStage.reading || '');
    setHr(currentStage.vitals?.hr ?? 80);
    setBp(currentStage.vitals?.bp ?? '120/80');
    setSpo2(currentStage.vitals?.spo2 ?? '99%');
    setMapVal(currentStage.vitals?.map ?? 93);

    if (m === 'choices_seq' && currentStage.choices1toN) {
      setPrompt(currentStage.choices1toN.prompt || '');
      setRows(
        (currentStage.choices1toN.options || []).map((o, i) => ({
          id: o.id,
          text: o.text,
          correct: !!o.correct,
          trayId: '',
          order: i + 1,
          img: '',
        }))
      );
    } else if (m === 'trays' && currentStage.traysTask) {
      const tsk = currentStage.traysTask;
      const trays = tsk.trays || [];
      setPrompt(tsk.prompt || '');
      setRows(
        (tsk.pool || []).map((it, i) => {
          let targetTrayId = trays[0]?.id || 'tr1';
          trays.forEach((tr) => {
            if (tr.expectedIds?.includes(it.id) || tr.expectedOrder?.includes(it.id)) {
              targetTrayId = tr.id;
            }
          });
          return {
            id: it.id,
            text: it.text,
            correct: true,
            trayId: targetTrayId,
            order: i + 1,
            img: it.img || '',
          };
        })
      );
    } else if (m === 'unordered' && currentStage.unorderedDropTask) {
      const tsk = currentStage.unorderedDropTask;
      setPrompt(tsk.prompt || '');
      setRows(
        (tsk.pool || []).map((it, i) => ({
          id: it.id,
          text: it.text,
          correct: (tsk.expectedIds || []).includes(it.id),
          trayId: '',
          order: i + 1,
          img: it.img || '',
        }))
      );
    } else {
      const tsk = currentStage.sequenceTask;
      const orderArr = tsk?.correctOrder || [];
      setPrompt(tsk?.prompt || '');
      setRows(
        (tsk?.pool || []).map((it, i) => {
          const idx = orderArr.indexOf(it.id);
          return {
            id: it.id,
            text: it.text,
            correct: true,
            trayId: '',
            order: idx >= 0 ? idx + 1 : i + 1,
            img: it.img || '',
          };
        })
      );
    }
  }, [stepIdx, bed.bedNum]);

  const traysList = currentStage?.traysTask?.trays || [
    { id: 'tr1', name: '🟩 ถาดปลอดเชื้อ (Sterile Tray)', sterile: true, expectedIds: [] },
    { id: 'tr2', name: '🟦 ถาดทั่วไปข้างเตียง (General Tray)', sterile: false, expectedIds: [] },
  ];

  const handleModeChange = (newMode: MechanicMode) => {
    setMode(newMode);
    if (newMode === 'choices_seq') setMechanic('เลือก 1|N + เรียงลำดับ');
    else if (newMode === 'trays') setMechanic('จัด 2 ถาด (ไม่เรียงลำดับ)');
    else if (newMode === 'unordered') setMechanic('ลาก-วาง ไม่เป็นลำดับ');
    else setMechanic(stepIdx === 5 ? 'สรุป ISBAR เรียงลำดับ' : 'ลาก-วาง เรียงลำดับ');
  };

  const handleAddRow = () => {
    SFX.pick();
    setRows((prev) => [
      ...prev,
      {
        id: `item_${Date.now()}_${prev.length}`,
        text: '',
        correct: true,
        trayId: traysList[0]?.id || 'tr1',
        order: prev.length + 1,
        img: '',
      },
    ]);
  };

  const handleRemoveRow = (idx: number) => {
    SFX.pick();
    if (rows.length <= 1) {
      onToast('ต้องมีตัวเลือกอย่างน้อย 1 ข้อ');
      return;
    }
    setRows((prev) => prev.filter((_, i) => i !== idx));
  };

  const handleSave = async () => {
    if (saving) return;
    const validRows = rows.filter((r) => r.text.trim().length > 0);
    if (validRows.length === 0) {
      onToast('กรุณาระบุข้อความตัวเลือกอย่างน้อย 1 ข้อ');
      return;
    }

    const updated: StageData = {
      ...currentStage,
      id: currentStage.id || stepIdx + 1,
      name: name.trim() || currentStage.name,
      mechanic: mechanic.trim() || currentStage.mechanic,
      doctorSpeech: docSpeech.trim() ? `💬 "${docSpeech.trim()}"` : currentStage.doctorSpeech,
      reading: reading.trim() || currentStage.reading,
      vitals: {
        hr: Number(hr) || 80,
        bp: bp.trim() || '120/80',
        spo2: spo2.trim() || '99%',
        map: Number(mapVal) || 93,
      },
    };

    if (mode === 'choices_seq') {
      updated.choices1toN = {
        prompt: prompt.trim() || 'เลือกตัวเลือกที่ถูกต้อง',
        options: validRows.map((r, i) => ({
          id: r.id || `c_${Date.now()}_${i}`,
          text: r.text.trim(),
          correct: r.correct,
        })),
      };
    } else if (mode === 'trays') {
      const trayBuckets: Record<string, string[]> = {};
      traysList.forEach((t) => {
        trayBuckets[t.id] = [];
      });
      const newPool = validRows.map((r, i) => {
        const id = r.id || `t_${Date.now()}_${i}`;
        const tId = trayBuckets[r.trayId] ? r.trayId : traysList[0].id;
        trayBuckets[tId].push(id);
        return { id, text: r.text.trim(), ...(r.img ? { img: r.img } : {}) };
      });
      updated.traysTask = {
        ordered: currentStage.traysTask?.ordered ?? false,
        prompt: prompt.trim() || 'หยิบอุปกรณ์ลงในถาดให้ถูกต้อง',
        pool: newPool,
        trays: traysList.map((tr) => ({
          ...tr,
          ...(currentStage.traysTask?.ordered
            ? { expectedOrder: trayBuckets[tr.id] || [] }
            : { expectedIds: trayBuckets[tr.id] || [] }),
        })),
      };
      delete updated.choices1toN;
      delete updated.unorderedDropTask;
      delete updated.sequenceTask;
    } else if (mode === 'unordered') {
      const expectedIds: string[] = [];
      const newPool = validRows.map((r, i) => {
        const id = r.id || `u_${Date.now()}_${i}`;
        if (r.correct) expectedIds.push(id);
        return { id, text: r.text.trim() };
      });
      updated.unorderedDropTask = {
        prompt: prompt.trim() || 'ลากการพยาบาลที่ถูกต้องลงในพื้นที่ปฏิบัติงาน',
        pool: newPool,
        expectedIds,
      };
      delete updated.choices1toN;
      delete updated.traysTask;
      delete updated.sequenceTask;
    } else {
      const temp = validRows.map((r, i) => ({
        id: r.id || `s_${Date.now()}_${i}`,
        text: r.text.trim(),
        orderNum: Number(r.order) || i + 1,
      }));
      const pool = temp.map(({ id, text }) => ({ id, text }));
      const sorted = [...temp].sort((a, b) => a.orderNum - b.orderNum);
      updated.sequenceTask = {
        prompt: prompt.trim() || 'ลาก-วาง เรียงตามลำดับที่ถูกต้อง',
        pool,
        correctOrder: sorted.map((x) => x.id),
      };
      delete updated.choices1toN;
      delete updated.traysTask;
      delete updated.unorderedDropTask;
    }

    setSaving(true);
    try {
      await onSaveStep(bed.bedNum, stepIdx, updated);
      onToast('บันทึกขั้นตอนและคำตอบเรียบร้อยแล้ว ✨');
    } catch (err: any) {
      onToast(err.message || 'ไม่สามารถบันทึกขั้นตอนได้');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={{ textAlign: 'left', maxHeight: '78vh', overflowY: 'auto', paddingRight: 4 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h2 style={{ font: '700 16px var(--font-display)', margin: 0 }}>
          📝 จัดการ 6 ขั้นตอน & คำตอบ
        </h2>
        <span style={{ fontSize: 11, color: 'var(--ink-3)' }}>{bed.bedCode}</span>
      </div>
      <p className="hint" style={{ margin: '2px 0 8px' }}>
        เลือกขั้นตอนด้านล่างเพื่อแก้ไขโจทย์ สัญญาณชีพ ตัวเลือก และเฉลยคำตอบ
      </p>

      <div className="step-nav-bar">
        {stages.map((_, idx) => (
          <button
            key={idx}
            type="button"
            className={`step-nav-pill ${idx === stepIdx ? 'on' : ''}`}
            onClick={() => {
              SFX.pick();
              setStepIdx(idx);
            }}
          >
            ขั้นที่ {idx + 1}
          </button>
        ))}
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <div className="form-row">
          <div className="form-group">
            <label>ชื่อขั้นตอน</label>
            <input className="form-input" id="st-name" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="form-group">
            <label>รูปแบบกลไก (Mechanic)</label>
            <select
              className="form-input"
              id="st-mech"
              value={mode}
              onChange={(e) => handleModeChange(e.target.value as MechanicMode)}
            >
              <option value="choices_seq">เลือกตัวเลือก (Choices 1..N)</option>
              <option value="trays">จัดอุปกรณ์ลงถาด (Multi-Tray)</option>
              <option value="unordered">ลาก-วาง ไม่เป็นลำดับ (Unordered)</option>
              <option value="sequence">ลาก-วาง เรียงลำดับ / ISBAR (Sequence)</option>
            </select>
          </div>
        </div>

        <div className="form-row" style={{ gridTemplateColumns: 'repeat(4, 1fr)' }}>
          <div className="form-group">
            <label>HR (bpm)</label>
            <input className="form-input" type="number" value={hr} onChange={(e) => setHr(Number(e.target.value))} />
          </div>
          <div className="form-group">
            <label>BP (mmHg)</label>
            <input className="form-input" value={bp} onChange={(e) => setBp(e.target.value)} />
          </div>
          <div className="form-group">
            <label>SpO₂</label>
            <input className="form-input" value={spo2} onChange={(e) => setSpo2(e.target.value)} />
          </div>
          <div className="form-group">
            <label>MAP</label>
            <input className="form-input" type="number" value={mapVal} onChange={(e) => setMapVal(Number(e.target.value))} />
          </div>
        </div>

        <div className="form-group">
          <label>คำพูดแพทย์ / โจทย์สถานการณ์</label>
          <input className="form-input" id="st-docSpeech" value={docSpeech} onChange={(e) => setDocSpeech(e.target.value)} />
        </div>

        <div className="form-group">
          <label>เอกสารความรู้ทางการแพทย์ (Reading Summary)</label>
          <textarea className="form-input form-textarea" id="st-reading" value={reading} onChange={(e) => setReading(e.target.value)} />
        </div>

        <div style={{ background: '#fff', border: '1.5px solid #bae6fd', borderRadius: 14, padding: 10, marginTop: 4 }}>
          <b style={{ font: '700 13px var(--font-display)', color: '#0369a1', display: 'block', marginBottom: 4 }}>
            ⚙️ คำตอบและตัวเลือกในขั้นนี้
          </b>

          <div className="form-group" style={{ marginTop: 6 }}>
            <label>โจทย์คำสั่ง (Prompt)</label>
            <input className="form-input" id="st-prompt" value={prompt} onChange={(e) => setPrompt(e.target.value)} />
          </div>

          <div style={{ marginTop: 10 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
              <label style={{ font: '700 12px var(--font-display)', color: 'var(--ink-2)' }}>
                รายการตัวเลือก / อุปกรณ์ & เฉลยคำตอบ
              </label>
              <button
                type="button"
                className="btn btn-sm btn-ghost"
                style={{ padding: '2px 8px', fontSize: 11 }}
                onClick={handleAddRow}
              >
                ➕ เพิ่มรายการ
              </button>
            </div>

            <div id="qa-items-list">
              {rows.map((r, oi) => (
                <div key={r.id || oi} className="qa-item-row" data-item-idx={oi}>
                  {mode === 'sequence' && (
                    <span style={{ font: '700 11px var(--font-display)', color: '#0284c7' }}>#{oi + 1}</span>
                  )}
                  <input
                    className="form-input"
                    type="text"
                    value={r.text}
                    placeholder="ข้อความตัวเลือก / อุปกรณ์"
                    onChange={(e) =>
                      setRows((prev) =>
                        prev.map((item, idx) => (idx === oi ? { ...item, text: e.target.value } : item))
                      )
                    }
                  />

                  {(mode === 'choices_seq' || mode === 'unordered') && (
                    <label className="qa-cb-wrap">
                      <input
                        type="checkbox"
                        checked={r.correct}
                        onChange={(e) =>
                          setRows((prev) =>
                            prev.map((item, idx) => (idx === oi ? { ...item, correct: e.target.checked } : item))
                          )
                        }
                      />
                      <span>ถูก</span>
                    </label>
                  )}

                  {mode === 'trays' && (
                    <>
                      <select
                        className="form-input"
                        value={r.trayId}
                        onChange={(e) =>
                          setRows((prev) =>
                            prev.map((item, idx) => (idx === oi ? { ...item, trayId: e.target.value } : item))
                          )
                        }
                      >
                        {traysList.map((tr) => (
                          <option key={tr.id} value={tr.id}>
                            {tr.name.split(':')[0].replace(/^[🟩🟦]\s*/u, '')}
                          </option>
                        ))}
                      </select>
                      <select
                        className="form-input"
                        value={r.img}
                        onChange={(e) =>
                          setRows((prev) =>
                            prev.map((item, idx) => (idx === oi ? { ...item, img: e.target.value } : item))
                          )
                        }
                      >
                        {EQUIPMENT_ICONS.map((ic) => (
                          <option key={ic.value} value={ic.value}>
                            {ic.label}
                          </option>
                        ))}
                      </select>
                    </>
                  )}

                  {mode === 'sequence' && (
                    <div className="qa-cb-wrap">
                      <span>ลำดับ:</span>
                      <input
                        className="form-input"
                        type="number"
                        value={r.order}
                        style={{ width: 50, minHeight: 36, padding: 4, textAlign: 'center' }}
                        onChange={(e) =>
                          setRows((prev) =>
                            prev.map((item, idx) =>
                              idx === oi ? { ...item, order: Number(e.target.value) } : item
                            )
                          )
                        }
                      />
                    </div>
                  )}

                  <button
                    type="button"
                    className="icon-btn"
                    style={{ width: 28, height: 28, color: '#ef4444' }}
                    title="ลบ"
                    onClick={() => handleRemoveRow(oi)}
                  >
                    ✕
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="modal-actions" style={{ marginTop: 14, display: 'flex', gap: 8 }}>
        <button type="button" className="btn btn-primary" disabled={saving} onClick={handleSave}>
          💾 {saving ? 'กำลังบันทึก...' : 'บันทึกคำตอบขั้นตอนนี้'}
        </button>
        <button type="button" className="btn btn-ghost" onClick={onClose}>
          ปิด
        </button>
      </div>
    </div>
  );
};

