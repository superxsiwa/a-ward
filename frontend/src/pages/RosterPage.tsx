import React from 'react';
import { BedCase, BedProgressRecord } from '../types/game';
import { BED_STAY_INFO, SHIFTS, THAI_MONTHS } from '../engine/MilestoneDefs';
import { Icon } from '../components/SvgIcons';
import { SFX } from '../engine/SFXEngine';

interface RosterPageProps {
  beds: BedCase[];
  progress: Record<number, BedProgressRecord>;
  calYear: number;
  calMonth: number;
  selectedDay: number;
  unlockedDay: number;
  rosterDaysProgress: Record<string, { passed: boolean }>;
  getShiftForDay: (year: number, month: number, day: number) => {
    id: string;
    name: string;
    icon: string;
    badgeClass: string;
    pillClass: string;
    time: string;
  };
  onSelectDay: (day: number, isLocked: boolean, buttonEl: HTMLElement) => void;
  onPrevMonth: () => void;
  onNextMonth: () => void;
  onRandomizeShifts: () => void;
  onGoWardShift: (shiftId: string | null) => void;
}

const WEEKDAYS_LONG = ['อาทิตย์', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์'];

export const RosterPage: React.FC<RosterPageProps> = ({
  beds,
  progress,
  calYear: y,
  calMonth: m,
  selectedDay,
  unlockedDay,
  rosterDaysProgress,
  getShiftForDay,
  onSelectDay,
  onPrevMonth,
  onNextMonth,
  onRandomizeShifts,
  onGoWardShift,
}) => {
  const firstDayIndex = new Date(y, m, 1).getDay();
  const daysInMonth = new Date(y, m + 1, 0).getDate();
  const myShift = getShiftForDay(y, m, selectedDay);
  const isSelectedDone = !!rosterDaysProgress[`${y}-${m}-${selectedDay}`]?.passed;

  const emptyCells = Array.from({ length: firstDayIndex }, (_, i) => (
    <div key={`empty-${i}`} className="cal-cell empty" />
  ));

  const dayCells = Array.from({ length: daysInMonth }, (_, idx) => {
    const d = idx + 1;
    const isSelected = d === selectedDay;
    const isLocked = d > unlockedDay;
    const dayKey = `${y}-${m}-${d}`;
    const isDone = !isLocked && !!rosterDaysProgress[dayKey]?.passed;
    const isPlayable = d === unlockedDay && !isDone;
    const isToday = d === 21 && m === 9 && y === 2026;
    const dayOfWeek = (firstDayIndex + d - 1) % 7;
    const isSun = dayOfWeek === 0;
    const shift = getShiftForDay(y, m, d);
    const shiftLabel = shift.id === 'off' ? 'OFF' : shift.id === 'morning' ? 'เช้า' : shift.id === 'afternoon' ? 'บ่าย' : 'ดึก';

    return (
      <button
        key={d}
        type="button"
        className={`cal-cell ${isSelected ? 'selected' : ''} ${isPlayable ? 'is-playable' : ''} ${isDone ? 'is-done' : ''} ${isToday ? 'today' : ''} ${isSun ? 'sun' : ''}`}
        data-day={d}
        data-locked={isLocked ? '1' : '0'}
        title={isPlayable ? 'เล่นวันนี้ได้ (เวรปัจจุบัน)' : isDone ? 'ผ่านเวรนี้แล้ว' : isLocked ? 'ยังไม่ถึงวันเข้าเวร' : ''}
        onClick={(e) => onSelectDay(d, isLocked, e.currentTarget)}
      >
        <span className="cal-day-num">{d}</span>
        <span className={`cal-shift-pill ${shift.pillClass}`}>{shiftLabel}</span>
      </button>
    );
  });

  return (
    <section className="page">
      <div className="roster-header">
        <div className="roster-header-top">
          <span className="roster-badge">📅 ปฏิทินเวรพยาบาล CCU</span>
          <button
            type="button"
            className="btn btn-ghost btn-sm"
            style={{ color: '#fff', background: 'rgba(255,255,255,0.2)', padding: '3px 10px', fontSize: 11 }}
            onClick={() => { SFX.pick(); onRandomizeShifts(); }}
          >
            🎲 สุ่มเวรใหม่
          </button>
        </div>
        <h2>ตารางเวรประจำเดือน</h2>
        <p>ต้องเล่นผ่านเวรเรียงตามวัน (ช่องสีทองที่มีเครื่องหมาย <b style={{ color: '#fde047' }}>▶ เล่นวันนี้ได้</b>) ปฏิบัติงานให้ครบเพื่อก้าวสู่วันถัดไป</p>
      </div>

      <div className="cal-layout-desktop">
        <div>
          <div className="cal-month-bar">
            <button type="button" className="cal-nav-btn" aria-label="เดือนก่อนหน้า" onClick={onPrevMonth}>◀</button>
            <div className="cal-month-title">{THAI_MONTHS[m]} {y + 543}</div>
            <button type="button" className="cal-nav-btn" aria-label="เดือนถัดไป" onClick={onNextMonth}>▶</button>
          </div>

          <div className="cal-grid-card">
            <div className="cal-weekdays">
              <span className="sun">อา</span><span>จ</span><span>อ</span><span>พ</span><span>พฤ</span><span>ศ</span><span className="sat">ส</span>
            </div>
            <div className="cal-days-grid">
              {emptyCells}
              {dayCells}
            </div>
          </div>
        </div>

        <div className="day-roster-box">
          <div className="day-roster-head">
            <div>
              <div className="day-roster-date">
                วัน{WEEKDAYS_LONG[(firstDayIndex + selectedDay - 1) % 7]}ที่ {selectedDay} {THAI_MONTHS[m]} {y + 543}
              </div>
              <div className="day-roster-sub">
                เวรของคุณวันนี้: <b>{myShift.icon} {myShift.name}</b>{' '}
                {isSelectedDone && <span className="status-badge s-passed">✓ ผ่านเวรนี้แล้ว</span>}
              </div>
            </div>
          </div>

          <div className="day-shifts">
            {myShift.id === 'off' && (
              <div className="card" style={{ textAlign: 'center', padding: '22px 14px', background: '#f8fafc' }}>
                <div style={{ fontSize: 36, marginBottom: 6 }}>☕🌴</div>
                <b style={{ font: '600 15px var(--font-display)', color: 'var(--ink)' }}>วันนี้เป็นวันหยุดของคุณ (Off)</b>
                <p className="hint" style={{ marginTop: 4 }}>พักผ่อนให้เต็มที่ หรือเลือกดูเคสหัตถการในวอร์ดเพื่อทบทวนความรู้ได้เสมอ</p>
                <div style={{ marginTop: 12, display: 'flex', justifyContent: 'center', gap: 8 }}>
                  <button type="button" className="btn btn-sm btn-outline" onClick={() => onGoWardShift(null)}>
                    <Icon name="bed" /><span>ดูวอร์ดทั้งหมด</span>
                  </button>
                </div>
              </div>
            )}

            {SHIFTS.map((shift) => {
              const isCurrent = shift.id === myShift.id;
              const assignedBeds = shift.bedIndices.map((idx) => ({ bed: beds[idx], idx })).filter((x) => !!x.bed);
              const completedCount = assignedBeds.filter(({ bed }) => progress[bed.bedNum]?.passed).length;

              return (
                <div key={shift.id} className={`day-shift-card ${isCurrent ? 'my-shift' : ''}`}>
                  <div className="day-shift-top">
                    <div className="day-shift-title">
                      <span>{shift.icon}</span>
                      <b>{shift.name}</b>
                      {isCurrent && <span className="status-badge s-passed" style={{ fontSize: 9.5, padding: '2px 6px' }}>เวรของคุณ</span>}
                    </div>
                    <span className={`day-shift-badge ${shift.badgeClass}`}>{shift.time}</span>
                  </div>
                  <div className="day-shift-meta">
                    หัวหน้าเวร: <b>{shift.chargeNurse}</b> · คนไข้ในความรับผิดชอบ ({completedCount}/{assignedBeds.length} เคส)
                  </div>
                  <div className="assigned-beds-list">
                    {assignedBeds.map(({ bed }) => {
                      const done = !!progress[bed.bedNum]?.passed;
                      const stayText = bed.stayDuration || BED_STAY_INFO[bed.bedNum]?.stay || 'หอผู้ป่วย CCU';
                      return (
                        <div key={bed.bedNum} className={`assigned-bed-item ${done ? 'is-done' : ''}`}>
                          <span className="assigned-bed-no">เตียง {String(bed.bedNum).padStart(2, '0')}</span>
                          <div style={{ flex: 1, minWidth: 0 }}>
                            <div className="assigned-bed-title">{bed.caseTitle}</div>
                            <div className="assigned-bed-sub">
                              <span>{bed.patientName}</span>
                              <span className="stay-tag">{stayText}</span>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                  <div className="shift-action-btn-wrap">
                    {isCurrent && (
                      <button type="button" className="btn btn-sm btn-gold shift-action-btn" onClick={() => onGoWardShift(shift.id)}>
                        <Icon name="bed" /><span>{isSelectedDone ? 'ทบทวนวอร์ดเวรนี้' : 'เข้าวอร์ดเวรนี้'}</span>
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
};
