// Shared helpers of M5's prompt modules (chat, dailyTip, weeklyInsight).
// They use the gateway's PromptContext {uid, db, now} like every module.

import type {PromptContext} from "../types";

/**
 * The signed-in user's document.
 * @param {PromptContext} ctx The gateway context.
 * @return {FirebaseFirestore.DocumentReference} users/{uid}.
 */
export function userDocument(ctx: PromptContext) {
  return ctx.db.collection("users").doc(ctx.uid);
}

/**
 * Wraps user data in a fenced block, so the AI treats it as data.
 * "<" is escaped so the data can never close the block.
 * @param {unknown} value Any JSON value.
 * @return {string} The block.
 */
export function untrustedData(value: unknown): string {
  return "<user_data>\n" +
    JSON.stringify(value).replaceAll("<", "\\u003c") +
    "\n</user_data>";
}

/**
 * Removes e-mail addresses and the user's own identifiers from free text.
 * @param {string} text The text written by the user.
 * @param {string[]} privateValues uid, name, e-mail...
 * @return {string} The cleaned text.
 */
export function cleanUserText(text: string, privateValues: string[]): string {
  let clean = text.replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, "[redacted]");
  for (const value of privateValues) {
    const trimmed = value.trim();
    if (trimmed.length < 2) continue;
    const escaped = trimmed.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    clean = clean.replace(new RegExp(escaped, "giu"), "[redacted]");
  }
  return clean;
}

/**
 * The ISO-like week key (yyyy-Www) of [now] in the user's time zone,
 * with the user's first day of the week (1 = Monday ... 7 = Sunday).
 * @param {Date} now The moment.
 * @param {string} timezone IANA time zone.
 * @param {number} startDay First day of the week.
 * @return {string} For example "2026-W47".
 */
export function currentWeekKey(
  now: Date,
  timezone: string,
  startDay: number,
): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone, year: "numeric", month: "numeric", day: "numeric",
  }).formatToParts(now);
  const part = (type: string) =>
    Number(parts.find((entry) => entry.type === type)?.value);
  const day = new Date(Date.UTC(part("year"), part("month") - 1, part("day")));
  const millis = 86400000;
  const start = (value: Date) => new Date(
    value.getTime() -
      ((value.getUTCDay() - (startDay % 7) + 7) % 7) * millis,
  );
  const beginning = start(day);
  const year = new Date(beginning.getTime() + 3 * millis).getUTCFullYear();
  const first = start(new Date(Date.UTC(year, 0, 4)));
  const week =
    Math.floor((beginning.getTime() - first.getTime()) / (7 * millis)) + 1;
  return year + "-W" + String(week).padStart(2, "0");
}

