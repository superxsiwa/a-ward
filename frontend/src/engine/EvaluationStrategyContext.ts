import { StageData, StepRuntimeState } from '../types/game';

export interface EvaluationResult {
  incompleteMsg?: string;
  passed: boolean;
  errorMessages: string[];
  wrongItemIds: Set<string>;
  wrongOptionIds: Set<string>;
}

export const cleanTray = (s: string) => s.replace(/^[🟩🟦]\s*/u, '');

export class EvaluationStrategyContext {
  public evaluateStep(step: StageData, S: StepRuntimeState): EvaluationResult {
    const inc: string[] = [];
    if (step.choices1toN && S.sel.size === 0) inc.push('เลือกตัวเลือกอย่างน้อย 1 ข้อ');
    if (S.seq && S.seq.includes(null)) inc.push('วางการ์ดให้ครบทุกช่อง');
    if (S.trays && S.pool.length > 0) inc.push('หยิบอุปกรณ์ลงถาดให้ครบทุกชิ้น');
    if (S.unordered && step.unorderedDropTask && S.unordered.length < step.unorderedDropTask.expectedIds.length) {
      inc.push(`เลือกให้ครบ ${step.unorderedDropTask.expectedIds.length} ข้อ`);
    }

    if (inc.length > 0) {
      return {
        incompleteMsg: 'ยังไม่ครบ: ' + inc[0],
        passed: false,
        errorMessages: [],
        wrongItemIds: new Set(),
        wrongOptionIds: new Set(),
      };
    }

    const wrong = new Set<string>();
    const wrongOpts = new Set<string>();
    const msgs: string[] = [];

    // 1. Choices Strategy
    if (step.choices1toN) {
      const opts = step.choices1toN.options;
      const correct = opts.filter((o) => o.correct).map((o) => o.id);
      opts.forEach((o) => {
        if (S.sel.has(o.id) && !o.correct) wrongOpts.add(o.id);
      });
      const missing = correct.some((id) => !S.sel.has(id));
      if (wrongOpts.size > 0) msgs.push('มีข้อที่ไม่ควรเลือกอยู่ (ข้อสีแดง)');
      else if (missing) msgs.push('ยังเลือกไม่ครบทุกข้อที่ต้องตรวจสอบ');
    }

    // 2. Sequence Order Strategy
    if (step.sequenceTask && S.seq) {
      const exp = step.sequenceTask.correctOrder;
      let bad = false;
      S.seq.forEach((id, i) => {
        if (id !== exp[i]) {
          if (id) wrong.add(id);
          bad = true;
        }
      });
      if (bad) msgs.push('ลำดับบางข้อยังไม่ถูกต้อง (การ์ดสีแดงอยู่ผิดตำแหน่ง)');
    }

    // 3. Multi-Tray Sorting Strategy
    if (step.traysTask && S.trays) {
      const t = step.traysTask;
      t.trays.forEach((tr) => {
        const arr = S.trays![tr.id] || [];
        let bad = false;
        if (t.ordered && tr.expectedOrder) {
          arr.forEach((id, i) => {
            if (id !== tr.expectedOrder![i]) {
              wrong.add(id);
              bad = true;
            }
          });
        } else if (tr.expectedIds) {
          arr.forEach((id) => {
            if (!tr.expectedIds!.includes(id)) {
              wrong.add(id);
              bad = true;
            }
          });
        }
        const need = (t.ordered ? tr.expectedOrder : tr.expectedIds)?.length || 0;
        if (!bad && arr.length !== need) bad = true;
        if (bad) {
          msgs.push(
            t.ordered
              ? `ลำดับใน “${cleanTray(tr.name)}” ยังไม่ถูกต้อง`
              : `ใน “${cleanTray(tr.name)}” มีอุปกรณ์อยู่ผิดถาด`
          );
        }
      });
    }

    // 4. Unordered Safe Action Strategy
    if (step.unorderedDropTask && S.unordered) {
      const exp = step.unorderedDropTask.expectedIds;
      let bad = false;
      S.unordered.forEach((id) => {
        if (!exp.includes(id)) {
          wrong.add(id);
          bad = true;
        }
      });
      if (!bad && (S.unordered.length !== exp.length || exp.some((id) => !S.unordered!.includes(id)))) {
        bad = true;
      }
      if (bad) msgs.push('มีการพยาบาลที่ไม่ปลอดภัยปนอยู่ (การ์ดสีแดง) ลองเอาออกแล้วเลือกใหม่');
    }

    return {
      passed: msgs.length === 0,
      errorMessages: msgs,
      wrongItemIds: wrong,
      wrongOptionIds: wrongOpts,
    };
  }

  /**
   * Populates the exact correct clinical answer into `S` (used by 3-Strike Mercy Rule "💡 ดูเฉลย & ไปต่อ")
   */
  public populateCorrectSolution(step: StageData, S: StepRuntimeState): StepRuntimeState {
    const next: StepRuntimeState = {
      ...S,
      pool: [],
      wrong: new Set(),
      wrongOpts: new Set(),
      picked: null,
      locked: true,
    };

    if (step.choices1toN) {
      next.sel = new Set(step.choices1toN.options.filter((o) => o.correct).map((o) => o.id));
    }
    if (step.sequenceTask) {
      next.seq = [...step.sequenceTask.correctOrder];
      next.pool = [];
    }
    if (step.traysTask) {
      const traysMap: Record<string, string[]> = {};
      step.traysTask.trays.forEach((tr) => {
        traysMap[tr.id] = step.traysTask!.ordered
          ? [...(tr.expectedOrder || [])]
          : [...(tr.expectedIds || [])];
      });
      next.trays = traysMap;
      next.pool = [];
    }
    if (step.unorderedDropTask) {
      const expected = [...step.unorderedDropTask.expectedIds];
      next.unordered = expected;
      next.pool = step.unorderedDropTask.pool
        .map((p) => p.id)
        .filter((id) => !expected.includes(id));
    }

    return next;
  }
}

export const evaluator = new EvaluationStrategyContext();
