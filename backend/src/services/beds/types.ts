export interface StagePayload {
  id: number | string;
  name: string;
  mechanic: string;
  reading: string;
  doctorSpeech: string;
  vitals: { hr: number; bp: string; spo2: string; map: number };
  choices1toN?: {
    prompt: string;
    options: Array<{ id: string; text: string; correct: boolean }>;
  };
  sequenceTask?: {
    prompt: string;
    pool: Array<{ id: string; text: string; img?: string }>;
    correctOrder: string[];
  };
  traysTask?: {
    ordered: boolean;
    prompt: string;
    trays: Array<{
      id: string;
      name: string;
      sterile: boolean;
      expectedIds?: string[];
      expectedOrder?: string[];
    }>;
    pool: Array<{ id: string; text: string; img?: string }>;
  };
  unorderedDropTask?: {
    prompt: string;
    expectedIds: string[];
    pool: Array<{ id: string; text: string; img?: string }>;
  };
}

export interface BedCasePayload {
  bedNum: number;
  bedCode: string;
  patientName: string;
  patientAge: number;
  caseTitle: string;
  dxBadge: string;
  status: 'stable' | 'alert' | 'critical';
  statusText: string;
  doctorName: string;
  doctorAvatar: string;
  stayDuration: string;
  clinicalNote: string;
  stageData: StagePayload[];
}
