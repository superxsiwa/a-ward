/* =========================================================================
   A-WARD CCU — game logic (offline, no backend)
   Screens: Ward (8 beds) · Progress · Settings · Game (6-step procedure)
   Input:   Pointer-based drag & drop (mouse + touch) with tap fallback.
   Data:    ccuBeds (from data.js)
   ========================================================================= */
(function () {
  'use strict';

  const SAVE_KEY = 'award_ccu_8beds_progress_v3'; // same key as previous prototype → keeps old progress
  const SET_KEY = 'award_settings_v1';
  const RANKS = [
    'นักศึกษาพยาบาลฝึกหัด', 'พยาบาลฝึกงาน', 'พยาบาลน้องใหม่ CCU', 'พยาบาล CCU ฝีมือดี',
    'พยาบาลชำนาญการ', 'หัวหน้าเวร CCU', 'พยาบาล CCU ดาวเด่น', 'ผู้เชี่ยวชาญ CCU', 'ตำนานแห่งหอผู้ป่วยวิกฤต'
  ];

  const $ = (s) => document.querySelector(s);
  const el = { top: $('#topbar'), view: $('#view'), dock: $('#dock'), sheet: $('#sheet'), modal: $('#modal'), toast: $('#toast') };

  /* ---------- storage ---------- */
  const load = (k, d) => { try { const r = localStorage.getItem(k); return r ? JSON.parse(r) : d; } catch (e) { return d; } };
  const save = (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) { /* storage full / private mode */ } };

  const ROSTER_KEY = 'award_ccu_roster_schedule_v1';
  const ROSTER_PROGRESS_KEY = 'award_ccu_roster_days_progress_v1';
  const STATS_KEY = 'award_ccu_player_stats_v1';
  const CUSTOM_BEDS_KEY = 'award_ccu_custom_beds_v1';

  let BEDS = load(CUSTOM_BEDS_KEY, null) || ccuBeds;
  const MAX_STARS = () => BEDS.length * 3;

  let progress = load(SAVE_KEY, {});
  let settings = Object.assign({ sound: true, haptics: true }, load(SET_KEY, {}));
  let rosterSchedule = load(ROSTER_KEY, {});
  let rosterDaysProgress = load(ROSTER_PROGRESS_KEY, {}); // { 'YYYY-M-D': { passed: true } }
  let playerStats = Object.assign({
    totalCompletedCases: 0,
    totalPlaySeconds: 0,
    perfectCases: 0,
    shiftsCompleted: 0,
    trayItemsSorted: 0,
    stepsWithoutMistake: 0,
    emergencyCasesDone: 0,
    replayedCases: 0
  }, load(STATS_KEY, {}));

  // บันทึกเวลาเล่นแบบอัตโนมัติขณะอยู่ในแอป
  setInterval(() => {
    playerStats.totalPlaySeconds += 5;
    save(STATS_KEY, playerStats);
  }, 5000);

  // นิยาม Milestone / Goal ทั้งหมด 20+ รายการ ครอบคลุมทุกมิติการพยาบาล CCU
  const MILESTONE_GOALS = [
    // --- หมวด 1: ประสบการณ์ & เวลาปฏิบัติหน้าที่ ---
    {
      id: 'cases',
      title: 'ยอดหัตถการที่สำเร็จ',
      icon: '💉',
      unit: 'ครั้ง',
      tiers: [5, 15, 30],
      getValue: () => playerStats.totalCompletedCases,
      desc: 'ทำหัตถการการพยาบาลผู้ป่วย CCU สำเร็จตามจำนวนครั้ง'
    },
    {
      id: 'hours',
      title: 'ชั่วโมงบินเวร CCU',
      icon: '⏱️',
      unit: 'ชั่วโมง',
      tiers: [0.5, 1.5, 3.0],
      getValue: () => +(playerStats.totalPlaySeconds / 3600).toFixed(1),
      formatVal: (v) => `${v} ชม. (${Math.floor(playerStats.totalPlaySeconds / 60)} นาที)`,
      desc: 'สะสมเวลาปฏิบัติการพยาบาลและเรียนรู้ในหอผู้ป่วยวิกฤต'
    },
    {
      id: 'perfect',
      title: 'ความแม่นยำระดับ 3 ดาว',
      icon: '🎯',
      unit: 'เคส',
      tiers: [3, 8, 16],
      getValue: () => playerStats.perfectCases,
      desc: 'ทำเคสได้ถูกต้อง 100% ไม่มีข้อผิดพลาดจนได้ 3 ดาวเต็ม'
    },
    {
      id: 'shifts',
      title: 'ผ่านเวรประจำวันครบ',
      icon: '📋',
      unit: 'เวร',
      tiers: [2, 7, 14],
      getValue: () => Object.values(rosterDaysProgress).filter((p) => p && p.passed).length,
      desc: 'ขึ้นเวรตามตารางและดูแลคนไข้ครบทุกเตียงประจำเวรนั้น'
    },
    {
      id: 'beds_unlocked',
      title: 'พิชิตเตียงในวอร์ด CCU',
      icon: '🛏️',
      unit: 'เตียง',
      tiers: [2, 5, 8],
      getValue: () => passedCount(),
      desc: 'ผ่านเคสหัตถการประจำเตียงต่างๆ ในวอร์ดครบตามจำนวน'
    },

    // --- หมวด 2: หัตถการเฉพาะทางใน CCU (Clinical Cases) ---
    {
      id: 'case_sheath',
      title: 'ผู้เชี่ยวชาญ Femoral Sheath',
      icon: '🩹',
      unit: 'ดาว',
      tiers: [1, 2, 3],
      getValue: () => (progress[1] && progress[1].stars) || 0,
      desc: 'เตียง 01: ถอดสายสวนหลอดเลือดแดงขาหนีบและกดหยุดเลือดอย่างปลอดภัย'
    },
    {
      id: 'case_cvc',
      title: 'หัตถการสายสวนดำใหญ่ (CVC)',
      icon: '🩸',
      unit: 'ดาว',
      tiers: [1, 2, 3],
      getValue: () => (progress[2] && progress[2].stars) || 0,
      desc: 'เตียง 02: เตรียมผู้ป่วยและจัดถาดปลอดเชื้อช่วยแพทย์ใส่สาย CVC'
    },
    {
      id: 'case_ett',
      title: 'กู้ทางเดินหายใจฉุกเฉิน (ETT)',
      icon: '🫁',
      unit: 'ดาว',
      tiers: [1, 2, 3],
      getValue: () => (progress[3] && progress[3].stars) || 0,
      desc: 'เตียง 03: เตรียมอุปกรณ์ท่อช่วยหายใจและดูดเสมหะเคส Acute Pulmonary Edema'
    },
    {
      id: 'case_tpm',
      title: 'กระตุ้นหัวใจชั่วคราว (TPM)',
      icon: '⚡',
      unit: 'ดาว',
      tiers: [1, 2, 3],
      getValue: () => (progress[4] && progress[4].stars) || 0,
      desc: 'เตียง 04: ปรับ Rate/Output เครื่อง TPM ช่วยชีวิต Complete Heart Block'
    },
    {
      id: 'case_levo',
      title: 'บริหารยาวาสโซเพรสเซอร์ (Levophed)',
      icon: '🧪',
      unit: 'ดาว',
      tiers: [1, 2, 3],
      getValue: () => (progress[5] && progress[5].stars) || 0,
      desc: 'เตียง 05: ไตเตรทยากู้ความดัน Titration ยาหลอดเลือดดำส่วนกลาง'
    },
    {
      id: 'case_drain',
      title: 'ระบายน้ำหุ้มหัวใจ (Pericardial)',
      icon: '🫀',
      unit: 'ดาว',
      tiers: [1, 2, 3],
      getValue: () => (progress[6] && progress[6].stars) || 0,
      desc: 'เตียง 06: ตรวจสอบ Three-way stopcock และปริมาณสิ่งคัดหลั่งป้องกัน Tamponade'
    },
    {
      id: 'case_cardioversion',
      title: 'ช็อกไฟฟ้ากู้ชีพ (Cardioversion)',
      icon: '💓',
      unit: 'ดาว',
      tiers: [1, 2, 3],
      getValue: () => (progress[7] && progress[7].stars) || 0,
      desc: 'เตียง 07: เปิดโหมด Sync ชาร์จพลังงาน Defibrillator เคสหัวใจเต้นผิดจังหวะ'
    },
    {
      id: 'case_rp_bleed',
      title: 'รับมือภาวะช็อกเลือดออกหลังช่องท้อง',
      icon: '🚨',
      unit: 'ดาว',
      tiers: [1, 2, 3],
      getValue: () => (progress[8] && progress[8].stars) || 0,
      desc: 'เตียง 08: วินิจฉัย RP Bleed และเปิดเส้นเลือดให้สารน้ำกู้ภาวะ Hypovolemic Shock'
    },

    // --- หมวด 3: ทักษะและความชำนาญการพยาบาล (Nursing Skills) ---
    {
      id: 'tray_master',
      title: 'ปรมาจารย์จัดถาดเครื่องมือ',
      icon: '🧰',
      unit: 'ชิ้น',
      tiers: [15, 45, 90],
      getValue: () => playerStats.trayItemsSorted,
      desc: 'หยิบจัดอุปกรณ์ปลอดเชื้อลงถาดหัตถการถูกต้องแม่นยำ'
    },
    {
      id: 'zero_mistakes',
      title: 'ก้าวไร้ที่ติ (Flawless Steps)',
      icon: '🛡️',
      unit: 'ขั้นตอน',
      tiers: [10, 30, 60],
      getValue: () => playerStats.stepsWithoutMistake,
      desc: 'ผ่านขั้นตอนหัตถการโดยไม่เกิดข้อผิดพลาดในการเลือกคำตอบ'
    },
    {
      id: 'emergency_hero',
      title: 'ผู้พิชิตเคสวิกฤตฉุกเฉิน',
      icon: '🚑',
      unit: 'ครั้ง',
      tiers: [3, 8, 15],
      getValue: () => playerStats.emergencyCasesDone,
      desc: 'ผ่านเคสที่มีสถานะวิกฤตสัญญาณชีพออดเตือน (Alarm & Critical cases)'
    },
    {
      id: 'continuous_learning',
      title: 'นักทบทวนฝึกฝนซ้ำ',
      icon: '🔁',
      unit: 'ครั้ง',
      tiers: [2, 6, 12],
      getValue: () => playerStats.replayedCases,
      desc: 'เข้าเล่นซ้ำเพื่อทบทวนทักษะและยกระดับความแม่นยำ'
    },
    {
      id: 'star_collector',
      title: 'นักสะสมดวงดาว CCU',
      icon: '⭐',
      unit: 'ดาว',
      tiers: [8, 16, 24],
      getValue: () => totalStars(),
      desc: 'สะสมดาวความสำเร็จจากการดูแลผู้ป่วยทั่วทั้งวอร์ด'
    },
    {
      id: 'safety_champion',
      title: 'แชมป์ความปลอดภัยผู้ป่วย (Patient Safety)',
      icon: '🏥',
      unit: 'เคส',
      tiers: [4, 8, 12],
      getValue: () => Math.min(playerStats.totalCompletedCases, Math.floor(playerStats.stepsWithoutMistake / 4)),
      desc: 'ปฏิบัติตามมาตรฐานความปลอดภัยสากล 2 Identify & Sterile Technique'
    },
    {
      id: 'ccu_legend',
      title: 'ตำนานพยาบาลผู้พิทักษ์หัวใจ',
      icon: '👑',
      unit: 'เป้าหมาย',
      tiers: [5, 10, 18],
      getValue: () => {
        // นับจำนวนเป้าหมายอื่นๆ ที่ได้อย่างน้อย 1 ดาว
        return MILESTONE_GOALS.filter((g) => g.id !== 'ccu_legend' && getMilestoneStars(g) >= 1).length;
      },
      desc: 'พิชิตเป้าหมาย Milestones อื่นๆ ในหอผู้ป่วยวิกฤตหัวใจ'
    }
  ];

  function getMilestoneStars(goal) {
    const val = goal.getValue();
    if (val >= goal.tiers[2]) return 3;
    if (val >= goal.tiers[1]) return 2;
    if (val >= goal.tiers[0]) return 1;
    return 0;
  }

  function totalMilestoneStars() {
    return MILESTONE_GOALS.reduce((s, g) => s + getMilestoneStars(g), 0);
  }

  // หา unlocked day ล่าสุดของเดือน
  function getRosterUnlockedDay(year, month) {
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    for (let d = 1; d <= daysInMonth; d++) {
      const key = `${year}-${month}-${d}`;
      const shift = getShiftForDay(year, month, d);
      // วันหยุดถือว่าผ่านอัตโนมัติ
      if (shift.id === 'off') {
        if (!rosterDaysProgress[key]) {
          rosterDaysProgress[key] = { passed: true };
          save(ROSTER_PROGRESS_KEY, rosterDaysProgress);
        }
      }
      if (!rosterDaysProgress[key] || !rosterDaysProgress[key].passed) {
        return d;
      }
    }
    return daysInMonth;
  }

  /* ---------- app state ---------- */
  const ui = {
    screen: 'ward',
    tab: 'roster', // default to roster (leftmost tab)
    filterShift: null, // null | 'morning' | 'afternoon' | 'night'
    calYear: 2026,
    calMonth: 9, // 0-indexed: 9 = October
    selectedDay: 21
  };
  let G = null; // current game: { bedIdx, stepIdx, mistakes, done:Set, S:stepState }

  /* ---------- helpers ---------- */
  const icon = (n, c = '') => `<svg class="ic ${c}" aria-hidden="true"><use href="#ic-${n}"/></svg>`;
  const starSvg = (on, size = 18, cls = '') =>
    `<svg class="star ${on ? 'on' : ''} ${cls}" width="${size}" height="${size}" viewBox="0 0 24 24" aria-hidden="true"><use href="#i-star"/></svg>`;
  const totalStars = () => BEDS.reduce((s, b) => s + ((progress[b.bedNum] && progress[b.bedNum].stars) || 0), 0);
  const passedCount = () => BEDS.filter((b) => progress[b.bedNum] && progress[b.bedNum].passed).length;
  const levelOf = (stars) => Math.min(Math.floor(stars / 3) + 1, RANKS.length);
  const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const cleanSpeech = (s) => s.replace(/^💬\s*/, '');
  const cleanTray = (s) => s.replace(/^[🟩🟦]\s*/u, '');
  const curBed = () => BEDS[G.bedIdx];
  const curStep = () => curBed().stageData[G.stepIdx];
  const liveStars = () => (G.mistakes === 0 ? 3 : G.mistakes <= 2 ? 2 : 1);
  const isAlarm = (v) => v.hr >= 120 || v.hr < 50 || parseInt(v.spo2, 10) <= 90 || v.map < 65;
  const nextTarget = () => {
    let i = BEDS.findIndex((b) => !(progress[b.bedNum] && progress[b.bedNum].passed));
    if (i < 0) i = BEDS.findIndex((b) => ((progress[b.bedNum] && progress[b.bedNum].stars) || 0) < 3);
    return i;
  };

  /* ---------- sound & haptics ---------- */
  let ac = null;
  function tone(notes, opt) {
    if (!settings.sound) return;
    const o = Object.assign({ type: 'sine', vol: 0.2 }, opt);
    try {
      ac = ac || new (window.AudioContext || window.webkitAudioContext)();
      if (ac.state === 'suspended') ac.resume();
      const t0 = ac.currentTime;
      notes.forEach(([f, d, at]) => {
        const osc = ac.createOscillator(); const g = ac.createGain();
        osc.type = o.type; osc.frequency.setValueAtTime(f, t0 + at);
        g.gain.setValueAtTime(0.0001, t0 + at);
        g.gain.exponentialRampToValueAtTime(o.vol, t0 + at + 0.012);
        g.gain.exponentialRampToValueAtTime(0.0001, t0 + at + d);
        osc.connect(g); g.connect(ac.destination);
        osc.start(t0 + at); osc.stop(t0 + at + d + 0.03);
      });
    } catch (e) { /* audio unsupported */ }
  }
  const SFX = {
    pick: () => tone([[680, 0.07, 0]]),
    drop: () => tone([[430, 0.06, 0], [760, 0.09, 0.05]]),
    ok: () => tone([[523, 0.12, 0], [659, 0.12, 0.09], [784, 0.12, 0.18], [1046, 0.28, 0.27]], { type: 'triangle', vol: 0.24 }),
    bad: () => tone([[210, 0.18, 0], [150, 0.24, 0.13]], { type: 'sawtooth', vol: 0.13 }),
    star: (i) => tone([[784 + i * 220, 0.3, 0], [1175 + i * 220, 0.25, 0.08]], { type: 'triangle', vol: 0.22 }),
    win: () => tone([[523, 0.14, 0], [659, 0.14, 0.12], [784, 0.14, 0.24], [1046, 0.14, 0.36], [1318, 0.4, 0.48]], { type: 'triangle', vol: 0.24 })
  };
  const haptic = (p) => { if (settings.haptics && navigator.vibrate) { try { navigator.vibrate(p); } catch (e) { /* noop */ } } };

  let toastTimer = null;
  function toast(msg) {
    el.toast.textContent = msg; el.toast.classList.add('show');
    clearTimeout(toastTimer); toastTimer = setTimeout(() => el.toast.classList.remove('show'), 2000);
  }
  function shake(node) { if (!node) return; node.classList.remove('shake'); void node.offsetWidth; node.classList.add('shake'); setTimeout(() => node.classList.remove('shake'), 500); }

  /* ---------- ECG (animated, speed follows heart rate) ---------- */
  function ecg(hr, color) {
    const beat = 'M0 15 h12 l3 -3 l3 3 h6 l2 4 l3 -16 l3 22 l2 -10 h8 l4 -5 l5 5 h9';
    let p = '';
    for (let i = 0; i < 8; i++) p += `<path transform="translate(${i * 60})" d="${beat}"/>`;
    const dur = (240 / Math.max(30, hr)).toFixed(2);
    return `<span class="ecg" style="--dur:${dur}s;--ecg:${color}"><svg viewBox="0 0 480 30" preserveAspectRatio="none">${p}</svg></span>`;
  }

  /* =======================================================================
     TOP BAR · DOCK
     ======================================================================= */
  function renderTop(lostStar) {
    if (ui.screen === 'ward') {
      const stars = totalStars(); const lvl = levelOf(stars);
      const xp = stars >= MAX_STARS ? 100 : ((stars % 3) / 3) * 100;
      el.top.innerHTML = `
        <div class="avatar">👩‍⚕️<b class="lvl">${lvl}</b></div>
        <div class="who"><div class="rank">${RANKS[lvl - 1]}</div><div class="xp"><i style="width:${xp}%"></i></div></div>
        <div class="pill">${starSvg(true, 20)}<span>${stars}</span><small>/${MAX_STARS}</small></div>
        <button class="icon-btn" data-act="toggle-sound" aria-label="เปิด/ปิดเสียง">${icon(settings.sound ? 'volume' : 'mute')}</button>`;
    } else {
      const b = curBed(); const ls = liveStars();
      el.top.innerHTML = `
        <button class="icon-btn" data-act="exit-game" aria-label="ออกจากเคส">${icon('back')}</button>
        <div class="t-title"><b>${b.bedCode}</b><small>${b.caseTitle}</small></div>
        <div class="live-stars" aria-label="ดาวที่ได้ตอนนี้ ${ls} ดวง">${[1, 2, 3].map((n) => starSvg(ls >= n, 22, lostStar === n ? 'lost' : '')).join('')}</div>`;
    }
  }

  function renderDock() {
    if (ui.screen === 'ward') {
      const tabs = [
        ['roster', 'calendar', 'ตารางเวร'],
        ['ward', 'bed', 'วอร์ด'],
        ['progress', 'trophy', 'ความก้าวหน้า'],
        ['settings', 'sliders', 'ตั้งค่า']
      ];
      el.dock.innerHTML = `<nav class="tabbar">${tabs.map(([k, ic, t]) =>
        `<button class="tab ${ui.tab === k ? 'on' : ''}" data-act="tab" data-tab="${k}" aria-current="${ui.tab === k}">${icon(ic)}<span>${t}</span></button>`).join('')}</nav>`;
    } else {
      const isFirstStep = G.stepIdx === 0;
      const isLastStep = G.stepIdx === curBed().stageData.length - 1;
      const isPassed = G.done.has(curStep().id);
      const canSkip = !isPassed && (G.stepMistakes[curStep().id] || 0) >= 3;
      el.dock.innerHTML = `
        <div class="game-dock">
          ${!isFirstStep ? `
            <button class="btn btn-ghost btn-nav" data-act="step-prev" aria-label="ย้อนกลับ">
              ${icon('back')}<span>ย้อนกลับ</span>
            </button>
          ` : ''}
          ${!isPassed ? (
            canSkip ? `
              <button class="btn btn-block btn-gold" data-act="step-skip" aria-label="ข้ามไปต่อ">
                <span>💡 ข้ามไปต่อ</span>${icon('forward')}
              </button>
            ` : `
              <button class="btn btn-block btn-primary" data-act="check">
                ${icon('check')}<span>ตรวจคำตอบ</span>
              </button>
            `
          ) : !isLastStep ? `
            <button class="btn btn-block btn-gold" data-act="step-next" aria-label="ไปต่อ">
              <span>ไปต่อ</span>${icon('forward')}
            </button>
          ` : `
            <div style="flex:1;text-align:center;font-weight:600;color:#16a34a;font-size:14px">
              ✓ ทำหัตถการครบทุกขั้นตอนแล้ว
            </div>
          `}
          <button class="btn btn-ghost btn-sq" data-act="reset-step" ${isPassed ? 'disabled' : ''} aria-label="จัดใหม่">
            ${icon('undo')}
          </button>
        </div>`;
    }
  }

  /* =======================================================================
     ROSTER / CALENDAR / WARD / PROGRESS / SETTINGS
     ======================================================================= */
  const SHIFTS = [
    {
      id: 'morning',
      name: 'เวรเช้า (Morning Shift)',
      badgeClass: 'badge-morning',
      pillClass: 's-morning',
      time: '07:00 – 15:00 น.',
      icon: '🌅',
      chargeNurse: 'พว. ณิชาภา (RN)',
      desc: 'รับส่งเวรเช้า ตรวจเยี่ยมคนไข้ post-catheterization และเตรียมหัตถการใส่สาย CVC',
      bedIndices: [0, 1] // เตียง 1, 2
    },
    {
      id: 'afternoon',
      name: 'เวรบ่าย (Afternoon Shift)',
      badgeClass: 'badge-afternoon',
      pillClass: 's-afternoon',
      time: '15:00 – 23:00 น.',
      icon: '☀️',
      chargeNurse: 'พว. กานดา (RN)',
      desc: 'ดูแลเคสวิกฤต ETT, ใส่ Temporary Pacemaker และบริหารยา Levophed ทางหลอดเลือด',
      bedIndices: [2, 3, 4] // เตียง 3, 4, 5
    },
    {
      id: 'night',
      name: 'เวรดึก (Night Shift)',
      badgeClass: 'badge-night',
      pillClass: 's-night',
      time: '23:00 – 07:00 น.',
      icon: '🌙',
      chargeNurse: 'พว. ปวีณา (RN)',
      desc: 'เฝ้าระวัง Pericardial Tamponade, ติดตาม Cardioversion และรับมือภาวะฉุกเฉิน RP Bleed',
      bedIndices: [5, 6, 7] // เตียง 6, 7, 8
    }
  ];

  // สุ่มเวรในแต่ละวัน (เช้า / บ่าย / ดึก / Off)
  const SHIFT_POOL = ['morning', 'afternoon', 'night', 'morning', 'afternoon', 'night', 'off'];
  function generateMonthSchedule(year, month) {
    const key = `${year}-${month}`;
    const days = new Date(year, month + 1, 0).getDate();
    const sched = {};
    for (let d = 1; d <= days; d++) {
      sched[d] = SHIFT_POOL[Math.floor(Math.random() * SHIFT_POOL.length)];
    }
    rosterSchedule[key] = sched;
    save(ROSTER_KEY, rosterSchedule);
    return sched;
  }

  function getShiftForDay(year, month, day) {
    const key = `${year}-${month}`;
    if (!rosterSchedule[key]) {
      generateMonthSchedule(year, month);
    }
    const shiftId = rosterSchedule[key][day] || 'morning';
    if (shiftId === 'off') {
      return { id: 'off', name: 'วันหยุดพักผ่อน (Off)', icon: '☕', badgeClass: '', pillClass: 's-off', time: 'เวรหยุด' };
    }
    return SHIFTS.find((s) => s.id === shiftId) || SHIFTS[0];
  }

  // ข้อมูลวันนอน รพ. (Length of Stay) ของแต่ละเตียงใน CCU
  const BED_STAY_INFO = {
    1: { stay: 'วันที่ 2 ใน CCU', note: 'Post-PCI วันที่ 2 เตรียมถอดสาย Femoral Sheath' },
    2: { stay: 'วันที่ 1 ใน CCU', note: 'เพิ่ง admit จาก ER เมื่อคืน อาการ Septic Shock' },
    3: { stay: 'วันที่ 3 ใน CCU', note: 'Pulmonary Edema เหนื่อยหอบวิกฤต เตรียม Intubation' },
    4: { stay: 'วันที่ 2 ใน CCU', note: 'Mobitz II progression สู่ CHB ต้องใส่ TPM ด่วน' },
    5: { stay: 'วันที่ 4 ใน CCU', note: 'Cardiogenic Shock วันที่ 4 ปรับ Levophed' },
    6: { stay: 'วันที่ 5 ใน CCU', note: 'Post Pericardiocentesis วันที่ 5 เฝ้าระวัง Tamponade' },
    7: { stay: 'วันที่ 1 ใน CCU', note: 'VT with pulse ฉุกเฉิน เตรียมทำ Cardioversion' },
    8: { stay: 'วันที่ 2 ใน CCU', note: 'Post-Cath 24 ชม. ปวดหลังรุนแรง สงสัย RP Bleed' }
  };

  const THAI_MONTHS = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];

  function renderTabs() {
    ui.screen = 'ward'; G = null; closeSheet();
    renderTop(); renderDock();
    if (ui.tab === 'roster') renderRoster();
    else if (ui.tab === 'ward') renderWard();
    else if (ui.tab === 'progress') renderProgress();
    else if (ui.tab === 'cases') renderCaseManager();
    else renderSettings();
    el.view.scrollTop = 0;
  }

  function renderRoster() {
    const y = ui.calYear; const m = ui.calMonth;
    const daysInMonth = new Date(y, m + 1, 0).getDate();
    const firstDayIndex = new Date(y, m, 1).getDay(); // 0 = Sun .. 6 = Sat
    const unlockedDay = getRosterUnlockedDay(y, m);
    if (!ui.selectedDay || ui.selectedDay > unlockedDay) {
      ui.selectedDay = unlockedDay;
    }
    const selectedDay = ui.selectedDay;
    const myShift = getShiftForDay(y, m, selectedDay);
    const isSelectedDone = !!(rosterDaysProgress[`${y}-${m}-${selectedDay}`] && rosterDaysProgress[`${y}-${m}-${selectedDay}`].passed);

    // สร้างเซลล์ปฏิทิน
    let cellsHtml = '';
    // ช่องว่างก่อนวันที่ 1
    for (let i = 0; i < firstDayIndex; i++) {
      cellsHtml += `<div class="cal-cell empty"></div>`;
    }
    // วันที่ 1 ถึงวันสิ้นเดือน
    for (let d = 1; d <= daysInMonth; d++) {
      const isSelected = d === selectedDay;
      const isLocked = d > unlockedDay;
      const dayKey = `${y}-${m}-${d}`;
      const isDone = !isLocked && !!(rosterDaysProgress[dayKey] && rosterDaysProgress[dayKey].passed);
      const isPlayable = d === unlockedDay && !isDone;
      const isToday = d === 21 && m === 9 && y === 2026;
      const dayOfWeek = (firstDayIndex + d - 1) % 7;
      const isSun = dayOfWeek === 0;
      const shift = getShiftForDay(y, m, d);
      const shiftLabel = shift.id === 'off' ? 'OFF' : shift.id === 'morning' ? 'เช้า' : shift.id === 'afternoon' ? 'บ่าย' : 'ดึก';

      cellsHtml += `
        <button class="cal-cell ${isSelected ? 'selected' : ''} ${isPlayable ? 'is-playable' : ''} ${isDone ? 'is-done' : ''} ${isToday ? 'today' : ''} ${isSun ? 'sun' : ''}"
          data-act="select-day" data-day="${d}" data-locked="${isLocked ? '1' : '0'}" title="${isPlayable ? 'เล่นวันนี้ได้ (เวรปัจจุบัน)' : isDone ? 'ผ่านเวรนี้แล้ว' : isLocked ? 'ยังไม่ถึงวันเข้าเวร' : ''}">
          <span class="cal-day-num">${d}</span>
          <span class="cal-shift-pill ${shift.pillClass}">${shiftLabel}</span>
        </button>
      `;
    }

    el.view.innerHTML = `
      <section class="page">
        <div class="roster-header">
          <div class="roster-header-top">
            <span class="roster-badge">📅 ปฏิทินเวรพยาบาล CCU</span>
            <button class="btn btn-ghost btn-sm" style="color:#fff;background:rgba(255,255,255,0.2);padding:3px 10px;font-size:11px" data-act="randomize-shifts">
              🎲 สุ่มเวรใหม่
            </button>
          </div>
          <h2>ตารางเวรประจำเดือน</h2>
          <p>ต้องเล่นผ่านเวรเรียงตามวัน (ช่องสีทองที่มีเครื่องหมาย <b style="color:#fde047">▶ เล่นวันนี้ได้</b>) ปฏิบัติงานให้ครบเพื่อก้าวสู่วันถัดไป</p>
        </div>

        <div class="cal-layout-desktop">
          <div>
            <div class="cal-month-bar">
              <button class="cal-nav-btn" data-act="cal-prev" aria-label="เดือนก่อนหน้า">◀</button>
              <div class="cal-month-title">${THAI_MONTHS[m]} ${y + 543}</div>
              <button class="cal-nav-btn" data-act="cal-next" aria-label="เดือนถัดไป">▶</button>
            </div>

            <div class="cal-grid-card">
              <div class="cal-weekdays">
                <span class="sun">อา</span><span>จ</span><span>อ</span><span>พ</span><span>พฤ</span><span>ศ</span><span class="sat">ส</span>
              </div>
              <div class="cal-days-grid">${cellsHtml}</div>
            </div>
          </div>

          <div class="day-roster-box">
            <div class="day-roster-head">
              <div>
                <div class="day-roster-date">วัน${['อาทิตย์', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์'][(firstDayIndex + selectedDay - 1) % 7]}ที่ ${selectedDay} ${THAI_MONTHS[m]} ${y + 543}</div>
                <div class="day-roster-sub">เวรของคุณวันนี้: <b>${myShift.icon} ${myShift.name}</b> ${isSelectedDone ? '<span class="status-badge s-passed">✓ ผ่านเวรนี้แล้ว</span>' : ''}</div>
              </div>
            </div>

            <div class="day-shifts">
              ${myShift.id === 'off' ? `
                <div class="card" style="text-align:center;padding:22px 14px;background:#f8fafc">
                  <div style="font-size:36px;margin-bottom:6px">☕🌴</div>
                  <b style="font:600 15px var(--font-display);color:var(--ink)">วันนี้เป็นวันหยุดของคุณ (Off)</b>
                  <p class="hint" style="margin-top:4px">พักผ่อนให้เต็มที่ หรือเลือกดูเคสหัตถการในวอร์ดเพื่อทบทวนความรู้ได้เสมอ</p>
                  <div style="margin-top:12px;display:flex;justify-content:center;gap:8px">
                    <button class="btn btn-sm btn-outline" data-act="go-ward-all">${icon('bed')}<span>ดูวอร์ดทั้งหมด</span></button>
                  </div>
                </div>
              ` : ''}

              ${SHIFTS.map((shift) => {
                const isCurrent = shift.id === myShift.id;
                const assignedBeds = shift.bedIndices.map((idx) => ({ bed: BEDS[idx], idx }));
                const completedCount = assignedBeds.filter(({ bed }) => progress[bed.bedNum] && progress[bed.bedNum].passed).length;
                return `
                  <div class="day-shift-card ${isCurrent ? 'my-shift' : ''}">
                    <div class="day-shift-top">
                      <div class="day-shift-title">
                        <span>${shift.icon}</span>
                        <b>${shift.name}</b>
                        ${isCurrent ? '<span class="status-badge s-passed" style="font-size:9.5px;padding:2px 6px">เวรของคุณ</span>' : ''}
                      </div>
                      <span class="day-shift-badge ${shift.badgeClass}">${shift.time}</span>
                    </div>
                    <div class="day-shift-meta">
                      หัวหน้าเวร: <b>${shift.chargeNurse}</b> · คนไข้ในความรับผิดชอบ (${completedCount}/${assignedBeds.length} เคส)
                    </div>
                    <div class="assigned-beds-list">
                      ${assignedBeds.map(({ bed, idx }) => {
                        const rec = progress[bed.bedNum] || {};
                        const done = !!rec.passed;
                        const stayInfo = BED_STAY_INFO[bed.bedNum] || { stay: 'หอผู้ป่วย CCU' };
                        return `
                          <div class="assigned-bed-item ${done ? 'is-done' : ''}">
                            <span class="assigned-bed-no">เตียง ${String(bed.bedNum).padStart(2, '0')}</span>
                            <div style="flex:1;min-width:0">
                              <div class="assigned-bed-title">${bed.caseTitle}</div>
                              <div class="assigned-bed-sub">
                                <span>${bed.patientName}</span>
                                <span class="stay-tag">${stayInfo.stay}</span>
                              </div>
                            </div>
                          </div>
                        `;
                      }).join('')}
                    </div>
                    <div class="shift-action-btn-wrap">
                      ${isCurrent ? `
                        <button class="btn btn-sm btn-gold shift-action-btn" data-act="go-ward-shift" data-shift="${shift.id}">
                          ${icon('bed')}<span>${isSelectedDone ? 'ทบทวนวอร์ดเวรนี้' : 'เข้าวอร์ดเวรนี้'}</span>
                        </button>
                      ` : ''}
                    </div>
                  </div>
                `;
              }).join('')}
            </div>
          </div>
        </div>
      </section>`;
  }

  function bedCard(b, i) {
    const rec = progress[b.bedNum] || {}; const stars = rec.stars || 0; const done = !!rec.passed;
    const v = b.stageData[0].vitals; const alarm = isAlarm(v);
    const pt = b.patientName.startsWith('นาง') ? '👵' : '👴';
    const stayInfo = BED_STAY_INFO[b.bedNum] || { stay: 'CCU' };
    const isFiltered = ui.filterShift && !SHIFTS.find((s) => s.id === ui.filterShift).bedIndices.includes(i);
    const dimmedStyle = isFiltered ? 'opacity: 0.35; filter: grayscale(0.5);' : '';

    return `
      <button class="bed s-${b.status} ${done ? 'is-done' : ''}" style="${dimmedStyle}" data-act="open-bed" data-i="${i}" aria-label="${b.bedCode} ${b.caseTitle}">
        <span class="bed-no">${String(b.bedNum).padStart(2, '0')}</span>
        ${done ? `<span class="bed-check">${icon('check')}</span>` : ''}
        <span class="bed-st">${done ? 'ผ่านแล้ว' : b.statusText}</span>
        <span class="bed-art">
          <span class="monitor-mini">${ecg(v.hr, alarm ? '#f87171' : '#4ade80')}<em>♥ ${v.hr}</em></span>
          <span class="mattress"><i class="pillow"></i></span>
          <span class="pt">${pt}</span>
        </span>
        <span class="bed-title">${b.caseTitle}</span>
        <span style="font-size:10px;color:var(--ink-3);display:block;margin-top:-2px"><span class="stay-tag">${stayInfo.stay}</span></span>
        <span class="bed-foot"><span class="stars">${[1, 2, 3].map((n) => starSvg(stars >= n, 18)).join('')}</span><span class="go">${icon('play')}</span></span>
      </button>`;
  }

  function renderWard() {
    const t = nextTarget();
    const cta = t < 0 ? '' : `<button class="btn btn-gold" data-act="play-next">${icon('play')}<span>${passedCount() === 0 ? 'เริ่มเลย' : 'เล่นต่อ'}</span></button>`;
    const cards = BEDS.map(bedCard);
    const curFilterShift = ui.filterShift ? SHIFTS.find((s) => s.id === ui.filterShift) : null;

    el.view.innerHTML = `
      <section class="ward">
        <div class="banner">
          <div class="sign">CCU</div>
          <div><h1>วอร์ดหัวใจ 8 เตียง</h1><p>แตะที่เตียงเพื่อเริ่มทำการพยาบาลและหัตถการ</p></div>
          ${cta}
        </div>
        ${curFilterShift ? `
          <div class="ward-filter-banner">
            <div>
              <b>${curFilterShift.icon} ประจำการ: ${curFilterShift.name}</b>
              <div style="font-size:11px;opacity:0.85">เน้นเตียงที่ได้รับมอบหมายในเวร (${curFilterShift.bedIndices.map((x) => 'เตียง ' + (x + 1)).join(', ')})</div>
            </div>
            <button class="clear-filter-btn" data-act="clear-filter">แสดงทุกเตียง ✕</button>
          </div>
        ` : ''}
        <div class="bays">
          ${cards.slice(0, 4).join('')}
          <div class="station">
            <div class="desk"><span>🖥️</span><span>👩‍⚕️</span><span>📋</span></div>
            <div class="st-info"><b>เคาน์เตอร์พยาบาล</b><small>ผ่านแล้ว ${passedCount()}/${BEDS.length} เตียง</small>
              <div class="dots">${BEDS.map((b) => `<i class="${progress[b.bedNum] && progress[b.bedNum].passed ? 'on' : ''}"></i>`).join('')}</div>
              <button class="station-office-btn" data-act="open-case-mgmt">
                <span>📁</span> ห้องจัดการเคส CCU ▶
              </button>
            </div>
          </div>
          ${cards.slice(4).join('')}
        </div>
      </section>`;
  }

  function renderProgress() {
    const stars = totalStars();
    const mStars = totalMilestoneStars();
    const grandStars = stars + mStars;
    const lvl = levelOf(stars);
    const R = 54; const C = 2 * Math.PI * R; const frac = stars / MAX_STARS;

    const playHours = (playerStats.totalPlaySeconds / 3600).toFixed(1);
    const playMins = Math.floor(playerStats.totalPlaySeconds / 60);

    el.view.innerHTML = `
      <section class="page">
        <h2 class="page-h">ความก้าวหน้า & เป้าหมาย (Milestones)</h2>

        <div class="card ring-card">
          <div class="ring-wrap">
            <svg class="ring" viewBox="0 0 140 140" aria-hidden="true">
              <circle class="ring-bg" cx="70" cy="70" r="${R}"/>
              <circle class="ring-fg" cx="70" cy="70" r="${R}" stroke-dasharray="${C.toFixed(1)}" stroke-dashoffset="${(C * (1 - frac)).toFixed(1)}" transform="rotate(-90 70 70)"/>
            </svg>
            <div class="ring-c"><b>${stars}</b><small>จาก ${MAX_STARS} ดาวเตียง</small></div>
          </div>
          <div class="rank-big">Lv.${lvl} · ${RANKS[lvl - 1]}</div>
          <div class="hint">ผ่านแล้ว ${passedCount()} / ${BEDS.length} เตียง · ดาวสะสมรวมทั้งหมด ${grandStars} ⭐</div>

          <div class="progress-stats-grid">
            <div class="p-stat-box">
              <small>ชั่วโมงบิน CCU</small>
              <b>${playMins < 60 ? playMins + ' น.' : playHours + ' ชม.'}</b>
            </div>
            <div class="p-stat-box">
              <small>หัตถการสำเร็จ</small>
              <b>${playerStats.totalCompletedCases} ครั้ง</b>
            </div>
            <div class="p-stat-box">
              <small>ดาว Milestone</small>
              <b>${mStars} / ${MILESTONE_GOALS.length * 3} ⭐</b>
            </div>
          </div>
        </div>

        <div class="milestone-section">
          <div class="section-sub-h">
            <span>🏆 เป้าหมายสะสมดาว (Goals & Milestones)</span>
            <small>ทำครบเงื่อนไขเพื่อรับดาวเพิ่ม</small>
          </div>

          ${MILESTONE_GOALS.map((goal) => {
            const currentVal = goal.getValue();
            const earnedStars = getMilestoneStars(goal);
            const isMax = earnedStars === 3;
            const nextTarget = isMax ? goal.tiers[2] : goal.tiers[earnedStars];
            const prevTarget = earnedStars === 0 ? 0 : goal.tiers[earnedStars - 1];
            const pct = isMax ? 100 : Math.min(100, Math.max(0, ((currentVal - prevTarget) / (nextTarget - prevTarget)) * 100));

            return `
              <div class="milestone-card ${isMax ? 'all-done' : ''}">
                <div class="m-card-top">
                  <div class="m-card-title">
                    <span class="m-icon">${goal.icon}</span>
                    <div>
                      <div>${goal.title}</div>
                      <small class="hint" style="display:block;font-size:10.5px">${goal.desc}</small>
                    </div>
                  </div>
                  <div class="m-stars">
                    ${[1, 2, 3].map((n) => starSvg(earnedStars >= n, 18)).join('')}
                  </div>
                </div>

                <div class="m-progress-bar-wrap">
                  <div class="m-progress-bar-fill" style="width:${pct.toFixed(0)}%"></div>
                </div>

                <div class="m-card-footer">
                  <span class="m-current-val">
                    ปัจจุบัน: <b>${goal.formatVal ? goal.formatVal(currentVal) : currentVal + ' ' + goal.unit}</b>
                  </span>
                  <span class="m-next-tier">
                    ${isMax ? '✓ ได้ครบ 3 ดาวแล้ว!' : `เป้าดาวถัดไป (${earnedStars + 1}⭐): ${nextTarget} ${goal.unit}`}
                  </span>
                </div>
              </div>
            `;
          }).join('')}
        </div>
      </section>`;
  }

  function renderSettings() {
    const sw = (k, on) => `<button class="switch" role="switch" aria-checked="${on}" data-act="toggle-setting" data-k="${k}"></button>`;
    el.view.innerHTML = `
      <section class="page">
        <h2 class="page-h">ตั้งค่า</h2>
        <div class="card">
          <div class="setting"><div class="s-t"><b>🔊 เสียงเอฟเฟกต์</b><small>เสียงตอนหยิบ วาง และผ่านด่าน</small></div>${sw('sound', settings.sound)}</div>
          <div class="setting"><div class="s-t"><b>📳 การสั่น</b><small>สั่นเบาๆ เมื่อตอบถูก/ผิด (มือถือ)</small></div>${sw('haptics', settings.haptics)}</div>
        </div>

        <div class="card" style="border-color:#bae6fd;background:#f0f9ff">
          <div class="s-t">
            <b style="font:700 15px var(--font-display);color:#0369a1">📁 จัดการเคสหัตถการ (Case Manager)</b>
            <small class="hint" style="display:block;margin-top:2px">เพิ่ม ลบ หรือแก้ไขเคสหัตถการในวอร์ด และนำเข้า/ส่งออกเคส</small>
          </div>
          <div style="display:flex;gap:8px;margin-top:6px">
            <button class="btn btn-sm btn-primary" data-act="open-case-mgmt">${icon('sliders')}<span>เปิดตัวจัดการเคส</span></button>
            <button class="btn btn-sm btn-outline" data-act="export-cases">${icon('share')}<span>ส่งออก JSON</span></button>
          </div>
        </div>

        <div class="card">
          <div class="s-t"><b style="font:600 14px var(--font-display)">ล้างความก้าวหน้า</b><small class="hint" style="display:block;margin-top:2px">ดาวและเตียงที่ผ่านแล้วจะถูกรีเซ็ตทั้งหมด</small></div>
          <button class="btn btn-danger btn-sm" data-act="reset-all">ล้างข้อมูลทั้งหมด</button>
        </div>
        <p class="about">A-WARD CCU · Prototype<br>ข้อมูลทั้งหมดเก็บในเครื่องของคุณ เล่นออฟไลน์ได้</p>
      </section>`;
  }

  /* =======================================================================
     CASE MANAGEMENT & BUILDER (ADMIN / TEACHER MODE)
     ======================================================================= */
  function renderCaseManager() {
    el.view.innerHTML = `
      <section class="page">
        <div class="case-mgmt-header">
          <div>
            <h2 class="page-h" style="margin:0">จัดการเคสหัตถการ CCU</h2>
            <small class="hint">มีเคสในระบบทั้งหมด ${BEDS.length} เคส</small>
          </div>
          <button class="btn btn-sm btn-gold" data-act="create-new-case">
            ${icon('plus')}<span>เพิ่มเคสใหม่</span>
          </button>
        </div>

        <div style="display:flex;gap:8px;margin-bottom:8px">
          <button class="btn btn-sm btn-ghost" data-act="tab" data-tab="ward">◀ กลับวอร์ด</button>
          <button class="btn btn-sm btn-outline" data-act="import-cases">📥 นำเข้าไฟล์ JSON</button>
          <button class="btn btn-sm btn-outline" data-act="reset-default-cases">🔄 คืนค่าเคสตั้งต้น</button>
        </div>

        <div class="list case-list-grid">
          ${BEDS.map((b, i) => `
            <div class="case-item-card">
              <div class="case-item-top">
                <div class="case-item-title">
                  <span style="font-size:18px">🛏️</span>
                  <b>เตียง ${String(b.bedNum).padStart(2, '0')}: ${b.caseTitle}</b>
                </div>
                <span class="status-badge s-${b.status}">${b.statusText}</span>
              </div>
              <div class="case-item-meta">
                <b>ผู้ป่วย:</b> ${b.patientName} (${b.patientAge || 60} ปี) · <b>โรค:</b> ${b.dxBadge}<br>
                <b>แพทย์:</b> ${b.doctorName} · <b>จำนวนขั้นตอน:</b> ${(b.stageData && b.stageData.length) || 6} ขั้นตอน
              </div>
              <div class="case-item-actions">
                <button class="btn btn-sm btn-ghost" data-act="open-bed" data-i="${i}" title="ทดสอบเล่น">
                  ${icon('play')}<span>ทดสอบ</span>
                </button>
                <button class="btn btn-sm btn-gold" data-act="manage-steps" data-i="${i}" title="จัดการ 6 ขั้นตอนและคำตอบ">
                  <span>📝</span><span>จัดการขั้นตอน & คำตอบ</span>
                </button>
                <button class="btn btn-sm btn-primary" data-act="edit-case" data-i="${i}">
                  ${icon('edit')}<span>ข้อมูลเคส</span>
                </button>
                ${BEDS.length > 1 ? `
                  <button class="btn btn-sm btn-danger" data-act="delete-case" data-i="${i}">
                    ${icon('trash')}<span>ลบ</span>
                  </button>
                ` : ''}
              </div>
            </div>
          `).join('')}
        </div>
      </section>
    `;
  }

  function openCaseEditor(idx) {
    const isEdit = idx >= 0;
    const b = isEdit ? BEDS[idx] : {
      bedNum: BEDS.length + 1,
      bedCode: `เตียง ${String(BEDS.length + 1).padStart(2, '0')} CCU`,
      patientName: 'นายใจดี มีสุข (65 ปี)',
      patientAge: 65,
      caseTitle: 'หัตถการจำลองใหม่ CCU',
      dxBadge: 'Cardiogenic Assessment',
      status: 'alert',
      statusText: 'เฝ้าระวังอาการ',
      doctorName: 'นพ. วิทยา (แพทย์ประจำบ้าน CCU)',
      doctorAvatar: '👨‍⚕️',
      stageData: []
    };

    openModal(`
      <div style="text-align:left;max-height:75vh;overflow-y:auto;padding-right:4px">
        <h2 style="font:700 17px var(--font-display);margin-top:0">${isEdit ? '✏️ แก้ไขเคสหัตถการ' : '➕ เพิ่มเคสหัตถการใหม่'}</h2>
        <div style="display:flex;flex-direction:column;gap:10px;margin-top:10px">
          <div class="form-row">
            <div class="form-group">
              <label>หมายเลขเตียง</label>
              <input class="form-input" id="ed-bedNum" type="number" value="${b.bedNum}">
            </div>
            <div class="form-group">
              <label>สถานะเตียง</label>
              <select class="form-input" id="ed-status">
                <option value="alert" ${b.status === 'alert' ? 'selected' : ''}>Alert (เฝ้าระวัง)</option>
                <option value="critical" ${b.status === 'critical' ? 'selected' : ''}>Critical (วิกฤต)</option>
                <option value="stable" ${b.status === 'stable' ? 'selected' : ''}>Stable (คงที่)</option>
              </select>
            </div>
          </div>

          <div class="form-group">
            <label>ชื่อเคสหัตถการ</label>
            <input class="form-input" id="ed-caseTitle" value="${b.caseTitle}">
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>ชื่อคนไข้ (และอายุ)</label>
              <input class="form-input" id="ed-patientName" value="${b.patientName}">
            </div>
            <div class="form-group">
              <label>ป้ายการวินิจฉัยโรค</label>
              <input class="form-input" id="ed-dxBadge" value="${b.dxBadge}">
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>ชื่อแพทย์ผู้สั่งการ</label>
              <input class="form-input" id="ed-doctorName" value="${b.doctorName}">
            </div>
            <div class="form-group">
              <label>ข้อความสถานะ</label>
              <input class="form-input" id="ed-statusText" value="${b.statusText}">
            </div>
          </div>

          <div class="hint" style="background:#f8fafc;padding:8px 10px;border-radius:10px;border:1px solid #e2e8f0">
            ℹ️ เคสใหม่จะได้รับชุดขั้นตอนพื้นฐาน 6 ขั้นตอนของ CCU โดยอัตโนมัติ ซึ่งสามารถนำไปใช้ฝึกการพยาบาลได้ทันที
          </div>
        </div>

        <div class="modal-actions" style="margin-top:16px;display:flex;gap:8px">
          <button class="btn btn-primary" data-act="save-case" data-i="${idx}">💾 บันทึกเคส</button>
          <button class="btn btn-ghost" data-act="modal-close">ยกเลิก</button>
        </div>
      </div>
    `, 'modal-card-lg');
  }

  function saveCaseFromForm(idx) {
    const isEdit = idx >= 0;
    const bedNum = parseInt($('#ed-bedNum').value, 10) || (BEDS.length + 1);
    const caseTitle = $('#ed-caseTitle').value.trim() || 'เคสหัตถการใหม่';
    const patientName = $('#ed-patientName').value.trim() || 'ผู้ป่วย CCU';
    const dxBadge = $('#ed-dxBadge').value.trim() || 'CCU Patient';
    const doctorName = $('#ed-doctorName').value.trim() || 'แพทย์ CCU';
    const status = $('#ed-status').value;
    const statusText = $('#ed-statusText').value.trim() || 'ดูแลตามแผนการรักษา';

    if (isEdit) {
      const b = BEDS[idx];
      b.bedNum = bedNum;
      b.bedCode = `เตียง ${String(bedNum).padStart(2, '0')} CCU`;
      b.caseTitle = caseTitle;
      b.patientName = patientName;
      b.dxBadge = dxBadge;
      b.doctorName = doctorName;
      b.status = status;
      b.statusText = statusText;
    } else {
      // สร้างเคสใหม่ คัดลอกเทมเพลต 6 ขั้นตอนมาจากเตียง 1 เป็นฐาน
      const templateStages = JSON.parse(JSON.stringify(ccuBeds[0].stageData));
      BEDS.push({
        bedNum,
        bedCode: `เตียง ${String(bedNum).padStart(2, '0')} CCU`,
        patientName,
        patientAge: 65,
        caseTitle,
        dxBadge,
        status,
        statusText,
        doctorName,
        doctorAvatar: '👨‍⚕️',
        stageData: templateStages
      });
    }

    save(CUSTOM_BEDS_KEY, BEDS);
    closeModal();
    renderCaseManager();
    toast('บันทึกข้อมูลเคสเรียบร้อยแล้ว ✨');
  }

  function deleteCase(idx) {
    if (BEDS.length <= 1) {
      toast('ต้องมีเคสอย่างน้อย 1 เคสในระบบ');
      return;
    }
    confirmDialog('ยืนยันการลบเคสนี้?', `เคส "${BEDS[idx].caseTitle}" จะถูกนำออกจากวอร์ด CCU`, 'ลบเคส', `delete-case-confirm-${idx}`);
  }

  function exportCasesAsJson() {
    const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(BEDS, null, 2));
    const dlAnchor = document.createElement('a');
    dlAnchor.setAttribute('href', dataStr);
    dlAnchor.setAttribute('download', `award_ccu_cases_${new Date().toISOString().slice(0, 10)}.json`);
    dlAnchor.click();
    toast('ดาวน์โหลดไฟล์ JSON เรียบร้อย 📤');
  }

  function importCasesJson() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json,application/json';
    input.onchange = (e) => {
      const file = e.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = (evt) => {
        try {
          const imported = JSON.parse(evt.target.result);
          if (Array.isArray(imported) && imported.length > 0 && imported[0].caseTitle) {
            BEDS = imported;
            save(CUSTOM_BEDS_KEY, BEDS);
            renderCaseManager();
            toast(`นำเข้าเคสสำเร็จทั้งหมด ${imported.length} เคส 🎉`);
          } else {
            toast('รูปแบบไฟล์ JSON ไม่ถูกต้อง');
          }
        } catch (err) {
          toast('เกิดข้อผิดพลาดในการอ่านไฟล์ JSON');
        }
      };
      reader.readAsText(file);
    };
    input.click();
  }

  function resetDefaultCases() {
    confirmDialog('คืนค่าเคสตั้งต้น?', 'เคสทั้งหมดจะถูกรีเซ็ตกลับเป็น 8 เตียงมาตรฐานของ CCU', 'คืนค่าเริ่มต้น', 'reset-default-cases-confirm');
  }

  /* =======================================================================
     STEP & ANSWER BUILDER (เพิ่ม ลบ แก้ไข ขั้นตอน & คำตอบ)
     ======================================================================= */
  let activeEditBedIdx = null;
  let activeEditStepIdx = 0;

  function openStepManager(bedIdx, stepIdx = 0) {
    activeEditBedIdx = bedIdx;
    activeEditStepIdx = stepIdx;
    const b = BEDS[bedIdx];
    const stages = b.stageData || [];
    const st = stages[stepIdx] || stages[0];

    // ตรวจสอบ mechanic ปัจจุบัน
    const isChoices = !!st.choices1toN;
    const isTrays = !!st.traysTask;
    const isUnordered = !!st.unorderedDropTask;
    const isSeq = !!st.sequenceTask && !st.choices1toN;

    let answersEditorHtml = '';

    if (isChoices) {
      const opts = st.choices1toN.options || [];
      answersEditorHtml = `
        <div class="form-group" style="margin-top:8px">
          <label>โจทย์คำถามย่อย (Prompt)</label>
          <input class="form-input" id="st-prompt" value="${st.choices1toN.prompt || ''}">
        </div>
        <div style="margin-top:10px">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
            <label style="font:700 12px var(--font-display);color:var(--ink-2)">รายการตัวเลือก & เฉลยคำตอบ</label>
            <button class="btn btn-sm btn-ghost" data-act="step-add-item" style="padding:2px 8px;font-size:11px">➕ เพิ่มตัวเลือก</button>
          </div>
          <div id="qa-items-list">
            ${opts.map((opt, oi) => `
              <div class="qa-item-row" data-item-idx="${oi}">
                <input class="form-input" type="text" data-field="text" value="${opt.text}" placeholder="ข้อความตัวเลือก">
                <label class="qa-cb-wrap">
                  <input type="checkbox" data-field="correct" ${opt.correct ? 'checked' : ''}>
                  <span>ถูก</span>
                </label>
                <button class="icon-btn" data-act="step-remove-item" data-oi="${oi}" style="width:28px;height:28px;color:#ef4444" title="ลบ">✕</button>
              </div>
            `).join('')}
          </div>
        </div>
      `;
    } else if (isTrays) {
      const tsk = st.traysTask;
      const pool = tsk.pool || [];
      const trays = tsk.trays || [];
      answersEditorHtml = `
        <div class="form-group" style="margin-top:8px">
          <label>โจทย์คำสั่งจัดถาด (Prompt)</label>
          <input class="form-input" id="st-prompt" value="${tsk.prompt || ''}">
        </div>
        <div style="margin-top:10px">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
            <label style="font:700 12px var(--font-display);color:var(--ink-2)">รายการอุปกรณ์ & ถาดเฉลยที่ถูกต้อง</label>
            <button class="btn btn-sm btn-ghost" data-act="step-add-item" style="padding:2px 8px;font-size:11px">➕ เพิ่มอุปกรณ์</button>
          </div>
          <div id="qa-items-list">
            ${pool.map((it, oi) => {
              // หาว่าไอเทมนี้เฉลยอยู่ในถาดไหน
              let targetTrayId = trays[0] ? trays[0].id : '';
              trays.forEach((tr) => {
                if ((tr.expectedIds && tr.expectedIds.includes(it.id)) || (tr.expectedOrder && tr.expectedOrder.includes(it.id))) {
                  targetTrayId = tr.id;
                }
              });
              return `
                <div class="qa-item-row" data-item-idx="${oi}">
                  <input class="form-input" type="text" data-field="text" value="${it.text}" placeholder="ชื่ออุปกรณ์">
                  <select class="form-input" data-field="tray">
                    ${trays.map((tr) => `
                      <option value="${tr.id}" ${tr.id === targetTrayId ? 'selected' : ''}>
                        ${tr.name.split(':')[0].replace(/^[🟩🟦]\s*/, '')}
                      </option>
                    `).join('')}
                  </select>
                  <button class="icon-btn" data-act="step-remove-item" data-oi="${oi}" style="width:28px;height:28px;color:#ef4444" title="ลบ">✕</button>
                </div>
              `;
            }).join('')}
          </div>
        </div>
      `;
    } else if (isUnordered) {
      const tsk = st.unorderedDropTask;
      const pool = tsk.pool || [];
      const expected = tsk.expectedIds || [];
      answersEditorHtml = `
        <div class="form-group" style="margin-top:8px">
          <label>โจทย์คำสั่งการพยาบาล (Prompt)</label>
          <input class="form-input" id="st-prompt" value="${tsk.prompt || ''}">
        </div>
        <div style="margin-top:10px">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
            <label style="font:700 12px var(--font-display);color:var(--ink-2)">การ์ดปฏิบัติการพยาบาล & เฉลยที่ต้องทำ</label>
            <button class="btn btn-sm btn-ghost" data-act="step-add-item" style="padding:2px 8px;font-size:11px">➕ เพิ่มการ์ด</button>
          </div>
          <div id="qa-items-list">
            ${pool.map((it, oi) => {
              const isCorrect = expected.includes(it.id);
              return `
                <div class="qa-item-row" data-item-idx="${oi}">
                  <input class="form-input" type="text" data-field="text" value="${it.text}" placeholder="ข้อความการพยาบาล">
                  <label class="qa-cb-wrap">
                    <input type="checkbox" data-field="correct" ${isCorrect ? 'checked' : ''}>
                    <span>ข้อที่ถูก</span>
                  </label>
                  <button class="icon-btn" data-act="step-remove-item" data-oi="${oi}" style="width:28px;height:28px;color:#ef4444" title="ลบ">✕</button>
                </div>
              `;
            }).join('')}
          </div>
        </div>
      `;
    } else {
      // Sequence Task (เรียงลำดับ)
      const tsk = st.sequenceTask;
      const pool = tsk ? (tsk.pool || []) : [];
      const order = tsk ? (tsk.correctOrder || []) : [];
      answersEditorHtml = `
        <div class="form-group" style="margin-top:8px">
          <label>โจทย์คำสั่งเรียงลำดับ (Prompt)</label>
          <input class="form-input" id="st-prompt" value="${(tsk && tsk.prompt) || ''}">
        </div>
        <div style="margin-top:10px">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
            <label style="font:700 12px var(--font-display);color:var(--ink-2)">การ์ดขั้นตอน & ลำดับเฉลยที่ถูกต้อง (1 ถึง N)</label>
            <button class="btn btn-sm btn-ghost" data-act="step-add-item" style="padding:2px 8px;font-size:11px">➕ เพิ่มขั้นตอน</button>
          </div>
          <div id="qa-items-list">
            ${pool.map((it, oi) => {
              const seqIdx = order.indexOf(it.id) + 1;
              return `
                <div class="qa-item-row" data-item-idx="${oi}">
                  <span style="font:700 11px var(--font-display);color:#0284c7">#${oi + 1}</span>
                  <input class="form-input" type="text" data-field="text" value="${it.text}" placeholder="ข้อความขั้นตอน">
                  <div class="qa-cb-wrap">
                    <span>ลำดับ:</span>
                    <input class="form-input" type="number" data-field="order" value="${seqIdx > 0 ? seqIdx : oi + 1}" style="width:50px;min-height:36px;padding:4px;text-align:center">
                  </div>
                  <button class="icon-btn" data-act="step-remove-item" data-oi="${oi}" style="width:28px;height:28px;color:#ef4444" title="ลบ">✕</button>
                </div>
              `;
            }).join('')}
          </div>
        </div>
      `;
    }

    openModal(`
      <div style="text-align:left;max-height:80vh;overflow-y:auto;padding-right:4px">
        <div style="display:flex;justify-content:space-between;align-items:center">
          <h2 style="font:700 16px var(--font-display);margin:0">📝 จัดการ 6 ขั้นตอน & คำตอบ</h2>
          <span style="font-size:11px;color:var(--ink-3)">${b.bedCode}</span>
        </div>
        <p class="hint" style="margin:2px 0 8px">เลือกขั้นตอนด้านล่างเพื่อแก้ไขโจทย์ ตัวเลือก และเฉลยคำตอบ</p>

        <!-- แถบเลือกขั้นตอน 1 ถึง 6 -->
        <div class="step-nav-bar">
          ${stages.map((s, idx) => `
            <button class="step-nav-pill ${idx === stepIdx ? 'on' : ''}" data-act="step-switch-tab" data-sidx="${idx}">
              ขั้นที่ ${idx + 1}
            </button>
          `).join('')}
        </div>

        <!-- ฟอร์มแก้ไขรายละเอียดขั้นตอน -->
        <div style="display:flex;flex-direction:column;gap:8px">
          <div class="form-row">
            <div class="form-group">
              <label>ชื่อขั้นตอน</label>
              <input class="form-input" id="st-name" value="${st.name || ''}">
            </div>
            <div class="form-group">
              <label>รูปแบบกลไก (Mechanic)</label>
              <input class="form-input" id="st-mech" value="${st.mechanic || ''}" readonly style="background:#f1f5f9;color:#64748b">
            </div>
          </div>

          <div class="form-group">
            <label>คำพูดแพทย์ / โจทย์สถานการณ์</label>
            <input class="form-input" id="st-docSpeech" value="${(st.doctorSpeech || '').replace(/^💬\s*"?|"?$/g, '')}">
          </div>

          <div class="form-group">
            <label>เอกสารความรู้ทางการแพทย์ (Reading Summary)</label>
            <textarea class="form-input form-textarea" id="st-reading">${st.reading || ''}</textarea>
          </div>

          <!-- กล่องจัดการตัวเลือก/อุปกรณ์/คำตอบ -->
          <div style="background:#fff;border:1.5px solid #bae6fd;border-radius:14px;padding:10px;margin-top:4px">
            <b style="font:700 13px var(--font-display);color:#0369a1;display:block;margin-bottom:4px">⚙️ คำตอบและตัวเลือกในขั้นนี้</b>
            ${answersEditorHtml}
          </div>
        </div>

        <div class="modal-actions" style="margin-top:14px;display:flex;gap:8px">
          <button class="btn btn-primary" data-act="save-step-data">💾 บันทึกคำตอบขั้นตอนนี้</button>
          <button class="btn btn-ghost" data-act="modal-close">ปิด</button>
        </div>
      </div>
    `, 'modal-card-lg');
  }

  function saveCurrentStepFromForm() {
    if (activeEditBedIdx === null) return;
    const b = BEDS[activeEditBedIdx];
    const st = b.stageData[activeEditStepIdx];
    if (!st) return;

    // อัปเดตข้อมูลทั่วไปของขั้นตอน
    st.name = $('#st-name').value.trim() || st.name;
    const speechVal = $('#st-docSpeech').value.trim();
    st.doctorSpeech = speechVal ? `💬 "${speechVal}"` : st.doctorSpeech;
    st.reading = $('#st-reading').value.trim() || st.reading;

    const promptVal = $('#st-prompt') ? $('#st-prompt').value.trim() : '';

    // อ่านรายการคำตอบจาก #qa-items-list
    const itemRows = document.querySelectorAll('#qa-items-list .qa-item-row');

    if (st.choices1toN) {
      st.choices1toN.prompt = promptVal || st.choices1toN.prompt;
      const newOpts = [];
      itemRows.forEach((row, i) => {
        const text = row.querySelector('[data-field="text"]').value.trim();
        const correct = row.querySelector('[data-field="correct"]').checked;
        if (text) {
          newOpts.push({ id: `c_${Date.now()}_${i}`, text, correct });
        }
      });
      if (newOpts.length) st.choices1toN.options = newOpts;
    } else if (st.traysTask) {
      st.traysTask.prompt = promptVal || st.traysTask.prompt;
      const newPool = [];
      const trayMap = {};
      st.traysTask.trays.forEach((tr) => { trayMap[tr.id] = []; });

      itemRows.forEach((row, i) => {
        const text = row.querySelector('[data-field="text"]').value.trim();
        const trayId = row.querySelector('[data-field="tray"]').value;
        if (text) {
          const itemId = `it_${Date.now()}_${i}`;
          newPool.push({ id: itemId, text });
          if (trayMap[trayId]) trayMap[trayId].push(itemId);
        }
      });

      if (newPool.length) {
        st.traysTask.pool = newPool;
        st.traysTask.trays.forEach((tr) => {
          if (st.traysTask.ordered) tr.expectedOrder = trayMap[tr.id] || [];
          else tr.expectedIds = trayMap[tr.id] || [];
        });
      }
    } else if (st.unorderedDropTask) {
      st.unorderedDropTask.prompt = promptVal || st.unorderedDropTask.prompt;
      const newPool = [];
      const newExpected = [];

      itemRows.forEach((row, i) => {
        const text = row.querySelector('[data-field="text"]').value.trim();
        const correct = row.querySelector('[data-field="correct"]').checked;
        if (text) {
          const itemId = `u_${Date.now()}_${i}`;
          newPool.push({ id: itemId, text });
          if (correct) newExpected.push(itemId);
        }
      });

      if (newPool.length) {
        st.unorderedDropTask.pool = newPool;
        st.unorderedDropTask.expectedIds = newExpected.length ? newExpected : [newPool[0].id];
      }
    } else if (st.sequenceTask) {
      st.sequenceTask.prompt = promptVal || st.sequenceTask.prompt;
      const tempItems = [];

      itemRows.forEach((row, i) => {
        const text = row.querySelector('[data-field="text"]').value.trim();
        const orderNum = parseInt(row.querySelector('[data-field="order"]').value, 10) || (i + 1);
        if (text) {
          tempItems.push({ id: `s_${Date.now()}_${i}`, text, orderNum });
        }
      });

      if (tempItems.length) {
        st.sequenceTask.pool = tempItems.map(({ id, text }) => ({ id, text }));
        // เรียงลำดับคำตอบตาม orderNum
        tempItems.sort((a, b) => a.orderNum - b.orderNum);
        st.sequenceTask.correctOrder = tempItems.map((item) => item.id);
      }
    }

    save(CUSTOM_BEDS_KEY, BEDS);
    toast('บันทึกขั้นตอนและคำตอบเรียบร้อยแล้ว ✨');
    openStepManager(activeEditBedIdx, activeEditStepIdx);
  }

  function addStepItemRow() {
    const list = $('#qa-items-list');
    if (!list) return;
    const b = BEDS[activeEditBedIdx];
    const st = b.stageData[activeEditStepIdx];
    const oi = list.children.length;

    const row = document.createElement('div');
    row.className = 'qa-item-row';
    row.dataset.itemIdx = oi;

    if (st.choices1toN || st.unorderedDropTask) {
      row.innerHTML = `
        <input class="form-input" type="text" data-field="text" value="" placeholder="ข้อความตัวเลือกใหม่">
        <label class="qa-cb-wrap">
          <input type="checkbox" data-field="correct" checked>
          <span>ถูก</span>
        </label>
        <button class="icon-btn" data-act="step-remove-item" data-oi="${oi}" style="width:28px;height:28px;color:#ef4444" title="ลบ">✕</button>
      `;
    } else if (st.traysTask) {
      const trays = st.traysTask.trays || [];
      row.innerHTML = `
        <input class="form-input" type="text" data-field="text" value="" placeholder="ชื่ออุปกรณ์ใหม่">
        <select class="form-input" data-field="tray">
          ${trays.map((tr) => `
            <option value="${tr.id}">${tr.name.split(':')[0].replace(/^[🟩🟦]\s*/, '')}</option>
          `).join('')}
        </select>
        <button class="icon-btn" data-act="step-remove-item" data-oi="${oi}" style="width:28px;height:28px;color:#ef4444" title="ลบ">✕</button>
      `;
    } else {
      row.innerHTML = `
        <span style="font:700 11px var(--font-display);color:#0284c7">#${oi + 1}</span>
        <input class="form-input" type="text" data-field="text" value="" placeholder="ข้อความขั้นตอนใหม่">
        <div class="qa-cb-wrap">
          <span>ลำดับ:</span>
          <input class="form-input" type="number" data-field="order" value="${oi + 1}" style="width:50px;min-height:36px;padding:4px;text-align:center">
        </div>
        <button class="icon-btn" data-act="step-remove-item" data-oi="${oi}" style="width:28px;height:28px;color:#ef4444" title="ลบ">✕</button>
      `;
    }

    list.appendChild(row);
    row.querySelector('input[type="text"]').focus();
  }

  function removeStepItemRow(oi) {
    const list = $('#qa-items-list');
    if (!list) return;
    if (list.children.length <= 1) {
      toast('ต้องมีตัวเลือกอย่างน้อย 1 ข้อ');
      return;
    }
    const row = list.querySelector(`[data-item-idx="${oi}"]`) || list.children[oi];
    if (row) row.remove();
  }

  /* =======================================================================
     GAME
     ======================================================================= */
  function buildState(step) {
    const task = step.sequenceTask || step.traysTask || step.unorderedDropTask;
    const items = {}; task.pool.forEach((it) => { items[it.id] = it; });
    const S = {
      items, pool: shuffle(task.pool.map((i) => i.id)), seq: null, trays: null, unordered: null,
      sel: new Set(), picked: null, wrong: new Set(), wrongOpts: new Set(), locked: false
    };
    if (step.sequenceTask) S.seq = new Array(step.sequenceTask.correctOrder.length).fill(null);
    if (step.traysTask) { S.trays = {}; step.traysTask.trays.forEach((t) => { S.trays[t.id] = []; }); }
    if (step.unorderedDropTask) S.unordered = [];
    return S;
  }

  function openBed(i) {
    closeModal();
    ui.screen = 'game';
    G = {
      bedIdx: i,
      stepIdx: 0,
      mistakes: 0,
      stepMistakes: {},
      done: new Set(),
      S: null,
      stepStates: {},
      startStars: totalStars()
    };
    renderTop(); loadStep(0);
  }

  function loadStep(idx) {
    if (G.S && curStep()) G.stepStates[curStep().id] = G.S;
    G.stepIdx = idx;
    const stId = curStep().id;
    G.S = G.stepStates[stId] || buildState(curStep());
    closeSheet(); renderGame(); renderDock(); el.view.scrollTop = 0;
  }

  function stepperHtml() {
    const st = curBed().stageData;
    return st.map((s, i) => {
      const cls = G.done.has(s.id) ? 'done' : i === G.stepIdx ? 'now' : '';
      return (i ? `<span class="st-line ${i <= G.stepIdx ? 'on' : ''}"></span>` : '') +
        `<span class="st-dot ${cls}" aria-label="ขั้นที่ ${i + 1}">${cls === 'done' ? icon('check') : i + 1}</span>`;
    }).join('');
  }
  const updateStepper = () => { const n = $('#stepper'); if (n) n.innerHTML = stepperHtml(); };

  function renderGame() {
    const b = curBed(); const step = curStep(); const v = step.vitals; const alarm = isAlarm(v);
    el.view.innerHTML = `
      <section class="game">
        <div class="stepper" id="stepper">${stepperHtml()}</div>
        <div class="step-head">
          <h2>${step.name.replace(/^\d+\.\s*/, '')}</h2>
          <span class="step-no">ขั้นที่ ${G.stepIdx + 1}/${b.stageData.length}</span>
          <span class="mech">🎮 ${step.mechanic}</span>
        </div>
        <div class="case">
          <div class="monitor ${alarm ? 'alarm' : ''}">
            <div class="m-top"><b>${b.bedCode}</b><span>${b.patientName}</span>${alarm ? '<span class="m-alarm">ALARM</span>' : ''}</div>
            <div class="m-grid">
              <div class="tile t-hr"><small>HR</small><b>${v.hr}</b></div>
              <div class="tile t-bp"><small>BP</small><b>${v.bp}</b></div>
              <div class="tile t-sp"><small>SpO₂</small><b>${v.spo2}</b></div>
              <div class="tile t-map"><small>MAP</small><b>${v.map}</b></div>
            </div>
            <div class="m-ecg">${ecg(v.hr, alarm ? '#f87171' : '#4ade80')}</div>
          </div>
          <div class="doc">
            <div class="doc-av">${b.doctorAvatar}</div>
            <div class="bubble"><b>${b.doctorName}</b>${cleanSpeech(step.doctorSpeech)}</div>
          </div>
        </div>
        <details class="reading" open><summary>📖 สาระความรู้</summary><p>${step.reading}</p></details>
        <div id="task"></div>
      </section>`;
    renderTask();
  }

  const chipHtml = (id, extra = '') => {
    const S = G.S;
    const it = S.items[id];
    const imgHtml = it.img ? `<img src="${it.img}" class="chip-img" alt="" />` : '';
    return `<div class="chip ${S.picked === id ? 'is-picked' : ''} ${S.wrong.has(id) ? 'is-wrong' : ''}" data-chip="${id}" role="button" tabindex="0">${extra}<span class="grip"></span>${imgHtml}<span>${it.text}</span></div>`;
  };
  const poolHtml = (hint) => {
    const S = G.S;
    return `<div class="pool" data-drop="pool">${S.pool.length ? S.pool.map((id) => chipHtml(id)).join('') : '<span class="pool-empty">วางครบทุกใบแล้ว 🎉</span>'}</div><p class="hint">${hint}</p>`;
  };

  function renderTask() {
    const step = curStep(); const S = G.S; let h = '';

    if (step.choices1toN) {
      const c = step.choices1toN;
      h += `<section class="card"><p class="prompt">${c.prompt}</p><div class="opts">${c.options.map((o) => {
        const on = S.sel.has(o.id);
        return `<button class="opt ${on ? 'is-on' : ''} ${S.wrongOpts.has(o.id) ? 'is-wrong' : ''}" data-act="toggle-opt" data-id="${o.id}" aria-pressed="${on}">
          <span class="cb">${on ? icon('check') : ''}</span><span>${o.text}</span></button>`;
      }).join('')}</div></section>`;
    }

    if (step.sequenceTask) {
      h += `<section class="card"><p class="prompt">${step.sequenceTask.prompt}</p>
        ${poolHtml('แตะการ์ดเพื่อเติมช่องถัดไป · ลากเพื่อสลับตำแหน่ง · แตะการ์ดที่วางแล้วเพื่อเอาออก')}
        <ol class="slots">${S.seq.map((id, i) => `
          <li class="slot dz ${id ? 'filled' : ''}" data-drop="seq:${i}"><span class="slot-no">${i + 1}</span>
            ${id ? chipHtml(id) : '<span class="slot-ph">ลากการ์ดมาวางที่นี่</span>'}</li>`).join('')}</ol></section>`;
    }

    if (step.traysTask) {
      const t = step.traysTask;
      h += `<section class="card"><p class="prompt">${t.prompt.replace(/\*\*/g, '')}</p>
        ${poolHtml('แตะการ์ดแล้วแตะถาดที่ต้องการ · หรือกดค้างแล้วลากไปวาง · แตะการ์ดในถาดเพื่อเอาออก')}
        <div class="trays">${t.trays.map((tr) => {
          const arr = S.trays[tr.id];
          return `<div class="tray ${tr.sterile ? 'sterile' : ''}" data-drop="tray:${tr.id}">
            <div class="tray-h"><span>${tr.sterile ? '✨' : '🧰'}</span><span>${cleanTray(tr.name)}</span><b class="count">${arr.length}</b></div>
            <div class="tray-body">${arr.length
              ? arr.map((id, i) => chipHtml(id, t.ordered ? `<b class="ord">${i + 1}</b>` : '')).join('')
              : '<span class="tray-ph">วางอุปกรณ์ในถาดนี้</span>'}</div></div>`;
        }).join('')}</div></section>`;
    }

    if (step.unorderedDropTask) {
      const u = step.unorderedDropTask; const n = u.expectedIds.length;
      h += `<section class="card"><p class="prompt">${u.prompt}</p>
        ${poolHtml('แตะหรือลากการ์ดที่ถูกต้องใส่กล่อง · แตะการ์ดในกล่องเพื่อเอาออก')}
        <div class="tray sterile" data-drop="unordered">
          <div class="tray-h"><span>📋</span><span>กล่องปฏิบัติการพยาบาล</span><b class="count">${S.unordered.length}/${n}</b></div>
          <div class="tray-body">${S.unordered.length ? S.unordered.map((id) => chipHtml(id)).join('') : '<span class="tray-ph">วางการ์ดที่ถูกต้องที่นี่</span>'}</div>
        </div></section>`;
    }

    $('#task').innerHTML = h;
  }

  /* ---------- item movement ---------- */
  function removeFrom(id) {
    const S = G.S; let k = S.pool.indexOf(id);
    if (k > -1) { S.pool.splice(k, 1); return { kind: 'pool' }; }
    if (S.seq) { k = S.seq.indexOf(id); if (k > -1) { S.seq[k] = null; return { kind: 'seq', i: k }; } }
    if (S.trays) { for (const t in S.trays) { k = S.trays[t].indexOf(id); if (k > -1) { S.trays[t].splice(k, 1); return { kind: 'tray', id: t }; } } }
    if (S.unordered) { k = S.unordered.indexOf(id); if (k > -1) { S.unordered.splice(k, 1); return { kind: 'unordered' }; } }
    return { kind: 'none' };
  }

  function moveItem(id, dest, idx) {
    const S = G.S; const origin = removeFrom(id); S.wrong.clear(); S.picked = null;
    if (dest === 'pool') { S.pool.push(id); return; }
    if (dest.startsWith('seq:')) {
      const i = +dest.slice(4); const prev = S.seq[i]; S.seq[i] = id;
      if (prev) { if (origin.kind === 'seq') S.seq[origin.i] = prev; else S.pool.push(prev); }
      return;
    }
    if (dest.startsWith('tray:')) {
      const arr = S.trays[dest.slice(5)]; const at = idx == null ? arr.length : Math.min(idx, arr.length);
      arr.splice(at, 0, id); return;
    }
    if (dest === 'unordered') S.unordered.push(id);
  }

  function handleTap(id) {
    const S = G.S; if (S.locked) return;
    if (S.pool.includes(id)) {
      if (S.seq) { const i = S.seq.indexOf(null); if (i > -1) { moveItem(id, 'seq:' + i); SFX.drop(); } }
      else if (S.unordered) { moveItem(id, 'unordered'); SFX.drop(); }
      else { S.picked = S.picked === id ? null : id; SFX.pick(); }
    } else { moveItem(id, 'pool'); SFX.pick(); }
    renderTask();
  }

  /* ---------- pointer drag & drop (mouse + touch) ---------- */
  let dnd = null;
  const insertIndex = (zone, y, id) => {
    const chips = [...zone.querySelectorAll('[data-chip]')].filter((c) => c.dataset.chip !== id);
    for (let i = 0; i < chips.length; i++) { const r = chips[i].getBoundingClientRect(); if (y < r.top + r.height / 2) return i; }
    return chips.length;
  };

  function onPointerDown(e) {
    const chip = e.target.closest('[data-chip]');
    if (!chip || !G || !G.S || G.S.locked) return;
    if (e.pointerType === 'mouse' && e.button !== 0) return;
    const r = chip.getBoundingClientRect();
    dnd = { id: chip.dataset.chip, chip, pid: e.pointerId, type: e.pointerType, x0: e.clientX, y0: e.clientY, x: e.clientX, y: e.clientY, ox: e.clientX - r.left, oy: e.clientY - r.top, w: r.width, active: false, timer: null, hover: null, ghost: null, raf: 0 };
    if (e.pointerType !== 'mouse') dnd.timer = setTimeout(beginDrag, 170); // long-press to drag on touch (keeps scrolling usable)
    window.addEventListener('pointermove', onPointerMove);
    window.addEventListener('pointerup', onPointerUp);
    window.addEventListener('pointercancel', onPointerCancel);
  }

  function beginDrag() {
    if (!dnd || dnd.active) return;
    dnd.active = true; clearTimeout(dnd.timer);
    const g = dnd.chip.cloneNode(true);
    g.classList.add('drag-ghost'); g.classList.remove('is-picked', 'is-wrong'); g.removeAttribute('data-chip'); g.style.width = dnd.w + 'px';
    document.body.appendChild(g); dnd.ghost = g; dnd.chip.classList.add('is-origin');
    moveGhost(); SFX.pick(); haptic(8);
    dnd.raf = requestAnimationFrame(autoScroll);
  }
  function moveGhost() { dnd.ghost.style.setProperty('--x', (dnd.x - dnd.ox) + 'px'); dnd.ghost.style.setProperty('--y', (dnd.y - dnd.oy) + 'px'); }
  function setHover(node) { if (dnd.hover === node) return; if (dnd.hover) dnd.hover.classList.remove('dz-hover'); if (node) node.classList.add('dz-hover'); dnd.hover = node; }
  function autoScroll() {
    if (!dnd || !dnd.active) return;
    const r = el.view.getBoundingClientRect(); let dy = 0;
    if (dnd.y < r.top + 70) dy = -Math.min(16, (r.top + 70 - dnd.y) / 4);
    else if (dnd.y > r.bottom - 70) dy = Math.min(16, (dnd.y - (r.bottom - 70)) / 4);
    if (dy) el.view.scrollTop += dy;
    dnd.raf = requestAnimationFrame(autoScroll);
  }
  function onPointerMove(e) {
    if (!dnd || e.pointerId !== dnd.pid) return;
    dnd.x = e.clientX; dnd.y = e.clientY;
    const dist = Math.hypot(dnd.x - dnd.x0, dnd.y - dnd.y0);
    if (!dnd.active) {
      if (dnd.type === 'mouse') { if (dist > 5) beginDrag(); }
      else if (dist > 10) { endDnd(); return; } // finger moved before long-press → user is scrolling
      if (!dnd || !dnd.active) return;
    }
    moveGhost();
    const t = document.elementFromPoint(dnd.x, dnd.y);
    setHover(t ? t.closest('#task [data-drop]') : null);
  }
  function onPointerUp(e) {
    if (!dnd || e.pointerId !== dnd.pid) return;
    const d = dnd; const wasActive = d.active; const { x, y, id } = d;
    if (wasActive) {
      const t = document.elementFromPoint(x, y); const zone = t && t.closest('#task [data-drop]');
      endDnd();
      if (zone) {
        const dest = zone.dataset.drop;
        moveItem(id, dest, dest.startsWith('tray:') ? insertIndex(zone, y, id) : null);
        SFX.drop(); haptic(10);
      }
      renderTask();
    } else { endDnd(); handleTap(id); }
  }
  function onPointerCancel(e) { if (dnd && e.pointerId === dnd.pid) endDnd(); }
  function endDnd() {
    if (!dnd) return;
    clearTimeout(dnd.timer); cancelAnimationFrame(dnd.raf);
    if (dnd.ghost) dnd.ghost.remove();
    if (dnd.hover) dnd.hover.classList.remove('dz-hover');
    if (dnd.chip) dnd.chip.classList.remove('is-origin');
    dnd = null;
    window.removeEventListener('pointermove', onPointerMove);
    window.removeEventListener('pointerup', onPointerUp);
    window.removeEventListener('pointercancel', onPointerCancel);
  }
  // Stop the page from scrolling while a touch drag is in progress
  window.addEventListener('touchmove', (e) => { if (dnd && dnd.active) e.preventDefault(); }, { passive: false });
  el.view.addEventListener('pointerdown', onPointerDown);
  el.view.addEventListener('contextmenu', (e) => { if (e.target.closest('[data-chip]')) e.preventDefault(); });
  el.view.addEventListener('keydown', (e) => {
    if ((e.key === 'Enter' || e.key === ' ') && e.target.matches && e.target.matches('[data-chip]')) { e.preventDefault(); handleTap(e.target.dataset.chip); }
  });

  /* ---------- check / feedback ---------- */
  function checkStep() {
    const step = curStep(); const S = G.S; if (S.locked) return;

    const inc = [];
    if (step.choices1toN && S.sel.size === 0) inc.push('เลือกตัวเลือกอย่างน้อย 1 ข้อ');
    if (S.seq && S.seq.includes(null)) inc.push('วางการ์ดให้ครบทุกช่อง');
    if (S.trays && S.pool.length) inc.push('หยิบอุปกรณ์ลงถาดให้ครบทุกชิ้น');
    if (S.unordered && S.unordered.length < step.unorderedDropTask.expectedIds.length) inc.push(`เลือกให้ครบ ${step.unorderedDropTask.expectedIds.length} ข้อ`);
    if (inc.length) { toast('ยังไม่ครบ: ' + inc[0]); SFX.pick(); shake($('[data-act="check"]')); return; }

    S.wrong = new Set(); S.wrongOpts = new Set(); const msgs = [];

    if (step.choices1toN) {
      const opts = step.choices1toN.options; const correct = opts.filter((o) => o.correct).map((o) => o.id);
      opts.forEach((o) => { if (S.sel.has(o.id) && !o.correct) S.wrongOpts.add(o.id); });
      const missing = correct.some((id) => !S.sel.has(id));
      if (S.wrongOpts.size) msgs.push('มีข้อที่ไม่ควรเลือกอยู่ (ข้อสีแดง)');
      else if (missing) msgs.push('ยังเลือกไม่ครบทุกข้อที่ต้องตรวจสอบ');
    }
    if (step.sequenceTask) {
      const exp = step.sequenceTask.correctOrder; let bad = false;
      S.seq.forEach((id, i) => { if (id !== exp[i]) { S.wrong.add(id); bad = true; } });
      if (bad) msgs.push('ลำดับบางข้อยังไม่ถูกต้อง (การ์ดสีแดงอยู่ผิดตำแหน่ง)');
    }
    if (step.traysTask) {
      const t = step.traysTask;
      t.trays.forEach((tr) => {
        const arr = S.trays[tr.id]; let bad = false;
        if (t.ordered) arr.forEach((id, i) => { if (id !== tr.expectedOrder[i]) { S.wrong.add(id); bad = true; } });
        else arr.forEach((id) => { if (!tr.expectedIds.includes(id)) { S.wrong.add(id); bad = true; } });
        const need = (t.ordered ? tr.expectedOrder : tr.expectedIds).length;
        if (!bad && arr.length !== need) bad = true;
        if (bad) msgs.push(t.ordered ? `ลำดับใน “${cleanTray(tr.name)}” ยังไม่ถูกต้อง` : `ใน “${cleanTray(tr.name)}” มีอุปกรณ์อยู่ผิดถาด`);
      });
    }
    if (step.unorderedDropTask) {
      const exp = step.unorderedDropTask.expectedIds; let bad = false;
      S.unordered.forEach((id) => { if (!exp.includes(id)) { S.wrong.add(id); bad = true; } });
      if (!bad && (S.unordered.length !== exp.length || exp.some((id) => !S.unordered.includes(id)))) bad = true;
      if (bad) msgs.push('มีการพยาบาลที่ไม่ปลอดภัยปนอยู่ (การ์ดสีแดง) ลองเอาออกแล้วเลือกใหม่');
    }

    if (msgs.length === 0) {
      S.locked = true; G.done.add(step.id); updateStepper();
      renderDock();
      SFX.ok(); haptic(30);

      // บันทึกสถิติขั้นตอนที่ทำถูกโดยไม่มีข้อผิดพลาด
      if (G.mistakes === 0) {
        playerStats.stepsWithoutMistake = (playerStats.stepsWithoutMistake || 0) + 1;
      }
      if (step.traysTask) {
        const sortedCount = Object.values(S.trays).reduce((sum, arr) => sum + arr.length, 0);
        playerStats.trayItemsSorted = (playerStats.trayItemsSorted || 0) + sortedCount;
      }
      save(STATS_KEY, playerStats);

      const last = G.stepIdx === curBed().stageData.length - 1;
      if (last) {
        finishCase();
        return;
      }
      const praise = ['ยอดเยี่ยม!', 'เก่งมาก!', 'เป๊ะเลย!', 'สุดยอด!'][Math.floor(Math.random() * 4)];
      showSheet('ok', praise, 'ผ่านขั้นตอนนี้แล้ว ถูกต้องตามหลักความปลอดภัย',
        '', '<button class="btn btn-success btn-block" data-act="sheet-next">ไปต่อ</button>');
    } else {
      G.mistakes++; SFX.bad(); haptic([30, 40, 30]);
      renderTop(G.mistakes === 1 ? 3 : G.mistakes === 3 ? 2 : 0);
      const stId = curStep().id;
      G.stepMistakes[stId] = (G.stepMistakes[stId] || 0) + 1;
      const count = G.stepMistakes[stId];

      if (count >= 3) {
        showSheet('bad', 'พยายามได้ดีมากแล้วจ้า!', 'ผิดครบ 3 ครั้งแล้ว สามารถดูเฉลยแล้วไปต่อได้เลยนะ',
          `<ul>${msgs.map((m) => `<li>${m}</li>`).join('')}</ul>`,
          `<div style="display:flex;gap:8px">
             <button class="btn btn-ghost" style="flex:1" data-act="sheet-retry">ลองอีกที</button>
             <button class="btn btn-gold" style="flex:2" data-act="step-skip">💡 ดูเฉลย & ไปต่อ</button>
           </div>`);
        renderDock();
      } else {
        showSheet('bad', `ยังไม่ถูกน้า (ครั้งที่ ${count}/3)`, 'ลองดูจุดที่ขึ้นสีแดงอีกครั้ง',
          `<ul>${msgs.map((m) => `<li>${m}</li>`).join('')}</ul>`,
          '<button class="btn btn-danger btn-block" data-act="sheet-retry">ลองอีกครั้ง</button>');
      }
      renderTask();
    }
  }

  function showSheet(kind, title, sub, listHtml, btnHtml) {
    el.sheet.className = 'sheet ' + kind;
    el.sheet.innerHTML = `<div class="sheet-h"><span class="sheet-badge">${icon(kind === 'ok' ? 'check' : 'x')}</span><div><b>${title}</b><small>${sub}</small></div></div>${listHtml}${btnHtml}`;
    void el.sheet.offsetWidth; el.sheet.classList.add('show');
  }
  function closeSheet() { el.sheet.classList.remove('show'); }

  function nextStep() {
    closeSheet();
    if (G.stepIdx < curBed().stageData.length - 1) loadStep(G.stepIdx + 1);
    else finishCase();
  }

  /* ---------- finish / modal ---------- */
  function openModal(html, cardClass = '') { el.modal.innerHTML = `<div class="modal-card ${cardClass}">${html}</div>`; el.modal.classList.add('show'); }
  function closeModal() { el.modal.classList.remove('show'); }

  function confetti(host) {
    const colors = ['#f59e0b', '#22c55e', '#0ea5e9', '#f43f5e', '#a855f7', '#fde047'];
    let h = '';
    for (let i = 0; i < 40; i++) {
      h += `<i style="left:${Math.random() * 100}%;background:${colors[i % colors.length]};animation-duration:${1.8 + Math.random() * 1.6}s;animation-delay:${Math.random() * 0.7}s;transform:rotate(${Math.random() * 360}deg)"></i>`;
    }
    const c = document.createElement('div'); c.className = 'confetti'; c.innerHTML = h; host.appendChild(c);
  }

  function finishCase() {
    const b = curBed(); const stars = liveStars();
    const before = totalStars(); const prev = progress[b.bedNum] || {};
    const best = Math.max(prev.stars || 0, stars);
    progress[b.bedNum] = { passed: true, stars: best }; save(SAVE_KEY, progress);

    // อัปเดตสถิติผู้เล่น (Player Stats สำหรับ Milestone Goals)
    playerStats.totalCompletedCases = (playerStats.totalCompletedCases || 0) + 1;
    if (stars === 3) playerStats.perfectCases = (playerStats.perfectCases || 0) + 1;
    if (b.status === 'critical' || b.status === 'alert') {
      playerStats.emergencyCasesDone = (playerStats.emergencyCasesDone || 0) + 1;
    }
    if (prev.passed) {
      playerStats.replayedCases = (playerStats.replayedCases || 0) + 1;
    }
    save(STATS_KEY, playerStats);

    // ตรวจสอบว่าในเวรปัจจุบัน (ถ้าเข้าผ่านเวร) ทำเคสครบทุกเตียงหรือยัง
    let shiftCompletedMsg = '';
    if (ui.filterShift) {
      const shiftObj = SHIFTS.find((s) => s.id === ui.filterShift);
      if (shiftObj) {
        const allPassed = shiftObj.bedIndices.every((idx) => progress[BEDS[idx].bedNum] && progress[BEDS[idx].bedNum].passed);
        if (allPassed) {
          const dayKey = `${ui.calYear}-${ui.calMonth}-${ui.selectedDay}`;
          if (!rosterDaysProgress[dayKey] || !rosterDaysProgress[dayKey].passed) {
            rosterDaysProgress[dayKey] = { passed: true };
            save(ROSTER_PROGRESS_KEY, rosterDaysProgress);
            const nextDay = ui.selectedDay + 1;
            shiftCompletedMsg = `<div class="lvl-up" style="background:#ecfdf5;border-color:#86efac;color:#065f46">🎉 ยินดีด้วย! ปฏิบัติหน้าที่ครบใน${shiftObj.name}แล้ว<br>ปลดล็อกวันที่ ${nextDay} เรียบร้อย!</div>`;
          }
        }
      }
    }

    const after = totalStars(); const lvlUp = levelOf(after) > levelOf(before);
    const gained = best - (prev.stars || 0);
    const msg = stars === 3 ? 'สุดยอด! ตอบเป๊ะทุกข้อ ได้ครบ 3 ดาวเลย'
      : `ผ่านเคสสำเร็จ! ลองเล่นซ้ำเพื่อเก็บให้ครบ 3 ดาวนะ${gained > 0 ? ` (ได้ดาวเพิ่ม +${gained})` : ''}`;
    const nxt = nextTarget();

    openModal(`
      <div class="win-ribbon">เสร็จสิ้นเคส!</div>
      <h2>${b.bedCode}</h2><p class="win-sub">${b.caseTitle}</p>
      <div class="big-stars">${[1, 2, 3].map((n) => `<span class="big-star ${stars >= n ? 'on' : ''}" style="--i:${n - 1}">${starSvg(stars >= n, 62)}</span>`).join('')}</div>
      <p class="win-msg">${msg}</p>
      ${shiftCompletedMsg}
      ${lvlUp ? `<div class="lvl-up">⬆️ เลื่อนระดับ! Lv.${levelOf(after)} · ${RANKS[levelOf(after) - 1]}</div>` : ''}
      <div class="modal-actions">
        ${nxt >= 0 && nxt !== G.bedIdx ? '<button class="btn btn-gold" data-act="win-next">เตียงถัดไป ▶</button>' : ''}
        <button class="btn" data-act="win-ward">${icon('bed')}<span>กลับวอร์ด</span></button>
        <button class="btn btn-ghost" data-act="win-replay">${icon('undo')}<span>เล่นซ้ำเก็บ 3 ดาว</span></button>
      </div>`);
    confetti(el.modal.firstElementChild);
    SFX.win(); haptic([20, 40, 20, 40, 60]);
    for (let i = 0; i < stars; i++) setTimeout(() => SFX.star(i), 450 + i * 320);
  }

  function confirmDialog(title, text, yesLabel, yesAct) {
    openModal(`<h2 class="dialog-t" style="margin-top:0">${title}</h2><p class="dialog-p">${text}</p>
      <div class="modal-actions"><button class="btn btn-danger" data-act="${yesAct}">${yesLabel}</button><button class="btn btn-ghost" data-act="modal-close">ยกเลิก</button></div>`);
  }

  /* =======================================================================
     EVENTS
     ======================================================================= */
  function act(name, node) {
    switch (name) {
      case 'tab':
        ui.tab = node.dataset.tab;
        SFX.pick();
        renderTabs();
        break;
      case 'step-prev':
        if (G.stepIdx > 0) {
          SFX.pick();
          loadStep(G.stepIdx - 1);
        }
        break;
      case 'step-next':
        if (G.done.has(curStep().id) && G.stepIdx < curBed().stageData.length - 1) {
          SFX.pick();
          loadStep(G.stepIdx + 1);
        }
        break;
      case 'select-day':
        if (node.dataset.locked === '1') {
          SFX.bad();
          haptic([20, 30, 20]);
          shake(node);
          toast('ยังเข้าเวรนี้ไม่ได้');
          return;
        }
        ui.selectedDay = +node.dataset.day;
        SFX.pick();
        renderRoster();
        break;
      case 'cal-prev':
        if (ui.calMonth === 0) { ui.calMonth = 11; ui.calYear--; } else { ui.calMonth--; }
        ui.selectedDay = 1;
        SFX.pick();
        renderRoster();
        break;
      case 'cal-next':
        if (ui.calMonth === 11) { ui.calMonth = 0; ui.calYear++; } else { ui.calMonth++; }
        ui.selectedDay = 1;
        SFX.pick();
        renderRoster();
        break;
      case 'go-ward-shift':
        ui.filterShift = node.dataset.shift;
        ui.tab = 'ward';
        SFX.pick();
        renderTabs();
        break;
      case 'go-ward-all':
        ui.filterShift = null;
        ui.tab = 'ward';
        SFX.pick();
        renderTabs();
        break;
      case 'clear-filter':
        ui.filterShift = null;
        SFX.pick();
        renderWard();
        break;
      case 'open-case-mgmt':
        ui.tab = 'cases';
        SFX.pick();
        renderTabs();
        break;
      case 'create-new-case':
        SFX.pick();
        openCaseEditor(-1);
        break;
      case 'edit-case':
        SFX.pick();
        openCaseEditor(+node.dataset.i);
        break;
      case 'manage-steps':
        SFX.pick();
        openStepManager(+node.dataset.i, 0);
        break;
      case 'step-switch-tab':
        SFX.pick();
        openStepManager(activeEditBedIdx, +node.dataset.sidx);
        break;
      case 'save-step-data':
        SFX.pick();
        saveCurrentStepFromForm();
        break;
      case 'step-add-item':
        SFX.pick();
        addStepItemRow();
        break;
      case 'step-remove-item':
        SFX.pick();
        removeStepItemRow(+node.dataset.oi);
        break;
      case 'delete-case':
        SFX.pick();
        deleteCase(+node.dataset.i);
        break;
      case 'save-case':
        SFX.pick();
        saveCaseFromForm(+node.dataset.i);
        break;
      case 'export-cases':
        SFX.pick();
        exportCasesAsJson();
        break;
      case 'import-cases':
        SFX.pick();
        importCasesJson();
        break;
      case 'reset-default-cases':
        SFX.pick();
        resetDefaultCases();
        break;
      case 'reset-default-cases-confirm':
        BEDS = ccuBeds;
        save(CUSTOM_BEDS_KEY, null);
        closeModal();
        renderCaseManager();
        toast('คืนค่าเคสมาตรฐาน CCU เรียบร้อย 🔄');
        break;
      case 'randomize-shifts':
        generateMonthSchedule(ui.calYear, ui.calMonth);
        SFX.pick();
        renderRoster();
        toast('สุ่มเวรใหม่ประจำเดือนแล้ว 🎲');
        break;
      case 'open-bed': SFX.pick(); openBed(+node.dataset.i); break;
      case 'play-next': SFX.pick(); openBed(nextTarget()); break;
      case 'toggle-sound': settings.sound = !settings.sound; save(SET_KEY, settings); renderTop(); SFX.pick(); break;
      case 'toggle-setting': { const k = node.dataset.k; settings[k] = !settings[k]; save(SET_KEY, settings); renderSettings(); renderTop(); SFX.pick(); if (k === 'haptics' && settings.haptics) haptic(20); break; }
      case 'reset-all': confirmDialog('ล้างความก้าวหน้าทั้งหมด?', 'ดาวและเตียงที่ผ่านแล้วจะหายไป ย้อนกลับไม่ได้', 'ล้างข้อมูล', 'reset-confirm'); break;
      case 'reset-confirm':
        progress = {};
        rosterDaysProgress = {};
        playerStats = { totalCompletedCases: 0, totalPlaySeconds: 0, perfectCases: 0, shiftsCompleted: 0 };
        save(SAVE_KEY, progress);
        save(ROSTER_PROGRESS_KEY, rosterDaysProgress);
        save(STATS_KEY, playerStats);
        closeModal();
        renderTabs();
        toast('ล้างความก้าวหน้าแล้ว');
        break;
      case 'modal-close': closeModal(); break;
      case 'exit-game': if (G.done.size === 0 && G.mistakes === 0) { renderTabs(); } else confirmDialog('ออกจากเคสนี้?', 'ความคืบหน้าในเคสนี้จะหายไป ต้องเริ่มใหม่ตั้งแต่ขั้นแรก', 'ออกจากเคส', 'exit-confirm'); break;
      case 'exit-confirm': closeModal(); renderTabs(); break;
      case 'toggle-opt': { const id = node.dataset.id; const S = G.S; S.wrongOpts.clear(); if (S.sel.has(id)) S.sel.delete(id); else S.sel.add(id); SFX.pick(); renderTask(); break; }
      case 'reset-step': if (!G.S.locked) { G.S = buildState(curStep()); renderTask(); SFX.pick(); } break;
      case 'check': checkStep(); break;
      case 'step-prev':
        if (G.stepIdx > 0) {
          SFX.pick();
          loadStep(G.stepIdx - 1);
        }
        break;
      case 'step-next':
        if (G.done.has(curStep().id) && G.stepIdx < curBed().stageData.length - 1) {
          SFX.pick();
          loadStep(G.stepIdx + 1);
        }
        break;
      case 'step-skip':
        closeSheet();
        G.done.add(curStep().id);
        SFX.ok();
        nextStep();
        break;
      case 'sheet-next': nextStep(); break;
      case 'sheet-retry': closeSheet(); break;
      case 'win-ward': closeModal(); renderTabs(); break;
      case 'win-next': { const n = nextTarget(); closeModal(); openBed(n); break; }
      case 'win-replay': { const i = G.bedIdx; closeModal(); openBed(i); break; }
      default:
        if (name && name.startsWith('delete-case-confirm-')) {
          const idx = parseInt(name.replace('delete-case-confirm-', ''), 10);
          BEDS.splice(idx, 1);
          // ปรับหมายเลขเตียงให้เรียงลำดับใหม่
          BEDS.forEach((b, k) => {
            b.bedNum = k + 1;
            b.bedCode = `เตียง ${String(k + 1).padStart(2, '0')} CCU`;
          });
          save(CUSTOM_BEDS_KEY, BEDS);
          closeModal();
          renderCaseManager();
          toast('ลบเคสเรียบร้อยแล้ว 🗑️');
        }
        break;
    }
  }

  document.addEventListener('click', (e) => {
    const a = e.target.closest('[data-act]');
    if (a) { act(a.dataset.act, a); return; }
    // tap-to-place: a picked chip + tap on a tray / pool zone
    if (ui.screen === 'game' && G && G.S && G.S.picked && !e.target.closest('[data-chip]')) {
      const zone = e.target.closest('#task [data-drop]');
      if (zone) {
        const dest = zone.dataset.drop;
        if (dest === 'pool') { G.S.picked = null; } else { moveItem(G.S.picked, dest); SFX.drop(); }
        renderTask();
      }
    }
  });
  el.modal.addEventListener('click', (e) => { if (e.target === el.modal && !el.modal.querySelector('.win-ribbon')) closeModal(); });

  renderTabs();
})();
