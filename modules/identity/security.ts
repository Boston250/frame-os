export const sessionPolicy = { cookieName: "__Host-frame_session", httpOnly: true, secure: true, sameSite: "lax" as const, idleTimeoutMinutes: 60, absoluteTimeoutHours: 12, twoFactorAuthentication: false };
export function normalizeEmployeeNumber(value: string) { const normalized=value.trim().toUpperCase(); if(!/^FRM-\d{4,}$/.test(normalized)) throw new Error("Invalid employee ID"); return normalized; }
export function canAttemptLogin(failedCount: number, lockedUntil: Date|null, now=new Date()) { return failedCount<5 || lockedUntil===null || lockedUntil<=now; }
