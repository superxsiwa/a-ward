# เอกสารข้อกำหนดระบบ (System Requirement Specification - SRS)
## โครงการ: A-WARD (CCU Nursing Clinical Decision & Simulation Game)

---

### 1. บทนำ (Introduction)
#### 1.1 วัตถุประสงค์ (Purpose)
เอกสารนี้จัดทำขึ้นเพื่อระบุข้อกำหนดทางฟังก์ชันการทำงาน (Functional Requirements) และข้อกำหนดด้านคุณภาพ (Non-Functional Requirements) สำหรับระบบ **A-WARD** ซึ่งเป็นเว็บแอปพลิเคชันจำลองสถานการณ์ทางคลินิก (Clinical Simulation Game) เพื่อฝึกฝนทักษะการประเมิน การคิดวิเคราะห์ และการตัดสินใจในภาวะวิกฤตของพยาบาลประจำหอผู้ป่วยวิกฤตหัวใจ (CCU - Coronary Care Unit)

#### 1.2 ขอบเขตของระบบ (System Scope)
- ระบบจำลองสถานการณ์ผู้ป่วยวิกฤตหลอดเลือดหัวใจ (STEMI Post-PCI with Femoral Sheath)
- การแสดงผลสัญญาณชีพแบบไดนามิก (Simulated Vital Signs Monitor) ประกอบด้วย HR, NIBP, SpO2, MAP พร้อมแอนิเมชันคลื่นไฟฟ้าหัวใจ (Dynamic ECG Lead II Waveform)
- สถานการณ์จำลองการตัดสินใจ 5 ลำดับขั้นตามแนวทางปฏิบัติการพยาบาลจริง
- ระบบประเมินผล: Patient Safety Score (คะแนนความปลอดภัยผู้ป่วย), ค่าประสบการณ์ (Nurse EXP) และการให้ผลสะท้อนกลับเชิงคลินิก (Clinical Feedback & Rationales)
- ระบบสรุปผลและรายงานสมรรถนะเมื่อสิ้นสุดเคส

---

### 2. ภาพรวมระบบ (System Overview)
ระบบ A-WARD เป็น Client-side Single Page Application (SPA) ทำงานบนเว็บเบราว์เซอร์ ทั้งบนอุปกรณ์พกพา (Mobile First) และหน้าจอคอมพิวเตอร์ โดยมี Node.js Static Server คอยให้บริการทรัพยากร

---

### 3. ข้อกำหนดเชิงฟังก์ชัน (Functional Requirements: FR)

| รหัสข้อกำหนด | หมวดหมู่ | รายละเอียดข้อกำหนด | ความสำคัญ |
|---|---|---|---|
| **FR-01** | Patient Monitor | ระบบต้องแสดงสัญญาณชีพจำลอง (HR, BP, SpO2, MAP) และป้ายสถานะผู้ป่วย (Stable, Warning, Critical) ให้สอดคล้องกับสถานการณ์ปัจจุบัน | High |
| **FR-02** | ECG Simulation | ระบบต้องวาดแอนิเมชันคลื่นไฟฟ้าหัวใจ (ECG Canvas) แบบต่อเนื่องตามจังหวะชีพจรของผู้ป่วย | Medium |
| **FR-03** | Scenario Flow | ระบบต้องนำเสนอเคสจำลอง 5 ขั้นตอนตามลำดับ (Sequential Progression):<br>1. Initial Assessment (รับเวร/ตรวจแผล)<br>2. Clinical Deterioration (ภาวะวิกฤตแทรกซ้อน)<br>3. Intervention & Medication (การบริหารยา Levophed ทาง Central Line)<br>4. Lab & Monitoring (การจัดการผลเลือดผิดปกติ & Hold Heparin)<br>5. Handover (การส่งเวรอย่างปลอดภัยตามหลัก ISBAR) | High |
| **FR-04** | Clinical Decision | ระบบต้องเปิดให้ผู้เล่นเลือกตัดสินใจในแต่ละสถานการณ์ (Choice A/B/C) โดยไม่สามารถกดย้อนกลับขณะตัดสินใจได้ | High |
| **FR-05** | Instant Feedback | เมื่อผู้ใช้เลือกคำตอบ ระบบต้องแสดงผลทันทีว่าถูกต้องหรือไม่ พร้อมอธิบายเหตุผลทางการพยาบาลเชิงคลินิก (Clinical Rationale) | High |
| **FR-06** | Scoring & EXP | ระบบต้องคำนวณคะแนน Patient Safety Score (เริ่มต้น 100%, หักคะแนนเมื่อผิด) และเพิ่มแต้ม EXP เมื่อตอบถูก | High |
| **FR-07** | Summary & Report | เมื่อจบขั้นตอนที่ 5 ระบบต้องแสดงหน้าต่างผลการประเมินสมรรถนะ (Result Modal) สรุปคะแนนรวม และเกรดสมรรถนะ | Medium |
| **FR-08** | Reset/Replay | ผู้ใช้สามารถเลือกเริ่มทำเคสใหม่ (Restart Simulation) เพื่อฝึกซ้ำได้ตลอดเวลา | Medium |

---

### 4. ข้อกำหนดที่มิใช่เชิงฟังก์ชัน (Non-Functional Requirements: NFR)

| รหัสข้อกำหนด | คุณลักษณะ | รายละเอียดข้อกำหนด |
|---|---|---|
| **NFR-01** | Usability / UI | ออกแบบในรูปแบบ **Mobile-First Container** ขนาด 440px เพื่อให้พยาบาลใช้งานผ่านสมาร์ตโฟนได้สะดวก สีและดีไซน์จำลองจอมอนิเตอร์ CCU สมจริง (Dark Clinical Theme) |
| **NFR-02** | Performance | เวลาตอบสนองต่อการเลือกชอยส์ และการเรนเดอร์ Canvas ECG ต้องมีเฟรมเรตไม่ต่ำกว่า 50-60 FPS |
| **NFR-03** | Reliability | ระบบทำงานเป็น Zero-dependency Vanilla JS Client ทำให้ทำงานได้เสถียร ไม่พึ่งพา Network ภายนอกหลังจากโหลดหน้าเสร็จสมบูรณ์ |
| **NFR-04** | Medical Accuracy | เนื้อหา คำถาม ตัวเลือก และคำอธิบายยึดหลักเกณฑ์ทางคลินิกสากล (AHA / ESC Guidelines และมาตรฐานสภาการพยาบาล) |
