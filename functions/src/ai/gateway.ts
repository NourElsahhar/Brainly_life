// The AI gateway logic (C.2, C.3). aiGateway.ts only wires it to Firebase,
// so this file can be tested with fakes (no emulator, no AI cost).
//
// For every call, in this order (cheap checks first, the AI last):
//   1. signed in?                        -> unauthenticated
//   2. { feature, payload } well formed? -> invalid_feature
//   3. feature in the registry?          -> invalid_feature
//   4. payload <= 20 KB?                 -> payload_too_large
//   5. payload valid for the feature?    -> invalid_feature (AI not called)
//   6. daily limit left?                 -> rate_limited
//   7. call the AI (JSON mode)           -> provider_unavailable
//   8. JSON + responseSchema + extra checks; if wrong, ONE repair retry
//                                        -> invalid_response
//   9. persist hook (optional)           -> internal if it fails
// Anything unexpected                    -> internal
//
// Logs: feature, status, duration and token counts only. NEVER the payload,
// the prompt or the answer (C.5).

import {z} from "zod";

import {AI_LIMITS, DEFAULT_TEMPERATURE, REPAIR_MESSAGE} from "./config";
import {AiProvider, ProviderError} from "./providers/aiProvider";
import {
  AiErrorCode,
  AiResponse,
  AiUsageInfo,
  FeatureModule,
  PromptContext,
} from "./types";
import {UsageStore} from "./usageStore";

import type {Firestore} from "firebase-admin/firestore";

export interface GatewayDeps {
  registry: ReadonlyMap<string, FeatureModule>;
  /** Created only when needed (no key is read for rejected calls). */
  provider: () => AiProvider;
  usage: UsageStore;
  db: Firestore;
  now: () => Date;
  log: (entry: GatewayLog) => void;
}

export interface GatewayLog {
  feature: string;
  status: "ok" | AiErrorCode;
  durationMs: number;
  attempts: number;
  inputTokens: number;
  outputTokens: number;
}

/** Short, safe messages. M5 maps the codes to the app's own texts. */
export const ERROR_MESSAGES: Record<AiErrorCode, string> = {
  unauthenticated: "Please sign in to use AI features.",
  invalid_feature: "This AI request is not valid.",
  payload_too_large: "This request is too large.",
  rate_limited: "You reached today's AI limit. Please try again tomorrow.",
  provider_unavailable:
    "The AI service is not available right now. Please try again later.",
  invalid_response: "The AI answer could not be used. Please try again.",
  internal: "Something went wrong. Please try again.",
};

const requestSchema = z.object({
  feature: z.string().min(1).max(64),
  // An object (not an array, not null).
  payload: z.record(z.string(), z.unknown()),
  promptVersion: z.number().int().optional(),
});

type Answer =
  | {ok: true; data: unknown}
  | {ok: false; stage: "json" | "schema" | "crossCheck"};

/** JSON.parse + responseSchema + validateAgainstPayload. */
export function checkAnswer(
  module: FeatureModule,
  payload: unknown,
  text: string,
): Answer {
  let json: unknown;
  try {
    json = JSON.parse(text);
  } catch {
    return {ok: false, stage: "json"};
  }
  const parsed = module.responseSchema.safeParse(json);
  if (!parsed.success) return {ok: false, stage: "schema"};
  const problems = module.validateAgainstPayload?.(payload, parsed.data) ?? [];
  if (problems.length > 0) return {ok: false, stage: "crossCheck"};
  return {ok: true, data: parsed.data};
}

export async function handleAiRequest(
  uid: string | undefined,
  data: unknown,
  deps: GatewayDeps,
): Promise<AiResponse> {
  const started = Date.now();
  const stats = {attempts: 0, inputTokens: 0, outputTokens: 0};
  let feature = "unknown";

  const fail = (code: AiErrorCode, usage?: AiUsageInfo): AiResponse => {
    deps.log({feature, status: code, durationMs: Date.now() - started, ...stats});
    return {
      ok: false,
      error: {code, message: ERROR_MESSAGES[code]},
      ...(usage ? {usage} : {}),
    };
  };

  try {
    // 1. Never trust a uid sent by the client: only request.auth.
    if (!uid) return fail("unauthenticated");

    // 2-3. The request and the feature.
    const request = requestSchema.safeParse(data);
    if (!request.success) return fail("invalid_feature");
    feature = request.data.feature;
    const module = deps.registry.get(feature);
    if (!module) return fail("invalid_feature");

    // 4. Size, before any heavy work.
    const bytes = Buffer.byteLength(JSON.stringify(request.data.payload), "utf8");
    if (bytes > AI_LIMITS.maxPayloadBytes) return fail("payload_too_large");

    // 5. The feature's own payload rules. Invalid -> no AI cost.
    const payload = module.payloadSchema.safeParse(request.data.payload);
    if (!payload.success) return fail("invalid_feature");

    // 6. Daily limits.
    const now = deps.now();
    const limits = {
      feature:
        module.dailyLimit ??
        AI_LIMITS.perFeaturePerDay[feature] ??
        AI_LIMITS.totalPerDay,
      total: AI_LIMITS.totalPerDay,
    };
    const reservation = await deps.usage.reserve(uid, feature, limits, now);
    const usage = {remainingToday: reservation.remainingToday, feature};
    if (!reservation.allowed) return fail("rate_limited", usage);

    // 7-8. Ask the AI, check the answer, one repair retry.
    const ctx: PromptContext = {uid, db: deps.db, now};
    const prompt = await module.buildPrompt(payload.data, ctx);
    const provider = deps.provider();
    const temperature = module.temperature ?? DEFAULT_TEMPERATURE;

    let answer: Answer = {ok: false, stage: "json"};
    for (let attempt = 0; attempt < 2 && !answer.ok; attempt++) {
      stats.attempts++;
      try {
        const reply = await provider.generate({
          system: prompt.system,
          user: attempt === 0 ? prompt.user : `${prompt.user}\n\n${REPAIR_MESSAGE}`,
          temperature,
        });
        stats.inputTokens += reply.inputTokens ?? 0;
        stats.outputTokens += reply.outputTokens ?? 0;
        answer = checkAnswer(module, payload.data, reply.text);
      } catch (error) {
        if (!(error instanceof ProviderError)) throw error;
        // Not the user's fault: give the call back.
        await deps.usage.release(uid, feature, reservation.dateKey);
        return fail("provider_unavailable", {
          remainingToday: reservation.remainingToday + 1,
          feature,
        });
      }
    }
    if (!answer.ok) return fail("invalid_response", usage);

    // 9. Save it when the feature wants that (weeklyReports...).
    if (module.persist) await module.persist(ctx, answer.data, payload.data);

    deps.log({feature, status: "ok", durationMs: Date.now() - started, ...stats});
    return {ok: true, data: answer.data, usage};
  } catch {
    return fail("internal");
  }
}
