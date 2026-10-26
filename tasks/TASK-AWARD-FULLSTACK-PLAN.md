# 🩺 Full-Stack System Analysis & Master Execution Plan
**Project:** `A-WARD CCU` (Full-Stack Clinical Decision & Simulation Web App)  
**Tech Stack:** React 19 + Vite + TypeScript (Frontend) | Node.js + Express + TypeScript + Prisma ORM + SQLite/PostgreSQL (Backend) | JWT + bcryptjs Auth (`NURSE` & `INSTRUCTOR` roles)  
**Status:** Approved & Ready for Implementation  

---

## 1. Architecture & Directory Structure

```text
a-ward/
├── backend/                     # Node.js + Express + TypeScript + Prisma API Server
│   ├── prisma/
│   │   ├── schema.prisma        # Relational Schema (User, PlayerStats, PlayerSettings, CcuBed, ProcedureStage, BedProgress, RosterSchedule, RosterDayProgress, CaseAttemptLog)
│   │   └── seed.ts              # Seeds all 8 CCU Beds (48 clinical stages) + Demo Nurse & Instructor accounts
│   ├── src/
│   │   ├── config/              # Env, JWT secret, CORS config
│   │   ├── middleware/          # authMiddleware.ts (JWT + RBAC), errorHandler.ts
│   │   ├── routes/              # auth.routes.ts, cases.routes.ts, progress.routes.ts, instructor.routes.ts
│   │   ├── controllers/         # Request handlers & validation (Zod)
│   │   ├── services/            # Business logic (Evaluation, Star calculation, Roster progression)
│   │   └── index.ts             # Express app entry (Port 4000, or serves frontend build in prod)
│   └── package.json
├── frontend/                    # React + Vite + TypeScript SPA
│   ├── public/
│   │   ├── assets/equipment/    # 16 Chibi clinical equipment PNGs (copied from prototype/assets/equipment)
│   │   ├── manifest.json        # PWA Manifest
│   │   └── icon.svg
│   ├── src/
│   │   ├── api/                 # Typed REST client (authApi, casesApi, progressApi, instructorApi)
│   │   ├── components/          # TopBar, BottomDock, EcgMonitor, PointerDnD, FeedbackSheet, WinModal
│   │   ├── pages/               # AuthPage, RosterPage, WardPage, GamePage, ProgressPage, CaseManagerPage, SettingsPage
│   │   ├── engine/              # FSM, EvaluationStrategyContext, GameEventBus, SFXEngine (Web Audio API), MilestoneDefs
│   │   ├── store/               # Auth & Game State Store (with optimistic LocalStorage sync)
│   │   ├── types/               # Shared TypeScript interfaces matching Prisma/API contracts
│   │   └── styles/              # Exact Chibi Hospital CSS ported from prototype/style.css
│   └── package.json
├── prototype/                   # Original reference prototype (preserved intact)
├── docs/                        # System Architecture & Specification Docs
└── tasks/                       # Task Breakdown Specs
```

---

## 2. Granular Task Breakdown (`TASK-AWARD-001` to `TASK-AWARD-017`)

| Task ID | Sprint | Task Title | Acceptance Criteria ("Definition of Done") |
| :--- | :--- | :--- | :--- |
| **TASK-AWARD-001** | Sprint 1 | **Backend Initialization & Prisma Schema Setup** | `backend/prisma/schema.prisma` defines `User`, `PlayerStats`, `PlayerSettings`, `CcuBed`, `ProcedureStage`, `BedProgress`, `RosterSchedule`, `RosterDayProgress`, and `CaseAttemptLog`. Database migrates cleanly. |
| **TASK-AWARD-002** | Sprint 1 | **JWT Authentication & RBAC Middleware** | `/api/auth/register`, `/api/auth/login`, `/api/auth/me`, `/api/auth/settings` implemented with `bcryptjs` and `jsonwebtoken`. Supports `NURSE` and `INSTRUCTOR` roles. |
| **TASK-AWARD-003** | Sprint 2 | **Complete 8-Bed Clinical Dataset (Beds 01–08 × 6 Steps)** | Dedicated 6-step clinical procedures authored for all 8 CCU beds (48 stages total): Bed 01 (Sheath), Bed 02 (CVC), Bed 03 (ETT), Bed 04 (TPM), Bed 05 (Levophed), Bed 06 (Pericardial Drain), Bed 07 (Cardioversion), Bed 08 (RP Bleed). Seeded via `prisma/seed.ts` with demo accounts (`nurse@award.ccu` / `instructor@award.ccu`). |
| **TASK-AWARD-004** | Sprint 2 | **Clinical Cases CRUD & JSON Import/Export API (`/api/cases`)** | `GET /api/cases`, `POST /api/cases`, `PUT /api/cases/:bedNum`, `PUT /api/cases/:bedNum/steps/:stepIndex`, `DELETE /api/cases/:bedNum`, `POST /api/cases/import`, and `POST /api/cases/reset-defaults`. |
| **TASK-AWARD-005** | Sprint 2 | **Player Progress, Star Rating & Shift Roster API (`/api/progress`, `/api/roster`)** | `GET /api/progress/me`, `POST /api/progress/complete-case` (atomic DB transaction updating `BedProgress`, `PlayerStats`, `CaseAttemptLog`, and unlocking next shift day), `PUT /api/roster/:monthKey`, `POST /api/roster/clear-day`, `POST /api/progress/reset`. |
| **TASK-AWARD-006** | Sprint 2 | **Instructor Student Analytics & Leaderboard API (`/api/instructor/students`)** | Returns student list sorted by `totalStars` with `passedBedsCount`, `totalCompletedCases`, `shiftsCompleted`, and `totalPlaySeconds`. |
| **TASK-AWARD-007** | Sprint 3 | **Frontend Scaffold (React + Vite + TypeScript) & Design System Port** | `frontend/` initialized with exact Chibi Hospital CSS (`prototype/style.css`), SVG sprites, Google Fonts (`Mitr`, `Prompt`), and 16 equipment PNGs. |
| **TASK-AWARD-008** | Sprint 3 | **Frontend Auth Store, API Client & Login/Register UI** | Email/Password Login & Register screen + 1-click Demo Nurse / Demo Instructor login buttons, JWT persistence, and TopBar user/role profile display. |
| **TASK-AWARD-009** | Sprint 3 | **Core Domain Engines in TypeScript (FSM, Strategy, EventBus, SFX)** | Modular TypeScript implementations of `ProcedureStateMachine`, `EvaluationStrategyContext`, `GameEventBus`, and `SFXEngine` (Web Audio API + Haptics). |
| **TASK-AWARD-010** | Sprint 3 | **Shift Roster Calendar View & Sequential Day Progression** | Monthly calendar (`RosterPage.tsx`) with pulsing gold `▶` playable indicator, locked future day guard, equal-height vertical shift cards, and DB sync. |
| **TASK-AWARD-011** | Sprint 3 | **8-Bed CCU Ward View, Animated ECG & Shift Filter** | `WardPage.tsx` with 8 CCU beds, HR-synchronized SVG ECG Lead II animation, stay tags, Nurse Station counter, and Shift Filter banner. |
| **TASK-AWARD-012** | Sprint 4 | **6-Step Procedure Game View & Pointer Drag-and-Drop Engine** | `GamePage.tsx` with Pointer Events Drag & Drop (120ms touch hold, floating ghost, auto-scroll), Tap-to-Place, keyboard support, and responsive Desktop 2-column split view. |
| **TASK-AWARD-013** | Sprint 4 | **Step Navigation, State Preservation & 20s Emergency Timer** | Bottom dock step navigation (`step-prev`, `check`, `step-next`, `reset-step`), `stepStates` cache, and Step-2 20s timer with modal pause/resume. |
| **TASK-AWARD-014** | Sprint 4 | **3-Strike Mercy Rule, Interactive Solution View & Victory Modal** | Instant feedback sheets (`#sheet`), 3-Strike Mercy Rule (`💡 ดูเฉลย & ไปต่อ` with solution preview), and Victory Modal with DB sync & confetti. |
| **TASK-AWARD-015** | Sprint 5 | **20 Milestones & Progress Analytics View (`ProgressPage.tsx`)** | Circular star ring, Nurse Rank Lv.1–9, telemetry boxes, and 20 Milestone Goals evaluated across 3 star tiers. |
| **TASK-AWARD-016** | Sprint 5 | **Instructor Case & 6-Step Builder + Student Leaderboard (`CaseManagerPage.tsx`)** | Full Case CRUD, 6-step Answer & Vitals Editor, dynamic mechanic switcher, equipment icon picker, JSON import/export, and Student Leaderboard table. |
| **TASK-AWARD-017** | Sprint 6 | **Unified Server Deployment, PWA Service Worker & E2E Verification** | Unified startup scripts (`npm run dev` / `npm start`), offline Service Worker (`sw.js`), and automated Puppeteer E2E verification across all 8 beds and APIs. |

