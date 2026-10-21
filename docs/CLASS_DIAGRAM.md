# แผนภาพคลาส (Class Diagram)
## โครงการ: A-WARD (CCU Nursing Simulation Game)

---

### 1. คำอธิบายสถาปัตยกรรมเชิงคลาส (Architecture Overview)
สถาปัตยกรรมของ A-WARD ถูกออกแบบตามหลัก Object-Oriented Design และ Separation of Concerns เพื่อให้การจัดการจำลองสถานการณ์ทางคลินิก (Clinical Simulation State), การแสดงผลสัญญาณชีพ (Vitals & Canvas Engine), และตัวขับเคลื่อนเคสการตัดสินใจ (Case Scenario Engine) มีความเป็นโมดูลาร์สูง

---

### 2. แผนภาพ Class Diagram (Mermaid)

```mermaid
classDiagram
    %% Entities / Models
    class Patient {
        +String name
        +int age
        +String bed
        +String diagnosis
        +getDemographics() String
    }

    class VitalSigns {
        +int hr
        +String bp
        +String spo2
        +int map
        +String condClass
        +String condText
        +calculateMAP(int systolic, int diastolic) int
        +isHypotensive() boolean
    }

    class Choice {
        +String letter
        +String text
        +boolean isCorrect
        +String rationale
    }

    class SimulationStep {
        +int id
        +String stageTitle
        +String scenarioDesc
        +String npcSpeech
        +VitalSigns vitals
        +List~Choice~ choices
        +getCorrectChoice() Choice
    }

    class CCUCaseScenario {
        +Patient patient
        +List~SimulationStep~ steps
        +int totalSteps
        +getStep(int index) SimulationStep
    }

    %% Controllers / Engines
    class GameController {
        -int currentStepIdx
        -int safetyScore
        -int nurseExp
        -boolean answeredCurrentStep
        -CCUCaseScenario currentCase
        +initGame() void
        +renderStep(int idx) void
        +makeDecision(int choiceIdx) void
        +nextStageStep() void
        +restartCase() void
        +calculateFinalResult() EvaluationResult
    }

    class MonitorEngine {
        -HTMLCanvasElement canvas
        -CanvasRenderingContext2D ctx
        -float currentX
        -float currentY
        -int animationFrameId
        +initEkgWave() void
        +drawEkgSegment() void
        +updateVitals(VitalSigns vitals) void
        +setCriticalAlarm(boolean active) void
    }

    class UIViewController {
        +HTMLElement stageContainer
        +HTMLElement feedbackPanel
        +HTMLElement modalOverlay
        +renderChoices(List~Choice~ choices) void
        +showFeedback(boolean isCorrect, String title, String rationale) void
        +updateScoreDisplay(int safetyScore, int exp) void
        +showCompletionModal(EvaluationResult result) void
        +hideModal() void
    }

    class EvaluationResult {
        +int finalScore
        +int totalExp
        +String grade
        +String clinicalCommentary
        +boolean passedCriteria
    }

    %% Relationships
    CCUCaseScenario "1" *-- "1" Patient : contains
    CCUCaseScenario "1" *-- "5" SimulationStep : contains
    SimulationStep "1" *-- "1" VitalSigns : defines
    SimulationStep "1" *-- "3" Choice : contains

    GameController "1" o-- "1" CCUCaseScenario : manages
    GameController "1" --> "1" MonitorEngine : controls
    GameController "1" --> "1" UIViewController : interacts
    GameController ..> EvaluationResult : produces
    UIViewController ..> EvaluationResult : renders
```

---

### 3. คำอธิบายรายละเอียดคลาส (Class Specifications)

#### 3.1 กลุ่ม Model / Data Entities
- **`Patient`**: ข้อมูลประชากรศาสตร์ของผู้ป่วย เช่น ชื่อ นามสกุล อายุ เตียง และการวินิจฉัยโรคเบื้องต้น (เช่น STEMI Post-PCI)
- **`VitalSigns`**: สัญญาณชีพของผู้ป่วยในแต่ละสถานะ (Heart Rate, NIBP, SpO2, Mean Arterial Pressure) พร้อมคลาส CSS กำกับระดับความรุนแรง (Stable, Warning, Critical)
- **`Choice`**: ตัวเลือกการตัดสินใจ (A, B, C) พร้อมการระบุคำตอบที่ถูกต้อง และคำอธิบายเชิงคลินิก (Clinical Rationale)
- **`SimulationStep`**: องค์ประกอบของแต่ละสถานการณ์จำลอง (คำอธิบายเหตุการณ์, บทพูดของ Charge Nurse, สัญญาณชีพ และตัวเลือก)
- **`CCUCaseScenario`**: อ็อบเจกต์รวบรวมเคสผู้ป่วยและขั้นตอนทั้งหมดในสถานการณ์

#### 3.2 กลุ่ม Controller & Engine
- **`GameController`**: สมองหลักในการควบคุม Flow ของเกม จัดการ State ปัจจุบัน บันทึกคะแนน Patient Safety และคะแนน EXP ตรวจสอบคำตอบ และสลับขั้นตอน
- **`MonitorEngine`**: ระบบเรนเดอร์สัญญาณชีพและคลื่นหัวใจ Canvas วาดรูปคลื่น P-QRS-T แบบไดนามิกตามรอบ Loop ความถี่สูง
- **`UIViewController`**: จัดการ DOM ในหน้าเว็บ ปรับปรุงข้อความ สไตล์ปุ่ม การเปิด/ปิด Feedback Panel และ Result Modal
- **`EvaluationResult`**: อ็อบเจกต์สรุปผลลัพธ์การประเมินทักษะทางการพยาบาลเมื่อจบเคส
