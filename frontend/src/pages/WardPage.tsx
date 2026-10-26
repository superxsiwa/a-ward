import React from 'react';
import { BedCase, BedProgressRecord, VitalSigns } from '../types/game';
import { BED_STAY_INFO, SHIFTS } from '../engine/MilestoneDefs';
import { EcgWave, Icon, StarSvg } from '../components/SvgIcons';

interface WardPageProps {
  beds: BedCase[];
  progress: Record<number, BedProgressRecord>;
  filterShift: string | null;
  passedCount: number;
  nextTargetIdx: number;
  onOpenBed: (index: number) => void;
  onClearFilter: () => void;
  onOpenCaseMgmt: () => void;
}

export const isAlarmVitals = (v: VitalSigns): boolean =>
  v.hr >= 120 || v.hr < 50 || parseInt(v.spo2, 10) <= 90 || v.map < 65;

export const WardPage: React.FC<WardPageProps> = ({
  beds,
  progress,
  filterShift,
  passedCount,
  nextTargetIdx,
  onOpenBed,
  onClearFilter,
  onOpenCaseMgmt,
}) => {
  const curFilterShift = filterShift ? SHIFTS.find((s) => s.id === filterShift) : null;

  const renderBedCard = (b: BedCase, i: number) => {
    const rec = progress[b.bedNum] || { passed: false, stars: 0 };
    const stars = rec.stars || 0;
    const done = !!rec.passed;
    const v = b.stageData[0]?.vitals || { hr: 80, bp: '120/80', spo2: '99%', map: 93 };
    const alarm = isAlarmVitals(v);
    const pt = b.patientName.startsWith('นาง') ? '👵' : '👴';
    const stayText = b.stayDuration || BED_STAY_INFO[b.bedNum]?.stay || 'CCU';
    const isFiltered =
      curFilterShift && !curFilterShift.bedIndices.includes(i);

    return (
      <button
        key={b.bedNum}
        type="button"
        className={`bed s-${b.status} ${done ? 'is-done' : ''}`}
        style={isFiltered ? { opacity: 0.35, filter: 'grayscale(0.5)' } : undefined}
        onClick={() => onOpenBed(i)}
        aria-label={`${b.bedCode} ${b.caseTitle}`}
        data-bed-idx={i}
      >
        <span className="bed-no">{String(b.bedNum).padStart(2, '0')}</span>
        {done && (
          <span className="bed-check">
            <Icon name="check" />
          </span>
        )}
        <span className="bed-st">{done ? 'ผ่านแล้ว' : b.statusText}</span>
        <span className="bed-art">
          <span className="monitor-mini">
            <EcgWave hr={v.hr} color={alarm ? '#f87171' : '#4ade80'} />
            <em>♥ {v.hr}</em>
          </span>
          <span className="mattress">
            <i className="pillow" />
          </span>
          <span className="pt">{pt}</span>
        </span>
        <span className="bed-title">{b.caseTitle}</span>
        <span
          style={{
            fontSize: 10,
            color: 'var(--ink-3)',
            display: 'block',
            marginTop: -2,
          }}
        >
          <span className="stay-tag">{stayText}</span>
        </span>
        <span className="bed-foot">
          <span className="stars">
            {[1, 2, 3].map((n) => (
              <StarSvg key={n} on={stars >= n} size={18} />
            ))}
          </span>
          <span className="go">
            <Icon name="play" />
          </span>
        </span>
      </button>
    );
  };

  return (
    <section className="ward">
      <div className="banner">
        <div className="sign">CCU</div>
        <div>
          <h1>วอร์ดหัวใจ {beds.length} เตียง</h1>
          <p>แตะที่เตียงเพื่อเริ่มทำการพยาบาลและหัตถการ</p>
        </div>
        {nextTargetIdx >= 0 && (
          <button
            type="button"
            className="btn btn-gold"
            onClick={() => onOpenBed(nextTargetIdx)}
          >
            <Icon name="play" />
            <span>{passedCount === 0 ? 'เริ่มเลย' : 'เล่นต่อ'}</span>
          </button>
        )}
      </div>

      {curFilterShift && (
        <div className="ward-filter-banner">
          <div>
            <b>
              {curFilterShift.icon} ประจำการ: {curFilterShift.name}
            </b>
            <div style={{ fontSize: 11, opacity: 0.85 }}>
              เน้นเตียงที่ได้รับมอบหมายในเวร (
              {curFilterShift.bedIndices.map((x) => `เตียง ${x + 1}`).join(', ')})
            </div>
          </div>
          <button type="button" className="clear-filter-btn" onClick={onClearFilter}>
            แสดงทุกเตียง ✕
          </button>
        </div>
      )}

      <div className="bays">
        {beds.slice(0, 4).map((b, i) => renderBedCard(b, i))}

        <div className="station">
          <div className="desk">
            <span>🖥️</span>
            <span>👩‍⚕️</span>
            <span>📋</span>
          </div>
          <div className="st-info">
            <b>เคาน์เตอร์พยาบาล</b>
            <small>
              ผ่านแล้ว {passedCount}/{beds.length} เตียง
            </small>
            <div className="dots">
              {beds.map((b) => (
                <i
                  key={b.bedNum}
                  className={progress[b.bedNum]?.passed ? 'on' : ''}
                />
              ))}
            </div>
            <button
              type="button"
              className="station-office-btn"
              onClick={onOpenCaseMgmt}
            >
              <span>📁</span> ห้องจัดการเคส CCU ▶
            </button>
          </div>
        </div>

        {beds.slice(4).map((b, i) => renderBedCard(b, i + 4))}
      </div>
    </section>
  );
};
