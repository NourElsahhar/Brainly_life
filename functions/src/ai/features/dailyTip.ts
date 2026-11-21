import { z } from 'zod';

export const feature = 'dailyTip';
export const promptVersion = 1;
export const payloadSchema = z.object({}).strict();
export const responseSchema = z.object({ tip: z.string().trim().min(1).max(240) }).strict();

export function buildPrompt(): string {
  return [
    'You write short daily productivity tips for students.',
    'Give one actionable, general suggestion. Avoid personal claims and medical, legal or harmful advice.',
    'Return JSON only, with exactly {tip: string}. The tip must be at most 240 characters.',
    'Example: {"tip":"Pick one task you can finish before checking your inbox."}',
  ].join('\n');
}
