# แผนภาพลำดับขั้นตอน (Sequence Diagrams) สำหรับแต่ละ Use Case
## โครงการ: A-WARD (CCU Nursing Simulation Game)

เอกสารนี้แสดง Sequence Diagram ในการส่งสาร (Message Exchanges) ระหว่าง Actor, หน้าจอผู้ใช้ (UI View), ตัวจัดการเกม (Game Controller), ตัวจำลองสัญญาณชีพ (Vitals & ECG Monitor), และคลังข้อมูลสถานการณ์ (Case Scenario Engine)

---

### 1. Sequence Diagram: UC-01 (Start / Restart Case)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse (User)
    participant UI as 📱 UI View / App
    participant Game as ⚙️ GameController
    participant CaseData as 📦 ScenarioData
    participant Monitor as 🩺 MonitorEngine

    Nurse ->> UI: เปิดเว็บแอป หรือกดปุ่ม "🔄 เล่นจำลองใหม่อีกครั้ง"
    UI ->> Game: initGame() / restartCase()
    Game ->> Game: รีเซ็ต state (step=0, score=100, exp=0)
    Game ->> CaseData: getStep(0)
    CaseData -->> Game: คืนข้อมูลขั้นตอนที่ 1 พร้อมค่า Vitals แรกรับ
    Game ->> Monitor: initEkgWave() & updateVitals(hr=88, bp="115/72", map=86)
    Monitor -->> UI: เริ่มวาดแอนิเมชัน ECG Lead II & แสดงค่าตัวเลข
    Game ->> UI: renderStep(0) แสดงคำถามชอยส์ A/B/C & บทพูด NPC
    UI -->> Nurse: แสดงหน้าจอขั้นตอนแรกรับ พร้อมมอนิเตอร์สัญญาณชีพ
```

---

### 2. Sequence Diagram: UC-02 (Monitor Vital Signs & Dynamic ECG)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse (User)
    participant UI as 📱 Vitals HUD
    participant Canvas as 📈 ECG Canvas
    participant Loop as ⏱️ Animation Loop (requestAnimationFrame)

    Loop ->> Loop: tick() คำนวณแกน x, y ตามสมการคลื่น EKG
    Loop ->> Canvas: strokeLine(x1, y1, x2, y2)
    Canvas -->> UI: แสดงเส้นคลื่น P-QRS-T เคลื่อนที่แบบ Real-time
    Nurse ->> UI: กวาดสายตาตรวจค่า HR, BP, SpO2, MAP และแถบสถานะผู้ป่วย
```

---

### 3. Sequence Diagram: UC-03 (Assess Initial STEMI Post-PCI)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse
    participant UI as 📱 Choices View
    participant Game as ⚙️ GameController
    participant Feedback as 📋 FeedbackPanel

    Note over Nurse, UI: ขั้นตอนที่ 1/5: รับเวร & ประเมินแรกรับ
    Nurse ->> UI: กดเลือก Choice A ("ตรวจคลำชีพจรหลังเท้า & ตรวจแผล")
    UI ->> Game: makeDecision(choiceIdx=0)
    Game ->> Game: ตรวจสอบ isCorrect (ผล: ถูกต้อง)
    Game ->> Game: safetyScore ไม่ลด (100%), nurseExp += 100
    Game ->> UI: อัปเดตปุ่มเป็นสีเขียว (Correct style) & ปิดการกดชอยส์อื่น
    Game ->> Feedback: renderFeedback(title="ถูกต้องยอดเยี่ยม!", rationale="...")
    Feedback -->> UI: ปรากฏกล่องคำอธิบายเชิงคลินิก + ปุ่ม "ต่อไปยังสถานการณ์ถัดไป ➔"
    UI -->> Nurse: ผู้เล่นอ่าน Clinical Rationale เพื่อเสริมทักษะ
    Nurse ->> UI: กดปุ่ม "ต่อไปยังสถานการณ์ถัดไป ➔"
    UI ->> Game: nextStageStep()
```

---

### 4. Sequence Diagram: UC-04 (Manage Retroperitoneal Bleed Deterioration)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse
    participant UI as 📱 Screen
    participant Game as ⚙️ GameController
    participant Monitor as 🩺 MonitorEngine
    participant Feedback as 📋 FeedbackPanel

    Note over Game, Monitor: เปลี่ยนเข้าสู่ขั้นตอนที่ 2/5 (วิกฤตความดันตก)
    Game ->> Monitor: updateVitals(hr=118, bp="85/50", map=58, "cond-critical")
    Monitor -->> UI: กะพริบแจ้งเตือนสีแดง "🚨 วิกฤต: BP Drop & Tachycardia"
    
    alt กรณีเลือกผิด (เช่น กดชอยส์ A: ให้ยานอนหลับ/พารา)
        Nurse ->> UI: กดเลือก Choice A
        UI ->> Game: makeDecision(choiceIdx=0)
        Game ->> Game: isCorrect=false -> หักคะแนน safetyScore -= 20
        Game ->> UI: ไฮไลต์ปุ่มสีแดง (Wrong) & แสดงชอยส์ที่ถูกต้อง
        Game ->> Feedback: renderFeedback(title="การตัดสินใจผิดพลาด!", rationale="อันตรายถึงชีวิต! ภาวะ Retroperitoneal Bleed...")
        Feedback -->> UI: แสดงคำเตือนระดับวิกฤต
    else กรณีเลือกถูก (กดชอยส์ B: โหลด IV + รายงานแพทย์ด่วน)
        Nurse ->> UI: กดเลือก Choice B
        UI ->> Game: makeDecision(choiceIdx=1)
        Game ->> Game: isCorrect=true -> nurseExp += 100
        Game ->> Feedback: renderFeedback(title="เฉียบขาดมาก!", rationale="ถูกต้อง เลือดออกด้านหลังเยื่อบุช่องท้องต้องรีบตามแพทย์...")
    end
    UI ->> Nurse: แสดงผลลัพธ์และคำอธิบายทางคลินิก
```

---

### 5. Sequence Diagram: UC-05 (Administer Vasoactive Drug - Levophed)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse
    participant UI as 📱 Choices View
    participant Game as ⚙️ GameController
    participant Feedback as 📋 FeedbackPanel

    Note over Nurse, UI: ขั้นตอนที่ 3/5: ข้อควรระวังการบริหารยา Levophed
    Nurse ->> UI: กดเลือก Choice B ("ต่อ Infusion pump ทาง Central Line & วัด BP ซ้ำ")
    UI ->> Game: makeDecision(choiceIdx=1)
    Game ->> Game: ตรวจคำตอบ (ถูกต้อง) -> safetyScore คงที่, nurseExp += 100
    Game ->> Feedback: renderFeedback(title="ถูกต้องตามมาตรฐาน CCU!", rationale="ต้องให้ทาง Central venous catheter เพื่อกัน Tissue Necrosis...")
    Feedback -->> UI: แสดงเหตุผลเชิงเภสัชวิทยาคลินิก
    UI -->> Nurse: ผู้เล่นได้รับองค์ความรู้ด้าน Extravasation & Titration
```

---

### 6. Sequence Diagram: UC-06 (Manage Heparin & Coagulopathy)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse
    participant UI as 📱 Choices View
    participant Game as ⚙️ GameController
    participant Monitor as 🩺 MonitorEngine
    participant Feedback as 📋 FeedbackPanel

    Note over Game, Monitor: ขั้นตอนที่ 4/5: aPTT = 140s & Hct Drop จาก 42% -> 31%
    Game ->> Monitor: updateVitals(hr=96, bp="102/65", map=72, "cond-warning")
    Nurse ->> UI: กดเลือก Choice B ("หยุด Hold Heparin ทันที & เตรียม Protamine sulfate")
    UI ->> Game: makeDecision(choiceIdx=1)
    Game ->> Game: isCorrect=true -> nurseExp += 100
    Game ->> Feedback: renderFeedback(title="ยอดเยี่ยมมาก!", rationale="เมื่อ aPTT เกินเป้าหมายร่วมกับมี Bleed ต้อง Hold ทันที...")
    Feedback -->> UI: ปรากฏ Clinical Rationale
```

---

### 7. Sequence Diagram: UC-07 (Execute ISBAR Handover)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse
    participant UI as 📱 Handover View
    participant Game as ⚙️ GameController
    participant Modal as 🏆 ResultModal

    Note over Nurse, UI: ขั้นตอนที่ 5/5: ส่งเวรบ่ายตามหลัก ISBAR
    Nurse ->> UI: กดเลือก Choice B (ส่งเวรครบทั้ง I-S-B-A-R)
    UI ->> Game: makeDecision(choiceIdx=1)
    Game ->> Game: isCorrect=true -> nurseExp += 100
    Nurse ->> UI: กดปุ่ม "ดูผลการประเมินสรุป ➔"
    UI ->> Game: nextStageStep() (ตรวจพบ currentStepIdx >= totalSteps)
    Game ->> Modal: showEvaluationReport(safetyScore, nurseExp)
    Modal -->> UI: แสดงหน้าต่าง Result Modal (ถ้วยรางวัล, เกรดประเมิน, คะแนนรวม)
    UI -->> Nurse: พยาบาลเห็นผลลัพธ์การฝึกทักษะพร้อมตัวเลือก Replay
```

---

### 8. Sequence Diagram: UC-08 & UC-09 (Clinical Feedback & Evaluation Scoring)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse
    participant Game as ⚙️ GameController
    participant Evaluator as 🧮 ScoreCalculator
    participant Modal as 🏆 ResultModal

    Game ->> Evaluator: computeFinalCompetency(safetyScore, nurseExp)
    Evaluator ->> Evaluator: ตรวจสอบระดับเกรด (เช่น >= 90: พยาบาลชำนาญการ CCU)
    Evaluator -->> Game: คืนค่า Evaluation Grade & Commentary
    Game ->> Modal: populateReport(grade, score, exp, comment)
    Modal -->> Nurse: นำเสนอคะแนนสมรรถนะการปฏิบัติการพยาบาลแบบองค์รวม
```
