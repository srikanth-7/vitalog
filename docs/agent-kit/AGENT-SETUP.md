# AI Agent Setup: Srikanth's portable kit

> **To the agent reading this (Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot, Windsurf, or anything else):**
> set up this machine or project so you work the way the user expects.
> 1. Work out which agent you are and find your row in the **Agent map** (§1). If you're not listed, use the "Other" row.
> 2. Do **§2 Install** for your agent. Confirm each step before moving on.
> 3. Write **§3 Rules** into your agent's global instructions file. These rules matter most; follow them from now on.
> 4. **§4** applies only to a Flutter/GetX project.
> Never invent tokens or secrets. If a step needs one, ask the user. If you're unsure of a path for your agent, check your own docs rather than guessing.

Kit contents (keep these two files together):
- `AGENT-SETUP.md`: this file
- `claude-kit-bundle.tar.gz`, which unpacks to:
  - `skills/`: 16 skill folders, each a `SKILL.md` plus references (the open Agent Skills format)
  - `commands/`, `statusline.sh`, `shutdown-summarizer-guide.md`: Claude Code extras
  - `templates/project/.claude/`: Flutter project agents, commands and skills

---

## 1. Agent map

| Agent | Global rules file (§3 goes here) | Project rules file | Skills folder | MCP config |
|---|---|---|---|---|
| **Claude Code** | `~/.claude/CLAUDE.md` | `CLAUDE.md` | `~/.claude/skills/` | `claude mcp add …` / `.mcp.json` |
| **OpenAI Codex CLI** | `~/.codex/AGENTS.md` | `AGENTS.md` | `~/.codex/skills/` | `~/.codex/config.toml` → `[mcp_servers.<name>]` |
| **Cursor** | Settings → Rules → User Rules (paste) | `AGENTS.md` or `.cursor/rules/*.mdc` | `.cursor/skills/` (if supported), else see note | `~/.cursor/mcp.json` |
| **Gemini CLI** | `~/.gemini/GEMINI.md` | `GEMINI.md` (or set `contextFileName: "AGENTS.md"`) | extensions / see note | `~/.gemini/settings.json` → `mcpServers` |
| **GitHub Copilot** | VS Code user instructions | `.github/copilot-instructions.md` or `AGENTS.md` | `.github/skills/` | `.vscode/mcp.json` |
| **Windsurf** | `global_rules.md` (Settings → Rules) | `.windsurf/rules/` or `AGENTS.md` | see note | `~/.codeium/windsurf/mcp_config.json` |
| **Other** | its global instructions file | `AGENTS.md` (the cross-agent standard) | `~/.agents/skills/` | its MCP config |

**Skills note:** if your agent has no native skills folder, still unpack them to `~/.agents/skills/`, then add this line to your rules file:
*"Before each task, scan `~/.agents/skills/*/SKILL.md` front-matter (`name` and `description`). When one matches the task, read that SKILL.md fully and follow it."*

---

## 2. Install

### 2.1 Every agent
```bash
# Unpack the kit
tmp=$(mktemp -d) && tar -xzf claude-kit-bundle.tar.gz -C "$tmp"
SKILLS_DIR=~/.agents/skills        # ← replace with your skills folder from §1
mkdir -p "$SKILLS_DIR" && cp -R "$tmp"/skills/* "$SKILLS_DIR"/
echo "templates: $tmp/templates/project/.claude"
```
Skills installed (16):

| Area | Skills |
|---|---|
| UI / design review | `impeccable`, `apple-hig`, `apple-design`, `emil-design-eng`, `mobile-native`, `pick-ui-library`, `prototype` |
| Motion | `animate`, `animate-expo`, `animation-vocabulary`, `find-animation-opportunities`, `improve-animations`, `review-animations` |
| Native / libraries | `write-swift`, `ask-sonner` |
| Hard problems | `arena` (multi-agent tournament; ask before running, it's expensive) |

**Corporate network (FortiGate):** if downloads fail with TLS errors, export the firewall CA into `~/.certs/ca-bundle.pem` and set `NODE_EXTRA_CA_CERTS`, `SSL_CERT_FILE` and `REQUESTS_CA_BUNDLE` to it in `~/.zshrc`. If a site is blocked outright (npm, some Apple endpoints), use a phone hotspot for that one download.

**Dart/Flutter MCP server** (works with any MCP-capable agent; needs Dart SDK ≥ 3.9): register command `dart` with args `["mcp-server"]` in your agent's MCP config from §1. Example for Codex:
```toml
[mcp_servers.dart]
command = "dart"
args = ["mcp-server"]
```

**graphify** (optional code knowledge graph): `uv tool install graphifyy`, then run `graphify update .` in the project root. Rule to add: *"If `graphify-out/graph.json` exists, run `graphify query "<question>"` before grepping."*

### 2.2 Claude Code only
```
/plugin marketplace add anthropics/claude-plugins-official
/plugin marketplace add DietrichGebert/ponytail
/plugin marketplace add flutter/agent-plugins
/plugin marketplace add Jakeschincariol/replica-skill
/plugin install superpowers@claude-plugins-official
/plugin install ponytail@ponytail
/plugin install dart-flutter@dart-flutter
/plugin install swift-lsp@claude-plugins-official
/plugin install replica-skill@replica-skill
/plugin install telegram@claude-plugins-official      # optional, needs a bot token
```
```bash
cp -R "$tmp"/commands/* ~/.claude/commands/
cp "$tmp"/statusline.sh ~/.claude/ && chmod +x ~/.claude/statusline.sh
cp "$tmp"/shutdown-summarizer-guide.md ~/.claude/
```
Merge into `~/.claude/settings.json`:
```json
{
  "model": "opus[1m]", "theme": "dark", "switchModelsOnFlag": true,
  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" },
  "hooks": {
    "PreToolUse":   [{ "matcher": "AskUserQuestion", "hooks": [{ "type": "command", "command": "afplay /System/Library/Sounds/Ping.aiff" }] }],
    "Stop":         [{ "hooks": [{ "type": "command", "command": "afplay /System/Library/Sounds/Glass.aiff" }] }],
    "Notification": [{ "hooks": [{ "type": "command", "command": "afplay /System/Library/Sounds/Funk.aiff" }] }]
  }
}
```

### 2.3 Other agents: equivalents of the Claude plugins
- **superpowers** (brainstorm → plan → TDD → debug → review): its repo (`obra/superpowers`) also ships setups for Codex, Cursor and others. Install it if your agent is supported. Otherwise the §3 rules cover the essentials.
- **ponytail** (minimal-diff, no over-engineering): no install needed. Its rules are in §3 under "How to code".
- **Sound/notification hooks:** use your agent's own notification setting if it has one, or skip them.

---

## 3. Rules: how to work with me (write into your global rules file from §1)

```markdown
# Working with Srikanth (all projects, all agents)

## Ask before acting
- **Confirm before edits.** Read, analyze and explain freely, but propose each code change (file + what + why) and wait for an explicit yes before writing. An approval covers only that change, not later fixes, even one-liners or fixes to code you just wrote. "Check / cross-check / lmk" means report findings, not fix them.
- **Never run the app** (flutter run, simulators, emulators, launching builds) without an explicit go-ahead. Prepare it, then ask.
- **Ask before heavy token or compute use.** Prefer a direct file read/search. Ask before spawning several sub-agents or doing deep multi-file sweeps.
- **Outward-facing git actions** (push, force-push, MR changes, history rewrites) need explicit confirmation. Prefer `git revert` over force-push. Before removing files from an MR, check which branch it merges into.

## Planning
- When asked to plan, write and update the plan file and stop. Don't start implementing until I say so.
- At the start of every task, check ALL installed skills. Name the ones you're using in one line, then follow them (UI: impeccable / apple-hig / emil-design-eng / mobile-native; motion: animate / review-animations; native iOS: write-swift). Expensive multi-agent skills (arena) need a yes first.
- Verify sub-agent claims: confirm any reported file, class or line exists before planning or coding on it.

## How to code
- Minimal and correct: understand the problem fully first, then make the shortest diff that fixes the root cause. Reuse what's already in the repo, then stdlib/native, then installed dependencies. Never add a dependency for a few lines. No speculative abstractions or "for later" scaffolding.
- **No unrequested tests.** Verify with the analyzer/linter and existing tests only.
- Never hand-write generated files (`*.g.dart`, `*.freezed.dart`, codegen output). Write the source and tell me to run the generator.
- Proactively use efficient data structures (Map/Set lookups instead of nested scans) and name the technique inline. Don't over-engineer.
- Use modern language features in new code (Dart 3: records, sealed classes, switch expressions). Don't retrofit working code.
- During migrations, don't delete legacy code. Repoint navigation to the new code and leave the old code as fallback.
- No hardcoded strings/numbers when the project has constants classes. User-facing text goes through localization.
- Match the surrounding code's style, naming and comment density.

## Communication
- Be concise, lead with the answer, and report honestly (say if something wasn't verified on a device).
- For screenshots/designs, trace the real cause in code before proposing a fix.
```

---

## 4. Optional Flutter / GetX project template

`$tmp/templates/project/.claude/` contains the HCM project's tooling, written for Claude Code. For other agents, copy the files and treat them as reusable prompts (Codex/Cursor/Copilot: save them as prompt files or custom commands):
- `agents/feature-planner.md`: read-only architect that maps a feature and writes a plan
- `agents/html-to-flutter.md`: HTML mockup → Flutter screens using the project's components
- `agents/sentry-fixer.md`: Sentry crash triage and fix
- `commands/`: `new-feature`, `summarize`, `resume-summary`, `session-handoff`, `sentry-morning`
- `skills/code-review`, `skills/hcm-flutter-feature-guide`: install these as project skills

Project conventions (put them in the project's `AGENTS.md` / `CLAUDE.md`):
- Layering is View → ViewModel (GetxController, Rx) → Repository (`.shared` singleton) → ApiManager/ApiImplementation → GraphQL/Dio. Register ViewModels with `Get.lazyPut(..., fenix: true)`. Use GetX only. No Provider/Riverpod/BLoC.
- New features go in the new-UI folder (`lib/hcm_4.0/`) using its components only, never legacy widgets.
- Enums go in the shared `core/enums/enums.dart`. ViewModels over 500 lines move payload/API code into a sibling `_api_payload.dart` extension file.
- Constants: `HCMStringConstants`, `IntegerConstants`, `Numbers` (spacing/radius tokens). Strings via `tr(LocaleKeys.x)` from `assets/translations/en.json`.
- Generated `.g.dart` files stay out of feature MRs unless the team says otherwise.
- Commands: `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`.

Safe auto-approve list (add to your agent's permission/allow-list): `flutter analyze`, `dart analyze`, `dart run`, `flutter pub`, `xcrun simctl`, `xcrun devicectl`, `adb devices`. Block agent writes to `ios/`, `android/` and `docs/` unless asked.

### Secrets to set up by hand (never commit them, never put them in allow-lists or rules files)
| What | Where |
|---|---|
| GitLab personal access token | `GITLAB_TOKEN` in `~/.zshrc` or the keychain |
| Sentry token | keychain service `sentry-akrivia` |
| Figma token | keychain service `figma-akrivia` |
| Telegram bot token | Claude: `/telegram:configure` |
