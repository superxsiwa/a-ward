import { Router } from 'express';
import { getStudentsLeaderboard } from '../controllers/instructor.controller';
import { verifyToken, requireRole } from '../middleware/authMiddleware';

const router = Router();

router.get('/students', verifyToken, requireRole('INSTRUCTOR'), getStudentsLeaderboard);

export default router;
