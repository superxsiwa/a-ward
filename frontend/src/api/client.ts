import {
  BedCase,
  BedProgressRecord,
  PlayerSettings,
  PlayerStats,
  StageData,
  StudentLeaderboardEntry,
  UserProfile,
} from '../types/game';

const TOKEN_KEY = 'award_ccu_jwt_token_v1';

export function getAuthToken(): string | null {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

export function setAuthToken(token: string | null): void {
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {
    // ignore storage errors
  }
}

async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getAuthToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...((options.headers as Record<string, string>) || {}),
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const res = await fetch(path, {
    ...options,
    headers,
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.error || `HTTP Error ${res.status}`);
  }
  return data as T;
}

export const authApi = {
  login: (email: string, password: string) =>
    apiFetch<{ token: string; user: UserProfile }>('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),
  register: (payload: {
    email: string;
    password: string;
    displayName: string;
    role?: 'NURSE' | 'INSTRUCTOR';
  }) =>
    apiFetch<{ token: string; user: UserProfile }>('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  me: () => apiFetch<{ user: UserProfile }>('/api/auth/me'),
  updateSettings: (payload: Partial<PlayerSettings> & { displayName?: string }) =>
    apiFetch<{ settings: PlayerSettings }>('/api/auth/settings', {
      method: 'PATCH',
      body: JSON.stringify(payload),
    }),
};

export const casesApi = {
  getAll: () => apiFetch<{ cases: BedCase[] }>('/api/cases'),
  create: (bed: Partial<BedCase>) =>
    apiFetch<{ cases: BedCase[] }>('/api/cases', {
      method: 'POST',
      body: JSON.stringify(bed),
    }),
  update: (bedNum: number, bed: Partial<BedCase>) =>
    apiFetch<{ cases: BedCase[] }>(`/api/cases/${bedNum}`, {
      method: 'PUT',
      body: JSON.stringify(bed),
    }),
  updateStep: (bedNum: number, stepIndex: number, stepData: StageData) =>
    apiFetch<{ cases: BedCase[] }>(`/api/cases/${bedNum}/steps/${stepIndex}`, {
      method: 'PUT',
      body: JSON.stringify(stepData),
    }),
  remove: (bedNum: number) =>
    apiFetch<{ cases: BedCase[] }>(`/api/cases/${bedNum}`, {
      method: 'DELETE',
    }),
  importJson: (cases: BedCase[]) =>
    apiFetch<{ cases: BedCase[] }>('/api/cases/import', {
      method: 'POST',
      body: JSON.stringify({ cases }),
    }),
  resetDefaults: () =>
    apiFetch<{ cases: BedCase[] }>('/api/cases/reset-defaults', {
      method: 'POST',
    }),
};

export const progressApi = {
  getMe: () =>
    apiFetch<{
      progress: Record<number, BedProgressRecord>;
      playerStats: PlayerStats;
      rosterSchedule: Record<string, Record<number, string>>;
      rosterDaysProgress: Record<string, { passed: boolean; shiftId?: string }>;
      settings: PlayerSettings;
    }>('/api/progress/me'),
  completeCase: (payload: {
    bedNum: number;
    mistakes: number;
    stars: number;
    durationSeconds?: number;
    trayItemsSortedDelta?: number;
    stepsWithoutMistakeDelta?: number;
    isEmergency?: boolean;
    activeShift?: string | null;
    dayKey?: string;
  }) =>
    apiFetch<{
      bedNum: number;
      starsEarned: number;
      bestStars: number;
      shiftDayCleared: boolean;
      playerStats: PlayerStats;
    }>('/api/progress/complete-case', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  heartbeat: (seconds = 5) =>
    apiFetch<{ totalPlaySeconds: number }>('/api/progress/heartbeat', {
      method: 'POST',
      body: JSON.stringify({ seconds }),
    }),
  reset: () =>
    apiFetch<{ ok: boolean }>('/api/progress/reset', {
      method: 'POST',
    }),
};

export const rosterApi = {
  saveMonth: (monthKey: string, schedule: Record<number, string>) =>
    apiFetch<{ ok: boolean }>(`/api/roster/${monthKey}`, {
      method: 'PUT',
      body: JSON.stringify({ schedule }),
    }),
  clearDay: (dayKey: string, shiftId = 'off') =>
    apiFetch<{ ok: boolean }>('/api/roster/clear-day', {
      method: 'POST',
      body: JSON.stringify({ dayKey, shiftId }),
    }),
};

export const instructorApi = {
  getStudents: () => apiFetch<{ students: StudentLeaderboardEntry[] }>('/api/instructor/students'),
};
