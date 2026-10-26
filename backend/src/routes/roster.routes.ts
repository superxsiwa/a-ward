import { Router } from 'express';
import { saveMonthRoster, clearRosterDay } from '../controllers/progress.controller';
import { verifyToken } from '../middleware/authMiddleware';

const router = Router();

router.put('/:monthKey', verifyToken, saveMonthRoster);
router.post('/clear-day', verifyToken, clearRosterDay);

export default router;
