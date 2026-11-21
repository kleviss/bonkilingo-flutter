# Bonkilingo brand direction

The rebrand adds colour graphics while keeping the app calm to use. It
borrows design *principles* from modern learning apps; it does not copy any
of their branding.

## What we took, and from where

| Principle | Seen in | How Bonkilingo does it |
|---|---|---|
| Onboarding shows the real product, animated, not illustrations | Nochmal | Each page plays a mini demo of a real screen (correction, quiz, rewards) |
| Soft colour glows behind content instead of flat or gradient walls | Nochmal | `GlowBackground`: sunny, tangerine, leaf and ribbon glows that drift slowly |
| One accent word per headline in a contrasting style | Nochmal (italic serif) | Our own version: a **yellow highlighter** swept over the word, since the app is about marking up text (`HighlightedTitle`) |
| One big pill button, page dots, Skip top right, "I already have an account" on the last page | Nochmal, most Dribbble onboarding shots | Same structure in `OnboardingScreen` |
| Warm cream background with a yellow accent | Dioma (Dribbble) | `BrandColors.cream` in light mode; near-black `night` in dark mode |
| Colour-coded categories in soft pastel tiles | Fluen AI (Dribbble) | Learning tools as tinted pills (Tiny Lesson orange, Vocabulary blue, Grammar green, Sentences purple) |
| A friendly mascot for a gamified feel | "Gamified Language Learning App" splash (Dribbble), Fluen AI robot | Not built yet. See the assets list below |

## Palette

Taken from the app icon (`lib/core/theme/brand_colors.dart`):

- Sunny `#FFD84D` and Tangerine `#FF9A3D`: the icon background; used for the primary button, BONK balance and highlighter
- Leaf `#7ED957`: the green book; streaks and success
- Ribbon `#F0477A`: the bookmark ribbon; small accents only
- Ink `#1C1C1E`: text on yellow, in both themes
- Cream `#FFF8EC` and Night `#111113`: brand-screen backgrounds

## Done

- First-launch onboarding with 3 animated pages (4 when the keyboard extension is enabled). It only shows once, and is skipped for people already signed in.
- **Home**: glow background, a "What will you *write* today?" headline, a composer card with a language chip, a gradient Correct pill, and streak and BONK pills when signed in. Results show your sentence with mistakes struck out in red above the corrected text with fixes in green (word-level diff in `lib/core/utils/word_diff.dart`). Until there is a result, an example correction shows what to expect.
- **Sign in and sign up**: glow background, the app mark, a highlighted title ("Welcome *back*", "Create your *account*"), card-style fields that glow tangerine when focused, the gradient pill button, and errors shown inline above the button instead of in an alert.
- **Rewards**: "Earn *BONK*" headline, the sunny-to-tangerine balance card with total earned and withdrawn inside it, a wallet card with an ink "Connect wallet" pill, and grouped rows with colour-coded icons for how to earn, recent activity and withdrawals.
- **Learn**: "Learn from your *mistakes*" headline, a hero card for the top suggested lesson (your own fixes shown as red → green chips), the next suggestions as rows, tinted tool tiles, and grouped rows for practice and courses (language-code badges instead of emoji).
- Brand widgets you can reuse elsewhere: `GlowBackground`, `HighlightedTitle`, `BrandMark`, `PillButton`, `BrandPalette` for card and text colours, `AuthLayout`, `BrandTextField`, `AuthError` and `AuthSwitchLink` for form screens, and `BrandCard`, `BrandSectionTitle`, `BrandListRow`, `BrandIconBadge` and `SecondaryPillButton` for lists and cards (`lib/presentation/widgets/brand/brand_surfaces.dart`).

## Inner pages

Done: History, Settings, My Account, keyboard setup, the explanation chat,
the suggested lesson, Tiny lesson, Cheatsheet, the structured courses and the
three quizzes (vocabulary, sentence building, grammar). Pushed pages use
`BrandPage` (`lib/presentation/widgets/brand/brand_page.dart`) for the glow
and a clear navigation bar, and the quizzes share `AnswerTile`, the progress
bar, inline feedback and the score card from
`lib/presentation/widgets/brand/quiz_widgets.dart`. Quizzes show right and
wrong answers inline instead of in alerts.

## Assets to create with AI

The current icon is a detailed 3D render. It looks rich large, but it gets
busy at small sizes and does not fit a flat UI. Suggested set:

1. **App icon: done.** A bold ink "b" over a yellow highlighter stroke on
   cream (`assets/brand/app_icon.png`, plus a transparent
   `app_icon_foreground.png` for Android adaptive icons). It is drawn in
   code by `tool/draw_app_icon.swift`
   (`swift tool/draw_app_icon.swift assets/brand/app_icon.png 1024 full`, and
   `... app_icon_foreground.png 1024 fg`). Regenerate the platform sets
   with `dart run flutter_launcher_icons`. The old 3D books
   (`assets/AppIcons-BONK/`) can become a hero illustration.
2. **Launch screen.** A plain cream (light) or night (dark) background with
   the mark centred, so the switch into the onboarding glow is seamless.
   Export the mark as a PNG with transparency at @1x, @2x and @3x for
   `LaunchScreen.storyboard`.
3. **Mascot (optional, biggest gamification win).** BONK suggests a dog. Use
   an original character, not the BONK token's logo dog.
   *Prompt idea:* "Friendly cartoon shiba-like puppy mascot holding a yellow
   highlighter, soft 3D clay style matching [attach current icon], warm
   yellow/orange/green palette, transparent background, several poses:
   waving, celebrating, thinking, sleeping."
   Uses: empty states, the streak screen, the "+BONK" celebration, and errors.
4. **Empty-state illustrations** in the same 3D clay style as the icon books:
   no corrections yet, no rewards yet, and offline.

## Build note

Flutter 3.35.7's simulator build fails on Xcode 27. Its `lipo -verify_arch`
check rejects two architectures, so `flutter build ios --simulator` and
`flutter run` on a simulator both stop at `debug_unpack_ios`. Workaround
without project changes:

```bash
flutter build ios --simulator --debug --config-only --dart-define-from-file=env.json
cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug \
  -sdk iphonesimulator -derivedDataPath ../build/ios_dd ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build
```

Then install `build/ios_dd/Build/Products/Debug-iphonesimulator/Runner.app`.
