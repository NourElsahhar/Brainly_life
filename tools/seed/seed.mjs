// Fills the Firebase EMULATOR with a demo user (owner: M1).
// Each owner adds seed data for their own collections below
// (Master Document: subjects, tasks, habits and logs, focus sessions).
//
//   firebase emulators:start          (terminal 1, repo root)
//   cd tools/seed && npm install      (once)
//   npm run seed                      (terminal 2)
//
// Then run the app with --dart-define=USE_EMULATOR=true and sign in with:
//   demo@baseet.app / Demo2026!
//
// Safety: it refuses to run unless it talks to the emulator.

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";

import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, Timestamp, getFirestore} from "firebase-admin/firestore";

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error("Refusing to seed: not connected to the emulator.");
  process.exit(1);
}

initializeApp({projectId: "brainly-life"});
const auth = getAuth();
const db = getFirestore();

const DEMO = {
  uid: "demo-user",
  email: "demo@baseet.app",
  password: "Demo2026!",
  displayName: "Demo Student",
};

// ---------- M1: the user and the profile ----------

async function seedUser() {
  try {
    await auth.deleteUser(DEMO.uid); // start clean on every run
  } catch {
    // not there yet
  }
  await auth.createUser(DEMO);
  await db.recursiveDelete(db.doc(`users/${DEMO.uid}`));
  await db.doc(`users/${DEMO.uid}`).set({
    displayName: DEMO.displayName,
    email: DEMO.email,
    photoUrl: null,
    settings: {
      dailyStudyHours: 4,
      preferredStudyTime: "evening",
      weekStartDay: 6, // Saturday
      timezone: "Africa/Cairo",
      themeMode: "system",
      aiEnabled: true,
    },
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

// ---------- M3: tasks and categories (add yours here) ----------

async function seedTasks(uid) {
  const now = Timestamp.now();
  const categories = db.collection(`users/${uid}/taskCategories`);
  const study = categories.doc("cat-study");
  await study.set({name: "Study", colorValue: 0xff6c5ce7});

  const tasks = db.collection(`users/${uid}/tasks`);
  await tasks.doc("task-1").set({
    title: "Revise chapter 3",
    description: null,
    priority: "high",
    categoryId: study.id,
    dueAt: null,
    status: "todo",
    completedAt: null,
    subtasks: [],
    createdAt: now,
    updatedAt: now,
  });
}

// ---------- M2, M4, M5: add a function for your collections ----------

async function main() {
  await seedUser();
  await seedTasks(DEMO.uid);
  console.log(`Seeded. Sign in with ${DEMO.email} / ${DEMO.password}`);
}

main().catch((error) => {
  console.error("Seed failed:", error.message);
  process.exit(1);
});
