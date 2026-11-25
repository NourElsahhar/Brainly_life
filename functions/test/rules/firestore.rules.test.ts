// Tests for firestore.rules on the Firestore EMULATOR (Master Document B.1:
// "own data allowed, other users' data denied, unauthenticated denied").
//
// Run (needs Java 21 and the Firebase CLI):
//   cd functions
//   npm run test:rules
// It starts the emulator, runs this file, then stops the emulator.
// A plain `npm test` skips this file.

import assert from "node:assert/strict";
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
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from "firebase/firestore";

let env: RulesTestEnvironment;

const ME = "shahd";
const OTHER = "nour";

const db = (uid?: string) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

const settings = {
  dailyStudyHours: 2,
  preferredStudyTime: "evening",
  weekStartDay: 6,
  timezone: "Africa/Cairo",
  themeMode: "system",
  aiEnabled: true,
};

// Exactly what AuthRemoteDataSource writes for a new user.
const newProfile = () => ({
  displayName: "Shahd",
  email: "shahd@student.edu",
  photoUrl: null,
  settings,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

// Exactly what Task.toFirestore() writes.
const task = (over: Record<string, unknown> = {}) => ({
  title: "Revise chapter 3",
  description: null,
  priority: "high",
  categoryId: null,
  dueAt: null,
  status: "todo",
  completedAt: null,
  subtasks: [],
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
  ...over,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "brainly-life-rules-test",
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

/** Saves [data] at [path] without any rule (test setup only). */
async function seed(path: string, data: Record<string, unknown>) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

describe("users/{uid}", () => {
  it("I can create and read my own profile", async () => {
    await assertSucceeds(setDoc(doc(db(ME), `users/${ME}`), newProfile()));
    await assertSucceeds(getDoc(doc(db(ME), `users/${ME}`)));
  });

  it("I cannot read or write another user's profile", async () => {
    await seed(`users/${OTHER}`, {displayName: "Nour"});
    await assertFails(getDoc(doc(db(ME), `users/${OTHER}`)));
    await assertFails(setDoc(doc(db(ME), `users/${OTHER}`), newProfile()));
  });

  it("signed out: nothing is allowed", async () => {
    await assertFails(getDoc(doc(db(), `users/${ME}`)));
    await assertFails(setDoc(doc(db(), `users/${ME}`), newProfile()));
  });

  it("unknown fields or bad settings are refused", async () => {
    await assertFails(
      setDoc(doc(db(ME), `users/${ME}`), {...newProfile(), isAdmin: true}),
    );
    await assertFails(
      setDoc(doc(db(ME), `users/${ME}`), {
        ...newProfile(),
        settings: {...settings, dailyStudyHours: 99},
      }),
    );
  });

  it("updating the name and the settings works, createdAt cannot change", async () => {
    await assertSucceeds(setDoc(doc(db(ME), `users/${ME}`), newProfile()));
    const ref = doc(db(ME), `users/${ME}`);

    await assertSucceeds(
      updateDoc(ref, {displayName: "Shahd Adel", updatedAt: serverTimestamp()}),
    );
    await assertSucceeds(
      updateDoc(ref, {
        settings: {...settings, themeMode: "dark"},
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(ref, {createdAt: Timestamp.now(), updatedAt: serverTimestamp()}),
    );
  });

  it("I can delete my profile", async () => {
    await seed(`users/${ME}`, {displayName: "Shahd"});
    await assertSucceeds(deleteDoc(doc(db(ME), `users/${ME}`)));
  });
});

describe("users/{uid}/tasks", () => {
  const path = `users/${ME}/tasks/t1`;

  it("a valid task is accepted", async () => {
    await assertSucceeds(setDoc(doc(db(ME), path), task()));
  });

  it("another user's tasks are denied", async () => {
    await assertFails(setDoc(doc(db(OTHER), path), task()));
    await seed(path, task());
    await assertFails(getDoc(doc(db(OTHER), path)));
  });

  it("bad tasks are refused", async () => {
    const bad = [
      task({title: ""}),
      task({title: "x".repeat(101)}),
      task({priority: "urgent"}),
      task({subtasks: new Array(21).fill({title: "s", done: false})}),
      task({status: "done", completedAt: null}), // done needs completedAt
      task({status: "todo", completedAt: Timestamp.now()}),
      task({hacked: true}),
    ];
    for (const data of bad) {
      await assertFails(setDoc(doc(db(ME), path), data));
    }
  });

  it("deleting a category clears categoryId in a batch", async () => {
    await seed(path, task({categoryId: "c1"}));
    const batch = writeBatch(db(ME));
    batch.update(doc(db(ME), path), {categoryId: null, updatedAt: Timestamp.now()});
    await assertSucceeds(batch.commit());
  });
});

describe("users/{uid}/taskCategories", () => {
  const path = `users/${ME}/taskCategories/c1`;

  it("valid category accepted, bad ones refused", async () => {
    await assertSucceeds(setDoc(doc(db(ME), path), {name: "Study", colorValue: 4284506343}));
    await assertFails(setDoc(doc(db(ME), path), {name: "", colorValue: 1}));
    await assertFails(setDoc(doc(db(ME), path), {name: "x".repeat(31), colorValue: 1}));
    await assertFails(setDoc(doc(db(ME), path), {name: "Study", colorValue: "red"}));
  });
});

describe("server-only collections (aiUsage, weeklyReports)", () => {
  for (const name of ["aiUsage", "weeklyReports"]) {
    const path = `users/${ME}/${name}/2026-11-25`;

    it(`${name}: I can read and delete mine, never write`, async () => {
      await seed(path, {count: 3});
      await assertSucceeds(getDoc(doc(db(ME), path)));
      await assertFails(setDoc(doc(db(ME), path), {count: 0}));
      await assertFails(updateDoc(doc(db(ME), path), {count: 0}));
      await assertSucceeds(deleteDoc(doc(db(ME), path)));
    });

    it(`${name}: another user cannot read it`, async () => {
      await seed(path, {count: 3});
      await assertFails(getDoc(doc(db(OTHER), path)));
    });
  }
});

describe("other collections (habits, focus, plans...)", () => {
  it("owner only", async () => {
    const path = `users/${ME}/habits/h1`;
    await assertSucceeds(setDoc(doc(db(ME), path), {name: "Read"}));
    await assertFails(getDoc(doc(db(OTHER), path)));
    await assertFails(getDoc(doc(db(), path)));
  });

  it("nothing outside users/{uid}", async () => {
    await assertFails(setDoc(doc(db(ME), "public/x"), {a: 1}));
  });
});

// Guard: the test file found the rules.
it("loads the repository's firestore.rules", () => {
  const rules = readFileSync(resolve(__dirname, "../../../firestore.rules"), "utf8");
  assert.match(rules, /match \/users\/\{uid\}/);
});
