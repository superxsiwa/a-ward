import React from 'react';
import { BedCase, BedProgressRecord, PlayerStats } from '../types/game';
import {
  getMilestoneStars,
  MILESTONE_GOALS,
  MilestoneContextData,
  RANKS,
} from '../engine/MilestoneDefs';
import { StarSvg } from '../components/SvgIcons';

interface ProgressPageProps {
  beds: BedCase[];
  progress: Record<number, BedProgressRecord>;
  playerStats: PlayerStats;
  rosterDaysProgress: Record<string, { passed: boolean }>;
  totalStars: number;
  passedCount: number;
}

export const levelOfStars = (stars: number): number =>
  Math.min(Math.floor(stars / 3) + 1, RANKS.length);

export const ProgressPage: React.FC<ProgressPageProps> = ({
  beds,
  progress,
  playerStats,
  rosterDaysProgress,
  totalStars,
  passedCount,
}) => {
  const maxStars = beds.length * 3;
  const ctx: MilestoneContextData = {
    playerStats,
    progress,
    rosterDaysProgress,
    totalStars,
    passedCount,
  };

  const mStars = MILESTONE_GOALS.reduce((s, g) => s + getMilestoneStars(g, ctx), 0);
  const grandStars = totalStars + mStars;
  const lvl = levelOfStars(totalStars);
  const R = 54;
  const C = 2 * Math.PI * R;
  const frac = maxStars > 0 ? Math.min(1, totalStars / maxStars) : 0;

  const playHours = (playerStats.totalPlaySeconds / 3600).toFixed(1);
  const playMins = Math.floor(playerStats.totalPlaySeconds / 60);

  return (
    <section className="page">
      <h2 className="page-h">ความก้าวหน้า & เป้าหมาย (Milestones)</h2>

      <div className="card ring-card">
        <div className="ring-wrap">
          <svg className="ring" viewBox="0 0 140 140" aria-hidden="true">
            <circle className="ring-bg" cx="70" cy="70" r={R} />
            <circle
              className="ring-fg"
              cx="70"
              cy="70"
              r={R}
              strokeDasharray={C.toFixed(1)}
              strokeDashoffset={(C * (1 - frac)).toFixed(1)}
              transform="rotate(-90 70 70)"
            />
          </svg>
          <div className="ring-c">
            <b>{totalStars}</b>
            <small>จาก {maxStars} ดาวเตียง</small>
          </div>
        </div>
        <div className="rank-big">
          Lv.{lvl} · {RANKS[lvl - 1]}
        </div>
        <div className="hint">
          ผ่านแล้ว {passedCount} / {beds.length} เตียง · ดาวสะสมรวมทั้งหมด {grandStars} ⭐
        </div>

        <div className="progress-stats-grid">
          <div className="p-stat-box">
            <small>ชั่วโมงบิน CCU</small>
            <b>{playMins < 60 ? `${playMins} น.` : `${playHours} ชม.`}</b>
          </div>
          <div className="p-stat-box">
            <small>หัตถการสำเร็จ</small>
            <b>{playerStats.totalCompletedCases} ครั้ง</b>
          </div>
          <div className="p-stat-box">
            <small>ดาว Milestone</small>
            <b>
              {mStars} / {MILESTONE_GOALS.length * 3} ⭐
            </b>
          </div>
        </div>
      </div>

      <div className="milestone-section">
        <div className="section-sub-h">
          <span>🏆 เป้าหมายสะสมดาว (Goals & Milestones)</span>
          <small>ทำครบเงื่อนไขเพื่อรับดาวเพิ่ม</small>
        </div>

        {MILESTONE_GOALS.map((goal) => {
          const currentVal = goal.getValue(ctx);
          const earnedStars = getMilestoneStars(goal, ctx);
          const isMax = earnedStars === 3;
          const nextTarget = isMax ? goal.tiers[2] : goal.tiers[earnedStars];
          const prevTarget = earnedStars === 0 ? 0 : goal.tiers[earnedStars - 1];
          const pct = isMax
            ? 100
            : Math.min(
                100,
                Math.max(0, ((currentVal - prevTarget) / (nextTarget - prevTarget)) * 100)
              );

          return (
            <div key={goal.id} className={`milestone-card ${isMax ? 'all-done' : ''}`}>
              <div className="m-card-top">
                <div className="m-card-title">
                  <span className="m-icon">{goal.icon}</span>
                  <div>
                    <div>{goal.title}</div>
                    <small className="hint" style={{ display: 'block', fontSize: 10.5 }}>
                      {goal.desc}
                    </small>
                  </div>
                </div>
                <div className="m-stars">
                  {[1, 2, 3].map((n) => (
                    <StarSvg key={n} on={earnedStars >= n} size={18} />
                  ))}
                </div>
              </div>

              <div className="m-progress-bar-wrap">
                <div className="m-progress-bar-fill" style={{ width: `${pct.toFixed(0)}%` }} />
              </div>

              <div className="m-card-footer">
                <span className="m-current-val">
                  ปัจจุบัน:{' '}
                  <b>
                    {goal.formatVal
                      ? goal.formatVal(currentVal, ctx)
                      : `${currentVal} ${goal.unit}`}
                  </b>
                </span>
                <span className="m-next-tier">
                  {isMax
                    ? '✓ ได้ครบ 3 ดาวแล้ว!'
                    : `เป้าดาวถัดไป (${earnedStars + 1}⭐): ${nextTarget} ${goal.unit}`}
                </span>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
};
