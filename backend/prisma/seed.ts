import bcrypt from 'bcryptjs';
import { prisma } from '../src/config/prisma';
import { DEFAULT_CCU_BEDS, BedCasePayload } from '../src/services/defaultCases';

export async function seedDefaultCases(forceReset = false): Promise<void> {
  const existingCount = await prisma.ccuBed.count();
  if (existingCount > 0 && !forceReset) {
    return;
  }

  if (forceReset) {
    await prisma.procedureStage.deleteMany({});
    await prisma.ccuBed.deleteMany({});
  }

  for (const bed of DEFAULT_CCU_BEDS) {
    await upsertBedCase(bed, true);
  }
}

export async function upsertBedCase(bed: BedCasePayload, isDefault = false) {
  const createdBed = await prisma.ccuBed.upsert({
    where: { bedNum: bed.bedNum },
    create: {
      bedNum: bed.bedNum,
      bedCode: bed.bedCode || `เตียง ${String(bed.bedNum).padStart(2, '0')} CCU`,
      patientName: bed.patientName,
      patientAge: bed.patientAge || 65,
      caseTitle: bed.caseTitle,
      dxBadge: bed.dxBadge,
      status: bed.status || 'alert',
      statusText: bed.statusText,
      doctorName: bed.doctorName,
      doctorAvatar: bed.doctorAvatar || '👨‍⚕️',
      stayDuration: bed.stayDuration || 'วันที่ 1 ใน CCU',
      clinicalNote: bed.clinicalNote || '',
      isDefault,
    },
    update: {
      bedCode: bed.bedCode || `เตียง ${String(bed.bedNum).padStart(2, '0')} CCU`,
      patientName: bed.patientName,
      patientAge: bed.patientAge || 65,
      caseTitle: bed.caseTitle,
      dxBadge: bed.dxBadge,
      status: bed.status || 'alert',
      statusText: bed.statusText,
      doctorName: bed.doctorName,
      doctorAvatar: bed.doctorAvatar || '👨‍⚕️',
      stayDuration: bed.stayDuration || 'วันที่ 1 ใน CCU',
      clinicalNote: bed.clinicalNote || '',
      isDefault,
    },
  });

  await prisma.procedureStage.deleteMany({ where: { bedId: createdBed.id } });

  const stages = bed.stageData || [];
  for (let idx = 0; idx < stages.length; idx++) {
    const st = stages[idx];
    await prisma.procedureStage.create({
      data: {
        bedId: createdBed.id,
        stepIndex: idx,
        stageNumber: idx + 1,
        name: st.name || `${idx + 1}. ขั้นตอนที่ ${idx + 1}`,
        mechanic: st.mechanic || 'ลาก-วาง เรียงลำดับ',
        doctorSpeech: st.doctorSpeech || '💬 "ดำเนินการตามขั้นตอนได้เลยครับ"',
        reading: st.reading || '',
        vitalsJson: JSON.stringify(st.vitals || { hr: 80, bp: '120/80', spo2: '99%', map: 93 }),
        choicesJson: st.choices1toN ? JSON.stringify(st.choices1toN) : null,
        sequenceJson: st.sequenceTask ? JSON.stringify(st.sequenceTask) : null,
        traysJson: st.traysTask ? JSON.stringify(st.traysTask) : null,
        unorderedJson: st.unorderedDropTask ? JSON.stringify(st.unorderedDropTask) : null,
      },
    });
  }

  return createdBed;
}

export async function seedDemoUsers(): Promise<void> {
  const passwordHash = await bcrypt.hash('password123', 10);

  // 1. Demo Nurse account
  await prisma.user.upsert({
    where: { email: 'nurse@award.ccu' },
    create: {
      email: 'nurse@award.ccu',
      passwordHash,
      displayName: 'พว. พิมพ์ชนก (พยาบาล CCU)',
      role: 'NURSE',
      avatar: '👩‍⚕️',
      stats: { create: {} },
      settings: { create: { soundEnabled: true, hapticsEnabled: true } },
    },
    update: {},
  });

  // 2. Demo Instructor account
  await prisma.user.upsert({
    where: { email: 'instructor@award.ccu' },
    create: {
      email: 'instructor@award.ccu',
      passwordHash,
      displayName: 'อ.ดร. นพ. ธีรภพ (อาจารย์พยาบาล CCU)',
      role: 'INSTRUCTOR',
      avatar: '👨‍⚕️',
      stats: { create: {} },
      settings: { create: { soundEnabled: true, hapticsEnabled: true } },
    },
    update: {},
  });

  // 3. Additional sample students for Leaderboard richness
  const sampleStudent1 = await prisma.user.upsert({
    where: { email: 'kanda.rn@award.ccu' },
    create: {
      email: 'kanda.rn@award.ccu',
      passwordHash,
      displayName: 'นศ.พย. กานดา สุขใจ',
      role: 'NURSE',
      avatar: '👩‍⚕️',
      stats: {
        create: {
          totalCompletedCases: 6,
          totalPlaySeconds: 4200,
          perfectCases: 4,
          shiftsCompleted: 2,
          trayItemsSorted: 42,
          stepsWithoutMistake: 30,
          emergencyCasesDone: 3,
          replayedCases: 1,
        },
      },
      settings: { create: { soundEnabled: true, hapticsEnabled: true } },
    },
    update: {},
  });

  const existingP1 = await prisma.bedProgress.count({ where: { userId: sampleStudent1.id } });
  if (existingP1 === 0) {
    await prisma.bedProgress.createMany({
      data: [
        { userId: sampleStudent1.id, bedNum: 1, passed: true, stars: 3, bestMistakes: 0, attemptCount: 1 },
        { userId: sampleStudent1.id, bedNum: 2, passed: true, stars: 3, bestMistakes: 0, attemptCount: 2 },
        { userId: sampleStudent1.id, bedNum: 3, passed: true, stars: 2, bestMistakes: 1, attemptCount: 1 },
        { userId: sampleStudent1.id, bedNum: 4, passed: true, stars: 3, bestMistakes: 0, attemptCount: 1 },
        { userId: sampleStudent1.id, bedNum: 5, passed: true, stars: 3, bestMistakes: 0, attemptCount: 1 },
      ],
    });
  }
}

async function main() {
  console.log('🌱 Seeding A-WARD CCU Database...');
  await seedDefaultCases(true);
  await seedDemoUsers();
  const bedCount = await prisma.ccuBed.count();
  const stageCount = await prisma.procedureStage.count();
  console.log(`✅ Seeded ${bedCount} CCU Beds (${stageCount} clinical stages) + Demo Nurse & Instructor accounts.`);
}

if (require.main === module) {
  main()
    .catch((e) => {
      console.error(e);
      process.exit(1);
    })
    .finally(async () => {
      await prisma.$disconnect();
    });
}
