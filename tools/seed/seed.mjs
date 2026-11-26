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

// ---------- M3: tasks and categories ----------
// Shapes follow Task.toFirestore() / TaskCategory.toFirestore() and the
// rules: exactly 10 task fields, client Timestamps, and completedAt only
// on done tasks. The dates move with "now", so every tab has something:
//   Today 2, Upcoming 2, Overdue 1, no date 1, Completed (30 days) 3,
//   plus 1 done task older than 30 days (counts on the Profile only).

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

/** A Timestamp [ms] from now (negative = in the past). */
function fromNow(ms) {
  return Timestamp.fromMillis(Date.now() + ms);
}

async function seedTasks(uid) {
  const categories = db.collection(`users/${uid}/taskCategories`);
  const university = categories.doc("cat-university");
  const personal = categories.doc("cat-personal");
  const health = categories.doc("cat-health");
  await university.set({ name: "University", colorValue: 0xff6c5ce7 });
  await personal.set({ name: "Personal", colorValue: 0xff00cec9 });
  await health.set({ name: "Health", colorValue: 0xff55efc4 });

  const tasks = db.collection(`users/${uid}/tasks`);
  // Before every completedAt below (the oldest is 45 days ago).
  const created = fromNow(-60 * DAY);

  /** One task with every field the rules expect. */
  function task({
    title,
    description = null,
    priority = "medium",
    categoryId = null,
    dueAt = null,
    completedAt = null,
    subtasks = [],
  }) {
    return {
      title,
      description,
      priority,
      categoryId,
      dueAt,
      status: completedAt ? "done" : "todo",
      completedAt,
      subtasks,
      createdAt: created,
      updatedAt: created,
    };
  }

  const all = {
    // Today
    "task-lab-report": task({
      title: "Finish the lab report",
      description: "Physics lab 4: results and conclusion.",
      priority: "high",
      categoryId: university.id,
      dueAt: fromNow(3 * HOUR),
      subtasks: [
        { id: "subtask_1", title: "Write the introduction", done: true },
        { id: "subtask_2", title: "Add the results", done: false },
      ],
    }),
    "task-gym": task({
      title: "Gym: leg day",
      categoryId: health.id,
      dueAt: fromNow(5 * HOUR),
    }),
    // Upcoming
    "task-slides": task({
      title: "Prepare presentation slides",
      priority: "low",
      categoryId: university.id,
      dueAt: fromNow(1 * DAY),
    }),
    "task-gift": task({
      title: "Buy a birthday gift",
      categoryId: personal.id,
      dueAt: fromNow(4 * DAY),
    }),
    // Overdue
    "task-email": task({
      title: "Email the supervisor",
      priority: "high",
      categoryId: university.id,
      dueAt: fromNow(-5 * HOUR),
    }),
    // No date, no category
    "task-books": task({ title: "Return library books" }),
    // Completed in the last 30 days (the Completed tab)
    "task-groceries": task({
      title: "Buy groceries",
      categoryId: personal.id,
      completedAt: fromNow(-1 * DAY),
    }),
    "task-quiz": task({
      title: "Math quiz 2",
      priority: "high",
      categoryId: university.id,
      completedAt: fromNow(-3 * DAY),
    }),
    "task-run": task({
      title: "Morning run",
      categoryId: health.id,
      completedAt: fromNow(-10 * DAY),
    }),
    // Done more than 30 days ago: not in the Completed tab, but the
    // Profile counts it (4 tasks done in total).
    "task-old": task({
      title: "Register for the semester",
      categoryId: university.id,
      completedAt: fromNow(-45 * DAY),
    }),
  };

  const batch = db.batch();
  for (const [id, data] of Object.entries(all)) {
    batch.set(tasks.doc(id), data);
  }
  await batch.commit();
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
