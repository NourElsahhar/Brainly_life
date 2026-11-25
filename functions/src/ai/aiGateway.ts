// aiGateway = the callable Cloud Function the Flutter app calls
// (M5's CloudFunctionsAiClient: FirebaseFunctions.instance
// .httpsCallable('aiGateway')). All the logic is in gateway.ts.
//
// The Gemini key is a secret (C.6):
//   production: firebase functions:secrets:set GEMINI_API_KEY
//   emulator:   functions/.secret.local  ->  GEMINI_API_KEY=your-own-key
// It never goes in the repository or in the app.
//
// Region: us-central1 (the default of FirebaseFunctions.instance in Flutter,
// so the app needs no region setting).

import {getFirestore} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import {defineSecret} from "firebase-functions/params";
import {onCall} from "firebase-functions/v2/https";

import {handleAiRequest} from "./gateway";
import {GeminiProvider} from "./providers/geminiProvider";
import {registry} from "./registry";
import {FirestoreUsageStore} from "./usageStore";

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

export const aiGateway = onCall(
  {
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 60,
    memory: "256MiB",
    maxInstances: 10,
    // Turn on before the public release, with App Check in the app (C.5).
    enforceAppCheck: false,
  },
  (request) => {
    const db = getFirestore();
    return handleAiRequest(request.auth?.uid, request.data, {
      registry,
      db,
      provider: () => new GeminiProvider(GEMINI_API_KEY.value()),
      usage: new FirestoreUsageStore(db),
      now: () => new Date(),
      log: (entry) => logger.info("aiGateway", entry),
    });
  },
);
