// Rules tests for M4's collections: habits, habitLogs, focusSessions and
// preferences/focus. Same setup as firestore.rules.test.ts, but its own
// emulator project so the two files never clear each other's data.
//
// Run: npm run test:rules

import {readFileSync} from "node:fs";
import {resolve} from "node:path";
import {after, afterEach, before, describe, it} from "node:test";

import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {Timestamp, deleteDoc, doc, getDoc, setDoc, updateDoc} from "firebase/firestore";

let env: RulesTestEnvironment;

const ME = "shahd";
const OTHER = "migoo";

const db = (uid?: string) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

// Exactly what Habit.toFirestore() writes.
const habit = (over: Record<string, unknown> = {}) => ({
  name: "Read 20 pages",
  icon: "book",
  colorValue: 4280391411,
  frequencyType: "daily",
  weekdays: [],
  timesPerWeek: null,
  startDate: "2026-11-20",
  archived: false,
  currentStreak: 0,
  bestStreak: 0,
  lastCompletedDate: null,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
  ...over,
});

// Exactly what HabitLog.toFirestore() writes.
const log = (habitId = "h1", date = "2026-11-25") => ({
  habitId,
  date,
  completedAt: Timestamp.now(),
});

// Exactly what FocusSession.toFirestore() writes.
const session = (over: Record<string, unknown> = {}) => ({
  type: "focus",
  startedAt: Timestamp.now(),
  endedAt: Timestamp.now(),
  plannedMinutes: 25,
  actualMinutes: 25,
  completed: true,
  dateKey: "2026-11-25",
  taskId: null,
  studySessionId: null,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
  ...over,
});

// Exactly what FocusSettings.toFirestore() writes.
const focusSettings = (over: Record<string, unknown> = {}) => ({
  focusMinutes: 25,
  shortBreakMinutes: 5,
  longBreakMinutes: 15,
  sessionsBeforeLong: 4,
  autoStart: false,
  sound: true,
  vibration: true,
  keepScreenOn: false,
  ...over,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "brainly-life-rules-m4",
    firestore: {
      rules: readFileSync(resolve(__dirname, "../../../firestore.rules"), "utf8"),
    },
  });
});

afterEach(async () => {
  await env.clearFirestore();
});

after(async () => {
  await env.cleanup();
});

describe("users/{uid}/habits", () => {
  const path = `users/${ME}/habits/h1`;

  it("I can create, read, update and delete my habit", async () => {
    await assertSucceeds(setDoc(doc(db(ME), path), habit()));
    await assertSucceeds(getDoc(doc(db(ME), path)));
    await assertSucceeds(updateDoc(doc(db(ME), path), {
      currentStreak: 3, bestStreak: 3, lastCompletedDate: "2026-11-25",
      updatedAt: Timestamp.now(),
    }));
    await assertSucceeds(deleteDoc(doc(db(ME), path)));
  });

  it("weekdays and times per week habits are accepted", async () => {
    await assertSucceeds(setDoc(doc(db(ME), path),
      habit({frequencyType: "weekdays", weekdays: [1, 3, 5]})));
    await assertSucceeds(setDoc(doc(db(ME), `users/${ME}/habits/h2`),
      habit({frequencyType: "timesPerWeek", timesPerWeek: 3})));
  });

  it("another user or a signed-out user is refused", async () => {
    await assertFails(setDoc(doc(db(OTHER), path), habit()));
    await assertFails(getDoc(doc(db(OTHER), path)));
    await assertFails(setDoc(doc(db(), path), habit()));
  });

  it("bad shapes are refused", async () => {
    const bad = [
      habit({name: ""}),
      habit({name: "x".repeat(51)}),
      habit({frequencyType: "hourly"}),
      habit({timesPerWeek: 9}),
      habit({currentStreak: -1}),
      habit({startDate: "25/11/2026"}),
      habit({isAdmin: true}),
    ];
    for (const data of bad) {
      await assertFails(setDoc(doc(db(ME), path), data));
    }
  });

  it("createdAt cannot change", async () => {
    await assertSucceeds(setDoc(doc(db(ME), path), habit()));
    await assertFails(updateDoc(doc(db(ME), path), {
      createdAt: Timestamp.fromMillis(0),
    }));
  });
});

describe("users/{uid}/habitLogs", () => {
  it("the id must be <habitId>_<date>", async () => {
    await assertSucceeds(
      setDoc(doc(db(ME), `users/${ME}/habitLogs/h1_2026-11-25`), log()));
    await assertFails(
      setDoc(doc(db(ME), `users/${ME}/habitLogs/random`), log()));
    await assertFails(
      setDoc(doc(db(ME), `users/${ME}/habitLogs/h1_2026-11-24`), log()));
  });

  it("I can delete my log (un-tick), others cannot read it", async () => {
    const path = `users/${ME}/habitLogs/h1_2026-11-25`;
    await assertSucceeds(setDoc(doc(db(ME), path), log()));
    await assertFails(getDoc(doc(db(OTHER), path)));
    await assertSucceeds(deleteDoc(doc(db(ME), path)));
  });

  it("extra fields are refused", async () => {
    await assertFails(setDoc(doc(db(ME), `users/${ME}/habitLogs/h1_2026-11-25`),
      {...log(), note: "hi"}));
  });
});

describe("users/{uid}/focusSessions", () => {
  const path = `users/${ME}/focusSessions/s1`;

  it("I can save and read a session", async () => {
    await assertSucceeds(setDoc(doc(db(ME), path), session()));
    await assertSucceeds(setDoc(doc(db(ME), `users/${ME}/focusSessions/s2`),
      session({type: "shortBreak", taskId: "t1", completed: false})));
    await assertSucceeds(getDoc(doc(db(ME), path)));
  });

  it("bad sessions are refused", async () => {
    const bad = [
      session({type: "nap"}),
      session({actualMinutes: 241}),
      session({actualMinutes: -5}),
      session({dateKey: "today"}),
      session({completed: "yes"}),
      session({extra: 1}),
    ];
    for (const data of bad) {
      await assertFails(setDoc(doc(db(ME), path), data));
    }
  });

  it("another user is refused", async () => {
    await assertFails(setDoc(doc(db(OTHER), path), session()));
  });
});

describe("users/{uid}/preferences/focus", () => {
  const path = `users/${ME}/preferences/focus`;

  it("I can save and read my timer settings", async () => {
    await assertSucceeds(setDoc(doc(db(ME), path), focusSettings()));
    await assertSucceeds(getDoc(doc(db(ME), path)));
  });

  it("bad settings are refused", async () => {
    await assertFails(setDoc(doc(db(ME), path), focusSettings({focusMinutes: 0})));
    await assertFails(setDoc(doc(db(ME), path), focusSettings({sound: "on"})));
    await assertFails(setDoc(doc(db(ME), path), focusSettings({theme: "x"})));
  });

  it("other preference documents stay owner-only", async () => {
    await assertSucceeds(
      setDoc(doc(db(ME), `users/${ME}/preferences/other`), {anything: 1}));
    await assertFails(
      setDoc(doc(db(OTHER), `users/${ME}/preferences/other`), {anything: 1}));
  });
});
