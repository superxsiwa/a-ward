# แผนภาพลำดับขั้นตอน (Sequence Diagrams)
## โครงการ: A-WARD CCU (CCU Nursing Simulation Game)

---

### 1. คำอธิบายภาพรวม (Overview)
เอกสารนี้แสดงการแลกเปลี่ยนข้อความ (Message Sequences) ระหว่างผู้เล่น (Nurse), หน้าจอแสดงผล (UI View), ตัวควบคุมเกม (GameEngine), แหล่งข้อมูลในเครื่อง (LocalStorage), และระบบเสียงสังเคราะห์ (SFXEngine) ตามหน้าจอจริงของ Prototype

---

### 2. Sequence Diagram 1: การเข้าดูตารางเวรและการตรวจเช็กเวรที่เล่นได้ (Roster Calendar Flow)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse (User)
    participant UI as 📱 Roster View
    participant Engine as ⚙️ GameEngine
    participant Roster as 📅 RosterSchedule
    participant Storage as 💾 LocalStorage
    participant SFX as 🔊 SFXEngine

    Nurse ->> UI: เปิดแอปพลิเคชัน (เริ่มต้นที่แท็บตารางเวร)
    UI ->> Engine: renderRoster()
    Engine ->> Storage: โหลดตารางเวร & วันที่ผ่านแล้ว (rosterDaysProgress)
    Storage -->> Engine: ข้อมูลเวรประจำเดือน
    Engine ->> Roster: getRosterUnlockedDay(year, month)
    Roster -->> Engine: คืนค่า unlockedDay (วันปัจจุบันที่เข้าเวรได้)
    Engine ->> UI: แสดงปฏิทินทั้งเดือน + ไฮไลต์วันที่มีสัญลักษณ์ '▶' สีทอง
    UI -->> Nurse: ผู้เล่นเห็นปฏิทินเวรและเวรวันนี้

    alt กรณีผู้เล่นกดวันที่ยังไม่ถึง (ข้ามวัน)
        Nurse ->> UI: แตะวันที่ในอนาคต (isLocked = true)
        UI ->> Engine: act('select-day', day)
        Engine ->> SFX: bad()
        Engine ->> UI: shake(node) + toast("ยังเข้าเวรนี้ไม่ได้")
        UI -->> Nurse: แสดงข้อความเตือนและสั่นเตือน
    else กรณีผู้เล่นกดวันปัจจุบันที่มี '▶'
        Nurse ->> UI: แตะวันปัจจุบัน
        UI ->> Engine: act('select-day', day)
        Engine ->> SFX: pick()
        Engine ->> UI: แสดงรายละเอียดเวร, หัวหน้าเวร และปุ่ม "เข้าวอร์ดเวรนี้"
    end
```

---

### 3. Sequence Diagram 2: การเข้าสู่วอร์ดและการกรองเตียงตามเวร (Shift to Ward Flow)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse (User)
    participant UI as 📱 UI View
    participant Engine as ⚙️ GameEngine
    participant SFX as 🔊 SFXEngine

    Nurse ->> UI: กดปุ่ม "เข้าวอร์ดเวรนี้" หรือ "เข้าวอร์ดทำหัตถการ ▶"
    UI ->> Engine: act('go-ward-shift', shiftId)
    Engine ->> SFX: pick()
    Engine ->> Engine: กำหนด filterShift = shiftId, tab = 'ward'
    Engine ->> UI: renderWard()
    Note over UI: แสดงแถบ "ประจำการ: [ชื่อเวร]"<br>และไฮไลต์เฉพาะเตียงที่รับผิดชอบ<br>(หรี่เตียงอื่นเป็นสีเทา)
    UI -->> Nurse: ผู้เล่นเห็นเตียงและคนไข้ที่ต้องดูแลในเวร
    Nurse ->> UI: แตะที่เตียงคนไข้ที่ต้องการทำหัตถการ
    UI ->> Engine: openBed(bedIndex)
    Engine ->> UI: โหลดหน้าจอทำหัตถการ 6 ขั้นตอน (loadStep 0)
```

---

### 4. Sequence Diagram 3: การทำหัตถการและจัดถาดอุปกรณ์ (Procedure & Multi-tray Drag & Drop)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse (User)
    participant UI as 📱 Game Screen
    participant Engine as ⚙️ GameEngine
    participant SFX as 🔊 SFXEngine

    Note over UI: ขั้นที่ 2: เตรียมอุปกรณ์ทำหัตถการ (Trays Task)
    Nurse ->> UI: ลากอุปกรณ์ปลอดเชื้อลงใน "ถาดปลอดเชื้อ" (Sterile Tray)
    UI ->> Engine: moveItem(itemId, trayId)
    Engine ->> SFX: drop()
    UI -->> Nurse: ชิปอุปกรณ์ย้ายเข้าไปอยู่ในถาดปลอดเชื้อ

    Nurse ->> UI: กดปุ่ม "ตรวจคำตอบ" (Check)
    UI ->> Engine: checkStep()

    alt มีข้อผิดพลาด (เช่น ใส่ของผิดถาด หรือลำดับผิด)
        Engine ->> Engine: mistakes++
        Engine ->> SFX: bad()
        Engine ->> UI: ไฮไลต์ชิปเป็นสีแดง + แสดง Bottom Sheet สีแดงพร้อมคำแนะนำ
        UI -->> Nurse: ผู้เล่นอ่านข้อผิดพลาดแล้วกด "ลองอีกครั้ง"
    else ถูกต้องครบถ้วนตามหลักความปลอดภัย
        Engine ->> Engine: done.add(step.id), บันทึก stepsWithoutMistake
        Engine ->> SFX: ok()
        Engine ->> UI: แสดง Bottom Sheet สีเขียว "ผ่านขั้นตอนนี้แล้ว" + ปุ่ม "ไปต่อ"
        Nurse ->> UI: กดปุ่ม "ไปต่อ"
        UI ->> Engine: nextStep() -> โหลดขั้นถัดไปจนครบ 6 ขั้น
    end
```

---

### 5. Sequence Diagram 4: สำเร็จเคสและปลดล็อกวันถัดไปในตารางเวร (Case Finish & Shift Clearance)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse (User)
    participant UI as 📱 Modal / View
    participant Engine as ⚙️ GameEngine
    participant Storage as 💾 LocalStorage
    participant SFX as 🔊 SFXEngine

    Note over Engine: ผ่านขั้นตอนที่ 6 (ISBAR Handover) สำเร็จ
    Engine ->> Engine: finishCase()
    Engine ->> Engine: คำนวณดาว (1-3 ดาว) ตามจำนวน mistakes
    Engine ->> Storage: บันทึก progress[bedNum] = { passed: true, stars }
    Engine ->> Storage: อัปเดต playerStats (ยอดหัตถการ, perfect cases)

    opt กรณีทำเคสครบทุกเตียงในเวรประจำวัน
        Engine ->> Storage: บันทึก rosterDaysProgress[dayKey] = { passed: true }
        Note over Engine: ปลดล็อกวันถัดไปในตารางเวร!
    end

    Engine ->> SFX: win() & star() ทีละดวง
    Engine ->> UI: openModal() แสดงริบบิ้นชัยชนะ + ดาวทอง + Confetti
    UI -->> Nurse: ผู้เล่นรับชมสรุปผลสำเร็จและเลื่อนขั้นเลเวลพยาบาล
```

---

### 6. Sequence Diagram 5: การติดตามเป้าหมาย 20 Milestones (Milestones Progress Tracking)

```mermaid
sequenceDiagram
    autonumber
    actor Nurse as 👩‍⚕️ Nurse (User)
    participant UI as 📱 Progress View
    participant Engine as ⚙️ GameEngine
    participant Storage as 💾 LocalStorage

    Nurse ->> UI: แตะแท็บ "ความก้าวหน้า" (Tabbar)
    UI ->> Engine: renderProgress()
    Engine ->> Storage: โหลด playerStats, rosterDaysProgress, progress
    Storage -->> Engine: คืนค่าสถิติทั้งหมด
    Engine ->> Engine: คำนวณเกณฑ์ดาวของ 20 Milestones (Tiers 1..3)
    Engine ->> Engine: คำนวณเปอร์เซ็นต์หลอดพลังของแต่ละเป้าหมาย
    Engine ->> UI: เรนเดอร์การ์ดเป้าหมาย 20 รายการ พร้อมแถบ Progress Bar สีฟ้า-ทอง
    UI -->> Nurse: ผู้เล่นตรวจสอบชั่วโมงบิน CCU และเป้าหมายดาวที่สะสมได้
```
