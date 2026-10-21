# แผนภาพยูสเคส (Use Case Diagram)
## โครงการ: A-WARD (CCU Nursing Simulation Game)

---

### 1. คำอธิบายภาพรวม (Overview)
แผนภาพ Use Case Diagram นี้แสดงความสัมพันธ์ระหว่าง Actor (พยาบาลผู้ฝึกอบรม / ผู้เล่น) และระบบ A-WARD ประกอบด้วย Use Case หลักในการเข้าเล่นเกมจำลอง การประเมินสัญญาณชีพ การตัดสินใจในภาวะวิกฤต และการประเมินผลสัมฤทธิ์

---

### 2. แผนภาพ Use Case Diagram (Mermaid)

```mermaid
flowchart LR
    %% Actors
    Nurse["👩‍⚕️ Nurse / Trainee<br>(พยาบาลผู้ฝึกอบรม)"]
    
    subgraph A_WARD_System ["🏥 ระบบเกมจำลอง A-WARD (System Boundary)"]
        UC1(["UC-01: เริ่มจำลองเคสผู้ป่วย CCU<br>(Start/Restart Case)"])
        UC2(["UC-02: ตรวจติดตามสัญญาณชีพจำลอง<br>(Monitor Vital Signs & ECG)"])
        UC3(["UC-03: ประเมินสถานการณ์แรกรับ<br>(Assess Initial STEMI Post-PCI)"])
        UC4(["UC-04: จัดการภาวะวิกฤตแทรกซ้อน<br>(Manage Retroperitoneal Bleed)"])
        UC5(["UC-05: บริหารยาฉุกเฉินและสารน้ำ<br>(Administer Vasoactive Drug - Levophed)"])
        UC6(["UC-06: ปรับการจัดการยาตามผลแล็บ<br>(Manage Heparin & Coagulopathy)"])
        UC7(["UC-07: สื่อสารส่งเวรผู้ป่วยวิกฤต<br>(Execute ISBAR Handover)"])
        UC8(["UC-08: ดูผลสะท้อนและคำอธิบายทางคลินิก<br>(View Clinical Rationale Feedback)"])
        UC9(["UC-09: ดูสรุปคะแนนประเมินสมรรถนะ<br>(View Evaluation & Safety Score)"])
    end

    %% Associations
    Nurse --> UC1
    Nurse --> UC2
    Nurse --> UC3
    Nurse --> UC4
    Nurse --> UC5
    Nurse --> UC6
    Nurse --> UC7
    Nurse --> UC9

    %% Includes & Extends
    UC3 -.->|<<include>>| UC8
    UC4 -.->|<<include>>| UC8
    UC5 -.->|<<include>>| UC8
    UC6 -.->|<<include>>| UC8
    UC7 -.->|<<include>>| UC8
    UC7 -.->|<<include>>| UC9
    UC3 -.->|<<include>>| UC2
    UC4 -.->|<<include>>| UC2
    UC5 -.->|<<include>>| UC2
    UC6 -.->|<<include>>| UC2
    UC7 -.->|<<include>>| UC2
```

---

### 3. ตารางสรุปรายละเอียด Use Cases (Use Case Descriptions)

| รหัส Use Case | ชื่อ Use Case | คำอธิบายโดยสังเขป |
|---|---|---|
| **UC-01** | Start/Restart Case | ผู้เล่นเริ่มต้นรอบจำลองสถานการณ์ใหม่ หรือกดเริ่มเล่นซ้ำเพื่อฝึกฝน |
| **UC-02** | Monitor Vital Signs & ECG | ผู้เล่นสังเกตค่า HR, BP, SpO2, MAP และคลื่นหัวใจเพื่อประกอบการตัดสินใจ |
| **UC-03** | Assess Initial STEMI Post-PCI | เลือกแนวทางตรวจประเมินแรกรับ (Neurovascular check vs ห้ามยกหัวเตียง) |
| **UC-04** | Manage Retroperitoneal Bleed | วินิจฉัยและรับมือภาวะช็อกซ่อนเร้นหลังแทงสายสวนที่ขาหนีบ |
| **UC-05** | Administer Vasoactive Drug | ปฏิบัติการพยาบาลในการให้ Levophed ทาง Central Line และ Titrate รักษา MAP > 65 |
| **UC-06** | Manage Heparin & Coagulopathy | ติดตามผล aPTT และตัดสินใจ Hold ยา พร้อมเตรียม Protamine antidote |
| **UC-07** | Execute ISBAR Handover | เลือกวิธีการส่งเวรต่อตามหลักการสื่อสารปลอดภัย ISBAR |
| **UC-08** | View Clinical Rationale Feedback | ระบบแสดงผลการตัดสินใจ พร้อมคำอธิบายเชิงวิชาการทางการพยาบาล |
| **UC-09** | View Evaluation & Safety Score | ระบบสรุปคะแนนความปลอดภัยผู้ป่วย (Safety Score) และ EXP |
