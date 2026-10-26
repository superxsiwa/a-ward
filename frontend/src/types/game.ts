export interface VitalSigns {
  hr: number;
  bp: string;
  spo2: string;
  map: number;
}

export interface ChoiceOption {
  id: string;
  text: string;
  correct: boolean;
}

export interface ChoicesTask {
  prompt: string;
  options: ChoiceOption[];
}

export interface PoolItem {
  id: string;
  text: string;
  img?: string;
}

export interface SequenceTask {
  prompt: string;
  pool: PoolItem[];
  correctOrder: string[];
}

export interface TrayDef {
  id: string;
  name: string;
  sterile: boolean;
  expectedIds?: string[];
  expectedOrder?: string[];
}

export interface TraysTask {
  ordered: boolean;
  prompt: string;
  trays: TrayDef[];
  pool: PoolItem[];
}

export interface UnorderedDropTask {
  prompt: string;
  expectedIds: string[];
  pool: PoolItem[];
}

export interface StageData {
  id: number | string;
  name: string;
  mechanic: string;
  reading: string;
  doctorSpeech: string;
  vitals: VitalSigns;
  choices1toN?: ChoicesTask;
  sequenceTask?: SequenceTask;
  traysTask?: TraysTask;
  unorderedDropTask?: UnorderedDropTask;
}

export interface BedCase {
  bedNum: number;
  bedCode: string;
  patientName: string;
  patientAge?: number;
  caseTitle: string;
  dxBadge: string;
  status: 'stable' | 'alert' | 'critical';
  statusText: string;
  doctorName: string;
  doctorAvatar: string;
  stayDuration?: string;
  clinicalNote?: string;
  stageData: StageData[];
}

export interface StepRuntimeState {
  items: Record<string, PoolItem>;
  pool: string[];
  seq: Array<string | null> | null;
  trays: Record<string, string[]> | null;
  unordered: string[] | null;
  sel: Set<string>;
  picked: string | null;
  wrong: Set<string>;
  wrongOpts: Set<string>;
  locked: boolean;
}

export interface BedProgressRecord {
  passed: boolean;
  stars: number;
  bestMistakes?: number;
}

export interface PlayerStats {
  totalCompletedCases: number;
  totalPlaySeconds: number;
  perfectCases: number;
  shiftsCompleted: number;
  trayItemsSorted: number;
  stepsWithoutMistake: number;
  emergencyCasesDone: number;
  replayedCases: number;
}

export interface PlayerSettings {
  sound: boolean;
  haptics: boolean;
}

export interface UserProfile {
  id: string;
  email: string;
  displayName: string;
  role: 'NURSE' | 'INSTRUCTOR';
  avatar: string;
  settings?: PlayerSettings;
}

export interface StudentLeaderboardEntry {
  id: string;
  email: string;
  displayName: string;
  role: 'NURSE' | 'INSTRUCTOR';
  avatar: string;
  level: number;
  rankTitle: string;
  totalStars: number;
  passedBedsCount: number;
  totalCompletedCases: number;
  perfectCases: number;
  shiftsCompleted: number;
  totalPlaySeconds: number;
  updatedAt: string;
}
