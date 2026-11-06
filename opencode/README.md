# opencode/ — agent workspace

This folder is the **persistent memory of the OpenCode agents** working on
Vitalog. Plans, audits, decisions and a complete change log live here so that
any agent taking over a session (OpenCode, Codex, a human reviewer) can
understand what happened without reading chat transcripts.

> **Not to be confused with `.opencode/`** (hidden) — that directory holds
> OpenCode *configuration* (skills, config). This folder holds agent *work
> products*. It is safe to commit to git.

## Structure

```
opencode/
├── README.md            ← you are here: purpose + rules
├── HANDOFF.md           ← ALWAYS read this first when taking over
├── plans/
│   ├── 2026-10-24-security-audit.md        completed audits & reports
│   └── 2026-10-24-security-hardening.md    active plans (with status)
└── log/
    └── changes.md       ← append-only log of every change agents make
```

## Rules for every agent

1. **Read `HANDOFF.md` first**, then the newest file in `plans/`.
2. **Every change gets a `log/changes.md` entry** — code, config, docs,
   even read-only analyses (so gaps in history are explainable).
3. **Append-only**: never delete or rewrite another agent's entries.
   If something was wrong, add a new entry that supersedes it.
4. **Plans carry status.** Each plan file starts with a Status/progress
   table; tick items off there as they complete.
5. **Date-prefix filenames** in `plans/` (`YYYY-MM-DD-topic.md`). New plan,
   new file — don't cram a new effort into an old plan file.
6. **Session IDs go in entries.** Find yours from your OpenCode session list.
7. `AGENTS.md` still governs the app code itself. This folder is agent
   meta-work only — never import from `lib/`, never put app code here.

## One-line summary of the project

Offline-first family health record (Flutter) — lab reports are read on-device
by OCR, never leaving the phone unless the user taps Sync (Supabase,
sign-in required). See `AGENTS.md` for the full guide.
