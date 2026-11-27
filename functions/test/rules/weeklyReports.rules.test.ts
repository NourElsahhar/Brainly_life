// Rules tests for users/{uid}/weeklyReports: the app (GeminiAiClient)
// saves the AI report of a finished week once, and never edits it.
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
import {
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from "firebase/firestore";

let env: RulesTestEnvironment;

const ME = "shahd";
const OTHER = "m5";
const PATH = `users/${ME}/weeklyReports/2026-W47`;

const db = (uid?: string) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

// Exactly what ai_assistant_injection.dart (saveWeeklyReport) writes.
const report = (over: Record<string, unknown> = {}) => ({
  weekKey: "2026-W47",
  stats: {tasksCreated: 4, tasksCompleted: 2, productivityScore: 60},
  summary: "You completed two tasks.",
  recommendations: ["Pick one priority.", "Plan a focus block.", "Review."],
  generatedAt: serverTimestamp(),
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  promptVersion: 1,
  ...over,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "brainly-life-rules-reports",
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

describe("users/{uid}/weeklyReports", () => {
  it("I can save my report once and read it", async () => {
    await assertSucceeds(setDoc(doc(db(ME), PATH), report()));
    await assertSucceeds(getDoc(doc(db(ME), PATH)));
  });

  it("a saved report cannot be edited", async () => {
    await assertSucceeds(setDoc(doc(db(ME), PATH), report()));
    await assertFails(updateDoc(doc(db(ME), PATH), {summary: "changed"}));
    await assertFails(setDoc(doc(db(ME), PATH), report({summary: "new"})));
  });

  it("another user or a signed-out user is refused", async () => {
    await assertFails(setDoc(doc(db(OTHER), PATH), report()));
    await assertFails(setDoc(doc(db(), PATH), report()));
  });

  it("bad reports are refused", async () => {
    const bad = [
      report({weekKey: "2026-W48"}),
      report({summary: ""}),
      report({recommendations: ["only one"]}),
      report({stats: "lots"}),
      report({isAdmin: true}),
    ];
    for (const data of bad) {
      await assertFails(setDoc(doc(db(ME), PATH), data));
    }
  });
});
