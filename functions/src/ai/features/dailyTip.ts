// Daily tip prompt module (owner: M5).
// The app sends {} and gets one short general study tip. No user data.

import {z} from "zod";

import type {AiPrompt} from "../types";

export const feature = "dailyTip";
export const promptVersion = 1;
/** A bit of variety for tips (Master C.4 rule 3). */
export const temperature = 0.7;

export const payloadSchema = z.object({}).strict();
export const responseSchema = z.object({
  tip: z.string().trim().min(1).max(240),
}).strict();

/**
 * Builds the prompt (no user data at all).
 * @return {AiPrompt} The system and user messages.
 */
export function buildPrompt(): AiPrompt {
  return {
    system: [
      "You write short daily productivity tips for students.",
      "Give one actionable, general suggestion. Avoid personal claims and " +
        "medical, legal or harmful advice.",
      "Return JSON only, with exactly {tip: string}. " +
        "The tip must be at most 240 characters.",
      "Example: {\"tip\":\"Pick one task you can finish before checking " +
        "your inbox.\"}",
    ].join("\n"),
    user: "Give today's tip as JSON.",
  };
}
