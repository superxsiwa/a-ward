# 🩺 A-WARD: CCU Nursing Clinical Decision & Simulation Game

เกมมือถือจำลองสถานการณ์ทางคลินิก (Mobile-First Clinical Decision Game) สำหรับฝึกทักษะการตัดสินใจ การประเมินสัญญาณชีพ และการปฏิบัติการพยาบาลผู้ป่วยวิกฤต CCU (Coronary Care Unit) ตามลำดับขั้นตอนการทำงานจริง

---

## 🌟 ฟีเจอร์หลักในเกม (Core Features)

1. **🏥 Realistic CCU Patient Monitor:**
   - มอนิเตอร์จำลองแบบ Real-time: HR, NIBP, MAP, SpO2 พร้อมแอนิเมชันคลื่นไฟฟ้าหัวใจ (EKG Lead II Rhythm)
   - ป้ายสถานะคนไข้เปลี่ยนตามผลการตัดสินใจ (`🟢 คงตัว`, `⚠️ เฝ้าระวัง`, `🚨 วิกฤต`)

2. **📋 เคสจำลองการทำงานตามขั้นตอนจริง (Step-by-Step Flow):**
   - **ขั้นที่ 1: รับเวร & ตรวจประเมินแรกรับ (Initial Assessment):** ตรวจ Neurovascular sign, Femoral Sheath, ข้อห้ามการงอขาหนีบ
   - **ขั้นที่ 2: สัญญาณเตือนวิกฤต (Clinical Deterioration):** ภาวะแทรกซ้อนคลาสสิก Retroperitoneal Hemorrhage (ปวดหลังรุนแรง + BP Drop)
   - **ขั้นที่ 3: การปฏิบัติการพยาบาล & บริหารยา (Intervention & Drug Titration):** ข้อควรระวังการให้ยา Levophed ทาง Central Line และ Titrate รักษา MAP > 65
   - **ขั้นที่ 4: การติดตามผลแล็บ & ยาต้านการแข็งตัวของเลือด (Lab & Heparin Monitoring):** ภาวะเลือดไม่แข็งตัวเมื่อ aPTT > 140s ร่วมกับ Active Bleed และการตัดสินใจ Hold ยา
   - **ขั้นที่ 5: การส่งเวรอย่างปลอดภัย (ISBAR Clinical Handover):** ส่งเวรเคสวิกฤตตามหลัก ISBAR อย่างปลอดภัยครบถ้วน

3. **🛡️ Patient Safety Score & EXP System:**
   - คะแนนความปลอดภัยคนไข้เริ่มต้น 100% (หากตัดสินใจผิด คนไข้เกิดความเสี่ยง คะแนนจะลดลง)
   - สะสมค่าประสบการณ์ (EXP) เมื่อตัดสินใจถูกต้องตามหลักวิชาชีพ
   - สรุปผลประเมินเมื่อจบเคส พร้อมคำอธิบายเชิงคลินิก (Clinical Rationale) ให้พยาบาลได้เรียนรู้ทุกข้อ

---

## 🚀 วิธีการรันโปรเจกต์ (Quick Start)

```bash
cd /home/superx-desktop/Documents/0_app_projects/a-ward
npm start
# หรือ node server.js
```

เปิด Browser ไปที่: **`http://localhost:3030`** (สามารถเปิดด้วยมือถือ หรือเปิด DevTools โหมด Mobile ในเบราว์เซอร์)
