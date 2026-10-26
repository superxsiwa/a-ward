import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  BedCase,
  BedProgressRecord,
  PlayerSettings,
  PlayerStats,
  PoolItem,
  StageData,
  StepRuntimeState,
  UserProfile,
} from './types/game';
import {
  authApi,
  casesApi,
  getAuthToken,
  progressApi,
  rosterApi,
  setAuthToken,
} from './api/client';
import { Icon, StarSvg, SvgSprite } from './components/SvgIcons';
import { RANKS, SHIFTS } from './engine/MilestoneDefs';
import { SFX } from './engine/SFXEngine';
import { evaluator } from './engine/EvaluationStrategyContext';
import { procedureFSM } from './engine/ProcedureStateMachine';
import { gameEventBus } from './engine/GameEventBus';
import { AuthPage } from './pages/AuthPage';
import { RosterPage } from './pages/RosterPage';
import { isAlarmVitals, WardPage } from './pages/WardPage';
import { cloneStepState, GamePage } from './pages/GamePage';
import { levelOfStars, ProgressPage } from './pages/ProgressPage';
import { CaseManagerPage } from './pages/CaseManagerPage';
import { SettingsPage } from './pages/SettingsPage';

const SAVE_KEY = 'award_ccu_8beds_progress_v3';
const SET_KEY = 'award_settings_v1';
const ROSTER_KEY = 'award_ccu_roster_schedule_v1';
const ROSTER_PROGRESS_KEY = 'award_ccu_roster_days_progress_v1';
const STATS_KEY = 'award_ccu_player_stats_v1';
const CUSTOM_BEDS_KEY = 'award_ccu_custom_beds_v1';

const loadLocal = <T,>(k: string, d: T): T => {
  try {
    const r = localStorage.getItem(k);
    return r ? (JSON.parse(r) as T) : d;
  } catch {
    return d;
  }
};

const saveLocal = (k: string, v: unknown): void => {
  try {
    localStorage.setItem(k, JSON.stringify(v));
  } catch {
    // ignore
  }
};

function shuffleArray<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function buildStepRuntimeState(step: StageData): StepRuntimeState {
  const task = step.sequenceTask || step.traysTask || step.unorderedDropTask;
  const items: Record<string, PoolItem> = {};
  const poolIds: string[] = [];

  if (task && task.pool) {
    task.pool.forEach((it) => {
      items[it.id] = it;
      poolIds.push(it.id);
    });
  }

  const S: StepRuntimeState = {
    items,
    pool: shuffleArray(poolIds),
    seq: step.sequenceTask ? new Array(step.sequenceTask.correctOrder.length).fill(null) : null,
    trays: null,
    unordered: step.unorderedDropTask ? [] : null,
    sel: new Set(),
    picked: null,
    wrong: new Set(),
    wrongOpts: new Set(),
    locked: false,
  };

  if (step.traysTask) {
    S.trays = {};
    step.traysTask.trays.forEach((t) => {
      S.trays![t.id] = [];
    });
  }

  return S;
}

const SHIFT_POOL = ['morning', 'afternoon', 'night', 'morning', 'afternoon', 'night', 'off'];

export const App: React.FC = () => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [authChecked, setAuthChecked] = useState(false);

  const [beds, setBeds] = useState<BedCase[]>(() => loadLocal<BedCase[]>(CUSTOM_BEDS_KEY, []));
  const [progress, setProgress] = useState<Record<number, BedProgressRecord>>(() =>
    loadLocal(SAVE_KEY, {})
  );
  const [settings, setSettings] = useState<PlayerSettings>(() =>
    Object.assign({ sound: true, haptics: true }, loadLocal(SET_KEY, {}))
  );
  const [rosterSchedule, setRosterSchedule] = useState<Record<string, Record<number, string>>>(() =>
    loadLocal(ROSTER_KEY, {})
  );
  const [rosterDaysProgress, setRosterDaysProgress] = useState<Record<string, { passed: boolean }>>(
    () => loadLocal(ROSTER_PROGRESS_KEY, {})
  );
  const [playerStats, setPlayerStats] = useState<PlayerStats>(() =>
    Object.assign(
      {
        totalCompletedCases: 0,
        totalPlaySeconds: 0,
        perfectCases: 0,
        shiftsCompleted: 0,
        trayItemsSorted: 0,
        stepsWithoutMistake: 0,
        emergencyCasesDone: 0,
        replayedCases: 0,
      },
      loadLocal(STATS_KEY, {})
    )
  );

  // Navigation & UI state
  const [screen, setScreen] = useState<'ward' | 'game'>('ward');
  const [tab, setTab] = useState<'roster' | 'ward' | 'cases' | 'progress' | 'settings'>('roster');
  const [filterShift, setFilterShift] = useState<string | null>(null);
  const [calYear, setCalYear] = useState(2026);
  const [calMonth, setCalMonth] = useState(9); // October (0-indexed)
  const [selectedDay, setSelectedDay] = useState(1);

  // Game Session State
  const [bedIdx, setBedIdx] = useState(0);
  const [stepIdx, setStepIdx] = useState(0);
  const [mistakes, setMistakes] = useState(0);
  const [stepMistakes, setStepMistakes] = useState<Record<string | number, number>>({});
  const [doneSet, setDoneSet] = useState<Set<string | number>>(new Set());
  const [stepState, setStepState] = useState<StepRuntimeState | null>(null);
  const stepStatesCacheRef = useRef<Record<string | number, StepRuntimeState>>({});
  const [lostStarAnim, setLostStarAnim] = useState<number>(0);

  // Step 2 Emergency Timer
  const [stepTimeRemaining, setStepTimeRemaining] = useState(20);
  const stepTimerRef = useRef<any>(null);

  // Sheet, Modal, Toast
  const [sheet, setSheet] = useState<{
    show: boolean;
    kind: 'ok' | 'bad';
    title: string;
    sub: string;
    errors: string[];
    canSkip?: boolean;
    isSolutionPreview?: boolean;
  }>({ show: false, kind: 'ok', title: '', sub: '', errors: [] });

  const [winModal, setWinModal] = useState<{
    show: boolean;
    bed: BedCase;
    stars: number;
    msg: string;
    shiftCompletedMsg: string;
    lvlUpText: string;
    nextIdx: number;
  } | null>(null);

  const [exitConfirmOpen, setExitConfirmOpen] = useState(false);
  const [resetConfirmOpen, setResetConfirmOpen] = useState(false);
  const [toastMsg, setToastMsg] = useState<{ text: string; show: boolean }>({
    text: '',
    show: false,
  });
  const toastTimerRef = useRef<any>(null);
  const viewportRef = useRef<HTMLElement | null>(null);

  const showToast = useCallback((text: string) => {
    clearTimeout(toastTimerRef.current);
    setToastMsg({ text, show: true });
    toastTimerRef.current = setTimeout(() => {
      setToastMsg((prev) => ({ ...prev, show: false }));
    }, 2200);
  }, []);

  useEffect(() => {
    SFX.soundEnabled = settings.sound;
    SFX.hapticsEnabled = settings.haptics;
  }, [settings]);

  // Initial load of Cases + Auth user + Progress
  const syncUserProgress = useCallback(async () => {
    try {
      const data = await progressApi.getMe();
      setProgress(data.progress || {});
      saveLocal(SAVE_KEY, data.progress || {});
      setPlayerStats(data.playerStats);
      saveLocal(STATS_KEY, data.playerStats);
      if (data.rosterSchedule && Object.keys(data.rosterSchedule).length > 0) {
        setRosterSchedule((prev) => {
          const merged = { ...prev, ...data.rosterSchedule };
          saveLocal(ROSTER_KEY, merged);
          return merged;
        });
      }
      if (data.rosterDaysProgress) {
        setRosterDaysProgress(data.rosterDaysProgress);
        saveLocal(ROSTER_PROGRESS_KEY, data.rosterDaysProgress);
      }
      if (data.settings) {
        setSettings(data.settings);
        saveLocal(SET_KEY, data.settings);
      }
    } catch {
      // fallback to local
    }
  }, []);

  useEffect(() => {
    (async () => {
      try {
        const res = await casesApi.getAll();
        if (res.cases && res.cases.length > 0) {
          setBeds(res.cases);
          saveLocal(CUSTOM_BEDS_KEY, res.cases);
        }
      } catch {
        // use cached beds
      }

      const token = getAuthToken();
      if (token) {
        try {
          const meRes = await authApi.me();
          setUser(meRes.user);
          await syncUserProgress();
        } catch {
          setAuthToken(null);
        }
      }
      setAuthChecked(true);
    })();
  }, [syncUserProgress]);

  // Playtime tracker
  useEffect(() => {
    const iv = setInterval(() => {
      setPlayerStats((prev) => {
        const next = { ...prev, totalPlaySeconds: (prev.totalPlaySeconds || 0) + 5 };
        saveLocal(STATS_KEY, next);
        return next;
      });
      if (getAuthToken()) {
        progressApi.heartbeat(5).catch(() => {});
      }
    }, 5000);
    return () => clearInterval(iv);
  }, []);

  const totalStars = beds.reduce((sum, b) => sum + (progress[b.bedNum]?.stars || 0), 0);
  const passedCount = beds.filter((b) => progress[b.bedNum]?.passed).length;
  const maxStars = beds.length * 3;

  const getNextTargetIdx = useCallback((): number => {
    const u = beds.findIndex((b) => !progress[b.bedNum]?.passed);
    if (u > -1) return u;
    return beds.findIndex((b) => (progress[b.bedNum]?.stars || 0) < 3);
  }, [beds, progress]);

  const generateMonthSchedule = useCallback(
    (year: number, month: number): Record<number, string> => {
      const key = `${year}-${month}`;
      const days = new Date(year, month + 1, 0).getDate();
      const sched: Record<number, string> = {};
      for (let d = 1; d <= days; d++) {
        sched[d] = SHIFT_POOL[Math.floor(Math.random() * SHIFT_POOL.length)];
      }
      setRosterSchedule((prev) => {
        const next = { ...prev, [key]: sched };
        saveLocal(ROSTER_KEY, next);
        return next;
      });
      if (getAuthToken()) {
        rosterApi.saveMonth(key, sched).catch(() => {});
      }
      return sched;
    },
    []
  );

  const getShiftForDay = useCallback(
    (year: number, month: number, day: number) => {
      const key = `${year}-${month}`;
      const monthMap = rosterSchedule[key];
      const shiftId = monthMap ? monthMap[day] || 'morning' : 'morning';
      if (shiftId === 'off') {
        return {
          id: 'off',
          name: 'วันหยุดพักผ่อน (Off)',
          icon: '☕',
          badgeClass: '',
          pillClass: 's-off',
          time: 'เวรหยุด',
        };
      }
      return SHIFTS.find((s) => s.id === shiftId) || SHIFTS[0];
    },
    [rosterSchedule]
  );

  useEffect(() => {
    const key = `${calYear}-${calMonth}`;
    if (!rosterSchedule[key]) {
      generateMonthSchedule(calYear, calMonth);
    }
  }, [calYear, calMonth, rosterSchedule, generateMonthSchedule]);

  const getRosterUnlockedDay = useCallback(
    (year: number, month: number): number => {
      const daysInMonth = new Date(year, month + 1, 0).getDate();
      const key = `${year}-${month}`;
      const monthMap = rosterSchedule[key] || {};
      for (let d = 1; d <= daysInMonth; d++) {
        const dayKey = `${year}-${month}-${d}`;
        if (!rosterDaysProgress[dayKey]?.passed) {
          const shiftId = monthMap[d] || 'morning';
          if (shiftId === 'off') {
            setRosterDaysProgress((prev) => {
              if (prev[dayKey]?.passed) return prev;
              const next = { ...prev, [dayKey]: { passed: true } };
              saveLocal(ROSTER_PROGRESS_KEY, next);
              return next;
            });
            if (getAuthToken()) {
              rosterApi.clearDay(dayKey, 'off').catch(() => {});
            }
            continue;
          }
          return d;
        }
      }
      return daysInMonth;
    },
    [rosterSchedule, rosterDaysProgress]
  );

  const unlockedDay = getRosterUnlockedDay(calYear, calMonth);

  useEffect(() => {
    if (!selectedDay || selectedDay > unlockedDay) {
      setSelectedDay(unlockedDay);
    }
  }, [unlockedDay, selectedDay]);

  const stopStepTimer = useCallback(() => {
    if (stepTimerRef.current) {
      clearInterval(stepTimerRef.current);
      stepTimerRef.current = null;
    }
  }, []);

  const curBed = beds[bedIdx] || beds[0];
  const curStep = curBed?.stageData?.[stepIdx] || curBed?.stageData?.[0];

  const handleStepTimeout = useCallback(() => {
    if (!curStep || !stepState || stepState.locked) return;
    stopStepTimer();
    SFX.bad();
    SFX.haptic([40, 50, 40]);

    setMistakes((prev) => {
      const next = prev + 1;
      setLostStarAnim(next === 1 ? 3 : next === 3 ? 2 : 0);
      return next;
    });

    const stId = curStep.id;
    setStepMistakes((prev) => {
      const count = (prev[stId] || 0) + 1;
      const nextMap = { ...prev, [stId]: count };
      if (count >= 3) {
        setSheet({
          show: true,
          kind: 'bad',
          title: 'หมดเวลา 20 วินาที!',
          sub: 'ผิด/หมดเวลาครบ 3 ครั้งแล้ว สามารถดูเฉลยแล้วไปต่อได้เลยนะ',
          errors: ['จัดเตรียมอุปกรณ์ไม่ทันในเวลา 20 วินาที'],
          canSkip: true,
        });
      } else {
        setSheet({
          show: true,
          kind: 'bad',
          title: `หมดเวลา 20 วินาที! (ครั้งที่ ${count}/3)`,
          sub: 'การจัดเตรียมอุปกรณ์ในภาวะฉุกเฉินต้องรวดเร็วและแม่นยำ ลองใหม่อีกครั้งนะ',
          errors: ['จัดเตรียมอุปกรณ์ไม่ทันในเวลา 20 วินาที'],
          canSkip: false,
        });
      }
      return nextMap;
    });
  }, [curStep, stepState, stopStepTimer]);

  const startStepTimer = useCallback(
    (seconds = 20) => {
      stopStepTimer();
      setStepTimeRemaining(seconds);
      stepTimerRef.current = setInterval(() => {
        setStepTimeRemaining((prev) => {
          if (prev <= 1) {
            clearInterval(stepTimerRef.current);
            stepTimerRef.current = null;
            setTimeout(() => handleStepTimeout(), 0);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    },
    [stopStepTimer, handleStepTimeout]
  );

  const loadStep = useCallback(
    (targetIdx: number, bedOverride?: BedCase, doneOverride?: Set<string | number>) => {
      stopStepTimer();
      const b = bedOverride || beds[bedIdx];
      if (!b) return;

      // Save current step state into cache before switching
      if (stepState && curStep && !bedOverride) {
        stepStatesCacheRef.current[curStep.id] = stepState;
      }

      const nextStage = b.stageData[targetIdx];
      if (!nextStage) return;

      setStepIdx(targetIdx);
      const cached = stepStatesCacheRef.current[nextStage.id];
      const nextS = cached || buildStepRuntimeState(nextStage);
      stepStatesCacheRef.current[nextStage.id] = nextS;
      setStepState(nextS);
      setSheet((prev) => ({ ...prev, show: false }));
      if (viewportRef.current) viewportRef.current.scrollTop = 0;

      const dSet = doneOverride || doneSet;
      procedureFSM.resetForStep(dSet.has(nextStage.id));
      if (targetIdx === 1 && !dSet.has(nextStage.id)) {
        startStepTimer(20);
      }
    },
    [beds, bedIdx, stepState, curStep, doneSet, stopStepTimer, startStepTimer]
  );

  const openBed = useCallback(
    (index: number) => {
      const b = beds[index];
      if (!b) return;
      stopStepTimer();
      setWinModal(null);
      setExitConfirmOpen(false);
      setScreen('game');
      setBedIdx(index);
      setMistakes(0);
      setStepMistakes({});
      const freshDone = new Set<string | number>();
      setDoneSet(freshDone);
      setLostStarAnim(0);
      stepStatesCacheRef.current = {};

      const firstStage = b.stageData[0];
      const initialS = buildStepRuntimeState(firstStage);
      stepStatesCacheRef.current[firstStage.id] = initialS;
      setStepIdx(0);
      setStepState(initialS);
      setSheet((prev) => ({ ...prev, show: false }));
      procedureFSM.resetForStep(false);
    },
    [beds, stopStepTimer]
  );

  const liveStars = mistakes === 0 ? 3 : mistakes <= 2 ? 2 : 1;

  const finishCase = useCallback(
    async (traySortedDelta = 0, flawlessStepsDelta = 0) => {
      stopStepTimer();
      if (!curBed) return;
      procedureFSM.transitionTo('CASE_COMPLETED');
      gameEventBus.emit('CASE_FINISHED', { bedNum: curBed.bedNum, stars: liveStars });

      const stars = liveStars;
      const beforeStars = totalStars;
      const prevRec = progress[curBed.bedNum] || { passed: false, stars: 0 };
      const best = Math.max(prevRec.stars || 0, stars);

      const newProgress = {
        ...progress,
        [curBed.bedNum]: { passed: true, stars: best },
      };
      setProgress(newProgress);
      saveLocal(SAVE_KEY, newProgress);

      const isEmergency =
        curBed.status === 'critical' ||
        curBed.status === 'alert' ||
        curBed.stageData.some((s) => isAlarmVitals(s.vitals));

      setPlayerStats((prev) => {
        const next: PlayerStats = {
          ...prev,
          totalCompletedCases: (prev.totalCompletedCases || 0) + 1,
          perfectCases: (prev.perfectCases || 0) + (stars === 3 ? 1 : 0),
          emergencyCasesDone: (prev.emergencyCasesDone || 0) + (isEmergency ? 1 : 0),
          replayedCases: (prev.replayedCases || 0) + (prevRec.passed ? 1 : 0),
          trayItemsSorted: (prev.trayItemsSorted || 0) + traySortedDelta,
          stepsWithoutMistake: (prev.stepsWithoutMistake || 0) + flawlessStepsDelta,
        };
        saveLocal(STATS_KEY, next);
        return next;
      });

      let shiftCompletedMsg = '';
      const dayKey = `${calYear}-${calMonth}-${selectedDay}`;
      if (filterShift) {
        const shiftObj = SHIFTS.find((s) => s.id === filterShift);
        if (shiftObj) {
          const allPassed = shiftObj.bedIndices.every((idx) => {
            const b = beds[idx];
            return b && newProgress[b.bedNum]?.passed;
          });
          if (allPassed && !rosterDaysProgress[dayKey]?.passed) {
            const nextRosterProg = { ...rosterDaysProgress, [dayKey]: { passed: true } };
            setRosterDaysProgress(nextRosterProg);
            saveLocal(ROSTER_PROGRESS_KEY, nextRosterProg);
            shiftCompletedMsg = `🎉 ยินดีด้วย! ปฏิบัติหน้าที่ครบใน${shiftObj.name}แล้ว ปลดล็อกวันที่ ${selectedDay + 1} เรียบร้อย!`;
          }
        }
      }

      if (getAuthToken()) {
        progressApi
          .completeCase({
            bedNum: curBed.bedNum,
            mistakes,
            stars,
            trayItemsSortedDelta: traySortedDelta,
            stepsWithoutMistakeDelta: flawlessStepsDelta,
            isEmergency,
            activeShift: filterShift,
            dayKey,
          })
          .catch(() => {});
      }

      const afterStars = beds.reduce((s, b) => s + (newProgress[b.bedNum]?.stars || 0), 0);
      const lvlUp = levelOfStars(afterStars) > levelOfStars(beforeStars);
      const gained = best - (prevRec.stars || 0);
      const msg =
        stars === 3
          ? 'สุดยอด! ตอบเป๊ะทุกข้อ ได้ครบ 3 ดาวเลย'
          : `ผ่านเคสสำเร็จ! ลองเล่นซ้ำเพื่อเก็บให้ครบ 3 ดาวนะ${gained > 0 ? ` (ได้ดาวเพิ่ม +${gained})` : ''}`;

      const nxt = beds.findIndex((b) => !newProgress[b.bedNum]?.passed);
      const fallbackNxt = beds.findIndex((b) => (newProgress[b.bedNum]?.stars || 0) < 3);

      setWinModal({
        show: true,
        bed: curBed,
        stars,
        msg,
        shiftCompletedMsg,
        lvlUpText: lvlUp
          ? `⬆️ เลื่อนระดับ! Lv.${levelOfStars(afterStars)} · ${RANKS[levelOfStars(afterStars) - 1]}`
          : '',
        nextIdx: nxt > -1 ? nxt : fallbackNxt,
      });

      SFX.win();
      SFX.haptic([20, 40, 20, 40, 60]);
      for (let i = 0; i < stars; i++) {
        setTimeout(() => SFX.star(i), 450 + i * 320);
      }
    },
    [
      curBed,
      liveStars,
      totalStars,
      progress,
      calYear,
      calMonth,
      selectedDay,
      filterShift,
      beds,
      rosterDaysProgress,
      mistakes,
      stopStepTimer,
    ]
  );

  const checkStep = useCallback(() => {
    if (!curBed || !curStep || !stepState || stepState.locked) return;
    procedureFSM.transitionTo('EVALUATING');

    const res = evaluator.evaluateStep(curStep, stepState);
    if (res.incompleteMsg) {
      showToast(res.incompleteMsg);
      SFX.pick();
      procedureFSM.transitionTo('INTERACTING');
      return;
    }

    if (res.passed) {
      stopStepTimer();
      procedureFSM.transitionTo('STEP_PASSED');
      const lockedS = cloneStepState(stepState);
      lockedS.locked = true;
      lockedS.wrong.clear();
      lockedS.wrongOpts.clear();
      stepStatesCacheRef.current[curStep.id] = lockedS;
      setStepState(lockedS);

      const nextDone = new Set(doneSet);
      nextDone.add(curStep.id);
      setDoneSet(nextDone);

      SFX.ok();
      SFX.haptic(30);

      let trayDelta = 0;
      if (curStep.traysTask && lockedS.trays) {
        trayDelta = Object.values(lockedS.trays).reduce((sum, arr) => sum + arr.length, 0);
      }
      const flawlessDelta = (stepMistakes[curStep.id] || 0) === 0 ? 1 : 0;

      const isLast = stepIdx === curBed.stageData.length - 1;
      if (isLast) {
        finishCase(trayDelta, flawlessDelta);
        return;
      }

      setPlayerStats((prev) => {
        const next: PlayerStats = {
          ...prev,
          trayItemsSorted: (prev.trayItemsSorted || 0) + trayDelta,
          stepsWithoutMistake: (prev.stepsWithoutMistake || 0) + flawlessDelta,
        };
        saveLocal(STATS_KEY, next);
        return next;
      });

      const praise = ['ยอดเยี่ยม!', 'เก่งมาก!', 'เป๊ะเลย!', 'สุดยอด!'][Math.floor(Math.random() * 4)];
      setSheet({
        show: true,
        kind: 'ok',
        title: praise,
        sub: 'ผ่านขั้นตอนนี้แล้ว ถูกต้องตามหลักความปลอดภัย',
        errors: [],
      });
    } else {
      stopStepTimer();
      procedureFSM.transitionTo('STEP_FAILED');
      SFX.bad();
      SFX.haptic([30, 40, 30]);

      const nextS = cloneStepState(stepState);
      nextS.wrong = res.wrongItemIds;
      nextS.wrongOpts = res.wrongOptionIds;
      stepStatesCacheRef.current[curStep.id] = nextS;
      setStepState(nextS);

      setMistakes((prev) => {
        const next = prev + 1;
        setLostStarAnim(next === 1 ? 3 : next === 3 ? 2 : 0);
        return next;
      });

      const stId = curStep.id;
      const newCount = (stepMistakes[stId] || 0) + 1;
      setStepMistakes((prev) => ({ ...prev, [stId]: newCount }));

      if (newCount >= 3) {
        setSheet({
          show: true,
          kind: 'bad',
          title: 'พยายามได้ดีมากแล้วจ้า!',
          sub: 'ผิดครบ 3 ครั้งแล้ว สามารถดูเฉลยแล้วไปต่อได้เลยนะ',
          errors: res.errorMessages,
          canSkip: true,
        });
      } else {
        setSheet({
          show: true,
          kind: 'bad',
          title: `ยังไม่ถูกน้า (ครั้งที่ ${newCount}/3)`,
          sub: 'ลองดูจุดที่ขึ้นสีแดงอีกครั้ง',
          errors: res.errorMessages,
          canSkip: false,
        });
      }
    }
  }, [curBed, curStep, stepState, doneSet, stepMistakes, stepIdx, showToast, stopStepTimer, finishCase]);

  const handleMercySkip = useCallback(() => {
    if (!curBed || !curStep || !stepState) return;
    stopStepTimer();
    const solvedS = evaluator.populateCorrectSolution(curStep, stepState);
    stepStatesCacheRef.current[curStep.id] = solvedS;
    setStepState(solvedS);

    const nextDone = new Set(doneSet);
    nextDone.add(curStep.id);
    setDoneSet(nextDone);
    procedureFSM.transitionTo('STEP_PASSED');
    SFX.ok();

    setSheet({
      show: true,
      kind: 'ok',
      title: '💡 เฉลยคำตอบที่ถูกต้อง',
      sub: 'ระบบได้จัดเรียงคำตอบที่ถูกต้องให้แล้ว ศึกษาแล้วกดไปต่อได้เลยจ้า',
      errors: [],
      isSolutionPreview: true,
    });
  }, [curBed, curStep, stepState, doneSet, stopStepTimer]);

  const handleNextStep = useCallback(() => {
    setSheet((prev) => ({ ...prev, show: false }));
    if (!curBed) return;
    if (stepIdx < curBed.stageData.length - 1) {
      loadStep(stepIdx + 1);
    } else {
      finishCase();
    }
  }, [curBed, stepIdx, loadStep, finishCase]);

  useEffect(() => {
    (window as any).__AWARD = {
      beds,
      progress,
      playerStats,
      openBed,
      loadStep,
      checkStep,
      handleMercySkip,
      finishCase,
      handleStepTimeout,
      startStepTimer,
      stopStepTimer,
    };
  }, [
    beds,
    progress,
    playerStats,
    openBed,
    loadStep,
    checkStep,
    handleMercySkip,
    finishCase,
    handleStepTimeout,
    startStepTimer,
    stopStepTimer,
  ]);

  const handleSelectDay = (day: number, isLocked: boolean, buttonEl: HTMLElement) => {
    if (isLocked) {
      SFX.bad();
      SFX.haptic([20, 30, 20]);
      buttonEl.classList.remove('shake');
      void buttonEl.offsetWidth;
      buttonEl.classList.add('shake');
      showToast(`ยังเข้าเวรนี้ไม่ได้! กรุณาผ่านเวรวันที่ ${unlockedDay} ให้สำเร็จก่อน`);
      return;
    }
    SFX.pick();
    setSelectedDay(day);
  };

  const handleToggleSetting = (key: 'sound' | 'haptics') => {
    setSettings((prev) => {
      const next = { ...prev, [key]: !prev[key] };
      saveLocal(SET_KEY, next);
      if (getAuthToken()) {
        authApi.updateSettings(next).catch(() => {});
      }
      if (key === 'haptics' && next.haptics) SFX.haptic(20);
      return next;
    });
    SFX.pick();
  };

  const handleExportCases = () => {
    SFX.pick();
    const dataStr =
      'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(beds, null, 2));
    const dlAnchor = document.createElement('a');
    dlAnchor.setAttribute('href', dataStr);
    dlAnchor.setAttribute(
      'download',
      `award_ccu_cases_${new Date().toISOString().slice(0, 10)}.json`
    );
    dlAnchor.click();
    showToast('ดาวน์โหลดไฟล์ JSON เรียบร้อย 📤');
  };

  const handleSwitchRoleDemo = async (targetRole: 'NURSE' | 'INSTRUCTOR') => {
    const email = targetRole === 'INSTRUCTOR' ? 'instructor@award.ccu' : 'nurse@award.ccu';
    try {
      const res = await authApi.login(email, 'password123');
      setAuthToken(res.token);
      setUser(res.user);
      await syncUserProgress();
      showToast(`สลับบัญชีเป็น ${res.user.displayName} ✨`);
    } catch (err: any) {
      showToast(err.message || 'สลับบัญชีไม่สำเร็จ');
    }
  };

  if (authChecked && !user) {
    return (
      <div className="app" id="app">
        <SvgSprite />
        <main className="viewport" id="view">
          <AuthPage
            onAuthenticated={async (loggedInUser) => {
              setUser(loggedInUser);
              await syncUserProgress();
            }}
            onToast={showToast}
          />
        </main>
        <div className={`toast ${toastMsg.show ? 'show' : ''}`} id="toast" role="status">
          {toastMsg.text}
        </div>
      </div>
    );
  }

  const lvl = levelOfStars(totalStars);
  const xp = maxStars > 0 && totalStars >= maxStars ? 100 : ((totalStars % 3) / 3) * 100;
  const isFirstStep = stepIdx === 0;
  const isLastStep = curBed ? stepIdx === curBed.stageData.length - 1 : false;
  const isPassed = curStep ? doneSet.has(curStep.id) : false;
  const canSkip = curStep ? !isPassed && (stepMistakes[curStep.id] || 0) >= 3 : false;

  return (
    <div className="app" id="app">
      <SvgSprite />

      <header className="topbar" id="topbar">
        {screen === 'ward' ? (
          <>
            <div className="avatar">
              {user?.avatar || '👩‍⚕️'}
              <b className="lvl">{lvl}</b>
            </div>
            <div className="who">
              <div className="rank" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span>{RANKS[lvl - 1]}</span>
                {user && (
                  <span
                    className={`role-pill ${user.role === 'INSTRUCTOR' ? 'instructor' : ''}`}
                    title={user.displayName}
                  >
                    {user.role === 'INSTRUCTOR' ? 'อาจารย์' : 'พยาบาล'}
                  </span>
                )}
              </div>
              <div className="xp">
                <i style={{ width: `${xp}%` }} />
              </div>
            </div>
            <div className="pill">
              <StarSvg on={true} size={20} />
              <span>{totalStars}</span>
              <small>/{maxStars}</small>
            </div>
            <button
              type="button"
              className="icon-btn"
              aria-label="เปิด/ปิดเสียง"
              onClick={() => handleToggleSetting('sound')}
            >
              <Icon name={settings.sound ? 'volume' : 'mute'} />
            </button>
          </>
        ) : (
          <>
            <button
              type="button"
              className="icon-btn"
              aria-label="ออกจากเคส"
              onClick={() => {
                if (doneSet.size === 0 && mistakes === 0) {
                  stopStepTimer();
                  setScreen('ward');
                } else {
                  setExitConfirmOpen(true);
                }
              }}
            >
              <Icon name="back" />
            </button>
            <div className="t-title">
              <b>{curBed?.bedCode}</b>
              <small>{curBed?.caseTitle}</small>
            </div>
            <div className="live-stars" aria-label={`ดาวที่ได้ตอนนี้ ${liveStars} ดวง`}>
              {[1, 2, 3].map((n) => (
                <StarSvg
                  key={n}
                  on={liveStars >= n}
                  size={22}
                  className={lostStarAnim === n ? 'lost' : ''}
                />
              ))}
            </div>
          </>
        )}
      </header>

      <main className="viewport" id="view" ref={viewportRef}>
        {screen === 'game' && curBed && stepState ? (
          <GamePage
            bed={curBed}
            stepIdx={stepIdx}
            doneSet={doneSet}
            stepState={stepState}
            stepTimeRemaining={stepTimeRemaining}
            viewportRef={viewportRef}
            onUpdateStepState={(updater) => {
              setStepState((prev) => {
                if (!prev) return prev;
                const updated = updater(prev);
                if (curStep) stepStatesCacheRef.current[curStep.id] = updated;
                return updated;
              });
            }}
          />
        ) : tab === 'roster' ? (
          <RosterPage
            beds={beds}
            progress={progress}
            calYear={calYear}
            calMonth={calMonth}
            selectedDay={selectedDay}
            unlockedDay={unlockedDay}
            rosterDaysProgress={rosterDaysProgress}
            getShiftForDay={getShiftForDay}
            onSelectDay={handleSelectDay}
            onPrevMonth={() => {
              SFX.pick();
              if (calMonth === 0) {
                setCalMonth(11);
                setCalYear((y) => y - 1);
              } else {
                setCalMonth((m) => m - 1);
              }
              setSelectedDay(1);
            }}
            onNextMonth={() => {
              SFX.pick();
              if (calMonth === 11) {
                setCalMonth(0);
                setCalYear((y) => y + 1);
              } else {
                setCalMonth((m) => m + 1);
              }
              setSelectedDay(1);
            }}
            onRandomizeShifts={() => {
              generateMonthSchedule(calYear, calMonth);
              showToast('สุ่มเวรใหม่ประจำเดือนแล้ว 🎲');
            }}
            onGoWardShift={(shiftId) => {
              SFX.pick();
              setFilterShift(shiftId);
              setTab('ward');
            }}
          />
        ) : tab === 'ward' ? (
          <WardPage
            beds={beds}
            progress={progress}
            filterShift={filterShift}
            passedCount={passedCount}
            nextTargetIdx={getNextTargetIdx()}
            onOpenBed={(idx) => {
              SFX.pick();
              openBed(idx);
            }}
            onClearFilter={() => {
              SFX.pick();
              setFilterShift(null);
            }}
            onOpenCaseMgmt={() => {
              SFX.pick();
              setTab('cases');
            }}
          />
        ) : tab === 'progress' ? (
          <ProgressPage
            beds={beds}
            progress={progress}
            playerStats={playerStats}
            rosterDaysProgress={rosterDaysProgress}
            totalStars={totalStars}
            passedCount={passedCount}
          />
        ) : tab === 'cases' ? (
          <CaseManagerPage
            beds={beds}
            onOpenBed={(idx) => {
              SFX.pick();
              openBed(idx);
            }}
            onCreateCase={async (payload) => {
              const res = await casesApi.create(payload);
              setBeds(res.cases);
              saveLocal(CUSTOM_BEDS_KEY, res.cases);
            }}
            onUpdateCase={async (bedNum, payload) => {
              const res = await casesApi.update(bedNum, payload);
              setBeds(res.cases);
              saveLocal(CUSTOM_BEDS_KEY, res.cases);
            }}
            onUpdateStep={async (bedNum, sIdx, stage) => {
              const res = await casesApi.updateStep(bedNum, sIdx, stage);
              setBeds(res.cases);
              saveLocal(CUSTOM_BEDS_KEY, res.cases);
            }}
            onDeleteCase={async (bedNum) => {
              const res = await casesApi.remove(bedNum);
              setBeds(res.cases);
              saveLocal(CUSTOM_BEDS_KEY, res.cases);
            }}
            onImportCases={async (imported) => {
              const res = await casesApi.importJson(imported);
              setBeds(res.cases);
              saveLocal(CUSTOM_BEDS_KEY, res.cases);
            }}
            onResetDefaultCases={async () => {
              const res = await casesApi.resetDefaults();
              setBeds(res.cases);
              saveLocal(CUSTOM_BEDS_KEY, res.cases);
            }}
            onExportCases={handleExportCases}
            onToast={showToast}
          />
        ) : (
          <SettingsPage
            user={user}
            settings={settings}
            onToggleSetting={handleToggleSetting}
            onOpenCaseMgmt={() => {
              SFX.pick();
              setTab('cases');
            }}
            onExportCases={handleExportCases}
            onResetAll={() => setResetConfirmOpen(true)}
            onLogout={() => {
              SFX.pick();
              setAuthToken(null);
              setUser(null);
              showToast('ออกจากระบบเรียบร้อยแล้ว');
            }}
            onSwitchRoleDemo={handleSwitchRoleDemo}
          />
        )}
      </main>

      <footer className="dock" id="dock">
        {screen === 'ward' ? (
          <nav className="tabbar">
            {(
              [
                ['roster', 'calendar', 'ตารางเวร'],
                ['ward', 'bed', 'วอร์ด'],
                ['progress', 'trophy', 'ความก้าวหน้า'],
                ['settings', 'sliders', 'ตั้งค่า'],
              ] as const
            ).map(([k, ic, label]) => (
              <button
                key={k}
                type="button"
                className={`tab ${tab === k ? 'on' : ''}`}
                data-tab={k}
                aria-current={tab === k}
                onClick={() => {
                  SFX.pick();
                  setTab(k);
                  if (viewportRef.current) viewportRef.current.scrollTop = 0;
                }}
              >
                <Icon name={ic} />
                <span>{label}</span>
              </button>
            ))}
          </nav>
        ) : (
          <div className="game-dock">
            {!isFirstStep && (
              <button
                type="button"
                className="btn btn-ghost btn-nav"
                data-act="step-prev"
                aria-label="ย้อนกลับ"
                onClick={() => {
                  SFX.pick();
                  loadStep(stepIdx - 1);
                }}
              >
                <Icon name="back" />
                <span>ย้อนกลับ</span>
              </button>
            )}

            {!isPassed ? (
              canSkip ? (
                <button
                  type="button"
                  className="btn btn-block btn-gold"
                  data-act="step-skip"
                  aria-label="ข้ามไปต่อ"
                  onClick={handleMercySkip}
                >
                  <span>💡 ดูเฉลย & ไปต่อ</span>
                  <Icon name="forward" />
                </button>
              ) : (
                <button
                  type="button"
                  className="btn btn-block btn-primary"
                  data-act="check"
                  onClick={checkStep}
                >
                  <Icon name="check" />
                  <span>ตรวจคำตอบ</span>
                </button>
              )
            ) : !isLastStep ? (
              <button
                type="button"
                className="btn btn-block btn-gold"
                data-act="step-next"
                aria-label="ไปต่อ"
                onClick={() => {
                  SFX.pick();
                  handleNextStep();
                }}
              >
                <span>ไปต่อ</span>
                <Icon name="forward" />
              </button>
            ) : (
              <div style={{ flex: 1, textAlign: 'center', fontWeight: 600, color: '#16a34a', fontSize: 14 }}>
                ✓ ทำหัตถการครบทุกขั้นตอนแล้ว
              </div>
            )}

            <button
              type="button"
              className="btn btn-ghost btn-sq"
              data-act="reset-step"
              disabled={isPassed}
              aria-label="จัดใหม่"
              onClick={() => {
                if (!curStep || isPassed) return;
                SFX.pick();
                const fresh = buildStepRuntimeState(curStep);
                stepStatesCacheRef.current[curStep.id] = fresh;
                setStepState(fresh);
              }}
            >
              <Icon name="undo" />
            </button>
          </div>
        )}
      </footer>

      <div
        className={`sheet ${sheet.kind} ${sheet.show ? 'show' : ''}`}
        id="sheet"
        role="status"
        aria-live="polite"
      >
        {sheet.show && (
          <>
            <div className="sheet-h">
              <span className="sheet-badge">
                <Icon name={sheet.kind === 'ok' ? 'check' : 'x'} />
              </span>
              <div>
                <b>{sheet.title}</b>
                <small>{sheet.sub}</small>
              </div>
            </div>
            {sheet.errors.length > 0 && (
              <ul>
                {sheet.errors.map((m, i) => (
                  <li key={i}>{m}</li>
                ))}
              </ul>
            )}
            {sheet.kind === 'ok' ? (
              <button type="button" className="btn btn-success btn-block" data-act="sheet-next" onClick={handleNextStep}>
                ไปต่อ
              </button>
            ) : sheet.canSkip ? (
              <div style={{ display: 'flex', gap: 8 }}>
                <button
                  type="button"
                  className="btn btn-ghost"
                  style={{ flex: 1 }}
                  data-act="sheet-retry"
                  onClick={() => {
                    setSheet((prev) => ({ ...prev, show: false }));
                    if (stepIdx === 1 && curStep && !doneSet.has(curStep.id)) {
                      startStepTimer(20);
                    }
                  }}
                >
                  ลองอีกที
                </button>
                <button
                  type="button"
                  className="btn btn-gold"
                  style={{ flex: 2 }}
                  data-act="step-skip"
                  onClick={handleMercySkip}
                >
                  💡 ดูเฉลย & ไปต่อ
                </button>
              </div>
            ) : (
              <button
                type="button"
                className="btn btn-danger btn-block"
                data-act="sheet-retry"
                onClick={() => {
                  setSheet((prev) => ({ ...prev, show: false }));
                  if (stepIdx === 1 && curStep && !doneSet.has(curStep.id)) {
                    startStepTimer(20);
                  }
                }}
              >
                {stepIdx === 1 ? 'ลองอีกครั้ง (จับเวลา 20 วิ)' : 'ลองอีกครั้ง'}
              </button>
            )}
          </>
        )}
      </div>

      <div
        className={`modal ${winModal?.show || exitConfirmOpen || resetConfirmOpen ? 'show' : ''}`}
        id="modal"
        role="dialog"
        aria-modal="true"
        onClick={(e) => {
          if (e.target === e.currentTarget && !winModal?.show) {
            setExitConfirmOpen(false);
            setResetConfirmOpen(false);
          }
        }}
      >
        {winModal?.show && (
          <div className="modal-card">
            <div className="confetti" aria-hidden="true">
              {Array.from({ length: 40 }, (_, i) => {
                const colors = ['#f59e0b', '#22c55e', '#0ea5e9', '#f43f5e', '#a855f7', '#fde047'];
                return (
                  <i
                    key={i}
                    style={{
                      left: `${(i * 2.5) % 100}%`,
                      background: colors[i % colors.length],
                      animationDuration: `${1.8 + (i % 5) * 0.3}s`,
                      animationDelay: `${(i % 7) * 0.1}s`,
                      transform: `rotate(${(i * 37) % 360}deg)`,
                    }}
                  />
                );
              })}
            </div>
            <div className="win-ribbon">เสร็จสิ้นเคส!</div>
            <h2>{winModal.bed.bedCode}</h2>
            <p className="win-sub">{winModal.bed.caseTitle}</p>
            <div className="big-stars">
              {[1, 2, 3].map((n) => (
                <span
                  key={n}
                  className={`big-star ${winModal.stars >= n ? 'on' : ''}`}
                  style={{ '--i': n - 1 } as React.CSSProperties}
                >
                  <StarSvg on={winModal.stars >= n} size={62} />
                </span>
              ))}
            </div>
            <p className="win-msg">{winModal.msg}</p>
            {winModal.shiftCompletedMsg && (
              <div className="lvl-up" style={{ background: '#ecfdf5', borderColor: '#86efac', color: '#065f46' }}>
                {winModal.shiftCompletedMsg}
              </div>
            )}
            {winModal.lvlUpText && <div className="lvl-up">{winModal.lvlUpText}</div>}
            <div className="modal-actions">
              {winModal.nextIdx >= 0 && winModal.nextIdx !== bedIdx && (
                <button
                  type="button"
                  className="btn btn-gold"
                  data-act="win-next"
                  onClick={() => {
                    const nxt = winModal.nextIdx;
                    setWinModal(null);
                    openBed(nxt);
                  }}
                >
                  เตียงถัดไป ▶
                </button>
              )}
              <button
                type="button"
                className="btn"
                data-act="win-ward"
                onClick={() => {
                  setWinModal(null);
                  setScreen('ward');
                }}
              >
                <Icon name="bed" />
                <span>กลับวอร์ด</span>
              </button>
              <button
                type="button"
                className="btn btn-ghost"
                data-act="win-replay"
                onClick={() => {
                  setWinModal(null);
                  openBed(bedIdx);
                }}
              >
                <Icon name="undo" />
                <span>เล่นซ้ำเก็บ 3 ดาว</span>
              </button>
            </div>
          </div>
        )}

        {exitConfirmOpen && (
          <div className="modal-card">
            <h2 className="dialog-t" style={{ marginTop: 0 }}>
              ออกจากเคสนี้?
            </h2>
            <p className="dialog-p">ความคืบหน้าในเคสนี้จะหายไป ต้องเริ่มใหม่ตั้งแต่ขั้นแรก</p>
            <div className="modal-actions">
              <button
                type="button"
                className="btn btn-danger"
                data-act="exit-confirm"
                onClick={() => {
                  stopStepTimer();
                  setExitConfirmOpen(false);
                  setScreen('ward');
                }}
              >
                ออกจากเคส
              </button>
              <button type="button" className="btn btn-ghost" onClick={() => setExitConfirmOpen(false)}>
                ยกเลิก
              </button>
            </div>
          </div>
        )}

        {resetConfirmOpen && (
          <div className="modal-card">
            <h2 className="dialog-t" style={{ marginTop: 0 }}>
              ล้างความก้าวหน้าทั้งหมด?
            </h2>
            <p className="dialog-p">ดาวและเตียงที่ผ่านแล้วจะหายไป ย้อนกลับไม่ได้</p>
            <div className="modal-actions">
              <button
                type="button"
                className="btn btn-danger"
                data-act="reset-confirm"
                onClick={async () => {
                  setProgress({});
                  setRosterDaysProgress({});
                  const emptyStats: PlayerStats = {
                    totalCompletedCases: 0,
                    totalPlaySeconds: 0,
                    perfectCases: 0,
                    shiftsCompleted: 0,
                    trayItemsSorted: 0,
                    stepsWithoutMistake: 0,
                    emergencyCasesDone: 0,
                    replayedCases: 0,
                  };
                  setPlayerStats(emptyStats);
                  saveLocal(SAVE_KEY, {});
                  saveLocal(ROSTER_PROGRESS_KEY, {});
                  saveLocal(STATS_KEY, emptyStats);
                  if (getAuthToken()) {
                    await progressApi.reset().catch(() => {});
                  }
                  setResetConfirmOpen(false);
                  showToast('ล้างความก้าวหน้าแล้ว');
                }}
              >
                ล้างข้อมูล
              </button>
              <button type="button" className="btn btn-ghost" onClick={() => setResetConfirmOpen(false)}>
                ยกเลิก
              </button>
            </div>
          </div>
        )}
      </div>

      <div className={`toast ${toastMsg.show ? 'show' : ''}`} id="toast" role="status" aria-live="polite">
        {toastMsg.text}
      </div>
    </div>
  );
};






