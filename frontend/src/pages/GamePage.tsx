import React, { useRef } from 'react';
import { BedCase, StageData, StepRuntimeState } from '../types/game';
import { EcgWave, Icon } from '../components/SvgIcons';
import { isAlarmVitals } from './WardPage';
import { cleanTray } from '../engine/EvaluationStrategyContext';
import { SFX } from '../engine/SFXEngine';
import { usePointerDnD } from '../components/PointerDnD';


interface GamePageProps {
  bed: BedCase;
  stepIdx: number;
  doneSet: Set<string | number>;
  stepState: StepRuntimeState;
  stepTimeRemaining: number;
  viewportRef: React.RefObject<HTMLElement | null>;
  onUpdateStepState: (updater: (prev: StepRuntimeState) => StepRuntimeState) => void;
}

const cleanSpeech = (s: string) => s.replace(/^💬\s*/, '');

function removeFromState(S: StepRuntimeState, id: string): { kind: string; i?: number; id?: string } {
  let k = S.pool.indexOf(id);
  if (k > -1) {
    S.pool.splice(k, 1);
    return { kind: 'pool' };
  }
  if (S.seq) {
    k = S.seq.indexOf(id);
    if (k > -1) {
      S.seq[k] = null;
      return { kind: 'seq', i: k };
    }
  }
  if (S.trays) {
    for (const t in S.trays) {
      k = S.trays[t].indexOf(id);
      if (k > -1) {
        S.trays[t].splice(k, 1);
        return { kind: 'tray', id: t };
      }
    }
  }
  if (S.unordered) {
    k = S.unordered.indexOf(id);
    if (k > -1) {
      S.unordered.splice(k, 1);
      return { kind: 'unordered' };
    }
  }
  return { kind: 'none' };
}

export function cloneStepState(S: StepRuntimeState): StepRuntimeState {
  const traysClone: Record<string, string[]> | null = S.trays ? {} : null;
  if (S.trays && traysClone) {
    Object.keys(S.trays).forEach((k) => {
      traysClone[k] = [...S.trays![k]];
    });
  }
  return {
    items: S.items,
    pool: [...S.pool],
    seq: S.seq ? [...S.seq] : null,
    trays: traysClone,
    unordered: S.unordered ? [...S.unordered] : null,
    sel: new Set(S.sel),
    picked: S.picked,
    wrong: new Set(S.wrong),
    wrongOpts: new Set(S.wrongOpts),
    locked: S.locked,
  };
}

export function moveItemInState(
  prev: StepRuntimeState,
  id: string,
  dest: string,
  idx?: number | null
): StepRuntimeState {
  const S = cloneStepState(prev);
  const origin = removeFromState(S, id);
  S.wrong.clear();
  S.picked = null;

  if (dest === 'pool') {
    S.pool.push(id);
    return S;
  }
  if (dest.startsWith('seq:') && S.seq) {
    const i = +dest.slice(4);
    const oldVal = S.seq[i];
    S.seq[i] = id;
    if (oldVal) {
      if (origin.kind === 'seq' && origin.i !== undefined) S.seq[origin.i] = oldVal;
      else S.pool.push(oldVal);
    }
    return S;
  }
  if (dest.startsWith('tray:') && S.trays) {
    const trayKey = dest.slice(5);
    const arr = S.trays[trayKey] || [];
    const at = idx == null ? arr.length : Math.min(idx, arr.length);
    arr.splice(at, 0, id);
    S.trays[trayKey] = arr;
    return S;
  }
  if (dest === 'unordered' && S.unordered) {
    S.unordered.push(id);
  }
  return S;
}

export const GamePage: React.FC<GamePageProps> = ({
  bed,
  stepIdx,
  doneSet,
  stepState: S,
  stepTimeRemaining,
  viewportRef,
  onUpdateStepState,
}) => {
  const step: StageData = bed.stageData[stepIdx] || bed.stageData[0];
  const v = step.vitals || { hr: 80, bp: '120/80', spo2: '99%', map: 93 };
  const alarm = isAlarmVitals(v);
  const isStep2 = stepIdx === 1;

  const stateRef = useRef(S);
  stateRef.current = S;

  const handleTap = (id: string) => {
    const cur = stateRef.current;
    if (cur.locked) return;

    if (cur.pool.includes(id)) {
      if (cur.seq) {
        const emptyIdx = cur.seq.indexOf(null);
        if (emptyIdx > -1) {
          SFX.drop();
          onUpdateStepState((prev) => moveItemInState(prev, id, `seq:${emptyIdx}`));
        }
      } else if (cur.unordered) {
        SFX.drop();
        onUpdateStepState((prev) => moveItemInState(prev, id, 'unordered'));
      } else {
        SFX.pick();
        onUpdateStepState((prev) => {
          const next = cloneStepState(prev);
          next.picked = prev.picked === id ? null : id;
          return next;
        });
      }
    } else {
      SFX.pick();
      onUpdateStepState((prev) => moveItemInState(prev, id, 'pool'));
    }
  };

  usePointerDnD(viewportRef, stateRef, stepIdx, bed.bedNum, onUpdateStepState, handleTap);

  const handleDropZoneClick = (dest: string, e: React.MouseEvent) => {
    if ((e.target as HTMLElement).closest('[data-chip]')) return;
    if (!S.picked || S.locked) return;
    const pickedId = S.picked;
    if (dest === 'pool') {
      onUpdateStepState((prev) => {
        const next = cloneStepState(prev);
        next.picked = null;
        return next;
      });
    } else {
      SFX.drop();
      onUpdateStepState((prev) => moveItemInState(prev, pickedId, dest));
    }
  };

  const renderChip = (id: string, extraNode?: React.ReactNode) => {
    const it = S.items[id];
    if (!it) return null;
    const isPicked = S.picked === id;
    const isWrong = S.wrong.has(id);

    if (it.img) {
      return (
        <div
          key={id}
          className={`chip chip-iconic ${isPicked ? 'is-picked' : ''} ${isWrong ? 'is-wrong' : ''}`}
          data-chip={id}
          role="button"
          tabIndex={0}
          onKeyDown={(e) => {
            if (e.key === 'Enter' || e.key === ' ') {
              e.preventDefault();
              handleTap(id);
            }
          }}
        >
          {extraNode}
          <img src={it.img} className="chip-img-large" alt={it.text} />
          <span className="chip-label-short">{it.text}</span>
        </div>
      );
    }

    return (
      <div
        key={id}
        className={`chip ${isPicked ? 'is-picked' : ''} ${isWrong ? 'is-wrong' : ''}`}
        data-chip={id}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            handleTap(id);
          }
        }}
      >
        {extraNode}
        <span className="grip" />
        <span>{it.text}</span>
      </div>
    );
  };

  const renderPool = (hintText: string) => (
    <>
      <div className="pool" data-drop="pool" onClick={(e) => handleDropZoneClick('pool', e)}>
        {S.pool.length > 0 ? (
          S.pool.map((id) => renderChip(id))
        ) : (
          <span className="pool-empty">วางครบทุกใบแล้ว 🎉</span>
        )}
      </div>
      <p className="hint">{hintText}</p>
    </>
  );

  const timerClass =
    stepTimeRemaining <= 5
      ? 'step-timer timer-urgent'
      : stepTimeRemaining <= 10
      ? 'step-timer timer-warn'
      : 'step-timer';

  return (
    <section className="game">
      <div className="stepper" id="stepper">
        {bed.stageData.map((s, i) => {
          const cls = doneSet.has(s.id) ? 'done' : i === stepIdx ? 'now' : '';
          return (
            <React.Fragment key={s.id}>
              {i > 0 && <span className={`st-line ${i <= stepIdx ? 'on' : ''}`} />}
              <span className={`st-dot ${cls}`} aria-label={`ขั้นที่ ${i + 1}`}>
                {cls === 'done' ? <Icon name="check" /> : i + 1}
              </span>
            </React.Fragment>
          );
        })}
      </div>

      <div className="step-head">
        <h2>{step.name.replace(/^\d+\.\s*/, '')}</h2>
        <span className="step-no">
          ขั้นที่ {stepIdx + 1}/{bed.stageData.length}
        </span>
        <span className="mech">🎮 {step.mechanic}</span>
        {isStep2 && (
          <div className={timerClass} id="step-timer">
            ⏱️ <span>{stepTimeRemaining}</span>s
          </div>
        )}
      </div>

      <div className="case">
        <div className={`monitor ${alarm ? 'alarm' : ''}`}>
          <div className="m-top">
            <b>{bed.bedCode}</b>
            <span>{bed.patientName}</span>
            {alarm && <span className="m-alarm">ALARM</span>}
          </div>
          <div className="m-grid">
            <div className="tile t-hr"><small>HR</small><b>{v.hr}</b></div>
            <div className="tile t-bp"><small>BP</small><b>{v.bp}</b></div>
            <div className="tile t-sp"><small>SpO₂</small><b>{v.spo2}</b></div>
            <div className="tile t-map"><small>MAP</small><b>{v.map}</b></div>
          </div>
          <div className="m-ecg">
            <EcgWave hr={v.hr} color={alarm ? '#f87171' : '#4ade80'} />
          </div>
        </div>

        <div className="doc">
          <div className="doc-av">{bed.doctorAvatar}</div>
          <div className="bubble">
            <b>{bed.doctorName}</b>
            {cleanSpeech(step.doctorSpeech)}
          </div>
        </div>
      </div>

      <details className="reading" open>
        <summary>📖 สาระความรู้</summary>
        <p>{step.reading}</p>
      </details>

      <div id="task">
        {step.choices1toN && (
          <section className="card">
            <p className="prompt">{step.choices1toN.prompt}</p>
            <div className="opts">
              {step.choices1toN.options.map((o) => {
                const on = S.sel.has(o.id);
                const isWrong = S.wrongOpts.has(o.id);
                return (
                  <button
                    key={o.id}
                    type="button"
                    className={`opt ${on ? 'is-on' : ''} ${isWrong ? 'is-wrong' : ''}`}
                    aria-pressed={on}
                    data-id={o.id}
                    onClick={() => {
                      if (S.locked) return;
                      SFX.pick();
                      onUpdateStepState((prev) => {
                        const next = cloneStepState(prev);
                        next.wrongOpts.clear();
                        if (next.sel.has(o.id)) next.sel.delete(o.id);
                        else next.sel.add(o.id);
                        return next;
                      });
                    }}
                  >
                    <span className="cb">{on ? <Icon name="check" /> : null}</span>
                    <span>{o.text}</span>
                  </button>
                );
              })}
            </div>
          </section>
        )}

        {step.sequenceTask && S.seq && (
          <section className="card">
            <p className="prompt">{step.sequenceTask.prompt}</p>
            {renderPool('แตะการ์ดเพื่อเติมช่องถัดไป · ลากเพื่อสลับตำแหน่ง · แตะการ์ดที่วางแล้วเพื่อเอาออก')}
            <ol className="slots">
              {S.seq.map((id, i) => (
                <li
                  key={i}
                  className={`slot dz ${id ? 'filled' : ''}`}
                  data-drop={`seq:${i}`}
                  onClick={(e) => handleDropZoneClick(`seq:${i}`, e)}
                >
                  <span className="slot-no">{i + 1}</span>
                  {id ? renderChip(id) : <span className="slot-ph">ลากการ์ดมาวางที่นี่</span>}
                </li>
              ))}
            </ol>
          </section>
        )}

        {step.traysTask && S.trays && (
          <section className="card">
            <p className="prompt">{step.traysTask.prompt.replace(/\*\*/g, '')}</p>
            {renderPool('แตะการ์ดแล้วแตะถาดที่ต้องการ · หรือกดค้างแล้วลากไปวาง · แตะการ์ดในถาดเพื่อเอาออก')}
            <div className="trays">
              {step.traysTask.trays.map((tr) => {
                const arr = S.trays![tr.id] || [];
                return (
                  <div
                    key={tr.id}
                    className={`tray ${tr.sterile ? 'sterile' : ''}`}
                    data-drop={`tray:${tr.id}`}
                    onClick={(e) => handleDropZoneClick(`tray:${tr.id}`, e)}
                  >
                    <div className="tray-h">
                      <span>{tr.sterile ? '✨' : '🧰'}</span>
                      <span>{cleanTray(tr.name)}</span>
                      <b className="count">{arr.length}</b>
                    </div>
                    <div className="tray-body">
                      {arr.length > 0
                        ? arr.map((id, i) =>
                            renderChip(id, step.traysTask!.ordered ? <b className="ord">{i + 1}</b> : undefined)
                          )
                        : <span className="tray-ph">วางอุปกรณ์ในถาดนี้</span>}
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        )}

        {step.unorderedDropTask && S.unordered && (
          <section className="card">
            <p className="prompt">{step.unorderedDropTask.prompt}</p>
            {renderPool('แตะหรือลากการ์ดที่ถูกต้องใส่กล่อง · แตะการ์ดในกล่องเพื่อเอาออก')}
            <div
              className="tray sterile"
              data-drop="unordered"
              onClick={(e) => handleDropZoneClick('unordered', e)}
            >
              <div className="tray-h">
                <span>📋</span>
                <span>กล่องปฏิบัติการพยาบาล</span>
                <b className="count">
                  {S.unordered.length}/{step.unorderedDropTask.expectedIds.length}
                </b>
              </div>
              <div className="tray-body">
                {S.unordered.length > 0
                  ? S.unordered.map((id) => renderChip(id))
                  : <span className="tray-ph">วางการ์ดที่ถูกต้องที่นี่</span>}
              </div>
            </div>
          </section>
        )}
      </div>
    </section>
  );
};


