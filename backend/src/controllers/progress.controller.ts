import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/prisma';

const SHIFT_BEDS: Record<string, number[]> = {
  morning: [1, 2],
  afternoon: [3, 4, 5],
  night: [6, 7, 8],
};

export async function getMyProgress(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = req.user!.userId;

    const [bedProg, statsRow, settingsRow, rosterRows, dayRows] = await Promise.all([
      prisma.bedProgress.findMany({ where: { userId } }),
      prisma.playerStats.upsert({ where: { userId }, create: { userId }, update: {} }),
      prisma.playerSettings.upsert({ where: { userId }, create: { userId }, update: {} }),
      prisma.rosterSchedule.findMany({ where: { userId } }),
      prisma.rosterDayProgress.findMany({ where: { userId } }),
    ]);

    const progressMap: Record<number, { passed: boolean; stars: number; bestMistakes?: number }> = {};
    bedProg.forEach((bp) => {
      progressMap[bp.bedNum] = {
        passed: bp.passed,
        stars: bp.stars,
        bestMistakes: bp.bestMistakes,
      };
    });

    const rosterScheduleMap: Record<string, Record<string, string>> = {};
    rosterRows.forEach((r) => {
      try {
        rosterScheduleMap[r.monthKey] = JSON.parse(r.scheduleJson);
      } catch (_e) {
        rosterScheduleMap[r.monthKey] = {};
      }
    });

    const rosterDaysProgressMap: Record<string, { passed: boolean; shiftId?: string }> = {};
    dayRows.forEach((d) => {
      rosterDaysProgressMap[d.dayKey] = {
        passed: d.passed,
        shiftId: d.shiftId,
      };
    });

    res.json({
      progress: progressMap,
      playerStats: {
        totalCompletedCases: statsRow.totalCompletedCases,
        totalPlaySeconds: statsRow.totalPlaySeconds,
        perfectCases: statsRow.perfectCases,
        shiftsCompleted: statsRow.shiftsCompleted,
        trayItemsSorted: statsRow.trayItemsSorted,
        stepsWithoutMistake: statsRow.stepsWithoutMistake,
        emergencyCasesDone: statsRow.emergencyCasesDone,
        replayedCases: statsRow.replayedCases,
      },
      rosterSchedule: rosterScheduleMap,
      rosterDaysProgress: rosterDaysProgressMap,
      settings: {
        sound: settingsRow.soundEnabled,
        haptics: settingsRow.hapticsEnabled,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function completeCase(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = req.user!.userId;
    const {
      bedNum,
      mistakes = 0,
      stars: inputStars,
      durationSeconds = 60,
      trayItemsSortedDelta = 0,
      stepsWithoutMistakeDelta = 0,
      isEmergency = false,
      activeShift,
      dayKey,
    } = req.body;

    const bNum = Number(bedNum);
    const calcStars = inputStars || (mistakes === 0 ? 3 : mistakes <= 2 ? 2 : 1);

    const existingProg = await prisma.bedProgress.findUnique({
      where: { userId_bedNum: { userId, bedNum: bNum } },
    });

    const wasAlreadyPassed = !!existingProg?.passed;
    const bestStars = Math.max(existingProg?.stars || 0, calcStars);
    const bestMistakes = existingProg
      ? Math.min(existingProg.bestMistakes, Number(mistakes))
      : Number(mistakes);

    await prisma.bedProgress.upsert({
      where: { userId_bedNum: { userId, bedNum: bNum } },
      create: {
        userId,
        bedNum: bNum,
        passed: true,
        stars: bestStars,
        bestMistakes: Number(mistakes),
        attemptCount: 1,
      },
      update: {
        passed: true,
        stars: bestStars,
        bestMistakes,
        attemptCount: { increment: 1 },
      },
    });

    await prisma.caseAttemptLog.create({
      data: {
        userId,
        bedNum: bNum,
        starsEarned: calcStars,
        mistakesCount: Number(mistakes),
        durationSeconds: Number(durationSeconds) || 0,
      },
    });

    let shiftDayCleared = false;
    if (activeShift && dayKey && SHIFT_BEDS[activeShift]) {
      const allUserProg = await prisma.bedProgress.findMany({ where: { userId } });
      const passedSet = new Set(allUserProg.filter((p) => p.passed).map((p) => p.bedNum));
      const requiredBeds = SHIFT_BEDS[activeShift];
      if (requiredBeds.every((n) => passedSet.has(n))) {
        const existingDay = await prisma.rosterDayProgress.findUnique({
          where: { userId_dayKey: { userId, dayKey } },
        });
        if (!existingDay || !existingDay.passed) {
          await prisma.rosterDayProgress.upsert({
            where: { userId_dayKey: { userId, dayKey } },
            create: { userId, dayKey, shiftId: activeShift, passed: true },
            update: { passed: true, shiftId: activeShift },
          });
          shiftDayCleared = true;
        }
      }
    }

    const updatedStats = await prisma.playerStats.upsert({
      where: { userId },
      create: {
        userId,
        totalCompletedCases: 1,
        perfectCases: calcStars === 3 ? 1 : 0,
        shiftsCompleted: shiftDayCleared ? 1 : 0,
        trayItemsSorted: Number(trayItemsSortedDelta) || 0,
        stepsWithoutMistake: Number(stepsWithoutMistakeDelta) || 0,
        emergencyCasesDone: isEmergency ? 1 : 0,
        replayedCases: wasAlreadyPassed ? 1 : 0,
      },
      update: {
        totalCompletedCases: { increment: 1 },
        ...(calcStars === 3 ? { perfectCases: { increment: 1 } } : {}),
        ...(shiftDayCleared ? { shiftsCompleted: { increment: 1 } } : {}),
        ...(trayItemsSortedDelta ? { trayItemsSorted: { increment: Number(trayItemsSortedDelta) } } : {}),
        ...(stepsWithoutMistakeDelta ? { stepsWithoutMistake: { increment: Number(stepsWithoutMistakeDelta) } } : {}),
        ...(isEmergency ? { emergencyCasesDone: { increment: 1 } } : {}),
        ...(wasAlreadyPassed ? { replayedCases: { increment: 1 } } : {}),
      },
    });

    res.json({
      bedNum: bNum,
      starsEarned: calcStars,
      bestStars,
      shiftDayCleared,
      playerStats: updatedStats,
    });
  } catch (err) {
    next(err);
  }
}

export async function recordHeartbeat(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = req.user!.userId;
    const seconds = Math.min(60, Math.max(1, Number(req.body.seconds) || 5));

    const stats = await prisma.playerStats.upsert({
      where: { userId },
      create: { userId, totalPlaySeconds: seconds },
      update: { totalPlaySeconds: { increment: seconds } },
    });

    res.json({ totalPlaySeconds: stats.totalPlaySeconds });
  } catch (err) {
    next(err);
  }
}

export async function resetProgress(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = req.user!.userId;
    await prisma.$transaction([
      prisma.bedProgress.deleteMany({ where: { userId } }),
      prisma.rosterDayProgress.deleteMany({ where: { userId } }),
      prisma.playerStats.upsert({
        where: { userId },
        create: { userId },
        update: {
          totalCompletedCases: 0,
          totalPlaySeconds: 0,
          perfectCases: 0,
          shiftsCompleted: 0,
          trayItemsSorted: 0,
          stepsWithoutMistake: 0,
          emergencyCasesDone: 0,
          replayedCases: 0,
        },
      }),
    ]);

    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}

export async function saveMonthRoster(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = req.user!.userId;
    const monthKey = String(req.params.monthKey);
    const schedule = req.body.schedule || req.body;

    await prisma.rosterSchedule.upsert({
      where: { userId_monthKey: { userId, monthKey } },
      create: {
        userId,
        monthKey,
        scheduleJson: JSON.stringify(schedule),
      },
      update: {
        scheduleJson: JSON.stringify(schedule),
      },
    });

    res.json({ ok: true, monthKey, schedule });
  } catch (err) {
    next(err);
  }
}

export async function clearRosterDay(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const userId = req.user!.userId;
    const { dayKey, shiftId = 'off' } = req.body;
    if (!dayKey) {
      res.status(400).json({ error: 'dayKey is required' });
      return;
    }

    await prisma.rosterDayProgress.upsert({
      where: { userId_dayKey: { userId, dayKey } },
      create: { userId, dayKey, shiftId, passed: true },
      update: { passed: true, shiftId },
    });

    res.json({ ok: true, dayKey });
  } catch (err) {
    next(err);
  }
}
