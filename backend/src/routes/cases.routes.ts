import { Router } from 'express';
import {
  getAllCases,
  getCaseByBedNum,
  createCase,
  updateCase,
  updateCaseStep,
  deleteCase,
  importCases,
  resetDefaultCases,
} from '../controllers/cases.controller';
import { verifyToken, requireRole } from '../middleware/authMiddleware';

const router = Router();

router.get('/', getAllCases);
router.get('/:bedNum', getCaseByBedNum);
router.post('/', verifyToken, requireRole('INSTRUCTOR'), createCase);
router.put('/:bedNum', verifyToken, requireRole('INSTRUCTOR'), updateCase);
router.put('/:bedNum/steps/:stepIndex', verifyToken, requireRole('INSTRUCTOR'), updateCaseStep);
router.delete('/:bedNum', verifyToken, requireRole('INSTRUCTOR'), deleteCase);
router.post('/import', verifyToken, requireRole('INSTRUCTOR'), importCases);
router.post('/reset-defaults', verifyToken, requireRole('INSTRUCTOR'), resetDefaultCases);

export default router;
