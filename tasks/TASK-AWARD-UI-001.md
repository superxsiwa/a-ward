# 📋 SuperXDev Task Specification (Updated: Navigation & Mercy Rule)
**Task ID:** `TASK-AWARD-UI-001`  
**Title:** เพิ่มชุดปุ่มควบคุมการนำทางในหน้าหัตถการ 6 ขั้นตอน พร้อมระบบช่วยเหลือเมื่อตอบผิดเกิน 3 ครั้ง  
**Target Project:** `a-ward` (Prototype)  
**Assignee:** ก้อง & สน (Dev Pair)  
**Architecture Reference:** State Machine, UX State Preservation, Mercy / Assist Pattern  
**Status:** Completed & Fully Implemented  

---

## 🎯 1. วัตถุประสงค์ (Goal)
ปรับปรุงเงื่อนไขการแสดงผลปุ่มควบคุมในแถบควบคุมด้านล่าง (`.game-dock`) และกลไกการจำลองขั้นตอนหัตถการ CCU ให้สมบูรณ์แบบตาม UX ที่ถูกต้อง:
1. **ขั้นตอนที่ 1 (`isFirstStep`)**: **ไม่มีปุ่ม "ย้อนกลับ"**
2. **ขั้นตอนที่ยังไม่ส่งตรวจคำตอบ / ยังไม่ผ่าน (`!isPassed`)**: **แสดงปุ่ม "ตรวจคำตอบ"** และ **ไม่มีปุ่ม "ไปต่อ"**
3. **ขั้นตอนที่ 1 ถึง 5 เมื่อตรวจผ่านแล้ว (`isPassed && !isLastStep`)**: สลับมาแสดงปุ่ม **"ไปต่อ ▶"** ทันที
4. **ขั้นตอนสุดท้าย (ขั้นที่ 6) (`isLastStep`)**: **ไม่มีปุ่ม "ไปต่อ"** (เมื่อตรวจผ่านจะเข้าสู่หน้าต่างสรุปผลเคสทันที)
5. **State Preservation (จำสถานะคำตอบ)**: เมื่อกดย้อนกลับไปดูขั้นตอนก่อนหน้า ข้อมูลตัวเลือกหรือการ์ดในถาดที่เคยทำไว้ต้องยังอยู่ และหากขั้นนั้นเคยตรวจผ่านแล้ว สามารถกด "ไปต่อ" กลับมาได้ทันที
6. **ปุ่มจัดใหม่ (Undo ↺)**: หากขั้นตอนนี้ตรวจผ่านแล้ว ให้ `disabled` ปุ่มจัดใหม่ เพื่อป้องกันการเผลอรีเซ็ตคำตอบที่ถูกต้องแล้ว
7. **ระบบช่วยเหลือตอบผิดเกิน 3 ครั้ง (Mercy Rule / 3-Strike Skip)**: หากในขั้นตอนใดตอบผิดครบ 3 ครั้ง ระบบจะปลดล็อกปุ่ม **"💡 ดูเฉลย & ไปต่อ"** ใน Sheet และปุ่ม **"ข้ามไปต่อ ▶"** ใน Dock เพื่อไม่ให้ผู้เล่นติดหล่ม

---

## 📦 2. ขอบเขตไฟล์ที่ต้องแก้ไข (Scope of Work)

| File | Changes Required |
|---|---|
| `prototype/index.html` | เพิ่ม SVG Symbol `ic-forward` สำหรับปุ่มไปต่อ |
| `prototype/game.js` | ปรับฟังก์ชัน `renderDock()`, จัดการแคช State ใน `G.stepStates`, ตัวนับ `G.stepMistakes`, และ Action Handlers |
| `prototype/style.css` | สไตล์ CSS ของ `.game-dock` และปุ่มนำทาง `.btn-nav` |

---

## 🛠️ 3. ข้อกำหนดทางเทคนิค (Technical Instructions)

### Task 3.1: เพิ่ม SVG Icon (`prototype/index.html`)
* ภายใน `<svg ...>` sprite ด้านบน เพิ่ม:
```html
<symbol id="ic-forward" viewBox="0 0 24 24"><path d="m9 18 6-6-6-6"/></symbol>
```

---

### Task 3.2: State Preservation, Navigation & Mercy Rule (`prototype/game.js`)

#### 1) เพิ่มตัวแปรเก็บสถานะใน `openBed(i)`:
```javascript
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
```

#### 2) บันทึกและดึงสถานะเดิมใน `loadStep(idx)`:
```javascript
function loadStep(idx) {
  if (G.S && curStep()) {
    G.stepStates[curStep().id] = G.S;
  }
  G.stepIdx = idx;
  const stId = curStep().id;
  G.S = G.stepStates[stId] || buildState(curStep());
  closeSheet();
  renderGame();
  renderDock();
  el.view.scrollTop = 0;
}
```

#### 3) ปรับปรุง `renderDock()` ให้รองรับเงื่อนไขสมบูรณ์:
```javascript
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
        <!-- 1. ปุ่มย้อนกลับ: มีเฉพาะเมื่อไม่ใช่ขั้นที่ 1 -->
        ${!isFirstStep ? `
          <button class="btn btn-ghost btn-nav" data-act="step-prev" aria-label="ย้อนกลับ">
            ${icon('back')}<span>ย้อนกลับ</span>
          </button>
        ` : ''}

        <!-- 2. ปุ่มตรงกลาง -->
        ${!isPassed ? (
          canSkip ? `
            <button class="btn btn-block btn-gold" data-act="step-skip" aria-label="ข้ามไปต่อ">
              <span>ข้ามไปต่อ</span>${icon('forward')}
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

        <!-- 3. ปุ่มจัดใหม่ (Undo): Disabled เมื่อผ่านแล้ว -->
        <button class="btn btn-ghost btn-sq" data-act="reset-step" ${isPassed ? 'disabled' : ''} aria-label="จัดใหม่">
          ${icon('undo')}
        </button>
      </div>
    `;
  }
}
```

#### 4) ระบบนับจำนวนครั้งที่ผิดใน `checkStep()`:
เมื่อตรวจคำตอบไม่ผ่าน:
```javascript
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
```

#### 5) Actions ใน `act()`:
```javascript
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
```

---

## ✅ 4. เกณฑ์การตรวจรับงาน (Acceptance Criteria)
1. **[AC-01]** ขั้นที่ 1: **ต้องไม่ปรากฏ** ปุ่มย้อนกลับ
2. **[AC-02]** ขั้นตอนที่ยังไม่ผ่านและผิดไม่ถึง 3 ครั้ง: **ปรากฏเฉพาะปุ่ม "ตรวจคำตอบ"** (ไม่มีปุ่มไปต่อ)
3. **[AC-03]** ขั้นที่ 1 ถึง 5 เมื่อตรวจผ่านแล้ว: สลับปุ่มตรงกลางเป็น **"ไปต่อ ▶"** ทันที
4. **[AC-04]** ขั้นที่ 6 เมื่อตรวจผ่าน: **ไม่มีปุ่มไปต่อ** (เปิด Modal สรุปผลเคสทันที)
5. **[AC-05]** กดย้อนกลับไปขั้นตอนก่อนหน้า: ตัวเลือก/การ์ดที่เคยจัดวางไว้ต้อง **คงอยู่ครบถ้วน** ไม่ถูกรีเซ็ต
6. **[AC-06]** ในขั้นตอนที่ตรวจผ่านแล้ว: ปุ่มจัดใหม่ (Undo ↺) ต้องเป็นสถานะ `disabled`
7. **[AC-07]** เมื่อตอบผิดครบ 3 ครั้งในขั้นตอนใด: จะปรากฏปุ่ม **"💡 ดูเฉลย & ไปต่อ"** ให้สามารถกดข้ามไปขั้นตอนถัดไปได้ทันที
