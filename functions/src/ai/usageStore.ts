// UsageStore = the per-user daily AI limits (C.5).
//
// One document per user per day: users/{uid}/aiUsage/{dateKey}
//   { dateKey: "2026-11-24", count: 7, byFeature: {studyPlan: 2, chat: 5},
//     updatedAt }
// Only the gateway writes it (firestore.rules: the app may only read it).
//
// "Today" is the day in the USER's time zone (users/{uid}.settings.timezone),
// so the limit resets at the user's midnight, not at UTC midnight.
//
// reserve() counts the call BEFORE the AI is called, inside a transaction,
// so 10 calls at the same moment cannot pass a limit of 5.
// release() gives the call back when the provider failed (not the user's
// fault).

import {FieldValue, Firestore} from "firebase-admin/firestore";

export interface Reservation {
  allowed: boolean;
  /** Calls left today for this feature (also limited by the total). */
  remainingToday: number;
  dateKey: string;
}

export interface UsageStore {
  reserve(
    uid: string,
    feature: string,
    limits: {feature: number; total: number},
    now: Date,
  ): Promise<Reservation>;
  release(uid: string, feature: string, dateKey: string): Promise<void>;
}

/** 'yyyy-MM-dd' of [now] in [timeZone] (IANA). Bad zone -> UTC. */
export function dateKeyIn(now: Date, timeZone: string | undefined): string {
  try {
    // en-CA formats dates as yyyy-MM-dd.
    return new Intl.DateTimeFormat("en-CA", {
      timeZone: timeZone || "UTC",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).format(now);
  } catch {
    return now.toISOString().slice(0, 10);
  }
}

/** Calls left after [used] calls (never below 0). */
export function remaining(
  limits: {feature: number; total: number},
  featureUsed: number,
  totalUsed: number,
): number {
  return Math.max(
    0,
    Math.min(limits.feature - featureUsed, limits.total - totalUsed),
  );
}

export class FirestoreUsageStore implements UsageStore {
  constructor(private readonly db: Firestore) {}

  async reserve(
    uid: string,
    feature: string,
    limits: {feature: number; total: number},
    now: Date,
  ): Promise<Reservation> {
    const userRef = this.db.doc(`users/${uid}`);

    return this.db.runTransaction(async (tx) => {
      const user = await tx.get(userRef);
      const timeZone = user.get("settings.timezone") as string | undefined;
      const dateKey = dateKeyIn(now, timeZone);
      const usageRef = userRef.collection("aiUsage").doc(dateKey);

      const usage = await tx.get(usageRef);
      const total = (usage.get("count") as number | undefined) ?? 0;
      const used =
        (usage.get(`byFeature.${feature}`) as number | undefined) ?? 0;

      if (used >= limits.feature || total >= limits.total) {
        return {allowed: false, remainingToday: 0, dateKey};
      }

      tx.set(
        usageRef,
        {
          dateKey,
          count: FieldValue.increment(1),
          byFeature: {[feature]: FieldValue.increment(1)},
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return {
        allowed: true,
        remainingToday: remaining(limits, used + 1, total + 1),
        dateKey,
      };
    });
  }

  async release(uid: string, feature: string, dateKey: string): Promise<void> {
    await this.db.doc(`users/${uid}/aiUsage/${dateKey}`).set(
      {
        count: FieldValue.increment(-1),
        byFeature: {[feature]: FieldValue.increment(-1)},
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  }
}

/** In-memory UsageStore for tests (no Firestore). */
export class MemoryUsageStore implements UsageStore {
  readonly counts = new Map<string, {total: number; byFeature: Map<string, number>}>();

  constructor(private readonly timeZone = "UTC") {}

  async reserve(
    uid: string,
    feature: string,
    limits: {feature: number; total: number},
    now: Date,
  ): Promise<Reservation> {
    const dateKey = dateKeyIn(now, this.timeZone);
    const day = this.day(uid, dateKey);
    const used = day.byFeature.get(feature) ?? 0;
    if (used >= limits.feature || day.total >= limits.total) {
      return {allowed: false, remainingToday: 0, dateKey};
    }
    day.total++;
    day.byFeature.set(feature, used + 1);
    return {
      allowed: true,
      remainingToday: remaining(limits, used + 1, day.total),
      dateKey,
    };
  }

  async release(uid: string, feature: string, dateKey: string): Promise<void> {
    const day = this.day(uid, dateKey);
    day.total = Math.max(0, day.total - 1);
    day.byFeature.set(feature, Math.max(0, (day.byFeature.get(feature) ?? 0) - 1));
  }

  private day(uid: string, dateKey: string) {
    const key = `${uid}/${dateKey}`;
    let day = this.counts.get(key);
    if (!day) {
      day = {total: 0, byFeature: new Map()};
      this.counts.set(key, day);
    }
    return day;
  }
}
