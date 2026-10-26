import { Request, Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { prisma } from '../config/prisma';
import { ENV } from '../config/env';

const registerSchema = z.object({
  email: z.string().email('รูปแบบอีเมลไม่ถูกต้อง'),
  password: z.string().min(6, 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'),
  displayName: z.string().min(1, 'กรุณาระบุชื่อที่แสดง'),
  role: z.enum(['NURSE', 'INSTRUCTOR']).optional().default('NURSE'),
  avatar: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().email('รูปแบบอีเมลไม่ถูกต้อง'),
  password: z.string().min(1, 'กรุณาระบุรหัสผ่าน'),
});

const settingsSchema = z.object({
  sound: z.boolean().optional(),
  haptics: z.boolean().optional(),
  displayName: z.string().min(1).optional(),
  avatar: z.string().optional(),
});

function signToken(user: { id: string; email: string; role: string }) {
  return jwt.sign(
    {
      userId: user.id,
      email: user.email,
      role: user.role as 'NURSE' | 'INSTRUCTOR',
    },
    ENV.JWT_SECRET,
    { expiresIn: '30d' }
  );
}

export async function register(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const body = registerSchema.parse(req.body);
    const emailLower = body.email.toLowerCase().trim();

    const existing = await prisma.user.findUnique({ where: { email: emailLower } });
    if (existing) {
      res.status(409).json({ error: 'อีเมลนี้ถูกใช้งานแล้ว กรุณาเข้าสู่ระบบ' });
      return;
    }

    const passwordHash = await bcrypt.hash(body.password, 10);
    const defaultAvatar = body.avatar || (body.role === 'INSTRUCTOR' ? '👨‍⚕️' : '👩‍⚕️');

    const user = await prisma.user.create({
      data: {
        email: emailLower,
        passwordHash,
        displayName: body.displayName.trim(),
        role: body.role,
        avatar: defaultAvatar,
        stats: { create: {} },
        settings: { create: { soundEnabled: true, hapticsEnabled: true } },
      },
      include: {
        stats: true,
        settings: true,
      },
    });

    const token = signToken(user);
    res.status(201).json({
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
        avatar: user.avatar,
        settings: {
          sound: user.settings?.soundEnabled ?? true,
          haptics: user.settings?.hapticsEnabled ?? true,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function login(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const body = loginSchema.parse(req.body);
    const emailLower = body.email.toLowerCase().trim();

    const user = await prisma.user.findUnique({
      where: { email: emailLower },
      include: { stats: true, settings: true },
    });

    if (!user) {
      res.status(401).json({ error: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });
      return;
    }

    const valid = await bcrypt.compare(body.password, user.passwordHash);
    if (!valid) {
      res.status(401).json({ error: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });
      return;
    }

    // Ensure stats and settings exist
    if (!user.stats) {
      await prisma.playerStats.create({ data: { userId: user.id } });
    }
    if (!user.settings) {
      await prisma.playerSettings.create({ data: { userId: user.id } });
    }

    const token = signToken(user);
    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
        avatar: user.avatar,
        settings: {
          sound: user.settings?.soundEnabled ?? true,
          haptics: user.settings?.hapticsEnabled ?? true,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: req.user.userId },
      include: { stats: true, settings: true },
    });

    if (!user) {
      res.status(404).json({ error: 'ไม่พบบัญชีผู้ใช้งาน' });
      return;
    }

    res.json({
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
        avatar: user.avatar,
        settings: {
          sound: user.settings?.soundEnabled ?? true,
          haptics: user.settings?.hapticsEnabled ?? true,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function updateSettings(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const body = settingsSchema.parse(req.body);
    const userId = req.user.userId;

    if (body.displayName || body.avatar) {
      await prisma.user.update({
        where: { id: userId },
        data: {
          ...(body.displayName ? { displayName: body.displayName.trim() } : {}),
          ...(body.avatar ? { avatar: body.avatar } : {}),
        },
      });
    }

    const updatedSettings = await prisma.playerSettings.upsert({
      where: { userId },
      create: {
        userId,
        soundEnabled: body.sound ?? true,
        hapticsEnabled: body.haptics ?? true,
      },
      update: {
        ...(body.sound !== undefined ? { soundEnabled: body.sound } : {}),
        ...(body.haptics !== undefined ? { hapticsEnabled: body.haptics } : {}),
      },
    });

    res.json({
      settings: {
        sound: updatedSettings.soundEnabled,
        haptics: updatedSettings.hapticsEnabled,
      },
    });
  } catch (err) {
    next(err);
  }
}
