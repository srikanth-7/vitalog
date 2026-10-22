# Vitalog — Family Health

Offline-first family health records. Upload a lab report (photo or PDF); it is
read on the phone, every test is filed into its category, and each report gets
its own place on a timeline. Cloud backup (Supabase) happens only when you tap
Sync.

- **Start here:** [`AGENTS.md`](AGENTS.md) — architecture, rules, data flow.
- Backend spec: [`docs/SUPABASE_REQUIREMENTS.md`](docs/SUPABASE_REQUIREMENTS.md) · schema: [`supabase/schema.sql`](supabase/schema.sql)
- What's left: [`docs/PENDING_TASKS.md`](docs/PENDING_TASKS.md)
- Code graph: `graphify-out/GRAPH_REPORT.md` (refresh with `graphify update .`)

```bash
flutter pub get
flutter run -d "iPhone 16 Plus"   # simulator, no Apple account needed
flutter test
```
