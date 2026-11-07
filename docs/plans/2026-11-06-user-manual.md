# Plan — Vitalog user manual + app guide (2026-11-06)

Two PDFs, both in `docs/manual/`:

| PDF | Reader | What it covers |
|---|---|---|
| `Vitalog_User_Manual.pdf` | People using the app (incl. older family members, testers, native-speaker reviewers) | How to do each task, with screenshots. Plain words, no code. |
| `Vitalog_App_Guide.pdf` | Product owner, new developers, new agents | Every feature and how it works underneath, privacy/security model, backend, project history (all sessions 2026-10-26 → 2026-11-06), status and pending work. |

## User manual — chapters

1. **Welcome** — what Vitalog is (family lab reports in one place), what it is not (no diagnosis, no health score), privacy promise (read on the phone; nothing leaves until Sync).
2. **First launch** — splash, 3 welcome pages, sign in or *Continue without an account*, first-run tour.
3. **The screen at a glance** — bottom tray: member switcher, Add a report, tabs (Home, Categories, Reports, Family).
4. **Add your family** — add member (name, relation, sex, birth year, photo), edit, remove, switch member.
5. **Add a lab report** — camera / photos / any file; *Reading…*; ready / needs review / couldn't read; Try again, Cancel; wrong person → Move to…; duplicates.
6. **Home dashboard** — At a glance, Needs attention, trends ("Up 3 times in a row"), latest report, categories, recent results.
7. **Categories** — tested groups, "Not yet: …", "Yet to test", "When your doctor advises".
8. **A test's history** — chart over the printed range, every dated value, Edit (fix a value, pick a category, Looks right, compare with original).
9. **Reports timeline** — open a report's own dashboard, delete, pull to refresh.
10. **Reminders** — bell on Home, add a reminder, what the lock screen shows.
11. **Display settings** — Simple mode, Home sections, theme, accent, language (English / తెలుగు / हिन्दी).
12. **Privacy & security** — encryption, Face ID / fingerprint lock on originals, app-switcher cover.
13. **Account, Sync and backup** — sign in, Sync, recovery key (save it!), restore on a new phone, delete account.
14. **Share with family** — invite link, family card, accept an invite, combine "You" profiles.
15. **Big screens & sideways** — iPhone Duo / foldables: side tray, two panes.
16. **Troubleshooting & FAQ** — couldn't read, needs review, wrong status, Sync not set up, lost recovery key.

## Screenshots

- **How:** `integration_test/manual_screenshots_test.dart` drives the real app
  on the iOS simulator (iPhone 16 Plus) with the built-in sample family
  (Maya, Arjun, Anika, Meera — made-up values), driver
  `test_driver/manual_screenshots.dart` saves PNGs to
  `docs/manual/screens/`. Re-run any time the UI changes:
  `flutter drive --driver test_driver/manual_screenshots.dart --target integration_test/manual_screenshots_test.dart -d "iPhone 16 Plus"`
- Its data lives in a temp folder with fixed test keys, so it never touches
  real reports on the simulator or the Keychain.
- **List:** welcome pages 1–3, sign-in offer, empty Home (new user), Home
  with data, Needs attention / trends, Categories, category results, test
  history, Edit sheet, Reports timeline, add-report sheet, report dashboard,
  Family tab, add-member sheet, display settings, Simple mode Home, dark
  theme Home, reminders.
- **Not captured (needs a server / real device):** Sync, recovery key sheet,
  invite/claim screens, camera, Face ID prompt. Described in words only.

## Build

- HTML (one file per PDF, print CSS) → PDF with headless Chrome
  (`--print-to-pdf`). No new Python packages (system Python 3.9 can't run
  current reportlab).
- Sources kept in `docs/manual/src/` so the PDFs can be rebuilt.

## Done when

- Both PDFs open, every page renders, every screenshot appears.
- Manual matches the app as of 2026-11-06 (Sync/sharing marked "needs the
  server set up" where true).
- `flutter analyze` still clean.
