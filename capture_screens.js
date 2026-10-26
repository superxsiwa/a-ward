const puppeteer = require('puppeteer-core');
const path = require('path');
const fs = require('fs');

const OUTPUT_DIR = path.join(__dirname, 'screen', 'mobi');
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

async function captureScreen(page, filename, options = {}) {
  // Ensure styles allow full content display
  await page.evaluate(() => {
    document.documentElement.style.height = 'auto';
    document.body.style.height = 'auto';
    document.body.style.overflow = 'visible';
    const app = document.querySelector('#app');
    if (app) {
      app.style.height = 'auto';
      app.style.minHeight = 'auto';
      app.style.overflow = 'visible';
    }
    const view = document.querySelector('#view');
    if (view) {
      view.style.height = 'auto';
      view.style.overflow = 'visible';
    }
  });

  // Short delay for render
  await new Promise(r => setTimeout(r, options.delay || 350));

  const filePath = path.join(OUTPUT_DIR, filename);
  await page.screenshot({ path: filePath, fullPage: true });
  console.log(`Saved: ${filename}`);
}

(async () => {
  const browser = await puppeteer.launch({
    executablePath: '/usr/bin/google-chrome',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  });

  const page = await browser.newPage();
  // iPhone 14 / modern mobile viewport (390 x 844, scale 2)
  await page.setViewport({ width: 390, height: 844, isMobile: true, hasTouch: true, deviceScaleFactor: 2 });

  await page.goto('http://localhost:3030/prototype/', { waitUntil: 'networkidle0' });
  await page.waitForSelector('#view');

  async function clickAct(actName, extraSelector = '') {
    await page.evaluate((act, sel) => {
      const el = sel ? document.querySelector(sel) : document.querySelector(`[data-act="${act}"]`);
      if (el) el.click();
    }, actName, extraSelector);
    await new Promise(r => setTimeout(r, 400));
  }

  console.log('--- Capturing Main Navigation Tabs ---');

  // 1. Roster tab
  await captureScreen(page, '01_tab_roster.png');

  // 2. Ward tab
  await clickAct('tab', '[data-tab="ward"]');
  await captureScreen(page, '02_tab_ward_all.png');

  // Filter morning shift
  await page.evaluate(() => {
    const morningBtn = document.querySelector('.shift-chip.s-morning') || document.querySelector('[data-shift="morning"]');
    if (morningBtn) morningBtn.click();
  });
  await new Promise(r => setTimeout(r, 400));
  await captureScreen(page, '02b_tab_ward_filter_morning.png');

  // Reset filter back to all
  await clickAct('clear-filter');

  // 3. Progress tab (Milestones)
  await clickAct('tab', '[data-tab="progress"]');
  await captureScreen(page, '03_tab_progress_milestones.png');

  // 4. Cases tab (Case Manager)
  await page.evaluate(() => {
    // Open settings tab first, then click open case manager
    document.querySelector('[data-tab="settings"]').click();
  });
  await new Promise(r => setTimeout(r, 400));
  await page.evaluate(() => {
    const btn = document.querySelector('[data-act="open-case-mgmt"]');
    if (btn) btn.click();
  });
  await new Promise(r => setTimeout(r, 400));
  await captureScreen(page, '04_tab_case_manager.png');

  // 5. Settings tab
  await clickAct('tab', '[data-tab="settings"]');
  await captureScreen(page, '05_tab_settings.png');

  console.log('--- Capturing Modals & Editors ---');

  // 6. Case Editor (Create New Case modal)
  await page.evaluate(() => {
    const btn = document.querySelector('[data-act="open-case-mgmt"]');
    if (btn) btn.click();
  });
  await new Promise(r => setTimeout(r, 400));
  await clickAct('create-new-case');
  await captureScreen(page, '06_modal_case_editor_create.png');
  await clickAct('modal-close');

  // 7. Case Editor (Edit Case 1)
  await page.evaluate(() => {
    const editBtn = document.querySelector('[data-act="edit-case"]');
    if (editBtn) editBtn.click();
  });
  await new Promise(r => setTimeout(r, 400));
  await captureScreen(page, '07_modal_case_editor_edit_bed1.png');
  await clickAct('modal-close');

  // 8. Step Manager (Manage Steps for Case 1)
  await page.evaluate(() => {
    const mgmtBtn = document.querySelector('[data-act="manage-steps"]');
    if (mgmtBtn) mgmtBtn.click();
  });
  await new Promise(r => setTimeout(r, 400));
  await captureScreen(page, '08_modal_step_manager_step1.png');

  // Step 2 in step manager
  await page.evaluate(() => {
    const step2Tab = document.querySelectorAll('.step-tabs .tab-chip')[1];
    if (step2Tab) step2Tab.click();
  });
  await new Promise(r => setTimeout(r, 400));
  await captureScreen(page, '08b_modal_step_manager_step2_trays.png');
  await clickAct('modal-close');

  console.log('--- Capturing In-Game Procedure Steps (Bed 1) ---');

  // Open Bed 1
  await clickAct('tab', '[data-tab="ward"]');
  await page.evaluate(() => {
    const bed1 = document.querySelector('[data-act="open-bed"][data-i="0"]');
    if (bed1) bed1.click();
  });
  await new Promise(r => setTimeout(r, 500));

  // Game Step 1: Multiple choice
  await captureScreen(page, '09_game_step1_choices.png');

  // Pass Step 1 to show sheet feedback
  await page.evaluate(() => {
    const opts = document.querySelectorAll('.opt');
    if (opts.length >= 3) {
      opts[0].click();
      opts[1].click();
      opts[2].click();
    }
    const checkBtn = document.querySelector('[data-act="check"]');
    if (checkBtn) checkBtn.click();
  });
  await new Promise(r => setTimeout(r, 500));
  await captureScreen(page, '10_game_step1_passed_sheet.png');

  // Go to Step 2
  await page.evaluate(() => {
    const nextBtn = document.querySelector('[data-act="sheet-next"]') || document.querySelector('[data-act="step-next"]');
    if (nextBtn) nextBtn.click();
  });
  await new Promise(r => setTimeout(r, 500));

  // Game Step 2: Equipment Tray with 20s Countdown Timer
  await captureScreen(page, '11_game_step2_trays_timer.png');

  // Trigger timeout sheet
  console.log('Simulating timeout for Step 2...');
  await page.evaluate(() => {
    if (window.__AWARD && window.__AWARD.handleStepTimeout) {
      window.__AWARD.handleStepTimeout();
    }
  });
  await new Promise(r => setTimeout(r, 500));
  await captureScreen(page, '12_game_step2_timeout_sheet.png');

  // Trigger retry
  await clickAct('sheet-retry');
  await new Promise(r => setTimeout(r, 400));

  // Trigger Mercy Rule (skip option after 3 mistakes)
  console.log('Simulating Mercy Rule for Step 2...');
  await page.evaluate(() => {
    const A = window.__AWARD;
    const stId = A.curStep().id;
    A.G.stepMistakes[stId] = 3;
    A.handleStepTimeout();
  });
  await new Promise(r => setTimeout(r, 500));
  await captureScreen(page, '13_game_step2_mercy_rule_sheet.png');

  // Skip to Step 3
  await clickAct('step-skip');
  await new Promise(r => setTimeout(r, 500));

  // Game Step 3: Sequence Task
  await captureScreen(page, '14_game_step3_sequence.png');

  // Step 4
  await page.evaluate(() => {
    const A = window.__AWARD;
    A.G.done.add(A.curStep().id);
    A.loadStep(3);
  });
  await new Promise(r => setTimeout(r, 500));
  await captureScreen(page, '15_game_step4_nursing_actions.png');

  // Step 5
  await page.evaluate(() => {
    const A = window.__AWARD;
    A.G.done.add(A.curStep().id);
    A.loadStep(4);
  });
  await new Promise(r => setTimeout(r, 500));
  await captureScreen(page, '16_game_step5_assessment.png');

  // Step 6
  await page.evaluate(() => {
    const A = window.__AWARD;
    A.G.done.add(A.curStep().id);
    A.loadStep(5);
  });
  await new Promise(r => setTimeout(r, 500));
  await captureScreen(page, '17_game_step6_documentation.png');

  // Case Completion Victory Modal
  console.log('Capturing Case Victory Modal...');
  await page.evaluate(() => {
    const A = window.__AWARD;
    A.G.done.add(A.curStep().id);
    A.finishCase();
  });
  await new Promise(r => setTimeout(r, 600));
  await captureScreen(page, '18_modal_case_completed_victory.png');

  console.log('--- ALL SCREENSHOTS COMPLETED SUCCESSFULLY! ---');
  await browser.close();
})();

