import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/prisma';
import { DEFAULT_CCU_BEDS, BedCasePayload, StagePayload } from '../services/defaultCases';
import { seedDefaultCases, upsertBedCase } from '../services/seedService';

export function formatBedFromDb(bed: any): BedCasePayload {
  const stages: StagePayload[] = (bed.stages || [])
    .sort((a: any, b: any) => a.stepIndex - b.stepIndex)
    .map((st: any) => {
      const stageObj: StagePayload = {
        id: st.stageNumber || st.stepIndex + 1,
        name: st.name,
        mechanic: st.mechanic,
        reading: st.reading,
        doctorSpeech: st.doctorSpeech,
        vitals: JSON.parse(st.vitalsJson || '{"hr":80,"bp":"120/80","spo2":"99%","map":93}'),
      };
      if (st.choicesJson) stageObj.choices1toN = JSON.parse(st.choicesJson);
      if (st.sequenceJson) stageObj.sequenceTask = JSON.parse(st.sequenceJson);
      if (st.traysJson) stageObj.traysTask = JSON.parse(st.traysJson);
      if (st.unorderedJson) stageObj.unorderedDropTask = JSON.parse(st.unorderedJson);
      return stageObj;
    });

  return {
    bedNum: bed.bedNum,
    bedCode: bed.bedCode,
    patientName: bed.patientName,
    patientAge: bed.patientAge,
    caseTitle: bed.caseTitle,
    dxBadge: bed.dxBadge,
    status: bed.status as 'stable' | 'alert' | 'critical',
    statusText: bed.statusText,
    doctorName: bed.doctorName,
    doctorAvatar: bed.doctorAvatar,
    stayDuration: bed.stayDuration,
    clinicalNote: bed.clinicalNote,
    stageData: stages,
  };
}

export async function getAllCases(_req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    let beds = await prisma.ccuBed.findMany({
      orderBy: { bedNum: 'asc' },
      include: { stages: { orderBy: { stepIndex: 'asc' } } },
    });

    if (beds.length === 0) {
      await seedDefaultCases(true);
      beds = await prisma.ccuBed.findMany({
        orderBy: { bedNum: 'asc' },
        include: { stages: { orderBy: { stepIndex: 'asc' } } },
      });
    }

    res.json({ cases: beds.map(formatBedFromDb) });
  } catch (err) {
    next(err);
  }
}

export async function getCaseByBedNum(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const bedNum = parseInt(String(req.params.bedNum), 10);
    const bed = await prisma.ccuBed.findUnique({
      where: { bedNum },
      include: { stages: { orderBy: { stepIndex: 'asc' } } },
    });

    if (!bed) {
      res.status(404).json({ error: `ไม่พบเคสเตียง ${bedNum}` });
      return;
    }

    res.json({ caseItem: formatBedFromDb(bed) });
  } catch (err) {
    next(err);
  }
}

export async function createCase(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const body = req.body;
    const count = await prisma.ccuBed.count();
    const bedNum = Number(body.bedNum) || count + 1;

    const templateStages =
      Array.isArray(body.stageData) && body.stageData.length > 0
        ? body.stageData
        : JSON.parse(JSON.stringify(DEFAULT_CCU_BEDS[0].stageData));

    const payload: BedCasePayload = {
      bedNum,
      bedCode: body.bedCode || `เตียง ${String(bedNum).padStart(2, '0')} CCU`,
      patientName: body.patientName || 'ผู้ป่วยใหม่ CCU (65 ปี)',
      patientAge: Number(body.patientAge) || 65,
      caseTitle: body.caseTitle || 'เคสหัตถการจำลองใหม่ CCU',
      dxBadge: body.dxBadge || 'CCU Patient',
      status: body.status || 'alert',
      statusText: body.statusText || 'เฝ้าระวังอาการ',
      doctorName: body.doctorName || 'นพ. ธีรภพ (อายุรแพทย์หัวใจ)',
      doctorAvatar: body.doctorAvatar || '👨‍⚕️',
      stayDuration: body.stayDuration || 'วันที่ 1 ใน CCU',
      clinicalNote: body.clinicalNote || '',
      stageData: templateStages,
    };

    await upsertBedCase(payload, false);
    const allBeds = await prisma.ccuBed.findMany({
      orderBy: { bedNum: 'asc' },
      include: { stages: { orderBy: { stepIndex: 'asc' } } },
    });

    res.status(201).json({ cases: allBeds.map(formatBedFromDb) });
  } catch (err) {
    next(err);
  }
}

export async function updateCase(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const targetBedNum = parseInt(String(req.params.bedNum), 10);
    const existing = await prisma.ccuBed.findUnique({ where: { bedNum: targetBedNum } });
    if (!existing) {
      res.status(404).json({ error: `ไม่พบเคสเตียง ${targetBedNum}` });
      return;
    }

    const body = req.body;
    const newBedNum = Number(body.bedNum) || targetBedNum;

    await prisma.ccuBed.update({
      where: { id: existing.id },
      data: {
        bedNum: newBedNum,
        bedCode: body.bedCode || `เตียง ${String(newBedNum).padStart(2, '0')} CCU`,
        patientName: body.patientName ?? existing.patientName,
        patientAge: body.patientAge !== undefined ? Number(body.patientAge) : existing.patientAge,
        caseTitle: body.caseTitle ?? existing.caseTitle,
        dxBadge: body.dxBadge ?? existing.dxBadge,
        status: body.status ?? existing.status,
        statusText: body.statusText ?? existing.statusText,
        doctorName: body.doctorName ?? existing.doctorName,
        doctorAvatar: body.doctorAvatar ?? existing.doctorAvatar,
        stayDuration: body.stayDuration ?? existing.stayDuration,
        clinicalNote: body.clinicalNote ?? existing.clinicalNote,
      },
    });

    const allBeds = await prisma.ccuBed.findMany({
      orderBy: { bedNum: 'asc' },
      include: { stages: { orderBy: { stepIndex: 'asc' } } },
    });
    res.json({ cases: allBeds.map(formatBedFromDb) });
  } catch (err) {
    next(err);
  }
}

export async function updateCaseStep(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const bedNum = parseInt(String(req.params.bedNum), 10);
    const stepIndex = parseInt(String(req.params.stepIndex), 10);
    const bed = await prisma.ccuBed.findUnique({ where: { bedNum } });
    if (!bed) {
      res.status(404).json({ error: `ไม่พบเคสเตียง ${bedNum}` });
      return;
    }

    const st: StagePayload = req.body;
    const dataPayload = {
      name: st.name || `${stepIndex + 1}. ขั้นตอนที่ ${stepIndex + 1}`,
      mechanic: st.mechanic || 'ลาก-วาง เรียงลำดับ',
      doctorSpeech: st.doctorSpeech || '💬 "ดำเนินการตามขั้นตอนได้เลยครับ"',
      reading: st.reading || '',
      vitalsJson: JSON.stringify(st.vitals || { hr: 80, bp: '120/80', spo2: '99%', map: 93 }),
      choicesJson: st.choices1toN ? JSON.stringify(st.choices1toN) : null,
      sequenceJson: st.sequenceTask ? JSON.stringify(st.sequenceTask) : null,
      traysJson: st.traysTask ? JSON.stringify(st.traysTask) : null,
      unorderedJson: st.unorderedDropTask ? JSON.stringify(st.unorderedDropTask) : null,
    };

    await prisma.procedureStage.upsert({
      where: { bedId_stepIndex: { bedId: bed.id, stepIndex } },
      create: { bedId: bed.id, stepIndex, stageNumber: stepIndex + 1, ...dataPayload },
      update: dataPayload,
    });

    const allBeds = await prisma.ccuBed.findMany({
      orderBy: { bedNum: 'asc' },
      include: { stages: { orderBy: { stepIndex: 'asc' } } },
    });
    res.json({ cases: allBeds.map(formatBedFromDb) });
  } catch (err) {
    next(err);
  }
}

export async function deleteCase(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const bedNum = parseInt(String(req.params.bedNum), 10);
    const total = await prisma.ccuBed.count();
    if (total <= 1) {
      res.status(400).json({ error: 'ต้องมีเคสอย่างน้อย 1 เคสในระบบ' });
      return;
    }

    await prisma.ccuBed.delete({ where: { bedNum } });
    const remaining = await prisma.ccuBed.findMany({ orderBy: { bedNum: 'asc' } });
    for (let i = 0; i < remaining.length; i++) {
      const newNum = i + 1;
      if (remaining[i].bedNum !== newNum) {
        await prisma.ccuBed.update({
          where: { id: remaining[i].id },
          data: { bedNum: newNum, bedCode: `เตียง ${String(newNum).padStart(2, '0')} CCU` },
        });
      }
    }

    const allBeds = await prisma.ccuBed.findMany({
      orderBy: { bedNum: 'asc' },
      include: { stages: { orderBy: { stepIndex: 'asc' } } },
    });
    res.json({ cases: allBeds.map(formatBedFromDb) });
  } catch (err) {
    next(err);
  }
}

export async function importCases(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const casesInput: BedCasePayload[] = Array.isArray(req.body) ? req.body : req.body.cases;
    if (!Array.isArray(casesInput) || casesInput.length === 0 || !casesInput[0].caseTitle) {
      res.status(400).json({ error: 'รูปแบบข้อมูลเคส JSON ไม่ถูกต้อง' });
      return;
    }

    await prisma.procedureStage.deleteMany({});
    await prisma.ccuBed.deleteMany({});
    for (let i = 0; i < casesInput.length; i++) {
      const c = casesInput[i];
      c.bedNum = Number(c.bedNum) || i + 1;
      await upsertBedCase(c, false);
    }

    const allBeds = await prisma.ccuBed.findMany({
      orderBy: { bedNum: 'asc' },
      include: { stages: { orderBy: { stepIndex: 'asc' } } },
    });
    res.json({ cases: allBeds.map(formatBedFromDb) });
  } catch (err) {
    next(err);
  }
}

export async function resetDefaultCases(_req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await seedDefaultCases(true);
    const allBeds = await prisma.ccuBed.findMany({
      orderBy: { bedNum: 'asc' },
      include: { stages: { orderBy: { stepIndex: 'asc' } } },
    });
    res.json({ cases: allBeds.map(formatBedFromDb) });
  } catch (err) {
    next(err);
  }
}
