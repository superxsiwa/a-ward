# Critical Care (Flutter)

The CCU nursing training game, rebuilt in Flutter for Google Play and the App Store. The React and
Express app beside this folder (`../frontend`, `../backend`) is the spec: the game rules and the 8
cases come from there.

Offline: no server, no accounts, no network calls, no analytics.

## Layout

| Path | What |
|---|---|
| `lib/game/` | The rules in pure Dart: case model and validation, card moves, the step checker, stars, mercy rule, step-2 timer, the case session |
| `lib/data/` | Loads the bundled cases |
| `lib/features/` | Screens: bed list (temporary), the game screen |
| `lib/l10n/` | Strings; Thai is the template (`app_th.arb`) |
| `assets/cases/` | `bed01.json` .. `bed08.json`, converted from `../backend/src/services/beds` |
| `assets/equipment/` | Equipment images from `../frontend/public/assets/equipment` |
| `assets/fonts/` | Prompt and Mitr, SIL Open Font License 1.1 |
| `tool/convert_cases.mjs` | Writes the case JSON; `--check` reports drift from the `.ts` files |

## Commands

```sh
flutter test                          # rules, content lint over all 8 cases, bed 01 played by taps
flutter analyze
node tool/convert_cases.mjs --check   # are the bundled cases in step with backend/?
flutter build apk --debug
```

Release builds are signed only with the upload key named in `android/key.properties` (not in git).
Without it the release APK comes out unsigned; it is never signed with the debug keystore.

## Clinical content

The cases are written by superxsiwa and reviewed by the nurse he builds the game for. Code changes
never change answers, doses or vital signs; the content lint only checks that a case can be played.
