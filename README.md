# aurora_test

Attached in my Coding Assessment for Aurora

### The app contains the following ###

### Launch
1. Native splash screen (platform launch screen)
2. Launcher video 
3. Streaming in initial batch of images – preloads whilst the video plays

### Fetching and Processing Images
4. Background fetch – awaiting more images in the background as the user scrolls, triggered by their position in the carousel
5. Manual fetch – users can request more images via the another button when we don't have any prefetched
6. Prefetch caching – if we have images preloaded we give the impression of low latency
7. Data augmentation – use of an LLM interface (ChatGPT or Gemini) to provide the image with a title and description for accessibility
8. Duplication management – ensure no images are duplicated, using both URL checking and pixel color analysis. If we get 3 duplicate images in a row, we notify the user
9. Exponential back off – if we receive an error from our image fetching service we retry with exponential back off until the target batch is satisfied or we hit our attempt limit
10. Image visualisation fallbacks – we save the image locally and use cached network images so we have stable loading into the widget (no empty state)

### UI
11. Expansion mode - expand the image such that you can see the title, description and colour palette of the image
12. Linear interpolation between colors – as the carousel moves the background palette changes with respect to the ratio of which image is primarily visible
13. Expandable image cards – tap an image to expand and see the full title and description, with the play button for TTS
14. Accessibility – interfaces with Eleven Labs API to read out the short story/description of the image
15. Favourite and Share – users can favourite and share images (share uses the local image and description)
16. Dynamic 'Another' button – changes colour based on the image's color palette, ensuring at least 7 contrast levels for accessibility and holds next up image or selected image as a faint background. 
17. Light and Dark mode – toggle via the button at the top right
18. Control bar – collapsible and updates to changes in selected image colors
19. Main button – dynamic and changes depending on whether we're in image view, loading view or expanded (play/pause for TTS)
20. Error dialogs – we surface fetch failures and duplicate exhaustion so the user knows what's going on


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
- `cubit` – TtsCubit for playback, FavouritesCubit for favourites (kept separate to limit rebuilds)
- `view` – Flow (ImageViewerFlow) orchestrates video + image viewer, plus pages and widgets

**Patterns**

- Bloc for complex state, Cubit for simpler concerns
- GoRouter for app-level navigation; FlowBuilder-style flows inside features
- Features communicate via the app layer (e.g. callbacks passed from the router), not directly with each other
- Core packages are shared; features depend on core, not the other way around

### Architectural decisions

**With more time – Optimisation, Refactoring Eleven Labs and LLM resilience**

The view layer (control bar, image carousel, main view) could be broken down further and optimised. Right now some widgets are doing more than they should and the nesting can get deep. I prioritised UX and polish and getting the flow and behaviour right over refactoring the UI into smaller, more composable pieces. That refactor would be a natural next step – extracting more presentational components, tightening the separation between layout and logic, and reducing rebuild scope.

I would make Eleven Labs (TTS) and LLM (ChatGPT/Gemini) failures more robust – retries, fallbacks, clearer error handling and user feedback when those services fail.

**No Retrofit – raw Dio**

API calls use Dio directly rather than Retrofit. For this project we only have a handful of endpoints (Unsplash for image URLs, Eleven Labs for TTS, ChatGPT/Gemini for image analysis), and the request/response shapes are fairly simple. Retrofit would add another layer and codegen without much payoff at this scale. If the API surface grows or we standardise on more REST-style resources, Retrofit would make sense. For now Dio alone keeps things straightforward.

**Overall focus**

Polish and end experience were the key focus here – making it feel good to use, with smooth transitions, clear feedback and no rough edges.

