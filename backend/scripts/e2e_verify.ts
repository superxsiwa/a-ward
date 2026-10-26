import assert from 'assert';
import '../src/index';

const BASE_URL = 'http://localhost:4000';

async function api(path: string, options: RequestInit = {}, token?: string) {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...((options.headers as Record<string, string>) || {}),
  };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${BASE_URL}${path}`, { ...options, headers });
  const body = await res.json().catch(() => ({}));
  return { status: res.status, body };
}

async function runVerification() {
  await new Promise((r) => setTimeout(r, 800));
  console.log('\n============================================================');
  console.log('🧪 Running A-WARD CCU Full-Stack E2E Verification Suite');
  console.log('============================================================\n');

  // 1. Health Check
  const health = await api('/api/health');
  assert.strictEqual(health.status, 200);
  console.log('✅ [1/8] GET /api/health -> OK');

  // 2. Demo Nurse & Demo Instructor Login
  const nurseLogin = await api('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: 'nurse@award.ccu', password: 'password123' }),
  });
  assert.strictEqual(nurseLogin.status, 200);
  assert.strictEqual(nurseLogin.body.user.role, 'NURSE');
  const nurseToken = nurseLogin.body.token;

  const instLogin = await api('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: 'instructor@award.ccu', password: 'password123' }),
  });
  assert.strictEqual(instLogin.status, 200);
  assert.strictEqual(instLogin.body.user.role, 'INSTRUCTOR');
  const instToken = instLogin.body.token;
  console.log('✅ [2/8] POST /api/auth/login (NURSE & INSTRUCTOR) -> OK');

  // 3. Verify 8 Unique CCU Beds x 6 Stages = 48 Clinical Stages
  const casesRes = await api('/api/cases');
  assert.strictEqual(casesRes.status, 200);
  const cases = casesRes.body.cases;
  assert.strictEqual(cases.length, 8);
  const totalStages = cases.reduce((sum: number, c: any) => sum + c.stageData.length, 0);
  assert.strictEqual(totalStages, 48);

  const uniquePrompts = new Set(cases.map((c: any) => c.stageData[0].choices1toN.prompt));
  assert.strictEqual(uniquePrompts.size, 8, 'All 8 CCU beds must have unique clinical procedures');
  console.log('✅ [3/8] GET /api/cases (8 Unique CCU Beds / 48 Clinical Stages) -> OK');

  // 4. Player Progress & Complete Case + Shift Clearance
  const complete1 = await api(
    '/api/progress/complete-case',
    {
      method: 'POST',
      body: JSON.stringify({
        bedNum: 1,
        mistakes: 0,
        stars: 3,
        trayItemsSortedDelta: 7,
        stepsWithoutMistakeDelta: 6,
        isEmergency: true,
        activeShift: 'morning',
        dayKey: '2026-9-1',
      }),
    },
    nurseToken
  );
  assert.strictEqual(complete1.status, 200);
  assert.strictEqual(complete1.body.starsEarned, 3);

  const complete2 = await api(
    '/api/progress/complete-case',
    {
      method: 'POST',
      body: JSON.stringify({
        bedNum: 2,
        mistakes: 1,
        stars: 2,
        trayItemsSortedDelta: 7,
        stepsWithoutMistakeDelta: 5,
        isEmergency: true,
        activeShift: 'morning',
        dayKey: '2026-9-1',
      }),
    },
    nurseToken
  );
  assert.strictEqual(complete2.status, 200);
  assert.strictEqual(complete2.body.shiftDayCleared, true);
  console.log('✅ [4/8] POST /api/progress/complete-case & Shift Day Clearance -> OK');

  // 5. Verify GET /api/progress/me
  const myProg = await api('/api/progress/me', {}, nurseToken);
  assert.strictEqual(myProg.status, 200);
  assert.strictEqual(myProg.body.progress[1].stars, 3);
  assert.strictEqual(myProg.body.progress[2].stars, 2);
  assert.strictEqual(myProg.body.rosterDaysProgress['2026-9-1'].passed, true);
  console.log('✅ [5/8] GET /api/progress/me (Persisted Stars, Stats & Roster) -> OK');

  // 6. Verify Case CRUD & Reset Defaults
  const createRes = await api(
    '/api/cases',
    {
      method: 'POST',
      body: JSON.stringify({
        bedNum: 9,
        caseTitle: 'เคสทดสอบ ECMO Cannulation',
        patientName: 'นายทดสอบ ระบบ (60 ปี)',
        dxBadge: 'Refractory Cardiogenic Shock',
        status: 'critical',
        statusText: 'ECMO Support',
        doctorName: 'นพ. ธีรภพ',
      }),
    },
    instToken
  );
  assert.strictEqual(createRes.status, 201);
  assert.strictEqual(createRes.body.cases.length, 9);

  const resetRes = await api('/api/cases/reset-defaults', { method: 'POST' }, instToken);
  assert.strictEqual(resetRes.status, 200);
  assert.strictEqual(resetRes.body.cases.length, 8);
  console.log('✅ [6/8] POST /api/cases & POST /api/cases/reset-defaults -> OK');

  // 7. Verify Instructor Leaderboard API
  const leaderboard = await api('/api/instructor/students', {}, instToken);
  assert.strictEqual(leaderboard.status, 200);
  assert.ok(Array.isArray(leaderboard.body.students) && leaderboard.body.students.length >= 2);
  console.log(`✅ [7/8] GET /api/instructor/students (${leaderboard.body.students.length} users) -> OK`);

  // 8. Verify Frontend SPA static serving & assets
  const indexHtmlRes = await fetch(`${BASE_URL}/`);
  const indexHtml = await indexHtmlRes.text();
  assert.strictEqual(indexHtmlRes.status, 200);
  assert.ok(indexHtml.includes('A-WARD CCU'));

  const equipImgRes = await fetch(`${BASE_URL}/assets/equipment/stethoscope.png`);
  assert.strictEqual(equipImgRes.status, 200);
  console.log('✅ [8/8] Frontend SPA & Chibi Equipment Assets Served at / -> OK');

  // Reset demo nurse progress back to clean state for fresh user experience
  await api('/api/progress/reset', { method: 'POST' }, nurseToken);

  console.log('\n🎉 ALL E2E VERIFICATION CHECKS PASSED SUCCESSFULLY!\n');
  process.exit(0);
}

runVerification().catch((err) => {
  console.error('❌ E2E Verification Failed:', err);
  process.exit(1);
});
