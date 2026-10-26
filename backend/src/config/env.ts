import dotenv from 'dotenv';
dotenv.config();

export const ENV = {
  PORT: parseInt(process.env.PORT || '4000', 10),
  JWT_SECRET: process.env.JWT_SECRET || 'award-ccu-super-secret-clinical-jwt-key-2026',
  DATABASE_URL: process.env.DATABASE_URL || 'file:./dev.db',
};
