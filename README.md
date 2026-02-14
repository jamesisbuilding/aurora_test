# aurora_test (IMGO)

Flutter coding-assessment project for Aurora.

IMGO is a feed-based, luxury-travel inspiration app with:
- intro video + seamless transition into an image carousel,
- AI-generated titles/descriptions for accessibility/storytelling,
- text-to-speech playback with word-highlighting,
- favourites + share,
- dynamic colour-driven UI.

## Demo
- Video demos: https://drive.google.com/drive/folders/1iASAfGXv4h4pXNdNDrNEwNQArccPV5KO?usp=sharing
- Recommended clip to review: **audio and text highlighting**.

---

## Monorepo layout

This repo is intentionally modular and package-oriented:

- `app/` – composition root (app bootstrap, routing, dependency registration, theme)
- `feature/image_viewer/` – primary feature package (domain/data/state/UI flow)
- `core/design_system/` – shared theme, assets, reusable widgets/buttons
- `core/services/image_analysis_service/` – image processing + caption generation pipelines (ChatGPT/Gemini)
- `core/services/tts_service/` – ElevenLabs-backed TTS generation + playback helper
- `core/services/share_service/` – sharing adapter using `share_plus`

### Architectural style
- **Feature-first modularization** with clean package boundaries.
- **Dependency Injection via GetIt** at app level; feature modules register their own dependencies.
- **BLoC + Cubit split by responsibility**:
  - `ImageViewerBloc` handles image retrieval, carousel selection, loading/error state.
  - Separate cubits handle TTS state, favourites, and collected colors to reduce unrelated rebuilds.
- **Flow orchestration pattern** in `ImageViewerFlow`: preloads image state while intro video overlays, then fades out.

This is architecturally sound for a small-to-mid Flutter product because dependencies flow one way:
`app -> feature/core`, and shared core packages are reused by features without reverse coupling.

---

## Runtime flow (current implementation)

1. `app/main.dart` initializes Firebase, registers dependencies, and launches `MaterialApp.router`.
2. Router opens `/image-viewer` and creates `ImageViewerFlow`.
3. `ImageViewerFlow` creates feature blocs/cubits and triggers initial fetch (`ImageViewerFetchRequested`).
4. Intro video (`assets/video/intro.mp4`) is shown while image content preloads behind it.
5. Image retrieval pipeline:
   - remote URL fetch from `https://november7-730026606190.europe-west1.run.app/image/`
   - image analysis service enriches each image with AI title/description and palette/signature data
   - duplicate protection combines URL-level and pixel-signature checks
   - retries + exponential backoff for transient failures
6. User interactions:
   - swipe carousel, expand/collapse cards, trigger “Another” fetch
   - start/stop TTS with text highlighting
   - favourite or share image + text
   - toggle light/dark mode

---

## Setup

## 1) Prerequisites
- Flutter SDK compatible with Dart `^3.10.0`
- iOS/Android tooling for your target device
- Firebase config files already present in repo (`firebase_options.dart`, platform files)

## 2) Environment variables
Create `app/.env` with:

```env
OPENAI_API_KEY=your_key
ELEVENLABS_API_KEY=your_key
```

> Note: `OPENAI_API_KEY` is required for the configured default image-analysis pipeline (`chatGpt`).

## 3) Install dependencies
```bash
cd app
flutter pub get
```

## 4) Generate env code
```bash
dart run build_runner build -d
```

## 5) Run
```bash
flutter run
```

---

## Key product capabilities

- Intro splash/video transition into live feed.
- Background prefetch near end-of-carousel.
- Manual fetch fallback (“Another” button).
- AI caption/title enrichment per image.
- Duplicate-image exhaustion handling with user feedback.
- Dynamic gradient/background and button colors from image palettes.
- TTS playback + progressive word highlighting.
- Share and favourites actions.
- Light/Dark theme switch.
- Error dialogs for retrieval/pipeline failures.

---

## Architectural assessment summary

### What is strong now
- Clear package boundaries and low coupling between app shell and feature internals.
- Sensible state partitioning (bloc for complex orchestration, cubits for focused concerns).
- Good UX-oriented flow orchestration (preload behind intro video).
- Service abstraction points (`AbstractTtsService`, analysis pipeline interface) support swapping implementations.

### Recommended next hardening steps
1. Add automated tests:
   - unit tests for bloc/cubit transitions and repository retry/duplicate logic,
   - widget tests for critical controls and expanded card behaviour,
   - integration test for video -> viewer transition + initial fetch.
2. Introduce environment-driven pipeline selection (ChatGPT vs Gemini) instead of code-level toggle.
3. Add structured logging/telemetry and production log-level controls.
4. Consider an explicit repository/result error model to remove generic thrown exceptions.
5. Add CI checks for formatting, linting, and test execution across packages.

---

## Known constraints

- Current optimization target is iPhone-class form factors; broader device matrix testing is still needed.
- External provider limits/latency (image API, OpenAI/Gemini, ElevenLabs) can impact perceived responsiveness.
- Test coverage is currently minimal in the repository.

---

## Quick commands

```bash
# from app/
flutter pub get
dart run build_runner build -d
flutter analyze
flutter test
flutter run
```
