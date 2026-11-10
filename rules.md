# OctetPulse Autonomous Engineering Governance & Memory Rules

This document specifies the strict operational rules for the OctetPulse repository. Whenever the user prompts "run daily sprint" (or "run sprint" / "next sprint"), you MUST execute the following 6-Phase Protocol without skipping any phase.

---

## MANDATORY 6-PHASE PROTOCOL FOR "run daily sprint"

### PHASE 1: PRE-FLIGHT HEALTH CHECK (BEFORE TOUCHING NEW CODE)
- Never start a new feature on a broken or dirty repository.
- Run:
  1. `git status` and `git pull --rebase origin main` (ensure local branch is synced with GitHub).
  2. `flutter pub get`
  3. `flutter analyze`
  4. `flutter test`
- If ANY pre-flight error, warning, or unpushed commit exists from a previous session, fix and resolve it FIRST before reading the backlog.

### PHASE 2: BACKLOG SELECTION & ARCHITECTURAL PLANNING
- Open `docs/AUTONOMOUS_BACKLOG.md` and select the first `[ ]` item.
- If all items in `docs/AUTONOMOUS_BACKLOG.md` are marked `[x]`, autonomously generate 15 new senior-level architectural or feature sprints in `docs/AUTONOMOUS_BACKLOG.md` and select the first new `[ ]` item.

### PHASE 3: PRODUCTION IMPLEMENTATION & UI SAFETY
- Implement the selected feature end-to-end across `data/`, `domain/`, and `presentation/` following SOLID, DRY, and Clean Architecture.
- Enforce strict UI & Runtime Safety:
  - Zero emojis anywhere in code, UI strings, logs, or commit messages. Use vector Material Symbols / Icons exclusively.
  - Zero hardcoded colors (`Theme.of(context).colorScheme` only; test both Dark and Light mode).
  - Explicit unique `heroTag` on every `FloatingActionButton`.
  - 360dp-height landscape safety (independent scroll controllers, explicit `mainAxisExtent` on grids, edge-to-edge charts).
  - Every button, chip, dialog, and share sheet must be 100% wired and functional (`AppFeedback` toasts + inline form validation).

### PHASE 4: AUTOMATED & LIVE DEVICE RUNTIME VERIFICATION
- Add or update unit and widget tests in `test/` covering the new feature AND verifying zero landscape overflow (800x360 viewport).
- Execute `dart run tool/sprint_gate.dart` (runs `flutter pub get` -> `dart format lib test` -> `flutter analyze` -> `flutter test` -> connected device smoke test).
- LIVE DEVICE RUN CHECK: If a physical device or mobile emulator is connected, run the app on the connected device, wait for the SplashView transition to the main shell, and inspect runtime logs (`adb logcat -d` / console output). If ANY runtime error, `Hero` tag collision, state warning, or layout overflow appears on the device, fix the code and re-run until 0 runtime issues occur.

### PHASE 5: ATOMIC GIT COMMIT & GUARANTEED GITHUB PUSH
- Mark the completed item as `[x]` in `docs/AUTONOMOUS_BACKLOG.md`.
- Stage all files: `git add -A`
- Commit with a clean conventional commit message (no emojis):
  `git commit -m "feat(<module>): <concise senior description>"`
- Push to GitHub:
  `git push origin main`

### PHASE 6: POST-PUSH PROOF VERIFICATION (NEVER SKIP)
- After running `git push origin main`, you MUST execute:
  `git status -sb` AND `git log origin/main..HEAD --oneline`
- Verify that `git log origin/main..HEAD` returns 0 unpushed commits and working tree is 100% clean.
- If the push failed due to network timeout or remote changes, run `git pull --rebase origin main` and `git push origin main` again until remote sync is confirmed.
- Report the exact Commit SHA, modified files, test count, device runtime status, and confirmed `origin/main` push status to the user.
