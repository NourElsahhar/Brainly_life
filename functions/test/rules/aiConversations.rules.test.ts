// Rules tests for M5's chat history: users/{uid}/aiConversations and its
// messages subcollection. Own emulator project, like the other rules files.
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
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from "firebase/firestore";

let env: RulesTestEnvironment;

const ME = "shahd";
const OTHER = "m5";
const CONVERSATION = `users/${ME}/aiConversations/assistant`;
const MESSAGE = `${CONVERSATION}/messages/m1`;

const db = (uid?: string) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

// Exactly what ChatRemoteDataSource.save writes.
const conversation = () => ({
  title: "Brainly AI",
  lastMessageAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  createdAt: serverTimestamp(),
});
const message = (over: Record<string, unknown> = {}) => ({
  role: "user",
  text: "Help me plan my week",
  actions: [],
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  clientCreatedAt: Timestamp.now(),
  ...over,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "brainly-life-rules-m5",
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

describe("users/{uid}/aiConversations", () => {
  it("I can save the conversation and a message, then read them", async () => {
    await assertSucceeds(setDoc(doc(db(ME), CONVERSATION), conversation()));
    await assertSucceeds(setDoc(doc(db(ME), MESSAGE), message()));
    await assertSucceeds(setDoc(doc(db(ME), `${CONVERSATION}/messages/m2`),
      message({role: "assistant", text: "Sure!",
        actions: [{type: "start_focus"}]})));
    await assertSucceeds(getDoc(doc(db(ME), MESSAGE)));
  });

  it("another user or a signed-out user is refused", async () => {
    await assertFails(setDoc(doc(db(OTHER), MESSAGE), message()));
    await assertFails(setDoc(doc(db(), MESSAGE), message()));
    await assertSucceeds(setDoc(doc(db(ME), MESSAGE), message()));
    await assertFails(getDoc(doc(db(OTHER), MESSAGE)));
  });

  it("text must be 1 to 4000 characters", async () => {
    await assertSucceeds(setDoc(doc(db(ME), MESSAGE),
      message({text: "x".repeat(4000)})));
    await assertFails(setDoc(doc(db(ME), `${CONVERSATION}/messages/m2`),
      message({text: "x".repeat(4001)})));
    await assertFails(setDoc(doc(db(ME), `${CONVERSATION}/messages/m3`),
      message({text: ""})));
  });

  it("role must be user or assistant", async () => {
    await assertFails(setDoc(doc(db(ME), MESSAGE), message({role: "system"})));
  });

  it("extra fields, too many actions or a fake date are refused", async () => {
    await assertFails(setDoc(doc(db(ME), MESSAGE), message({isAdmin: true})));
    await assertFails(setDoc(doc(db(ME), MESSAGE), message({
      actions: Array(5).fill({type: "start_focus"}),
    })));
    await assertFails(setDoc(doc(db(ME), MESSAGE), message({
      createdAt: Timestamp.fromMillis(0),
    })));
  });

  it("messages cannot be edited, but can be deleted (clear)", async () => {
    await assertSucceeds(setDoc(doc(db(ME), MESSAGE), message()));
    await assertFails(updateDoc(doc(db(ME), MESSAGE), {text: "changed"}));
    await assertSucceeds(deleteDoc(doc(db(ME), MESSAGE)));
  });

  it("conversation: bad id or extra fields are refused", async () => {
    await assertFails(setDoc(
      doc(db(ME), `users/${ME}/aiConversations/bad id!`), conversation()));
    await assertFails(setDoc(doc(db(ME), CONVERSATION),
      {...conversation(), secret: "x"}));
  });
});
