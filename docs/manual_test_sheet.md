# Manual test sheet (QA lead: M4)

How to use: pick a build from `develop`, go through every row, write the result
(OK / bug number) in the column of the device. Report bugs in GitHub Issues with
the label `bug` and one of `P1` (blocks release), `P2`, `P3`.

Devices: small phone (about 5"), large phone (about 6.7"), light mode, dark mode.

## Every screen (all members)

| Screen | Small phone | Large phone | Light | Dark | Offline | Loading, empty, error shown |
| --- | --- | --- | --- | --- | --- | --- |
| Splash / onboarding / login / register | | | | | | |
| Home | | | | | | |
| Tasks (list, form, detail, categories) | | | | | | |
| Plan (subjects, plan, detail) | | | | | | |
| Habits (list, form, detail) | | | | | | |
| Focus (timer, settings, stats) | | | | | | |
| AI assistant | | | | | | |
| Profile and settings | | | | | | |

## Habits

| # | Check | Result |
| --- | --- | --- |
| H1 | Empty state shows the 3 quick habits; tapping one fills the name and icon | |
| H2 | Create daily, weekdays and times-per-week habits | |
| H3 | Validation errors show under the field (empty name, no weekday, name over 50) | |
| H4 | Same name as an active habit is rejected | |
| H5 | Check a habit; the ring and the streak update at once | |
| H6 | Turn the network off and check a habit: it rolls back with an error, or syncs later | |
| H7 | Detail: calendar, streaks and rates look right; change month | |
| H8 | Tap a day up to 7 days back: marks and unmarks; older days and future days do nothing | |
| H9 | Edit a habit (name, start date, frequency); the numbers stay right | |
| H10 | Archive asks first; the habit leaves the list | |
| H11 | Delete asks first; the habit and its logs are gone | |
| H12 | Habit that is not due today does not show; "nothing due today" shows when none is due | |
| H13 | A streak keeps going when today is not done yet, and breaks after a missed day | |

## Focus

| # | Check | Result |
| --- | --- | --- |
| F1 | Start, pause, resume, stop work; the ring and the time are right | |
| F2 | Lock the phone for 2 minutes and unlock: the time is still correct | |
| F3 | Close the app while it runs and open it again: it continues | |
| F4 | Close the app, wait until the time is over, open it: it shows "finished" and the session is saved once | |
| F5 | Focus, short break, focus, long break order is right (change the settings to short times) | |
| F6 | Sound and vibration play when a block ends; both can be turned off | |
| F7 | Keep screen on works while the timer runs | |
| F8 | Stop before 1 minute saves nothing; after 1 minute saves a partial session | |
| F9 | Opened from a task or a study session: the link label shows, and study minutes are added | |
| F10 | Settings: +/- stay inside the limits, changes are kept after closing the app, reset works | |
| F11 | Stats: today, week, streak, 7-day chart, best time, history; empty state when no sessions | |

## Data and accounts

| # | Check | Result |
| --- | --- | --- |
| D1 | Two accounts: account B never sees the habits or sessions of account A | |
| D2 | Sign out and sign in on a second device: habits and sessions are there | |
| D3 | Fresh install shows the onboarding once; closing and opening it again does not | |
| D4 | Change the phone timezone: days (dateKeys) and streaks stay consistent | |
| D5 | Text size at the largest setting: nothing is cut or overlaps | |
| D6 | Every tap target is at least 48 dp | |
