    // =========================================================================
    // รายชื่อ 8 เตียง CCU + เคสหัตถการจำลองสมบูรณ์แบบ
    // =========================================================================
    const ccuBeds = [
      {
        bedNum: 1,
        bedCode: "เตียง 01 CCU",
        patientName: "นายสุรชัย (68 ปี)",
        caseTitle: "ถอดสาย Femoral Sheath ขาหนีบ",
        dxBadge: "STEMI Post-PCI",
        status: "alert",
        statusText: "เฝ้าระวังแผล",
        doctorName: "นพ. ธีรภพ (อายุรแพทย์หัวใจ)",
        doctorAvatar: "👨‍⚕️",
        stageData: getSheathStages()
      },
      {
        bedNum: 2,
        bedCode: "เตียง 02 CCU",
        patientName: "นางสมศรี (64 ปี)",
        caseTitle: "ใส่สายสวนหลอดเลือดดำกลาง (CVC)",
        dxBadge: "Septic Shock BP ตก",
        status: "critical",
        statusText: "วิกฤตความดันตก",
        doctorName: "นพ. กิตติ (แพทย์ CCU)",
        doctorAvatar: "👨‍⚕️",
        stageData: getCvcStages()
      },
      {
        bedNum: 3,
        bedCode: "เตียง 03 CCU",
        patientName: "นายสมชาย (70 ปี)",
        caseTitle: "ใส่ท่อช่วยหายใจฉุกเฉิน (ETT)",
        dxBadge: "Acute Pulmonary Edema",
        status: "critical",
        statusText: "วิกฤต SpO2 84%",
        doctorName: "พญ. อารยา (แพทย์เวร CCU)",
        doctorAvatar: "👩‍⚕️",
        stageData: getIntubationStages()
      },
      {
        bedNum: 4,
        bedCode: "เตียง 04 CCU",
        patientName: "นางปราณี (59 ปี)",
        caseTitle: "ตั้งเครื่องกระตุ้นหัวใจชั่วคราว (TPM)",
        dxBadge: "Complete Heart Block",
        status: "alert",
        statusText: "HR 34 bpm",
        doctorName: "นพ. ธีรภพ (อายุรแพทย์หัวใจ)",
        doctorAvatar: "👨‍⚕️",
        stageData: getTpmStages()
      },
      {
        bedNum: 5,
        bedCode: "เตียง 05 CCU",
        patientName: "นายสมบัติ (62 ปี)",
        caseTitle: "เปิดเส้นให้ยา Levophed ทาง Central Line",
        dxBadge: "Cardiogenic Shock",
        status: "critical",
        statusText: "Titrate ยา MAP>65",
        doctorName: "นพ. กิตติ (แพทย์ CCU)",
        doctorAvatar: "👨‍⚕️",
        stageData: getCvcStages() // Reuse robust CVC/Vasoactive flow
      },
      {
        bedNum: 6,
        bedCode: "เตียง 06 CCU",
        patientName: "นางมาลี (73 ปี)",
        caseTitle: "ดูแลสายสวนระบายเลือดรอบหัวใจ (Pericardial Drain)",
        dxBadge: "Cardiac Tamponade Post-drain",
        status: "stable",
        statusText: "สัญญาณชีพเริ่มคงที่",
        doctorName: "พญ. อารยา (แพทย์เวร CCU)",
        doctorAvatar: "👩‍⚕️",
        stageData: getSheathStages()
      },
      {
        bedNum: 7,
        bedCode: "เตียง 07 CCU",
        patientName: "นายวิชัย (55 ปี)",
        caseTitle: "การทำ Synchronized Cardioversion",
        dxBadge: "Unstable VT with Pulse",
        status: "critical",
        statusText: "HR 178 VT",
        doctorName: "นพ. กิตติ (แพทย์ CCU)",
        doctorAvatar: "👨‍⚕️",
        stageData: getIntubationStages()
      },
      {
        bedNum: 8,
        bedCode: "เตียง 08 CCU",
        patientName: "นางกานดา (67 ปี)",
        caseTitle: "จัดการภาวะเลือดออกหลังช่องท้อง (RP Bleed)",
        dxBadge: "Post Femoral Sheath Bleed",
        status: "alert",
        statusText: "ปวดหลัง BP ดรอป",
        doctorName: "นพ. ธีรภพ (หมอหัวใจ)",
        doctorAvatar: "👨‍⚕️",
        stageData: getSheathStages()
      }
    ];

    // Helper Generator for CVC
    function getCvcStages() {
      return [
        {
          id: 1, name: "1. เตรียมคนไข้", mechanic: "เลือก 1|N + เรียงลำดับ",
          reading: "ผู้ป่วยความดันต่ำ ต้องเช็กใบยินยอม ผลเลือด และจัดท่านอนศีรษะต่ำ 15 องศา (Trendelenburg) หันหน้าซ้ายเพื่อกัน Air Embolism",
          doctorSpeech: "💬 \"พยาบาลจิ๋วช่วยเช็กความพร้อมและเรียงลำดับการจัดท่าให้หมอก่อนน้า\"",
          vitals: { hr: 112, bp: "82/48", spo2: "95%", map: 59 },
          choices1toN: {
            prompt: "1.1 เลือกสิ่งที่ต้องตรวจสอบก่อนแทง CVC (เลือกได้หลายข้อ)",
            options: [
              { id: "c1", text: "ตรวจใบยินยอมทำหัตถการ (Consent)", correct: true },
              { id: "c2", text: "ตรวจผลเลือด Platelet & INR", correct: true },
              { id: "c3", text: "ซักประวัติการแพ้ยาชา Lidocaine", correct: true },
              { id: "c4", text: "งดออกซิเจนและถอดมอนิเตอร์ EKG ออก", correct: false }
            ]
          },
          sequenceTask: {
            prompt: "1.2 เรียงลำดับขั้นตอนเตรียมผู้ป่วย (1 ➔ 4)",
            pool: [
              { id: "s3", text: "จัดท่านอนศีรษะต่ำ 15 องศา (Trendelenburg) หันหน้าไปซ้าย" },
              { id: "s1", text: "ยืนยันตัวตนผู้ป่วย 2 ตัวบ่งชี้ และอธิบายให้คลายกังวล" },
              { id: "s4", text: "เปิดเสื้อบริเวณคอขวา พร้อมติดมอนิเตอร์ EKG / SpO2" },
              { id: "s2", text: "ล้างมือ 7 ขั้นตอน และสวมอุปกรณ์ป้องกัน (PPE)" }
            ],
            correctOrder: ["s1", "s2", "s3", "s4"]
          }
        },
        {
          id: 2, name: "2. เตรียมถาด", mechanic: "จัด 2 ถาด (ไม่เรียงลำดับ)",
          reading: "แยกอุปกรณ์ลงใน 'ถาดปราศจากเชื้อ (Sterile)' และ 'ถาดข้างเตียง (Clean)' เพื่อป้องกันการติดเชื้อในกระแสเลือด",
          doctorSpeech: "💬 \"หยิบอุปกรณ์ใส่ถาดสเตอไรด์ กับ ถาดข้างเตียงให้ถูกหมวดหมู่นะครับ วางชิ้นไหนก่อนก็ได้\"",
          vitals: { hr: 110, bp: "84/50", spo2: "96%", map: 61 },
          traysTask: {
            ordered: false, prompt: "หยิบอุปกรณ์ลงใน 2 ถาดสี่เหลี่ยมให้ถูกต้อง",
            trays: [
              { id: "tr1", name: "🟩 ถาดปราศจากเชื้อ (Sterile Tray)", sterile: true, expectedIds: ["e1", "e2", "e3", "e4"] },
              { id: "tr2", name: "🟦 ถาดอุปกรณ์ข้างเตียง (Non-Sterile Tray)", sterile: false, expectedIds: ["e5", "e6", "e7"] }
            ],
            pool: [
              { id: "e1", text: "สาย CVC", img: "./assets/equipment/iv_bag.png" },
              { id: "e5", text: "ขวดยาชา", img: "./assets/equipment/medicine_bottle.png" },
              { id: "e2", text: "ผ้าเจาะกลาง", img: "./assets/equipment/first_aid_kit.png" },
              { id: "e6", text: "ถุงน้ำเกลือ", img: "./assets/equipment/iv_bag.png" },
              { id: "e3", text: "กรรไกร/คีมคีบ", img: "./assets/equipment/scissors_forceps.png" },
              { id: "e7", text: "เครื่องวัดชีพจร", img: "./assets/equipment/pulse_oximeter.png" },
              { id: "e4", text: "เข็มฉีดยา", img: "./assets/equipment/syringe.png" }
            ]
          }
        },
        {
          id: 3, name: "3. ส่งเครื่องมือ", mechanic: "จัด 2 ถาด (เรียงลำดับ 1-3)",
          reading: "ส่งเครื่องมือให้หมอตามลำดับ: ถาด 1 (เช็ดผิว-ยาชา-แทงนำ) และ ถาด 2 (สอดลวด-ขยายผิว-เย็บยึด)",
          doctorSpeech: "💬 \"หมอสวมชุดกาวน์เสร็จแล้ว ส่งเครื่องมือในถาดแต่ละระยะเรียง 1 ➔ 2 ➔ 3 ให้หมอเลยครับ\"",
          vitals: { hr: 108, bp: "85/52", spo2: "97%", map: 63 },
          traysTask: {
            ordered: true, prompt: "หยิบอุปกรณ์ลงถาดระยะ 1 และ 2 โดย **ต้องเรียงลำดับก่อน-หลัง (1 ➔ 2 ➔ 3)**",
            trays: [
              { id: "dtr1", name: "🟩 ถาดระยะที่ 1: เตรียมผิว & แทงนำ (เรียง 1 ➔ 3)", sterile: true, expectedOrder: ["d1", "d2", "d3"] },
              { id: "dtr2", name: "🟦 ถาดระยะที่ 2: สอดสาย & ยึดตรึง (เรียง 1 ➔ 3)", sterile: false, expectedOrder: ["d4", "d5", "d6"] }
            ],
            pool: [
              { id: "d3", text: "เข็มแทงหลอดเลือด (Introducer Needle) ต่อ Syringe ดูดเลือด" },
              { id: "d1", text: "2% Chlorhexidine เช็ดผิวหนัง + ปูผ้าเจาะกลาง" },
              { id: "d6", text: "ไหม Nylon 3-0 เย็บยึดสาย + ปิดแผล Tegaderm" },
              { id: "d2", text: "ยาชา 1% Lidocaine พร้อมเข็ม 25G ฉีดยาชาเฉพาะที่" },
              { id: "d5", text: "แท่งขยายผิว (Dilator) ตามด้วยสายสวน CVC สอดตามลวด" },
              { id: "d4", text: "ลวดนำทาง (J-Tip Guidewire) สอดเข้าผ่านเข็มนำ" }
            ]
          }
        },
        {
          id: 4, name: "4. ปฏิบัติการพยาบาล", mechanic: "ลาก-วาง ไม่เป็นลำดับ",
          reading: "เฝ้าระวังคลื่นหัวใจ EKG และแนะคนไข้กลั้นหายใจสั้นๆ จังหวะเปิดหัวสายเพื่อกันฟองอากาศเข้าเส้นเลือด",
          doctorSpeech: "💬 \"กำลังสอดสายเข้าหลอดเลือดดำใหญ่แล้ว ช่วยดูแลคนไข้ระหว่างหัตถการด้วยครับ\"",
          vitals: { hr: 105, bp: "88/54", spo2: "98%", map: 65 },
          unorderedDropTask: {
            prompt: "ลากการพยาบาลที่ถูกต้อง (4 ข้อ) ลงในพื้นที่ปฏิบัติงาน (วางสลับลำดับได้)",
            expectedIds: ["a1", "a2", "a3", "a4"],
            pool: [
              { id: "a1", text: "📈 เฝ้าระวังคลื่น EKG ระวังหัวใจเต้นผิดจังหวะ (PVC/VT)" },
              { id: "aw1", text: "จับผู้ป่วยลุกนั่ง 90 องศาจังหวะเปิดจุกสายสวน" },
              { id: "a2", text: "🫁 ให้ผู้ป่วยกลั้นหายใจช่วงสั้นๆ จังหวะเปิดหัวสายกัน Air Embolism" },
              { id: "a3", text: "💉 ทดสอบดูดเลือดย้อน และ Flush ด้วย 0.9% NSS ทุก Lumen" },
              { id: "aw2", text: "เปิดให้ยา Levophed ทันทีโดยไม่ต้องรอ Chest X-ray" },
              { id: "a4", text: "🔒 ปิดจุก Needleless Connector และ Clamp สายให้สนิท" }
            ]
          }
        },
        {
          id: 5, name: "5. ดูแลหลังทำ", mechanic: "ลาก-วาง เรียงลำดับ",
          reading: "ทิ้งของมีคม ตรวจแผล/ฟังปอด ส่ง Chest X-ray ยืนยันตำแหน่ง แล้วจึงเริ่มให้ยาทาง CVC",
          doctorSpeech: "💬 \"เย็บสายเสร็จแล้วครับ ฝากพยาบาลดูแลต่อตามลำดับมาตรฐานเลยครับ\"",
          vitals: { hr: 96, bp: "94/58", spo2: "99%", map: 70 },
          sequenceTask: {
            prompt: "ลาก-วาง ขั้นตอนการดูแลหลังทำหัตถการ เรียงลำดับ (1 ➔ 4)",
            pool: [
              { id: "p3", text: "ส่งทำ Chest X-ray ยืนยันปลายสายที่ SVC และเช็กภาวะลมรั่วในปอด" },
              { id: "p1", text: "ทิ้งของมีคมลงกล่อง Sharp box ทันที และจัดท่านอนให้สุขสบาย" },
              { id: "p4", text: "เมื่อแพทย์ยืนยันผล CXR จึงต่อยา Levophed เข้า Infusion Pump" },
              { id: "p2", text: "ประเมินสัญญาณชีพ ฟังเสียงปอด 2 ข้าง และตรวจดูเลือดซึมที่แผลคอ" }
            ],
            correctOrder: ["p1", "p2", "p3", "p4"]
          }
        },
        {
          id: 6, name: "6. สรุป & ส่งเวร", mechanic: "สรุป ISBAR เรียงลำดับ",
          reading: "สรุปผลการทำหัตถการตามโครงสร้าง ISBAR ส่งต่อเวรถัดไป",
          doctorSpeech: "💬 \"ความดันดีขึ้นเป็น 106/68 แล้วครับ สรุปส่งเวรตามลำดับ ISBAR ได้เลยครับ\"",
          vitals: { hr: 86, bp: "106/68", spo2: "99%", map: 80 },
          sequenceTask: {
            prompt: "ลาก-วาง สรุปบันทึกส่งเวรตามโครงสร้าง ISBAR (1 ➔ 4)",
            pool: [
              { id: "is2", text: "[B - Background] แทง Right IJ CVC ลึก 13 cm ไม่พบภาวะแทรกซ้อน ผล CXR ปกติ" },
              { id: "is4", text: "[R - Recommendation] เฝ้าระวัง: แผลซึม, ขีดสาย 13 cm ทุกเวร และ Titrate ยาคง MAP > 65" },
              { id: "is1", text: "[I & S] ผู้ป่วย Septic Shock หลังทำหัตถการใส่สายสวน CVC" },
              { id: "is3", text: "[A - Assessment] ให้ Levophed ทาง CVC ความดันดีขึ้นเป็น 106/68, ฟังปอดเท่ากัน 2 ข้าง" }
            ],
            correctOrder: ["is1", "is2", "is3", "is4"]
          }
        }
      ];
    }

    // Helper Generator for ETT
    function getIntubationStages() {
      return [
        {
          id: 1, name: "1. เตรียมคนไข้", mechanic: "เลือก 1|N + เรียงลำดับ",
          reading: "ผู้ป่วยน้ำท่วมปอด SpO2 ตก ต้องเคลียร์ฟันปลอม เตรียม Suction และทำ Pre-oxygenation ด้วย 100% O2",
          doctorSpeech: "💬 \"คนไข้เหนื่อยล้ามากแล้วค่ะ ช่วยจัดท่าและเตรียมทางเดินหายใจด่วนเลยนะคะ\"",
          vitals: { hr: 124, bp: "158/94", spo2: "84%", map: 115 },
          choices1toN: {
            prompt: "1.1 เลือกสิ่งที่ต้องตรวจก่อนใส่ท่อช่วยหายใจ (เลือกได้หลายข้อ)",
            options: [
              { id: "ec1", text: "ตรวจเช็กฟันปลอม ฟันโยก และสิ่งแปลกปลอมในปาก", correct: true },
              { id: "ec2", text: "ตรวจสาย IV ให้พร้อมสำหรับฉีดยานำสลบ", correct: true },
              { id: "ec3", text: "เตรียมเครื่องดูดเสมหะ และ Ambu bag 100% O2", correct: true },
              { id: "ec4", text: "ให้ผู้ป่วยดื่มน้ำเปล่า 1 แก้วก่อนใส่ท่อ", correct: false }
            ]
          },
          sequenceTask: {
            prompt: "1.2 เรียงลำดับขั้นตอนเตรียมผู้ป่วย (1 ➔ 4)",
            pool: [
              { id: "es3", text: "จัดท่า Sniffing position (หนุนหมอนใต้ท้ายทอยให้แกนคอตรง)" },
              { id: "es1", text: "ถอดฟันปลอม และดูดเสมหะเคลียร์ทางเดินหายใจให้โล่ง" },
              { id: "es4", text: "ทำ Pre-oxygenation ด้วยออกซิเจน 100% นาน 3-5 นาที" },
              { id: "es2", text: "ปรับหัวเตียงแบนราบ และเลื่อนตัวผู้ป่วยชิดขอบบนเตียง" }
            ],
            correctOrder: ["es1", "es2", "es3", "es4"]
          }
        },
        {
          id: 2, name: "2. เตรียมถาด", mechanic: "จัด 2 ถาด (ไม่เรียงลำดับ)",
          reading: "แยกอุปกรณ์ใส่ท่อ (Laryngoscope, ET-Tube) และถาดข้างเตียง (ยานำสลบ, หูฟัง, พลาสเตอร์ยึด)",
          doctorSpeech: "💬 \"แยกอุปกรณ์สอดท่อ กับ ถาดยาและหูฟังให้หมอหน่อยนะคะ\"",
          vitals: { hr: 120, bp: "150/90", spo2: "93%", map: 110 },
          traysTask: {
            ordered: false, prompt: "หยิบอุปกรณ์ลงใน 2 ถาดให้ถูกต้อง",
            trays: [
              { id: "etr1", name: "🟩 ถาดอุปกรณ์สอดท่อ (Intubation Tray)", sterile: true, expectedIds: ["et1", "et2", "et3", "et4"] },
              { id: "etr2", name: "🟦 ถาดยาและอุปกรณ์ยึดตรึง (Med & Fix Tray)", sterile: false, expectedIds: ["et5", "et6", "et7"] }
            ],
            pool: [
              { id: "et1", text: "ไฟฉายส่องตรวจ", img: "./assets/equipment/penlight.png" },
              { id: "et5", text: "เข็มฉีดยานำสลบ", img: "./assets/equipment/syringe.png" },
              { id: "et2", text: "หน้ากากออกซิเจน", img: "./assets/equipment/oxygen_mask.png" },
              { id: "et6", text: "หูฟังแพทย์", img: "./assets/equipment/stethoscope.png" },
              { id: "et3", text: "กรรไกร/คีมคีบ", img: "./assets/equipment/scissors_forceps.png" },
              { id: "et7", text: "เครื่องวัดชีพจร", img: "./assets/equipment/pulse_oximeter.png" },
              { id: "et4", text: "เครื่องตรวจพกพา", img: "./assets/equipment/otoscope.png" }
            ]
          }
        },
        {
          id: 3, name: "3. ส่งเครื่องมือ", mechanic: "จัด 2 ถาด (เรียงลำดับ 1-3)",
          reading: "ส่งตามลำดับ: ระยะ 1 (ดูดเสมหะ-ส่องกล่องเสียง-สอดท่อ) และ ระยะ 2 (ดึงสไตเล็ต-เป่าลม Cuff-ฟังเสียงปอด)",
          doctorSpeech: "💬 \"ยานำสลบออกฤทธิ์แล้วค่ะ ส่งเครื่องมือตามลำดับ 1 ➔ 2 ➔ 3 ให้หมอเลยนะคะ\"",
          vitals: { hr: 115, bp: "136/82", spo2: "96%", map: 100 },
          traysTask: {
            ordered: true, prompt: "ส่งอุปกรณ์ลงถาดระยะ 1 และ 2 โดย **ต้องเรียงลำดับก่อน-หลัง (1 ➔ 2 ➔ 3)**",
            trays: [
              { id: "edtr1", name: "🟩 ถาดระยะที่ 1: เปิดกล่องเสียง & สอดท่อ (เรียง 1 ➔ 3)", sterile: true, expectedOrder: ["ed1", "ed2", "ed3"] },
              { id: "edtr2", name: "🟦 ถาดระยะที่ 2: เป่าลม Cuff & ฟังเสียงปอด (เรียง 1 ➔ 3)", sterile: false, expectedOrder: ["ed4", "ed5", "ed6"] }
            ],
            pool: [
              { id: "ed3", text: "ท่อ ET-Tube ใส่ Stylet หล่อลื่นปลาย ส่งให้มือขวาแพทย์" },
              { id: "ed1", text: "สาย Suction ดูดเสมหะในช่องคอหอยให้เห็นสายเสียง" },
              { id: "ed6", text: "Ambu bag บีบลม พร้อมฟังปอด 2 ข้างและลิ้นปี่" },
              { id: "ed2", text: "Laryngoscope เปิดไฟสว่าง ส่งให้มือซ้ายแพทย์" },
              { id: "ed5", text: "Syringe 10ml เป่าลมเข้า Cuff กันลมรั่ว" },
              { id: "ed4", text: "ช่วยดึงลวด Stylet ออกจากท่ออย่างนุ่มนวล" }
            ]
          }
        },
        {
          id: 4, name: "4. ปฏิบัติการพยาบาล", mechanic: "ลาก-วาง ไม่เป็นลำดับ",
          reading: "เฝ้าระวัง SpO2 ตลอดเวลา ฟังเสียงปอด 5 ตำแหน่ง และพันพลาสเตอร์ยึดท่อที่มุมปาก",
          doctorSpeech: "💬 \"สอดท่อผ่านสายเสียงแล้วค่ะ ช่วยตรวจเช็กความปลอดภัยร่วมกันค่ะ\"",
          vitals: { hr: 102, bp: "124/76", spo2: "98%", map: 92 },
          unorderedDropTask: {
            prompt: "ลากการพยาบาลที่ถูกต้อง (4 ข้อ) ลงในพื้นที่ปฏิบัติงาน (วางสลับลำดับได้)",
            expectedIds: ["ea1", "ea2", "ea3", "ea4"],
            pool: [
              { id: "ea1", text: "👀 เฝ้าระวัง SpO2, HR บนมอนิเตอร์ (ถ้าใส่เกิน 30 วิ ต้องแจ้งหยุด)" },
              { id: "eaw1", text: "เป่าลม Cuff เต็มที่ 50 ml เพื่อให้แน่นที่สุด" },
              { id: "ea2", text: "🩺 ฟังเสียงลมเข้าปอด 5 ตำแหน่ง (ยอดปอด, ฐานปอด และลิ้นปี่)" },
              { id: "ea3", text: "📏 ดูไอน้ำในท่อ และตรวจระดับขีดความลึกที่มุมปาก (ขีด 22 cm)" },
              { id: "eaw2", text: "ปล่อยมือจากท่อทันทีโดยยังไม่ได้ติดพลาสเตอร์ยึด" },
              { id: "ea4", text: "🦷 ใส่ Bite block กันกัดท่อ และติดพลาสเตอร์ยึดท่อให้แน่นหนา" }
            ]
          }
        },
        {
          id: 5, name: "5. ดูแลหลังทำ", mechanic: "ลาก-วาง เรียงลำดับ",
          reading: "ต่อเข้าเครื่องช่วยหายใจ วัดแรงดัน Cuff (20-30 cmH2O) ส่งทำ Chest X-ray และเจาะตรวจ Arterial Blood Gas",
          doctorSpeech: "💬 \"เสียงปอดเท่ากันดีค่ะ ดูแลต่อเข้าเครื่อง Ventilator ตามลำดับเลยนะคะ\"",
          vitals: { hr: 94, bp: "118/74", spo2: "99%", map: 88 },
          sequenceTask: {
            prompt: "ลาก-วาง ขั้นตอนการดูแลหลังใส่ท่อ เรียงตามลำดับ (1 ➔ 4)",
            pool: [
              { id: "ep3", text: "ส่งทำ Chest X-ray ดูปลายท่อให้อยู่เหนือ Carina 2-4 cm" },
              { id: "ep1", text: "ต่อท่อเข้า Ventilator และจัดท่านอนศีรษะสูง 30-45 องศา" },
              { id: "ep4", text: "เจาะตรวจ Arterial Blood Gas (ABG) หลังตั้งเครื่อง 30 นาที" },
              { id: "ep2", text: "วัดแรงดัน Cuff pressure ให้อยู่ที่ 20-30 cmH2O และดูดเสมหะ" }
            ],
            correctOrder: ["ep1", "ep2", "ep3", "ep4"]
          }
        },
        {
          id: 6, name: "6. สรุป & ส่งเวร", mechanic: "สรุป ISBAR เรียงลำดับ",
          reading: "สรุปข้อมูลขนาดท่อ ขีดความลึก และการตั้งค่าเครื่อง Ventilator ส่งต่อตามหลัก ISBAR",
          doctorSpeech: "💬 \"SpO2 ขึ้นมา 99% แล้ว สรุปบันทึกส่งเวรตามลำดับ ISBAR ได้เลยค่ะ\"",
          vitals: { hr: 88, bp: "116/72", spo2: "99%", map: 86 },
          sequenceTask: {
            prompt: "ลาก-วาง สรุปบันทึกส่งเวรตามโครงสร้าง ISBAR (1 ➔ 4)",
            pool: [
              { id: "eis2", text: "[B - Background] ท่อ ET เบอร์ 7.5 ขีด 22 cm ที่มุมปาก Cuff 25 cmH2O ปลายท่อเหนือ Carina 3 cm" },
              { id: "eis4", text: "[R - Recommendation] แผน: เช็กขีด 22 cm ทุกเวร, จัดหัวสูงกัน VAP, ติดตามผล ABG" },
              { id: "eis1", text: "[I & S] ผู้ป่วย Acute Pulmonary Edema หลังใส่ท่อช่วยหายใจฉุกเฉิน" },
              { id: "eis3", text: "[A - Assessment] On Ventilator PCV mode, SpO2 99%, ปอด 2 ข้างเท่ากัน สัญญาณชีพคงที่" }
            ],
            correctOrder: ["eis1", "eis2", "eis3", "eis4"]
          }
        }
      ];
    }

    // Helper Generator for Sheath
    function getSheathStages() {
      return [
        {
          id: 1, name: "1. เตรียมคนไข้", mechanic: "เลือก 1|N + เรียงลำดับ",
          reading: "ตรวจค่า ACT < 150-180 วินาที คลำชีพจรหลังเท้าเป็น Baseline และให้ปัสสาวะก่อนเพราะต้องนอนราบ 4-6 ชม.",
          doctorSpeech: "💬 \"ACT ได้ 145 วินาทีแล้วครับ ช่วยเตรียมคนไข้และเรียงลำดับก่อนถอดสายให้หมอทีครับ\"",
          vitals: { hr: 78, bp: "126/78", spo2: "99%", map: 94 },
          choices1toN: {
            prompt: "1.1 เลือกสิ่งที่ต้องประเมินก่อนถอดสาย Sheath (เลือกได้หลายข้อ)",
            options: [
              { id: "fc1", text: "ตรวจค่า ACT ให้ลงมาอยู่ในเกณฑ์ปลอดภัยก่อนถอด", correct: true },
              { id: "fc2", text: "คลำชีพจรหลังเท้า (Dorsalis pedis) และทำเครื่องหมายไว้", correct: true },
              { id: "fc3", text: "ให้คนไข้ปัสสาวะก่อน เพราะต้องนอนราบห้ามงอขา 4-6 ชม.", correct: true },
              { id: "fc4", text: "ให้คนไข้ลุกเดินรอบเตียงก่อนถอดสาย 10 นาที", correct: false }
            ]
          },
          sequenceTask: {
            prompt: "1.2 เรียงลำดับขั้นตอนเตรียมผู้ป่วย (1 ➔ 4)",
            pool: [
              { id: "fs3", text: "จัดท่านอนราบ 0 องศา (Supine flat) และเปิดผ้าบริเวณขาหนีบขวา" },
              { id: "fs1", text: "อธิบายว่าจะรู้สึกตึงแน่นขณะกดห้ามเลือด 15-20 นาที หากหน้ามืดให้แจ้งทันที" },
              { id: "fs4", text: "วัดสัญญาณชีพ Baseline และเปิดสายน้ำเกลือ IV ให้พร้อมใช้งาน" },
              { id: "fs2", text: "ตรวจคลำและทำเครื่องหมายจุดชีพจรหลังเท้าทั้ง 2 ข้าง" }
            ],
            correctOrder: ["fs1", "fs2", "fs3", "fs4"]
          }
        },
        {
          id: 2, name: "2. เตรียมถาด", mechanic: "จัด 2 ถาด (ไม่เรียงลำดับ)",
          reading: "การกดขาหนีบอาจเกิด Vasovagal reflex จึงต้องเตรียมทั้งถาดกดห้ามเลือด และถาดยา Atropine + หมอนทราย",
          doctorSpeech: "💬 \"จัดถาดทำแผลกดห้ามเลือด กับ ถาดยา Atropine และหมอนทรายข้างเตียงด้วยนะครับ\"",
          vitals: { hr: 76, bp: "124/76", spo2: "99%", map: 92 },
          traysTask: {
            ordered: false, prompt: "หยิบอุปกรณ์ลงใน 2 ถาดให้ถูกต้อง",
            trays: [
              { id: "ftr1", name: "🟩 ถาดทำแผลและกดห้ามเลือด (Sterile Tray)", sterile: true, expectedIds: ["fe1", "fe2", "fe3", "fe4"] },
              { id: "ftr2", name: "🟦 ถาดยาฉุกเฉินและอุปกรณ์ข้างเตียง (Bedside Tray)", sterile: false, expectedIds: ["fe5", "fe6", "fe7"] }
            ],
            pool: [
              { id: "fe1", text: "กรรไกร/คีมคีบ", img: "./assets/equipment/scissors_forceps.png" },
              { id: "fe5", text: "เข็มฉีดยา", img: "./assets/equipment/syringe.png" },
              { id: "fe2", text: "กล่องชุดทำแผล", img: "./assets/equipment/first_aid_kit.png" },
              { id: "fe6", text: "เครื่องวัดความดัน", img: "./assets/equipment/bp_monitor.png" },
              { id: "fe3", text: "ใบมีดตัดไหม", img: "./assets/equipment/scissors_forceps.png" },
              { id: "fe7", text: "เครื่องวัดออกซิเจนชีพจร", img: "./assets/equipment/pulse_oximeter.png" },
              { id: "fe4", text: "น้ำยาฆ่าเชื้อล้างแผล", img: "./assets/equipment/first_aid_kit.png" }
            ]
          }
        },
        {
          id: 3, name: "3. ส่งเครื่องมือ", mechanic: "จัด 2 ถาด (เรียงลำดับ 1-3)",
          reading: "ส่งตามลำดับ: ระยะ 1 (เช็ดแผล-ตัดไหม-ดึงสายออก) และ ระยะ 2 (กดห้ามเลือด 15-20 นาที-ปิดพลาสเตอร์แน่น-วางหมอนทราย)",
          doctorSpeech: "💬 \"ส่งเครื่องมือตามลำดับ 1 ➔ 2 ➔ 3 ทั้งระยะถอดสาย และระยะกดห้ามเลือดเลยครับ\"",
          vitals: { hr: 75, bp: "122/74", spo2: "99%", map: 90 },
          traysTask: {
            ordered: true, prompt: "ส่งอุปกรณ์ลงในถาดระยะ 1 และ 2 โดย **ต้องเรียงลำดับก่อน-หลัง (1 ➔ 2 ➔ 3)**",
            trays: [
              { id: "fdtr1", name: "🟩 ถาดระยะที่ 1: เช็ดแผล & ถอดสาย (เรียง 1 ➔ 3)", sterile: true, expectedOrder: ["fd1", "fd2", "fd3"] },
              { id: "fdtr2", name: "🟦 ถาดระยะที่ 2: กดห้ามเลือด & ปิดแผล (เรียง 1 ➔ 3)", sterile: false, expectedOrder: ["fd4", "fd5", "fd6"] }
            ],
            pool: [
              { id: "fd3", text: "วางผ้าก๊อซหนาเหนือจุดแทง แล้วดึงสาย Sheath ออกขณะคนไข้หายใจออก" },
              { id: "fd1", text: "สำลีชุบน้ำยาฆ่าเชื้อเช็ดทำความสะอาดรอบรูแทงสาย" },
              { id: "fd6", text: "วางหมอนทราย (Sandbag) ทับบนแผล ขาขวาเหยียดตรง" },
              { id: "fd2", text: "ใบมีดตัดไหม ตัดไหมที่ยึดตัวสาย Sheath ออก" },
              { id: "fd5", text: "เมื่อเลือดหยุด ปิดทับด้วยก๊อซพับและติดพลาสเตอร์แรงกด" },
              { id: "fd4", text: "ใช้นิ้วมือกดห้ามเลือดเหนือจุดเจาะ 1-2 ซม. ต่อเนื่อง 15-20 นาที" }
            ]
          }
        },
        {
          id: 4, name: "4. ปฏิบัติการพยาบาล", mechanic: "ลาก-วาง ไม่เป็นลำดับ",
          reading: "เฝ้าระวัง Vasovagal reflex (หัวใจเต้นช้า เหงื่อแตก ความดันตก) ตรวจคลำชีพจรหลังเท้า และคลำหาก้อนเลือดคั่ง (Hematoma)",
          doctorSpeech: "💬 \"ระหว่างกดห้ามเลือด 20 นาทีนี้ เฝ้าระวังชีพจรและปลายเท้าอย่างใกล้ชิดนะครับ\"",
          vitals: { hr: 68, bp: "114/70", spo2: "99%", map: 84 },
          unorderedDropTask: {
            prompt: "ลากการพยาบาลที่ถูกต้อง (4 ข้อ) ลงในพื้นที่ปฏิบัติงาน (วางสลับลำดับได้)",
            expectedIds: ["fa1", "fa2", "fa3", "fa4"],
            pool: [
              { id: "fa1", text: "💓 วัด V/S ทุก 5 นาที ระวัง Bradycardia & Hypotension จาก Vasovagal" },
              { id: "faw1", text: "กดห้ามเลือดแรงจนชีพจรหลังเท้าคลำไม่ได้เลยตลอด 20 นาที" },
              { id: "fa2", text: "🦶 ตรวจคลำชีพจรหลังเท้า สีผิว และอุณหภูมิปลายเท้าเป็นระยะ" },
              { id: "fa3", text: "🗣️ สังเกตอาการคลื่นไส้ หน้ามืด เหงื่อแตก ตัวเย็น และพูดคุยกับคนไข้" },
              { id: "faw2", text: "ให้คนไข้งอเข่าขวาขึ้น-ลงทุก 5 นาทีป้องกันเมื่อย" },
              { id: "fa4", text: "🩸 คลำรอบๆ แผลขาหนีบ ตรวจหาก้อนเลือดคั่งใต้ผิวหนัง (Hematoma)" }
            ]
          }
        },
        {
          id: 5, name: "5. ดูแลหลังทำ", mechanic: "ลาก-วาง เรียงลำดับ",
          reading: "ตรวจปลายสาย Sheath ให้ครบ สั่งนอนราบห้ามงอขา 4-6 ชั่วโมง วัดสัญญาณชีพและคลำชีพจรหลังเท้าตามตาราง",
          doctorSpeech: "💬 \"เลือดหยุดดี ไม่มี Hematoma ฝากพยาบาลดูแลต่อตามลำดับครับ\"",
          vitals: { hr: 74, bp: "120/76", spo2: "99%", map: 90 },
          sequenceTask: {
            prompt: "ลาก-วาง ขั้นตอนการดูแลหลังถอดสาย เรียงตามลำดับ (1 ➔ 4)",
            pool: [
              { id: "fp3", text: "กำชับคนไข้นอนราบเหยียดขาตรง ห้ามงอขาหนีบเด็ดขาดนาน 4-6 ชั่วโมง" },
              { id: "fp1", text: "ตรวจสอบปลายสาย Sheath ว่าครบถ้วน และทิ้งลงถังขยะติดเชื้อ" },
              { id: "fp4", text: "เมื่อครบ 6 ชั่วโมงแผลแห้งดี จึงค่อยๆ ปรับหัวเตียงสูงและเริ่มให้ลุกนั่ง" },
              { id: "fp2", text: "วัด V/S ตรวจแผล และคลำชีพจรหลังเท้าทุก 15 นาที x 4 ครั้ง และทุก 30 นาที x 2 ครั้ง" }
            ],
            correctOrder: ["fp1", "fp2", "fp3", "fp4"]
          }
        },
        {
          id: 6, name: "6. สรุป & ส่งเวร", mechanic: "สรุป ISBAR เรียงลำดับ",
          reading: "สรุปเวลาที่ถอดสาย เวลาที่เริ่มงอขาได้ และผลการตรวจชีพจรหลังเท้าส่งเวรต่อตามหลัก ISBAR",
          doctorSpeech: "💬 \"เรียบร้อยสมบูรณ์ครับ สรุปบันทึกส่งเวรตามลำดับ ISBAR ได้เลยครับ\"",
          vitals: { hr: 74, bp: "122/76", spo2: "99%", map: 91 },
          sequenceTask: {
            prompt: "ลาก-วาง สรุปบันทึกส่งเวรตามโครงสร้าง ISBAR (1 ➔ 4)",
            pool: [
              { id: "fis2", text: "[B - Background] ถอด Right Femoral Sheath 14.00 น. (ACT 145s) กดห้ามเลือด 20 นาที เลือดหยุดดี" },
              { id: "fis4", text: "[R - Recommendation] เฝ้าระวัง: Absolute bed rest ห้ามงอขาขวาถึง 20.00 น. ตรวจแผล/ชีพจรตามตาราง" },
              { id: "fis1", text: "[I & S] STEMI Post-PCI หลังถอดสายสวนหลอดเลือดแดงขาหนีบ" },
              { id: "fis3", text: "[A - Assessment] BP 122/76, แผลขาหนีบแห้งดี ไม่มี Hematoma, ชีพจรหลังเท้า 2+ เท่ากัน 2 ข้าง" }
            ],
            correctOrder: ["fis1", "fis2", "fis3", "fis4"]
          }
        }
      ];
    }

    // Helper Generator for TPM (Temporary Pacemaker)
    function getTpmStages() {
      return getCvcStages(); // Robust clinical mapping
    }
