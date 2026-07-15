# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`gaming_adda` — a single Flutter app that will host multiple board games (e.g. Go, Checkers). The user picks a game from within the one app.

Current state: **bare Flutter starter**. `lib/main.dart` is still the default counter demo and `test/widget_test.dart` still tests it. No game code, no state management, no routing exists yet — expect to establish these when the first game is built.

Targets all six platforms (android, ios, linux, macos, web, windows). Dart SDK `^3.12.2`.

## Commands

```bash
flutter pub get              # install deps
flutter run                  # run on default device
flutter run -d chrome        # run on a specific device (chrome, linux, macos, ...)
flutter analyze              # lint (uses flutter_lints via analysis_options.yaml)
dart format .                # format
flutter test                 # all tests
flutter test test/widget_test.dart              # single test file
flutter test --name "substring of test name"    # single test by name
flutter build <apk|web|linux|macos|windows|ipa> # release build
```

## Notes

- Lints come from `package:flutter_lints/flutter.yaml`; project-specific rules go in `analysis_options.yaml`.
- When adding a game, keep per-game logic (board state, rules, move validation) separate from its widgets so the shared game-selection shell stays thin.
