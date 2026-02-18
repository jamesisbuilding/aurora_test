# aurora_test (IMGO)

![IMGO](screenshots/imgo.png)

IMGO is a feed-based, luxury-travel inspiration app with:
- intro video + seamless transition into an image carousel,
- AI-generated titles/descriptions for accessibility,
- text-to-speech playback with word-highlighting,
- favourites + share,
- gyroscope parallax on the selected image (collapsed and expanded, iOS/Android),
- dynamic colour-driven UI.

> **Best experienced on a physical device in `--profile` mode:**  
This app uses haptic feedback, which is only available on real devices (not emulators/simulators). Running in `--profile` ensures Ahead-of-Time (AOT) compilation, leading to smoother animations and reduced jank. For the intended experience, use:

```
flutter run --profile
```

on a real device.


## Demo
- Video demos: https://drive.google.com/drive/folders/1iASAfGXv4h4pXNdNDrNEwNQArccPV5KO?usp=sharing  
  **1. Main video** — video demoing full flow  
  **2. Archive** - previous videos of implementation as backlog  

I got really into this challenge and built more than required - it was genuinely fun. The full version (IMGO) is in the repo, but I want to be clear: for the actual assignment, the core features took about 2-3 hours. The rest was me exploring the problem space because I found it interesting. I can definitely calibrate scope for production work

**Key highlights**
- **Background prefetching** — We fetch a batch of 5 on start (first visible, rest in a queue). When the user is 2 pages from the end we prefetch 5 more in the background; when they tap "Another" we consume from the queue and refill when it drops to 1. Deduplication by URL and pixel signature with exponential backoff.
- **Caching** — Fetched images are saved to app temp (`viewer_cache/`) and the UI prefers this local file over the network. Network URLs use `CachedNetworkImage`; the selected image is precached before showing as the button background to avoid flash.
- **Shader-driven color interpolation** — GPU-accelerated linear interpolation of palettes across the carousel; background transitions driven by visible-image ratios.
- **AI-augmented data** — LLM-powered titles and descriptions (ChatGPT/Gemini) for each image; accessibility-first description narration.
- **TTS with word highlighting** — ElevenLabs-backed text-to-speech; synchronized word highlighting for immersive playback.
- **90.9% business logic coverage** — 124 tests. Coverage measured for bloc, cubit, data, domain, utils, and DI only (excludes view layer). Includes tests for button loading cancel (TTS and manual fetch), collected colours button/sheet, scroll direction toggle, and ScrollDirectionCubit.
- **CI** — GitHub Actions runs `flutter analyze` and `flutter test` on app, image_viewer, and share_service.

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
   - swipe carousel (vertical or horizontal — user-toggleable), expand/collapse cards, trigger “Another” fetch
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
Copy `.env.example` to `app/.env` and add your keys:

```bash
cp .env.example app/.env
# Edit app/.env with OPENAI_API_KEY and ELEVENLABS_API_KEY
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

To use Gemini instead of ChatGPT: `flutter run -d IMAGE_ANALYSIS_PIPELINE=gemini`

The app is best optimized for iPhone 17 Pro. Although it should run on other devices, broader device-matrix testing would validate full compatibility.


### The app contains the following ###

### Launch
1. Native splash screen (platform launch screen - better with sound (no sound in emulator recording))
2. Launcher video 
3. Streaming in initial batch of images (5) – preloads whilst the video plays

### Fetching and Processing Images
4. Background fetch – awaiting more images in the background as the user scrolls, triggered by their position in the carousel
5. Manual fetch – users can request more images via the another button when we don't have any prefetched
6. Prefetch caching – if we have images preloaded we give the impression of low latency
7. Data augmentation – use of an LLM interface (ChatGPT or Gemini) to provide the image with a title and description for accessibility
8. Duplication management – ensure no images are duplicated, using both URL checking and pixel color analysis. If we get 3 duplicate images in a row, we notify the user
9. Exponential back off – if we receive an error from our image fetching service we retry with exponential back off until the target batch is satisfied or we hit our attempt limit
10. Image visualisation fallbacks – we save the image locally and use cached network images so we have stable loading into the widget (no empty state)

### UI
11. Expansion mode – expand the image to see title, description and colour palette. **Collected colours:** tap "Collect Colors" in the palette view to save the image’s palette; a top-left button (three overlapping circles) appears once colours are collected, opens a glassmorphic bottom sheet with DraggableNotch, no border, transparent barrier. Button is hidden when no colours collected. State persists via CollectedColorsCubit
12. Linear interpolation between colors – as the carousel moves the background palette changes with respect to the ratio of which image is primarily visible
13. Expandable image cards – tap an image to expand and see the full title and description, with the play button for TTS. **Tap affordance:** on the selected image, if the user has never expanded any card, a touch hint (animated gif) appears after 3 seconds of inactivity to indicate that tapping reveals the description; any tap or expand dismisses it and it does not show again once the user has expanded at least once.
14. **Gyroscope parallax** – the selected image card responds to device gyroscope on iPhone: tilt the device to see a subtle 3D parallax effect on the centred card (iOS/Android only)
15. Accessibility – interfaces with Eleven Labs API to read out the short story/description of the image and have highlighted text on each word. 
16. Favourite and Share – users can favourite and share images. Share has two modes: collapsed shares the raw image and description; expanded mode captures a screenshot of the carousel (excluding the control bar)
17. **Control bar main button** – dynamic button with multiple states:
    - **Background image:** shows the next image (from prefetched queue) if available; if none are fetched, shows the current/selected image; when carousel is expanded, shows the current image as a faint background. Colours driven by the image palette.
    - **Shimmer:** the button shimmers when there are new (prefetched) images to see and the carousel is collapsed; indicates that tapping "Another" will reveal the next image.
    - **Loading state:** shows a spinner when manually fetching ("Another" tapped with no prefetched images) or when loading audio.
    - **Button cancel during loading:** tapping the main button while it is loading cancels the in-flight operation—TTS playback stops if audio is loading, or the manual image fetch is cancelled via `FetchCancelled` if "Another" was tapped with an empty queue. Prevents accidental re-taps and gives users control to abort slow operations.
    - **Audio mode:** when the carousel is expanded, the button switches to play/pause for TTS (replacing the "Another" label).
    - Contrast ratio threshold (WCAG AAA). Minimum 7:1 for accessibility.
18. Light and Dark mode – toggle via the button at the top right
19. Control bar – collapsible and updates to changes in selected image colors. Background loading indicator sits 8px above the control bar and moves with expand/collapse. **Scroll direction toggle:** top-left icon switches carousel between horizontal (default) and vertical scroll; indicator is centered when vertical, right-aligned when horizontal; fades in/out on position change. Hidden/collapsed until the first image arrives, then reveals and pops up to expanded.
20. Error dialogs – glassmorphic, theme-inverted popups (dark in light mode, light in dark mode) surface fetch failures and duplicate exhaustion; retry on dismiss when no images visible

### Accessibility

| Feature | Implementation |
|--------|----------------|
| **Color contrast** | WCAG AAA 7:1 minimum on main button; `ImageModel.lightestColor` / `darkestColor` enforce contrast between foreground and dynamic palette background |
| **Light/dark mode** | User-selectable theme toggle; all UI adapts to system/app preference |
| **Text-to-speech** | ElevenLabs TTS reads AI-generated title and description; synchronized word highlighting during playback |
| **Descriptive content** | Each image has LLM-generated title and description for context (supports screen reader announcements) |
| **Haptic feedback** | Light/heavy haptics on key interactions (buttons, dialogs, sheet) for non-visual feedback |
| **Touch targets** | Main button and control bar elements meet Material Design 48dp minimum tap area guidance |
| **Tap affordance** | Touch hint on selected image (after 3s idle, first-time users) indicates that tapping expands to view title and description |

### Architecture

The project is structured as a modular Flutter app – each feature and core concern lives in its own package so we can slot things together and keep dependencies clear.

**Packages**

- `app` – Shell, main entry, routing (GoRouter), dependency injection (GetIt), theme
- `feature/image_viewer` – Main feature: domain, data, bloc/cubits, views
- `core/design_system` – Shared widgets, theming, assets
- `core/services` – image_analysis_service, tts_service, share_service

**Feature structure (image_viewer)**

- `domain` – Repository contracts, exceptions
- `data` – Datasources, repository implementations
- `bloc` – ImageViewerBloc for image state (fetch, selection, carousel)
- `cubit` – TtsCubit for playback, FavouritesCubit for favourites, CollectedColorsCubit for colour collector (kept separate to limit rebuilds)
- `view` – Flow (ImageViewerFlow) orchestrates video + image viewer, plus pages and widgets

**Patterns**

---

## Key product capabilities

**Refactoring and optimisation (done)**

The view layer has been refactored: the background loading indicator is integrated into the control bar and moves with it on expand/collapse. Bloc handlers use the current state at catch time (not the event’s original loading type) so error surfacing correctly tracks manual vs background loading even when state changes mid-fetch. Duplication handling uses URL deduplication before processing, pixel signature checks, `FailureType.duplicate` from the analysis service, and a bloc-level defensive filter. Sequential duplicate handling is now target-count aware, and duplicate rounds restart fetch attempts before surfacing exhaustion. Image analysis requests use a 30s timeout with `TimeoutException` surfaced for manual fetches. The Another button uses precache for its color/background image to avoid flash when new images load.

**Still to improve – Eleven Labs and LLM resilience**

Eleven Labs (TTS) and LLM (ChatGPT/Gemini) could be made more robust – retries, fallbacks, clearer error handling and user feedback when those services fail. 

**Hardening (done)**

- **Release-safe logging** — `debugPrint` wrapped in `kDebugMode`; no verbose logs in release
- **Typed exceptions** — `ImageFetchFailedException`, `NoMoreImagesException`
- **Env-driven pipeline** — `flutter run -d IMAGE_ANALYSIS_PIPELINE=gemini`
- **Null-safe carousel** — `_bloc!` removed; uses null-aware `?.`
- **UX polish** — Main button label "Another" capitalised

### Recommended next hardening steps
1. **Tests (90.9% business logic coverage):** Unit tests for bloc, repository, datasource, cubits, and DI; widget tests for control bar, expanded card, custom dialog; integration tests for fetch flow and video → viewer transition; golden tests for UI regression. See [Testing](#testing).
2. ~~Environment-driven pipeline selection~~ — Done: use `-d IMAGE_ANALYSIS_PIPELINE=gemini`.
3. Add structured logging/telemetry and production log-level controls.
4. ~~Explicit repository error model~~ — Done: `ImageFetchFailedException`, `NoMoreImagesException`.
5. ~~Add CI checks~~ — Done: `.github/workflows/ci.yml` runs `flutter pub get`, `flutter analyze`, and `flutter test` on app, image_viewer, and share_service.

---

## Known constraints

- Current optimization target is iPhone-class form factors; broader device matrix testing is still needed.
- External provider limits/latency (image API, OpenAI/Gemini, ElevenLabs) can impact perceived responsiveness.

---

## Production readiness notes

For production deployment, consider adding:

| Area | Recommendation |
|------|----------------|
| **Logging** | All `debugPrint` wrapped in `kDebugMode` (release-clean). Next: `logger` package with configurable levels for production diagnostics. |
| **Crash reporting** | Firebase Crashlytics (already have Firebase) or Sentry; ensure unhandled exceptions and Flutter framework errors are captured. |
| **Analytics** | Firebase Analytics or equivalent for carousel engagement, share/favourite events, TTS usage, and error-surface rates. |
| **Feature flags** | Environment-driven toggles for ChatGPT vs Gemini, TTS on/off, or A/B variants without app store releases. |
| **Secrets** | API keys via `.env` (current); for production use a secrets manager or build-time injection; never log keys. |

---

## Performance notes

| Component | Behaviour | Notes |
|-----------|-----------|-------|
| **Carousel** | Vertical or horizontal `PageView` with `viewportFraction: 0.8` | User can toggle scroll direction (top-left icon); default horizontal; single `PageController`; images loaded on demand via `CachedNetworkImage`; `AnimatedSwitcher` for transitions. |
| **Background shader** | `LiquidBackground` uses `FragmentShader` (`gradient.frag`) | GPU-rendered; `blendedColorsNotifier` updates drive repaints; 5-slot color interpolation is O(1) per frame. |
| **Prefetch** | Triggered at `page == images.length - 2` | Avoids over-fetch; queue capped by bloc; deduplication reduces redundant processing. |
| **TTS** | Streamed from ElevenLabs | Audio loads async; `TtsCubit` manages playback state; no blocking on main isolate. |
| **Image analysis** | Per-image LLM call with 30s timeout | Batch of 5; sequential processing in repository; consider parallelisation for larger batches. |
| **Memory** | `CachedNetworkImage` + local file fallback | Images evicted by cache; carousel disposes off-screen pages; `RepaintBoundary` on screenshot capture. |

**Profiling:** Run with `flutter run --profile` and use DevTools (Performance, Memory) to verify frame times and heap usage on target devices.

### Carousel scroll direction (vertical vs horizontal)

The carousel supports both vertical and horizontal scrolling, with a user-toggle (top-left icon). Research does not favour one direction universally; the choice depends on task and context. We default to horizontal and allow switching.

**Vertical scroll:** Vertical scrolling aligns with common mobile behaviour (feeds, social streams) and tends to be easier for users because of familiarity and muscle memory. Platform guidelines often discourage horizontal scroll because it can add friction. — [1] [ScienceDirect](https://www.sciencedirect.com/topics/computer-science/horizontal-scrolling) (vertical as usual default); [2] [UGent](https://libstore.ugent.be/fulltxt/RUG01/002/837/790/RUG01-002837790_2020_0001_AC.pdf) (muscle memory for vertical scroll; violating that can increase cognitive load).

**Horizontal scroll:** Horizontal swipe can be better suited to discrete, paged content (e.g. product carousels) and has been linked to higher cognitive absorption and playfulness in some flows. — [3] [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC9948611/) (horizontal swipe may be better for segmented information processing); [4] [ResearchGate](https://www.researchgate.net/publication/304344009_Swiping_vs_Scrolling_in_Mobile_Shopping_Applications) (horizontal swipe interfaces can increase cognitive absorption in mobile shopping).

---

## Testing

**Test coverage summary** — **124 tests** (119 image_viewer + 4 share_service + 1 app), **59.5% line coverage** (`feature/image_viewer`)

| Suite | Tests | Path |
|-------|-------|------|
| ShareService | 4 | `core/services/share_service/test/share_service_impl_test.dart` |
| ImageViewerBloc | 23 | `test/bloc/image_viewer_bloc_test.dart` |
| Fetch flow integration | 4 | `test/integration/fetch_flow_integration_test.dart` |
| ImageRepositoryImpl | 6 | `test/data/repositories/image_repository_impl_test.dart` |
| ImageRemoteDatasource | 4 | `test/data/datasources/image_remote_datasource_test.dart` |
| ImageViewerExceptions | 3 | `test/domain/exceptions/image_viewer_exceptions_test.dart` |
| CollectedColorsCubit | 5 | `test/cubit/collected_colors_cubit_test.dart` |
| ScrollDirectionCubit | 4 | `test/cubit/scroll_direction_cubit_test.dart` |
| TtsCubit | 4 | `test/cubit/tts_cubit_test.dart` |
| ImageProviderUtils | 7 | `test/utils/image_provider_utils_test.dart` |
| ImageViewerModule (DI) | 6 | `test/di/image_viewer_module_test.dart` |
| ImageViewerFlow | 4 | `test/view/flow/image_viewer_flow_test.dart` |
| ControlBar | 4 | `test/view/widgets/control_bar/control_bar_test.dart` |
| ControlBarMainButton | 8 | `test/view/widgets/control_bar/control_bar_main_button_test.dart` |
| ImageViewer expanded body | 3 | `test/view/widgets/image_square/image_viewer_expanded_body_test.dart` |
| BackgroundLoadingIndicator | 7 | `test/view/widgets/loading/background_loading_indicator_test.dart` |
| FavouriteStarButton | 3 | `test/view/widgets/control_bar/favourite_star_button_test.dart` |
| CollectedColorsButton | 4 | `test/view/widgets/collected_colors/collected_colors_button_test.dart` |
| CollectedColorsSheet | 5 | `test/view/widgets/collected_colors/collected_colors_sheet_test.dart` |
| ScrollDirectionToggle | 3 | `test/view/widgets/carousel/scroll_direction_toggle_test.dart` |
| CustomDialog | 1 | `test/view/widgets/alerts/custom_dialog_test.dart` |
| ErrorRetryFlow | 1 | `test/view/pages/error_retry_flow_test.dart` |
| GyroParallaxCard | 5 | `test/view/widgets/gyro/gyro_parallax_card_test.dart` |
| Golden (UI regression) | 10 | `test/golden/golden_test.dart` |

**Business logic coverage (90.9%):** Measured for `lib/src/{bloc,cubit,data,domain,utils,di}/` only. Excludes view layer (widgets, pages, flow) and generated files. Run `sh scripts/coverage_business_logic.sh` after `flutter test --coverage`.

**Golden tests (10):** `test/golden/golden_test.dart` — control bar collapsed/expanded/light/dark, loading indicator, intro thumbnail, expanded card (long text), error dialog, carousel collapsed, animated background. Run with `--update-goldens` to create/update. Golden PNGs are gitignored; CI skips golden tests. Run locally after UI changes. See `docs/GOLDEN_TESTS_PLAN.md` for full plan.

### ShareService unit tests

Share text construction for screenshot vs collapsed share modes:

```bash
cd core/services/share_service
flutter test
```

**Coverage (4 tests)**

| Test | Covers |
|------|--------|
| screenshot mode: empty description and null title yields only tagline | Full-screen share uses only "I sent this from Imgo!" |
| collapsed mode: title and description are included with tagline | Raw image share includes full title + description |
| title only yields title and tagline | Partial content handling |
| description only yields description and tagline | Partial content handling |

### ImageViewerBloc unit tests

The `feature/image_viewer` package includes unit tests for fetch logic, duplicate handling, and error surfacing. Run from the image_viewer package:

```bash
cd feature/image_viewer
flutter test test/bloc/image_viewer_bloc_test.dart
```

**Coverage (22 tests)**

*Fetch + duplicate guard:*
| Test | Covers |
|------|--------|
| first load sets visibleImages + selectedImage correctly | Initial fetch, first image path |
| manual fetch while on last page appends and navigates path | Manual fetch on last page, append + select |
| duplicate signatures are skipped via reservation guard | Duplicate handling via `tryReserveSignature` |
| NoMoreImagesException only shows manual-mode errors | Manual-only error surfacing |
| NoMoreImagesException during background fetch with images does NOT show error | Background fetch with images silently ignores |
| NoMoreImagesException during background fetch with NO visible images DOES show error | Initial/background load failure surfaces error |
| TimeoutException only shows manual-mode errors | Manual-only error surfacing |
| TimeoutException during background fetch with images does NOT show error | Background fetch with images silently ignores |
| TimeoutException during background fetch with NO visible images DOES show error | Initial load timeout surfaces error |
| generic error during background fetch with NO visible images DOES show error | Initial load failure surfaces error |
| background fetch completion resets loading to none | Loading state reset on stream complete |

*Fetch trigger behavior (manual, scrolling, Another button):*
| Test | Covers |
|------|--------|
| AnotherImageEvent with exactly 1 prefetched: consumes and triggers background fetch | Prefetch when queue drops to 1 after consume |
| AnotherImageEvent with 2+ prefetched: consumes first, no fetch when 2+ remain | No redundant fetch while well-stocked |
| AnotherImageEvent with no prefetched and loading none: triggers manual fetch | Manual fetch when user taps Another with empty queue |
| AnotherImageEvent with no prefetched and loading background: switches to manual, no new fetch | User waiting – switch to manual, no duplicate request |
| ImageViewerFetchRequested with default params triggers background prefetch | Scroll-to-page (length-2) prefetch path |

*FetchCancelled:*
| Test | Covers |
|------|--------|
| FetchCancelled during manual fetch cancels subscription and sets loadingType to none | In-flight manual fetch cancelled; subscription cancelled, loading cleared |

*Bloc handlers coverage:*
| Test | Covers |
|------|--------|
| ErrorDismissed clears errorType | Error dismissal path |
| CarouselControllerRegistered and Unregistered update state | Carousel controller lifecycle |
| generic catch emits unableToFetchImage for manual load | Non-Timeout/NoMoreImages error surfacing |
| releaseReservedSignature removes in-flight signature | Signature reservation cleanup |
| releaseReservedSignature does nothing for empty signature | Empty-signature guard |

**Fetch triggers (where `ImageViewerFetchRequested` is dispatched):**

| Trigger | Location | Type | When |
|---------|----------|------|------|
| Initial load | `ImageViewerFlow` | Background (count 10) | On flow mount |
| Scroll prefetch near end | `_onPageChange` (image_viewer_main_view) | Background (count 10) | When vertical scroll reaches `page == images.length - 2` and `loadingType == none` |
| Another (has prefetched) | `AnotherImageEvent` via `onNextPage` | Background (count 10) | When consuming last prefetched (length was 1) |
| Another (no prefetched) | `AnotherImageEvent` | Manual (count 10) | When `loadingType == none` |
| Another (no prefetched, already loading) | `AnotherImageEvent` | Switch to manual | When `loadingType == background` – no new request |

Uses `mocktail` to mock `ImageRepository`; no `bloc_test` (dependency conflicts with `flutter_bloc 9`).

### ScrollDirectionCubit unit tests

Carousel scroll direction state (vertical/horizontal) and toggle behavior:

```bash
cd feature/image_viewer
flutter test test/cubit/scroll_direction_cubit_test.dart
```

**Coverage (4 tests)**

| Test | Covers |
|------|--------|
| initial state is horizontal | Default Axis.horizontal |
| toggle from horizontal emits vertical | State transition on first toggle |
| toggle from vertical emits horizontal | State transition back |
| toggle alternates correctly multiple times | Multiple toggles alternate state |

### ScrollDirectionToggle widget tests

Top-left scroll direction toggle button that reads and updates ScrollDirectionCubit:

```bash
cd feature/image_viewer
flutter test test/view/widgets/carousel/scroll_direction_toggle_test.dart
```

**Coverage (3 tests)**

| Test | Covers |
|------|--------|
| shows tooltip for horizontal when in horizontal mode | Tooltip text when horizontal |
| tap toggles to vertical and updates tooltip | Tap calls cubit.toggle(), tooltip updates |
| double tap returns to horizontal | Toggle cycles back |

### Fetch flow integration tests

End-to-end bloc + repository orchestration and duplicate-risk logic:

```bash
cd feature/image_viewer
flutter test test/integration/fetch_flow_integration_test.dart
```

**Coverage (4 tests)**

| Test | Covers |
|------|--------|
| initial fetch → prefetch → Another → no duplicate signatures | Initial fetch, scroll-triggered prefetch, consume from queue, assert unique signatures |
| Another with prefetched queue: consumes without new fetch until queue=1 | No redundant fetch when 2+ in queue; fetch triggered when queue drops to 1 |
| Another with empty queue: triggers manual fetch | Manual fetch path when user taps Another with no prefetched |
| duplicate signatures from repo are never surfaced in bloc state | Bloc + repo dedupe: visibleImages + fetchedImages always unique |

Uses `ImageRepositoryImpl` with `FakeImageRemoteDatasource` and `FakeImageAnalysisService`. Aligns with duplicate-risk logic in bloc handlers and repository.

### ImageRepositoryImpl unit tests

Repository dedupe, retry, and duplicate-exhaustion logic are tested with fake datasource and fake analysis service:

```bash
cd feature/image_viewer
flutter test test/data/repositories/image_repository_impl_test.dart
```

**Coverage (6 tests)**

| Test | Covers |
|------|--------|
| URL dedupe (rawUrls.toSet()) works | Duplicate URLs from parallel fetches are deduped before analysis |
| duplicate result increments sequential duplicate counter and throws at threshold | `FailureType.duplicate` → `NoMoreImagesException` at 3 sequential |
| Success model with duplicate pixel signature increments sequential counter and throws at threshold | Success with duplicate sig in `_seenSignatures` → `NoMoreImagesException` |
| non-duplicate results decrement remainingToFetch and stream yields expected count | Success path, stream yields exactly `count` images |
| backoff retries stop once target count is reached | No extra rounds once target met |
| throws when all attempts fail | Generic `Exception` after all retries exhausted |

Uses `FakeImageRemoteDatasource` and `FakeImageAnalysisService` (no mocks).

### TtsCubit unit tests

TTS playback state transitions and stream subscription behavior:

```bash
cd feature/image_viewer
flutter test test/cubit/tts_cubit_test.dart
```

**Coverage (4 tests)**

| Test | Covers |
|------|--------|
| play() emits loading -> playing | State transition on successful play |
| onPlaybackComplete clears isPlaying/currentWord | Callback clears playback state and word highlight |
| stop() always clears state | Cancel + clear regardless of current state |
| exception in TTS service resets state and rethrows | Catch block clears state, rethrows to caller |
| stop() during loading prevents isPlaying from ever being emitted | Cancel TTS during load; no spurious isPlaying emission |

Uses `FakeTtsService` with controllable completion, error behavior, and `delayPlayReturn` for cancel-during-load tests.

### ImageViewerFlow widget tests

Video overlay, fade-out, and underlying viewer visibility:

```bash
cd feature/image_viewer
flutter test test/view/flow/image_viewer_flow_test.dart
```

**Coverage (4 tests)**

| Test | Covers |
|------|--------|
| VideoView initially visible, blocks pointer | Intro video shown on top, blocks touch |
| after onVideoComplete, opacity animates to 0 and pointer is released | Fade-out animation, pointer events enabled |
| ImageViewerScreen is present underneath throughout | Underlying viewer mounted throughout flow |
| Cold start → intro video → first content | Real orchestration: overlay visible, fetch runs on mount, content appears from bloc state, video complete fades overlay |

Uses `overlayBuilder` and `bottomLayer` test overrides to avoid shader assets and CarouselScope dependencies. The cold-start test uses a bloc-driven bottom layer (`useOrchestrationLayer: true`) that shows first content when `visibleImages` is non-empty, validating the full path: fetch → stream → bloc emit → UI.

### ControlBar background loading indicator

Tests the bottom-right indicator that shows during background prefetch:

```bash
cd feature/image_viewer
flutter test test/view/widgets/control_bar/control_bar_test.dart
```

**Coverage (4 tests)**

| Test | Covers |
|------|--------|
| visible when background loading and has images, carousel not expanded | Indicator shows during prefetch |
| not visible when manual loading | Manual "Another" uses main button spinner |
| not visible when no visible images | Initial load uses carousel indicator |
| indicator not in tree when carousel expanded | Collection-if hides entire widget when expanded |

### ControlBarMainButton widget tests

Main button background image, mode, and loading state logic:

```bash
cd feature/image_viewer
flutter test test/view/widgets/control_bar/control_bar_main_button_test.dart
```

**Coverage (6 tests)**

| Test | Covers |
|------|--------|
| collapsed with prefetched: background shows fetchedImages.first | Background uses prefetched queue when collapsed |
| collapsed with no prefetched: background shows selectedImage | Fallback to selected image when queue empty |
| expanded: background shows selectedImage | Expanded always shows selected image |
| manual loading collapsed: mode audio, isLoading true | Manual fetch shows spinner, mode switches to audio |
| background loading collapsed: no loading shown | Background fetch does not show spinner on main button |
| displayImageForColor overrides colors | displayImageForColor drives bg/foreground palette |
| tap during TTS loading calls TtsCubit.stop and clears loading | Button cancel during TTS load; TtsCubit.stop clears state |
| tap during manual fetch dispatches FetchCancelled and clears loading | Button cancel during manual fetch; FetchCancelled clears loadingType |

Uses `pump(const Duration(milliseconds: 300))` to allow AnimatedPressMixin timer to complete before teardown.

### BackgroundLoadingIndicator visibility

Two instances use different `visibleWhen` logic (carousel vs control bar):

```bash
cd feature/image_viewer
flutter test test/view/widgets/loading/background_loading_indicator_test.dart
```

**Coverage (7 tests)**

*Carousel (center area, initial load):*
| Test | Covers |
|------|--------|
| visible when visibleImages.isEmpty | Shows during initial load before any images |
| not visible when visibleImages is non-empty | Hides once content is loaded |
| not visible when expanded even if no images | Hidden when carousel expanded (no overlap with expanded card) |
| visible when loading and not expanded | Shows when loading AND collapsed |

*Control bar (right edge, background fetch):*
| Test | Covers |
|------|--------|
| visible when background loading and has images | Shows when prefetching more images (scrolling near end) |
| not visible when manual loading | Manual "Another" uses main button spinner instead |
| not visible when no visible images | Initial load uses carousel indicator, not control bar |

### ImageViewer expanded body + word highlighting

Expanded layout visibility and TTS word-highlight styling:

```bash
cd feature/image_viewer
flutter test test/view/widgets/image_square/image_viewer_expanded_body_test.dart
```

**Coverage (3 tests)**

| Test | Covers |
|------|--------|
| body only appears when expanded | ImageViewerBody present when `expanded=true`, absent when `expanded=false` |
| when currentWord is injected, one word span gets highlight style | Highlighted word has `backgroundColor` / `color`; exactly one span highlighted |
| title vs description index mapping displays expected highlighted token | `isTitle` + `wordIndex` maps correctly to title vs description token (e.g. index 1 in each) |

Requires `TtsCubit`, `CollectedColorsCubit`, and `FavouritesCubit` in harness for full widget tree.

### FavouriteStarButton widget tests

Favourites star rebuild behavior (selective `buildWhen`):

```bash
cd feature/image_viewer
flutter test test/view/widgets/control_bar/favourite_star_button_test.dart
```

**Coverage (3 tests)**

| Test | Covers |
|------|--------|
| tapping star toggles state | Add/remove UID from FavouritesCubit |
| icon color changes for selected UID when favourited | State drives visual (yellow vs onSurface) |
| unrelated UID toggle does not rebuild target star | `buildWhen` prevents rebuild when other UIDs change |

Uses `debugBuildCount` on `FavouriteStarButton` to instrument rebuilds.

### CollectedColorsButton widget tests

Button visibility and sheet-open behavior:

```bash
cd feature/image_viewer
flutter test test/view/widgets/collected_colors/collected_colors_button_test.dart
```

**Coverage (4 tests)**

| Test | Covers |
|------|--------|
| is hidden when collected is empty | Button returns SizedBox.shrink when no colours |
| is visible when collected has colors | GestureDetector shown when cubit has entries |
| tap opens collected colours sheet | Modal bottom sheet with CollectedColorsSheet |
| becomes visible when colors added after empty | BlocBuilder rebuilds on cubit state change |

### CollectedColorsSheet widget tests

Sheet layout, notch, and empty state:

```bash
cd feature/image_viewer
flutter test test/view/widgets/collected_colors/collected_colors_sheet_test.dart
```

**Coverage (5 tests)**

| Test | Covers |
|------|--------|
| shows my colours title | YesevaOne heading present |
| shows DraggableNotch at top | Notch matches control bar style |
| shows empty state when no colours collected | "No colours collected yet" message |
| shows empty state when collected has no entries | Empty-map handling |
| shows palette rows when colours collected | ListView with palette circles |

### Error-retry flow widget test

When an error is emitted with no visible images (e.g. initial load failure), the dialog is shown and on dismiss a retry fetch is triggered:

```bash
cd feature/image_viewer
flutter test test/view/pages/error_retry_flow_test.dart
```

**Coverage (1 test)**

| Test | Covers |
|------|--------|
| error with no visible images: dialog shown, on dismiss retries fetch | Error dialog, retry on dismiss when `visibleImages.isEmpty` |

### GyroParallaxCard widget tests

Gyroscope parallax on the selected image card (iOS/Android):

```bash
cd feature/image_viewer
flutter test test/view/widgets/gyro/gyro_parallax_card_test.dart
```

**Coverage (5 tests)**

| Test | Covers |
|------|--------|
| renders child when disabled | Pass-through when gyro disabled |
| renders child when enabled without gyro stream (non-mobile) | No-op on web/desktop |
| applies Transform when gyro stream emits and enabled | 3D tilt effect from gyroscope |
| stops applying Transform when disabled mid-stream | Cleanup when toggled off |
| disposes without error | Subscription cancellation |

Uses injectable `gyroscopeStream` for testing; on device uses `sensors_plus` gyroscope.

### Run all tests

From the repo root (`aurora_test/`):

```bash
# Run every test across all packages (120 tests)
cd app && flutter test && cd ../feature/image_viewer && flutter test && cd ../../core/services/share_service && flutter test

# Or run each package separately:
cd app && flutter test
cd feature/image_viewer && flutter test
cd core/services/share_service && flutter test

# image_viewer only (116 tests, main feature)
cd feature/image_viewer && flutter test

# With coverage
cd feature/image_viewer && flutter test --coverage
# Business logic only (bloc, cubit, data, domain, utils, di)
cd feature/image_viewer && flutter test --coverage && sh scripts/coverage_business_logic.sh

# Golden tests — update snapshots after UI changes
cd feature/image_viewer && flutter test test/golden/golden_test.dart --update-goldens
```

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
