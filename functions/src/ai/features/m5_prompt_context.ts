import type { Firestore } from 'firebase-admin/firestore';

export interface M5PromptContext {
  uid: string;
  firestore: Firestore;
  now?: () => Date;
}

export function userDocument(ctx: M5PromptContext) {
  return ctx.firestore.collection('users').doc(ctx.uid);
}

export function untrustedData(value: unknown): string {
  return '<user_data>\n' + JSON.stringify(value).replaceAll('<', '\\u003c') + '\n</user_data>';
}

export function cleanUserText(text: string, privateValues: string[]): string {
  let clean = text.replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, '[redacted]');
  for (const value of privateValues) {
    const trimmed = value.trim();
    if (trimmed.length < 2) continue;
    const escaped = trimmed.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    clean = clean.replace(new RegExp(escaped, 'giu'), '[redacted]');
  }
  return clean;
}

export function currentWeekKey(now: Date, timezone: string, startDay: number): string {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone, year: 'numeric', month: 'numeric', day: 'numeric',
  }).formatToParts(now);
  const part = (type: string) => Number(parts.find((entry) => entry.type === type)?.value);
  const day = new Date(Date.UTC(part('year'), part('month') - 1, part('day')));
  const millis = 86400000;
  const start = (value: Date) => new Date(
    value.getTime() - ((value.getUTCDay() - (startDay % 7) + 7) % 7) * millis,
  );
  const beginning = start(day);
  const year = new Date(beginning.getTime() + 3 * millis).getUTCFullYear();
  const first = start(new Date(Date.UTC(year, 0, 4)));
  const week = Math.floor((beginning.getTime() - first.getTime()) / (7 * millis)) + 1;
  return year + '-W' + String(week).padStart(2, '0');
}
