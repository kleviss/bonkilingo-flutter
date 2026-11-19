# Bonkilingo roadmap: iOS keyboard (Bonkilingo 2.0)

Status: **proposal, awaiting review** (2026-11-19). Architecture and rationale:
[BONKILINGO_ARCHITECTURE.md](BONKILINGO_ARCHITECTURE.md).

Goal: correct a message directly inside WhatsApp, iMessage, Gmail and Instagram with a Bonkilingo
keyboard, reusing the existing Express correction API and Supabase accounts. No rewrite of the
Flutter or Next.js apps.

Estimates assume one developer familiar with the codebase. "Days" means focused working days.

---

## Phase 0: Prerequisites (1–2 days)

These are needed for TestFlight anyway.

- [x] Deploy `bonkilingo-backend` to HTTPS: Vercel project `bonkilingo-backend` (team
      klv-bonk's projects), https://bonkilingo-backend.vercel.app, env vars set in Vercel.
      Not connected to GitHub yet, so deploy with `vercel deploy --prod` from the backend repo.
- [x] Point `API_BASE_URL` in `env.json` at it.
- [x] Optional Supabase JWT on `/api/correct`, `/api/chat`, `/api/detect-language`; per-user
      hourly limits in `reward_rate_limits`, smaller per-IP limits for signed-out users
      (`ANON_AI_REQUESTS_PER_HOUR=0` makes sign-in required). CORS allows no browser origin by default.
- [x] Use the `language` field in the correction prompt (and the app now sends the detected language or `auto`).
- [x] Stop logging user text in the backend (and in release builds of the app).
- [ ] Verify the signed-in path end to end (needs Supabase values in `env.json` and a test account).
- **Done when:** the Flutter app corrects text against the hosted backend while signed in, and signed-out calls are limited.
  Decision taken: signed-out corrections stay allowed (rate-limited) so the app's current
  try-before-sign-in flow keeps working.

## Phase 1: Installable keyboard that types (3–5 days)

- [x] Add `BonkilingoKeyboard` extension target (Swift/UIKit) to `ios/Runner.xcodeproj`,
      bundle ID `com.bonkilingo.app.keyboard`; embed phase before "Run Script" per Flutter docs; no pods.
      Version comes from Flutter's `Generated.xcconfig`, so it always matches the app.
- [x] Layouts: German QWERTZ (ü ö ä, default) and English QWERTY, toggled with the DE/EN button;
      shift (double tap = caps lock), numbers and symbols pages, delete with repeat (words after a while),
      long-press variants (ß, é, ç …), double-space period, autocapitalization per text field,
      return key title from the field, globe key when `needsInputModeSwitchKey`, light/dark appearance.
- [x] Bonkilingo bar above the keys with a disabled **Correct** button and a hint (Full Access off,
      Correct switched off in the app, or coming soon).
- [x] `RequestsOpenAccess = YES` in the extension Info.plist; `PrivacyInfo.xcprivacy` for UserDefaults.
- [x] Verified in the iOS 26.5 simulator: keyboard installs with the app, can be added in Settings,
      types (German and English), variants, numbers page and delete work.
- [ ] Spike: on a real iPhone, long-press "Bonkilingo" in the bar to show how many characters the
      keyboard sees before/after the cursor (counts only), in WhatsApp, iMessage, Gmail, Instagram
      (typed vs pasted, short vs long). **This decides how far the MVP can go.**
- [x] Measure memory on a device: 7.1 MiB physical footprint (iPhone 14 Pro, iOS 26.5, release
      build, Instruments Activity Monitor), far under the planned 40–50 MiB budget.
- [x] Installed on a real iPhone (release build, Full Access on). First feedback was "laggy";
      fixed edge-key touch delay, added rollover and key previews; typing now confirmed to feel right.
- [ ] Check on a device that "Open iPhone Settings" in the app's keyboard guide opens Bonkilingo's own
      Settings page (in the simulator it opens the Settings home screen).
- **Done when:** the keyboard installs from a TestFlight build, types normally in all four apps, and the context-window findings are written into the architecture doc.

## Phase 2: Correct button MVP (3–5 days)

- [ ] `TextCapture`: selection first, otherwise the context window; truncation heuristic + warning.
- [ ] `APIClient` (URLSession, 15 s timeout) → `POST /api/correct`.
- [ ] Panel: original vs corrected, **Accept / Reject**, loading indicator.
- [ ] Replace: cursor to end, grapheme-aware delete, insert, verify-after-replace, copy fallback.
- [ ] Errors: no Full Access, offline, timeout, 401 (not signed in), 429 (rate limited), 5xx.
- [ ] Unit tests for capture/replace logic against a fake `UITextDocumentProxy`.
- **Done when:** in each of the four apps, a typed message under ~200 characters can be corrected and replaced in three taps or fewer, and every error state shows a clear message.

## Phase 3: Sharing sign-in between app and keyboard (2–3 days)

- [ ] Backend: `keyboard_tokens` table (hashed), `POST/DELETE /api/keyboard/token`, accept `kb_` tokens on `/api/correct`.
- [ ] Entitlements: Keychain group `H9DTLRUW87.com.bonkilingo.shared` and App Group
      `group.com.bonkilingo.app` on both targets; register them in the Developer portal.
- [ ] Flutter: fetch the token after sign-in, store it with `flutter_secure_storage` (`groupId`),
      revoke it on sign-out; write the target language to the App Group.
- [ ] Keyboard: read the token and language; show "Open Bonkilingo to sign in" when missing.
- **Done when:** signing in or out in the app is reflected in the keyboard with no extra steps, and a revoked token gets a 401.

## Phase 4: Privacy, setup flow, App Review (1–2 days)

- [ ] Flutter `KeyboardSetupScreen`: how to enable the keyboard and Full Access, explicit consent
      naming OpenAI, stored in the App Group; the keyboard sends nothing without it.
- [ ] Update the privacy policy (collection, retention, deletion, withdrawal); App Privacy label;
      `PrivacyInfo.xcprivacy` for the extension.
- [ ] App Store screenshots/description covering the keyboard; review notes explaining Full Access.
- **Done when:** a TestFlight build passes an internal review checklist against guidelines 4.4.1, 5.1.1, 5.1.2 and 2.5.18.

## Phase 5: Device testing and hardening (2–3 days)

- [ ] Real-device matrix: iPhone sizes, iOS 26.x, the four host apps, light/dark, German and English.
- [ ] Emoji, multi-line, marked text (e.g. Japanese input), long pasted messages.
- [ ] Crash/memory monitoring.

**MVP total: about 12–20 days (roughly 3–4 weeks).**

---

## After the MVP (not scheduled)

- Explanations of corrections in the keyboard (reuse `/api/chat`, or a structured correction response).
- Keyboard corrections in History (`chat_sessions.source = 'keyboard'`, opt-in) and BONK rewards.
- Consolidate the Next.js web app onto the Express correction API (single prompt and model list).
- Personalized learning from keyboard mistakes (vocabulary quizzes from real messages).
- Inline suggestions while typing (much higher privacy and cost bar; revisit later).
