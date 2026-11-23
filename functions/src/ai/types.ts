// Shared types of the AI gateway (Master Document C.3).
//
// A feature owner writes ONE module in src/ai/features/<name>.ts that
// matches FeatureModule, then adds one line to registry.ts. Example: the
// studyPlan module (M2).

import type {Firestore} from "firebase-admin/firestore";
import type {z} from "zod";

/** The only error codes the gateway returns. No owner adds new ones. */
export const AI_ERROR_CODES = [
  "unauthenticated",
  "invalid_feature",
  "payload_too_large",
  "rate_limited",
  "provider_unavailable",
  "invalid_response",
  "internal",
] as const;

export type AiErrorCode = (typeof AI_ERROR_CODES)[number];

/** Given to buildPrompt and persist. Never send uid to the AI provider. */
export interface PromptContext {
  /** The signed-in user (from request.auth, never from the client data). */
  uid: string;
  /** Admin Firestore, to read the user's data on the server. */
  db: Firestore;
  /** The time of the request. */
  now: Date;
}

/** The two messages sent to the AI provider. */
export interface AiPrompt {
  system: string;
  user: string;
}

/* eslint-disable @typescript-eslint/no-explicit-any */
/** What every feature module exports (see functions/README.md). */
export interface FeatureModule<P = any, R = any> {
  /** The name the Flutter app sends, for example "studyPlan". */
  feature: string;
  /** Checks the client payload. Invalid -> the AI is never called. */
  payloadSchema: z.ZodType<P, any, any>;
  /** Checks the AI answer (after JSON.parse). */
  responseSchema: z.ZodType<R, any, any>;
  /** Builds the prompt from the validated payload. */
  buildPrompt(payload: P, ctx: PromptContext): AiPrompt | Promise<AiPrompt>;
  /** Optional extra checks of the answer against the payload. */
  validateAgainstPayload?(payload: P, response: R): string[];
  /** Optional: saves the answer (for example weeklyReports). */
  persist?(ctx: PromptContext, data: R, payload: P): Promise<void>;
  /** Calls per user per day for this feature (else config.ts). */
  dailyLimit?: number;
  /** 0.2-0.4 for structured features, 0.7 for chat (C.4 rule 3). */
  temperature?: number;
  promptVersion?: number;
}
/* eslint-enable @typescript-eslint/no-explicit-any */

/** What the Flutter app sends (C.3). */
export interface AiRequest {
  feature: string;
  payload: Record<string, unknown>;
  promptVersion?: number;
}

export interface AiUsageInfo {
  remainingToday: number;
  feature: string;
}

/** What the Flutter app receives (C.3). */
export type AiResponse =
  | {ok: true; data: unknown; usage: AiUsageInfo}
  | {
      ok: false;
      error: {code: AiErrorCode; message: string};
      usage?: AiUsageInfo;
    };
