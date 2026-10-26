import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/prisma';

const RANKS = [
  'นักศึกษาพยาบาลฝึกหัด',
  'พยาบาลฝึกงาน',
  'พยาบาลน้องใหม่ CCU',
  'พยาบาล CCU ฝีมือดี',
  'พยาบาลชำนาญการ',
  'หัวหน้าเวร CCU',
  'พยาบาล CCU ดาวเด่น',
  'ผู้เชี่ยวชาญ CCU',
  'ตำนานแห่งหอผู้ป่วยวิกฤต',
];

export async function getStudentsLeaderboard(_req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const users = await prisma.user.findMany({
      include: {
        stats: true,
        bedProgress: true,
        rosterDayProgress: true,
      },
      orderBy: { createdAt: 'asc' },
    });

    const students = users.map((u) => {
      const passedBeds = u.bedProgress.filter((b) => b.passed);
      const totalStars = u.bedProgress.reduce((sum, b) => sum + (b.stars || 0), 0);
      const level = Math.min(Math.floor(totalStars / 3) + 1, RANKS.length);
      const shiftsCleared = u.rosterDayProgress.filter((d) => d.passed).length;

      return {
        id: u.id,
        email: u.email,
        displayName: u.displayName,
        role: u.role,
        avatar: u.avatar,
        level,
        rankTitle: RANKS[level - 1],
        totalStars,
        passedBedsCount: passedBeds.length,
        totalCompletedCases: u.stats?.totalCompletedCases || 0,
        perfectCases: u.stats?.perfectCases || 0,
        shiftsCompleted: Math.max(u.stats?.shiftsCompleted || 0, shiftsCleared),
        totalPlaySeconds: u.stats?.totalPlaySeconds || 0,
        updatedAt: u.updatedAt,
      };
    });

    students.sort((a, b) => b.totalStars - a.totalStars || b.totalCompletedCases - a.totalCompletedCases);

    res.json({ students });
  } catch (err) {
    next(err);
  }
}
