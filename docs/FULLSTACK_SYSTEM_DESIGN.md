# 🩺 Full-Stack System Analysis & Design (A&D) — A-WARD CCU

> [!IMPORTANT]
> **Full-Stack Architecture Specification (Option 3):**
> - **Frontend:** **React 19 + Vite + TypeScript** preserving 100% of the Chibi/Candy Hospital UI/UX (`prototype/style.css`) + Optimistic LocalStorage Cache.
> - **Backend:** **Node.js + Express + TypeScript + Prisma ORM**.
> - **Database:** **SQLite** (zero-config local dev/testing) & **PostgreSQL** (production-ready via Prisma schema).
> - **Authentication & RBAC:** **JWT + bcryptjs** (`email` & `password`) with two roles:
>   - **`NURSE` (Student / Player):** Plays monthly shift rosters, completes 8-bed CCU clinical procedures, earns stars (`1–3 ⭐`), unlocks 20 milestones, and syncs all progress/stats to the database.
>   - **`INSTRUCTOR` (Admin / Educator):** Accesses the **Case & Step Manager** (CRUD beds, edit 6-step procedures & answer keys, import/export JSON) and views the **Student Progress & Leaderboard Dashboard**.

---

## 1. High-Level Full-Stack System Architecture

```mermaid
flowchart TB
    subgraph Client ["📱 Frontend SPA (React 19 + Vite + TypeScript)"]
        AuthUI["Auth Views<br>(Login / Register / Profile Badge)"]
        TabsUI["Main Navigation Views<br>(Roster Calendar, 8-Bed Ward, Progress & 20 Milestones, Settings)"]
        GameUI["6-Step Procedure Game View<br>(ECG Monitor, Doctor Prompt, Pointer DnD + Tap Engine, 20s Timer, Mercy Sheet)"]
        AdminUI["Instructor Portal (RBAC: INSTRUCTOR)<br>(Case & 6-Step Builder, JSON Import/Export, Student Leaderboard)"]
        StateStore["Client State & API Layer<br>(State Store + REST Client + LocalStorage Optimistic Cache)"]
    end

    subgraph Server ["⚙️ Backend API Server (Node.js + Express + TypeScript)"]
        AuthMW["JWT Auth & RBAC Middleware<br>(verifyToken, requireRole('INSTRUCTOR'))"]
        AuthCtrl["Auth Controller<br>(/api/auth/*)"]
        CaseCtrl["Cases & Stages Controller<br>(/api/cases/*)"]
        ProgCtrl["Progress, Roster & Stats Controller<br>(/api/progress/*, /api/roster/*)"]
        AdminCtrl["Instructor Analytics Controller<br>(/api/instructor/*)"]
        Prisma["Prisma ORM Client<br>(Transactions & Schema Validation)"]
    end

    subgraph DB ["🗄️ Relational Database (SQLite Dev / PostgreSQL Prod)"]
        UsersTbl[("User & PlayerStats")]
        CasesTbl[("CcuBed, ProcedureStage,<br>VitalSigns, TrayContainer, TaskItem")]
        ProgTbl[("BedProgress, RosterSchedule,<br>RosterDayProgress")]
    end

    AuthUI --> StateStore
    TabsUI --> StateStore
    GameUI --> StateStore
    AdminUI --> StateStore
    StateStore <-->|REST JSON + Bearer JWT| AuthMW
    AuthMW --> AuthCtrl
    AuthMW --> CaseCtrl
    AuthMW --> ProgCtrl
    AuthMW --> AdminCtrl
    AuthCtrl --> Prisma
    CaseCtrl --> Prisma
    ProgCtrl --> Prisma
    AdminCtrl --> Prisma
    Prisma <--> UsersTbl
    Prisma <--> CasesTbl
    Prisma <--> ProgTbl
```

---

## 2. Relational Database Schema (Prisma / ER Diagram)

```mermaid
erDiagram
    USER ||--|| PLAYER_STATS : "has"
    USER ||--|| PLAYER_SETTINGS : "configures"
    USER ||--o{ BED_PROGRESS : "earns stars on"
    USER ||--o{ ROSTER_SCHEDULE : "has monthly schedule"
    USER ||--o{ ROSTER_DAY_PROGRESS : "clears shift days"
    USER ||--o{ CASE_ATTEMPT_LOG : "records play history"

    CCU_BED ||--|{ PROCEDURE_STAGE : "contains 6 ordered steps"
    CCU_BED ||--o{ BED_PROGRESS : "tracked per user"

    USER {
        string id PK "UUID"
        string email UK "User login email"
        string passwordHash "bcrypt hash"
        string displayName "Nurse display name"
        string role "NURSE | INSTRUCTOR"
        datetime createdAt
        datetime updatedAt
    }

    PLAYER_STATS {
        string userId PK, FK
        int totalCompletedCases
        int totalPlaySeconds
        int perfectCases
        int shiftsCompleted
        int trayItemsSorted
        int stepsWithoutMistake
        int emergencyCasesDone
        int replayedCases
    }

    PLAYER_SETTINGS {
        string userId PK, FK
        boolean soundEnabled
        boolean hapticsEnabled
    }

    CCU_BED {
        int id PK
        int bedNum UK "1..N (Bed 01 to 08+)"
        string bedCode
        string patientName
        int patientAge
        string caseTitle
        string dxBadge
        string status "stable | alert | critical"
        string statusText
        string doctorName
        string doctorAvatar
        string stayDuration
        string clinicalNote
        boolean isDefault
        datetime updatedAt
    }

    PROCEDURE_STAGE {
        int id PK
        int bedId FK
        int stepIndex "0..5 (Step 1 to 6)"
        string name
        string mechanic
        string doctorSpeech
        text reading
        json vitals
        json choicesConfig
        json sequenceConfig
        json traysConfig
        json unorderedConfig
    }

    BED_PROGRESS {
        int id PK
        string userId FK
        int bedNum FK
        boolean passed
        int stars "1..3 (Highest achieved)"
        int bestMistakes
        int attemptCount
        datetime updatedAt
    }

    ROSTER_SCHEDULE {
        int id PK
        string userId FK
        string monthKey "YYYY-M"
        json scheduleMap
    }

    ROSTER_DAY_PROGRESS {
        int id PK
        string userId FK
        string dayKey "YYYY-M-D"
        string shiftId "morning | afternoon | night | off"
        boolean passed
        datetime clearedAt
    }

    CASE_ATTEMPT_LOG {
        int id PK
        string userId FK
        int bedNum
        int starsEarned
        int mistakesCount
        int durationSeconds
        datetime completedAt
    }
```

---

## 3. REST API Contracts

### 3.1 Auth Endpoints (`/api/auth`)
- `POST /api/auth/register` — `{ email, password, displayName, role?: "NURSE" | "INSTRUCTOR" }` ➔ `{ token, user }`
- `POST /api/auth/login` — `{ email, password }` ➔ `{ token, user }`
- `GET /api/auth/me` — Bearer JWT ➔ `{ user }`
- `PATCH /api/auth/settings` — Bearer JWT `{ sound?, haptics?, displayName? }` ➔ `{ settings }`

### 3.2 Clinical Cases Endpoints (`/api/cases`)
- `GET /api/cases` — Returns all CCU beds ordered by `bedNum` with `stageData[0..5]`
- `POST /api/cases` (`INSTRUCTOR`) — Create new CCU bed case
- `PUT /api/cases/:bedNum` (`INSTRUCTOR`) — Update bed/patient metadata
- `PUT /api/cases/:bedNum/steps/:stepIndex` (`INSTRUCTOR`) — Update stage vitals, prompt, mechanic, and answer keys
- `DELETE /api/cases/:bedNum` (`INSTRUCTOR`) — Delete bed case and re-index `bedNum`
- `POST /api/cases/import` (`INSTRUCTOR`) — Validate and import JSON case array
- `POST /api/cases/reset-defaults` (`INSTRUCTOR`) — Reset to canonical 8 CCU beds

### 3.3 Progress & Roster Endpoints (`/api/progress`, `/api/roster`, `/api/instructor`)
- `GET /api/progress/me` — Returns `{ progress, playerStats, rosterSchedule, rosterDaysProgress, settings }`
- `POST /api/progress/complete-case` — Atomically saves case completion, updates highest `stars`, increments `PlayerStats`, logs `CaseAttemptLog`, and unlocks next shift day if all shift beds are passed
- `POST /api/progress/heartbeat` — Increments `totalPlaySeconds`
- `POST /api/progress/reset` — Resets user's stars and roster progress
- `PUT /api/roster/:monthKey` — Saves randomized or updated monthly shift schedule
- `POST /api/roster/clear-day` — Marks a shift/off day as passed
- `GET /api/instructor/students` (`INSTRUCTOR`) — Returns student progress & star leaderboard

