// All the AI limits and settings in ONE place (Master Document C.5).
// Change a number here, deploy, done.

/** The features the app may ask for (C.3). */
export const KNOWN_FEATURES = [
  "studyPlan",
  "habitSuggest",
  "chat",
  "dailyTip",
  "weeklyInsight",
] as const;

export const AI_LIMITS = {
  /** All AI calls of one user in one day, every feature together. */
  totalPerDay: 30,
  /** Per feature, per user, per day. A module's dailyLimit wins. */
  perFeaturePerDay: {
    chat: 20,
    studyPlan: 5,
    weeklyInsight: 3,
  } as Record<string, number>,
  /** The client payload, as JSON text. */
  maxPayloadBytes: 20 * 1024,
};

/** Used when a module does not set its own temperature. */
export const DEFAULT_TEMPERATURE = 0.3;

/** The Gemini model. Change it here only. */
export const GEMINI_MODEL = "gemini-2.5-flash";

/** One provider call may take this long, then it is cancelled. */
export const PROVIDER_TIMEOUT_MS = 25_000;

/** Sent once when the first answer is not valid JSON (C.4 rule 4). */
export const REPAIR_MESSAGE = [
  "Your previous answer could not be used: it was not valid JSON or it did",
  "not follow the rules and the exact shape described above.",
  "Reply again with one JSON object only. No markdown, no code fences, no",
  "text before or after the JSON.",
].join("\n");
