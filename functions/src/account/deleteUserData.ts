// deleteUserData = runs by itself when a Firebase account is deleted
// (Settings > Delete account in the app, or from the Firebase console).
//
// It removes EVERYTHING of that user (Master Document D, security):
//   - users/{uid} and all its subcollections (tasks, habits, studyPlans,
//     aiUsage, weeklyReports, aiConversations/messages, ...)
//     with recursiveDelete
//   - the files in Storage under users/{uid}/ (the avatar)
//
// Why a trigger and not a function the app calls: it also runs if the app
// is closed in the middle, and nobody can call it for another user.
// (Auth triggers exist only in the v1 API; that is normal.)

import {getFirestore} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import * as logger from "firebase-functions/logger";
import * as functionsV1 from "firebase-functions/v1";

export async function deleteAllUserData(uid: string): Promise<void> {
  const db = getFirestore();
  // Works even when users/{uid} itself is already deleted: the
  // subcollections are found and removed too.
  await db.recursiveDelete(db.doc(`users/${uid}`));

  try {
    await getStorage().bucket().deleteFiles({prefix: `users/${uid}/`});
  } catch (error) {
    // No bucket or no files: the Firestore data is what matters.
    logger.warn("deleteUserData: storage cleanup skipped", {
      reason: error instanceof Error ? error.message : "unknown",
    });
  }
}

export const deleteUserData = functionsV1.auth.user().onDelete(async (user) => {
  await deleteAllUserData(user.uid);
  logger.info("deleteUserData: done"); // no uid or email in the logs
});
