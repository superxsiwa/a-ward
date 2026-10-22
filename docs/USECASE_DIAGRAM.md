# แผนภาพยูสเคส (Use Case Diagram)
## โครงการ: A-WARD CCU (CCU Nursing Simulation Game)

---

### 1. คำอธิบายภาพรวม (Overview)
แผนภาพ Use Case Diagram นี้แสดงความสัมพันธ์ระหว่าง Actor (พยาบาลผู้เล่น / พยาบาลประจำเวร CCU) และระบบ A-WARD CCU ครอบคลุมการเข้าดูตารางเวรประจำเดือน การขึ้นเวร การเข้าดูแลผู้ป่วยในวอร์ด 8 เตียง การทำหัตถการ 6 ขั้นตอน และการติดตามเป้าหมาย Milestones สะสมดาว

---

### 2. แผนภาพ Use Case Diagram (Mermaid)

```mermaid
flowchart LR
    %% Actors
    Nurse["👩‍⚕️ พยาบาลผู้เล่น / พยาบาล CCU<br>(Nurse Player)"]
    
    subgraph A_WARD_System ["🏥 ระบบเกมจำลอง A-WARD CCU (System Boundary)"]
        %% Module 1: Shift Roster
        UC1(["UC-01: ดูปฏิทินตารางเวรประจำเดือน<br>(View Monthly Shift Roster)"])
        UC2(["UC-02: สุ่มเวรประจำเดือนใหม่<br>(Randomize Shifts)"])
        UC3(["UC-03: ตรวจสอบเวรที่เข้าเล่นได้<br>(Check Playable Shift Status)"])
        UC4(["UC-04: เข้าประจำการในวอร์ดตามเวร<br>(Enter Ward via Shift Assignment)"])

        %% Module 2: CCU Ward
        UC5(["UC-05: ตรวจเยี่ยมคนไข้ 8 เตียง CCU<br>(Inspect 8-Bed CCU Patients & Vitals)"])
        UC6(["UC-06: กรองเตียงตามเวรที่ได้รับมอบหมาย<br>(Filter Beds by Shift)"])
        UC7(["UC-07: เลือกเตียงเพื่อเริ่มทำหัตถการ<br>(Select Bed to Start Procedure)"])

        %% Module 3: 6-Step Clinical Procedure
        UC8(["UC-08: เตรียมความพร้อมผู้ป่วย<br>(Step 1: Patient Preparation 1..N)"])
        UC9(["UC-09: เตรียมอุปกรณ์ลงถาดปลอดเชื้อ<br>(Step 2: Equipment Tray Setup)"])
        UC10(["UC-10: จัดส่งเครื่องมือตามลำดับให้แพทย์<br>(Step 3: Sequential Instrument Handing)"])
        UC11(["UC-11: ปฏิบัติการพยาบาลระหว่างหัตถการ<br>(Step 4: Unordered Clinical Nursing)"])
        UC12(["UC-12: ดูแลและเฝ้าระวังหลังหัตถการ<br>(Step 5: Sequential Post-Procedure Care)"])
        UC13(["UC-13: สรุปผลและส่งเวร ISBAR<br>(Step 6: Sequential ISBAR Handover)"])

        %% Module 4: Feedback & Evaluation
        UC14(["UC-14: ตรวจคำตอบและรับผลสะท้อนทันที<br>(Instant Check & Clinical Feedback)"])
        UC15(["UC-15: รับสรุปคะแนนดาวและเฉลิมฉลอง<br>(Complete Case & Win Star Ribbon)"])

        %% Module 5: Case & Step Management
        UC18(["UC-18: จัดการเพิ่ม ลบ แก้ไขเคสคนไข้<br>(Case CRUD Management)"])
        UC19(["UC-19: จัดการ 6 ขั้นตอน ตัวเลือก และคำตอบ<br>(Step & Answer Builder)"])
        UC20(["UC-20: ส่งออกและนำเข้าข้อมูลเคส JSON<br>(Export & Import Cases JSON)"])

        %% Module 6: Milestones & Settings
        UC16(["UC-16: ติดตามความก้าวหน้าและ 20 Milestones<br>(Track 20 Nursing Goals & Milestones)"])
        UC17(["UC-17: ปรับแต่งเสียงและการสั่น / รีเซ็ตข้อมูล<br>(Configure Audio/Haptics & Reset Progress)"])
    end

    %% Associations
    Nurse --> UC1
    Nurse --> UC2
    Nurse --> UC3
    Nurse --> UC4
    Nurse --> UC5
    Nurse --> UC7
    Nurse --> UC18
    Nurse --> UC16
    Nurse --> UC17

    %% Relationships
    UC18 -.->|<<include>>| UC19
    UC18 -.->|<<include>>| UC20

    %% Relationships
    UC4 -.->|<<include>>| UC6
    UC4 -.->|<<include>>| UC5
    UC7 -.->|<<include>>| UC8
    UC8 -.->|<<include>>| UC14
    UC9 -.->|<<include>>| UC14
    UC10 -.->|<<include>>| UC14
    UC11 -.->|<<include>>| UC14
    UC12 -.->|<<include>>| UC14
    UC13 -.->|<<include>>| UC14
    UC13 -.->|<<include>>| UC15
    UC15 -.->|<<include>>| UC16
```

---

### 3. ตารางสรุปรายละเอียด Use Cases (Use Case Descriptions)

| รหัส Use Case | ชื่อ Use Case | คำอธิบายโดยสังเขป |
|---|---|---|
| **UC-01** | View Monthly Shift Roster | ดูปฏิทินเวรของเดือน แสดงเวรเช้า/บ่าย/ดึก/Off พร้อมสัญลักษณ์ `✓` สำหรับวันที่ผ่านแล้ว |
| **UC-02** | Randomize Shifts | กดปุ่มสุ่มเวรใหม่ประจำเดือน (🎲 สุ่มเวรใหม่) สำหรับวางแผนการขึ้นเวร |
| **UC-03** | Check Playable Shift Status | ตรวจสอบสถานะการเล่นเรียงวัน โดยแสดงสัญลักษณ์ลูกศร `▶` กรอบสีทองที่วันปัจจุบัน และเตือน "ยังเข้าเวรนี้ไม่ได้" หากกดข้ามวัน |
| **UC-04** | Enter Ward via Shift Assignment | กดปุ่มเข้าวอร์ดจากตารางเวรเพื่อไปยังผังวอร์ด CCU |
| **UC-05** | Inspect 8-Bed CCU Patients | ตรวจสัญญาณชีพจำลอง, แอนิเมชัน ECG, ระยะเวลานอน รพ. และสถานะของทั้ง 8 เตียง |
| **UC-06** | Filter Beds by Shift | ไฮไลต์เฉพาะเตียงที่รับผิดชอบในเวรนั้น และหรี่เตียงอื่นเพื่อโฟกัสงาน |
| **UC-07** | Select Bed to Start Procedure | แตะที่เตียงคนไข้เพื่อเปิดหน้าจอทำหัตถการจำลอง |
| **UC-08** | Step 1: Patient Preparation | ตรวจสอบตัวตน 2 Identifiers, ประเมินข้อบ่งชี้ และเซ็นใบยินยอม (เลือก 1 ถึง N ข้อ) |
| **UC-09** | Step 2: Equipment Tray Setup | ลาก-วางอุปกรณ์ลงถาดสี่เหลี่ยม (แยกถาดปลอดเชื้อ / ขยะติดเชื้อ ไม่จำกัดลำดับ) |
| **UC-10** | Step 3: Sequential Instrument Handing | ลาก-วางส่งเครื่องมือให้แพทย์ตามลำดับความปลอดเชื้อที่ถูกต้อง |
| **UC-11** | Step 4: Unordered Clinical Nursing | ลาก-วางการ์ดปฏิบัติการพยาบาลที่ปลอดภัยลงในโซนหัตถการ |
| **UC-12** | Step 5: Sequential Post-Procedure Care | ลาก-วางเรียงลำดับการดูแลหลังหัตถการ การกดแผล และการตรวจภาวะแทรกซ้อน |
| **UC-13** | Step 6: Sequential ISBAR Handover | ลาก-วางเรียงการส่งเวรอย่างปลอดภัยตามโครงสร้าง ISBAR |
| **UC-14** | Instant Check & Clinical Feedback | ตรวจสอบความถูกต้อง แสดงการ์ดสีแดงเมื่อผิด และให้คำอธิบายทางการพยาบาล |
| **UC-15** | Complete Case & Win Star Ribbon | สรุปคะแนน 1-3 ดาว ปลดล็อกวันถัดไปในตารางเวร พร้อมเอฟเฟกต์ Confetti |
| **UC-16** | Track 20 Nursing Goals & Milestones | ตรวจสอบหลอดพลังและสะสมดาวจาก 20 เป้าหมาย (ชั่วโมงบิน, ยอดหัตถการ, ความแม่นยำ) |
| **UC-17** | Configure Settings & Reset | เปิด-ปิดเสียง SFX, ระบบสั่น Haptic หรือล้างข้อมูลความก้าวหน้าทั้งหมด |
| **UC-18** | Case CRUD Management | บริหารจัดการเคสคนไข้ในวอร์ด เพิ่มเคสใหม่ แก้ไขข้อมูลผู้ป่วย และลบเคส |
| **UC-19** | Step & Answer Builder | กำหนดชื่อขั้นตอน โจทย์แพทย์ สรุปความรู้ และจัดการตัวเลือกคำตอบ พร้อมสลับกลไก (Single choice, Checkbox, Trays, Sequence) |
| **UC-20** | Export & Import Cases JSON | สำรองข้อมูลเคสทั้งหมดออกเป็นไฟล์ JSON และนำเข้าไฟล์เคสกลับสู่ระบบ |
