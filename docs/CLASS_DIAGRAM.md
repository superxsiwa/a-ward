# แผนภาพคลาส (Class Diagram)
## โครงการ: A-WARD CCU (CCU Nursing Simulation Game)

---

### 1. คำอธิบายสถาปัตยกรรมเชิงคลาส (Architecture Overview)
โครงสร้างโปรแกรมถูกออกแบบแบบ Object-Oriented และ Data-Driven Architecture ประกอบด้วย:
- **Core Entities:** ข้อมูลเตียงคนไข้ (`CCUBed`), สัญญาณชีพ (`VitalSigns`), ขั้นตอนหัตถการ (`StageData`), และภารกิจ Drag & Drop (`SequenceTask`, `TraysTask`, `UnorderedTask`)
- **Shift & Progression Models:** ข้อมูลเวรประจำวัน (`Shift`), ปฏิทินเวร (`RosterSchedule`), และเป้าหมายสะสมดาว (`MilestoneGoal`)
- **Game Engine & UI State:** ตัวควบคุมลอจิกแอป (`GameEngine`), ระบบเสียงสังเคราะห์ Web Audio (`SFXEngine`), และตัวบันทึกข้อมูลเบราว์เซอร์ (`LocalStorageManager`)

---

### 2. แผนภาพ Class Diagram (Mermaid)

```mermaid
classDiagram
    %% Core Bed & Patient Models
    class CCUBed {
        +int bedNum
        +String bedCode
        +String patientName
        +int patientAge
        +String caseTitle
        +String dxBadge
        +String status
        +String statusText
        +String doctorName
        +String doctorAvatar
        +List~StageData~ stageData
        +getStayInfo() String
    }

    class VitalSigns {
        +int hr
        +String bp
        +String spo2
        +int map
        +isAlarm() boolean
    }

    class StageData {
        +String id
        +String name
        +String mechanic
        +String docSpeech
        +VitalSigns vitals
        +ChoicesTask choices1toN
        +SequenceTask sequenceTask
        +TraysTask traysTask
        +UnorderedTask unorderedDropTask
    }

    class Tray {
        +String id
        +String name
        +String type
        +List~String~ expectedIds
        +List~String~ expectedOrder
    }

    class TraysTask {
        +List~TrayItem~ pool
        +List~Tray~ trays
        +boolean ordered
    }

    class SequenceTask {
        +List~SequenceItem~ pool
        +List~String~ correctOrder
        +List~String~ placeholders
    }

    class UnorderedTask {
        +List~UnorderedItem~ pool
        +List~String~ expectedIds
    }

    %% Shift Roster Models
    class Shift {
        +String id
        +String name
        +String time
        +String icon
        +String chargeNurse
        +String badgeClass
        +List~int~ bedIndices
    }

    class RosterSchedule {
        +int year
        +int month
        +Map~int, String~ dailyShifts
        +generateMonthSchedule(int year, int month) Map
        +getShiftForDay(int day) Shift
        +isDayPlayable(int day) boolean
        +isDayLocked(int day) boolean
        +isDayCompleted(int day) boolean
    }

    %% Milestone & Progress Models
    class MilestoneGoal {
        +String id
        +String title
        +String icon
        +String unit
        +List~float~ tiers
        +String desc
        +getValue() float
        +getStars() int
        +getNextTarget() float
        +getProgressPercent() float
    }

    class PlayerStats {
        +int totalCompletedCases
        +int totalPlaySeconds
        +int perfectCases
        +int shiftsCompleted
        +int trayItemsSorted
        +int stepsWithoutMistake
        +int emergencyCasesDone
        +int replayedCases
    }

    %% Controllers & Engines
    class GameEngine {
        -String currentTab
        -int currentBedIdx
        -int currentStepIdx
        -int mistakesCount
        -Set~String~ doneSteps
        -Object stepState
        +renderRoster() void
        +renderWard() void
        +renderProgress() void
        +renderSettings() void
        +openBed(int bedIdx) void
        +loadStep(int stepIdx) void
        +checkStep() void
        +finishCase() void
    }

    class SFXEngine {
        -AudioContext ctx
        +pick() void
        +drop() void
        +ok() void
        +bad() void
        +win() void
        +star(int index) void
    }

    class LocalStorageManager {
        +load(String key, Object defaultVal) Object
        +save(String key, Object val) void
        +clearAll() void
    }

    %% Relationships
    CCUBed *-- StageData
    StageData *-- VitalSigns
    StageData o-- TraysTask
    StageData o-- SequenceTask
    StageData o-- UnorderedTask
    TraysTask *-- Tray
    Shift o-- CCUBed
    RosterSchedule o-- Shift
    GameEngine o-- CCUBed
    GameEngine o-- RosterSchedule
    GameEngine o-- MilestoneGoal
    GameEngine o-- PlayerStats
    GameEngine o-- SFXEngine
    GameEngine o-- LocalStorageManager
```

---

### 3. คำอธิบายคลาสหลัก (Class Descriptions)

1. **`CCUBed`**: ข้อมูลเตียงคนไข้ CCU ทั้ง 8 เตียง รายละเอียดโรค แพทย์ผู้ดูแล และชุดข้อมูลหัตถการ 6 ขั้นตอน
2. **`StageData`**: ขั้นตอนการทำหัตถการแต่ละขั้น บรรจุโจทย์ สัญญาณชีพ คำพูดแพทย์ และชนิดภารกิจ Drag & Drop
3. **`TraysTask` / `SequenceTask` / `UnorderedTask`**: โครงสร้างภารกิจจัดเตรียมอุปกรณ์ลงถาดหลายใบ, เรียงลำดับเครื่องมือให้หมอ, และเลือกการพยาบาลที่ปลอดภัย
4. **`Shift` / `RosterSchedule`**: ระบบตารางเวรหมุนเวียน (เช้า/บ่าย/ดึก/Off) ตรวจสอบเงื่อนไขการเล่นเรียงวัน และการล็อกเวร
5. **`MilestoneGoal` / `PlayerStats`**: ระบบบันทึกสถิติ 20 เป้าหมาย คำนวณดาวและเปอร์เซ็นต์ของหลอดพลังความก้าวหน้า
6. **`GameEngine`**: ตัวควบคุมหน้าจอและการโต้ตอบของผู้เล่น (Tabs, Modal, Feedback Sheet, Stepper)
7. **`SFXEngine`**: สังเคราะห์คลื่นเสียง (Sine, Triangle wave) ด้วย Web Audio API สำหรับเสียง Pop, Click, Star, Confetti
