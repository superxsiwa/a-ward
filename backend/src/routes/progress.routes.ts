import { Router } from 'express';
import {
  getMyProgress,
  completeCase,
  recordHeartbeat,
  resetProgress,
} from '../controllers/progress.controller';
import { verifyToken } from '../middleware/authMiddleware';

const router = Router();

router.get('/me', verifyToken, getMyProgress);
router.post('/complete-case', verifyToken, completeCase);
router.post('/heartbeat', verifyToken, recordHeartbeat);
router.post('/reset', verifyToken, resetProgress);

export default router;
