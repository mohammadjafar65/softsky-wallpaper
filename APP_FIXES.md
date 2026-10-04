# Wallpaper app fixes

The existing screens, visual styling, animations, navigation, and purchase flows are preserved. Changes target loading, data correctness, and error handling.

## Changes

- One shared wallpaper disk cache replaces repeated cache-manager creation. Cards, pack covers, detail previews, downloads, and automatic wallpaper downloads use that cache.
- Wallpaper data appears when its request finishes instead of waiting for categories, packs, wide images, and Pro images together.
- Failed API refreshes retain previously cached content instead of replacing it with empty lists.
- Free category feeds have isolated results and consistent page sizes. Returning to All reloads its first page. Older category responses cannot overwrite the selected category.
- The home grid and empty/loading states use the selected feed. Pack cards use the wallpaper provider's live pack data.
- Search actually debounces typing, ignores stale responses, and invalidates pending results when cleared or disposed.
- Missing thumbnail URLs fall back to the original image.
- Mutating API calls are sent once; safe GET requests retain their retry behavior. This avoids accidental duplicate comments, repeated download counts, and reversed like/save toggles.
- The backend accepts category IDs and slugs, constrains unknown categories, bounds pagination, and sorts equal-date records consistently. Category filtering no longer requires a separate category lookup.
- Local storage opens in parallel. Wallpapers preload during the existing splash screen. Backend session restoration starts without delaying the first frame; the splash still waits for restoration before navigation. Concurrent initialization calls share one restoration task.
- Wallpaper totals include free, Pro, and wide collections. Category wallpaper lookups and download counts include the selected category feed.

## Validation

The complete Flutter regression suite passed (9 tests), and the backend build/test command passed (4 tests). Final Dart analysis completed with no issues. The Android debug APK built successfully on 4 October 2026 and was installed and launched on the Pixel_9 emulator. `git diff --check` passed. The Windows Flutter launcher delayed the build; invoking the Flutter tool snapshot directly completed compilation.

Emulator smoke checks covered guest onboarding, dismissing the existing Pro offer, the home feed (374 free wallpapers), opening wallpaper detail after dismissing the existing interstitial advertisement, and searching for nature (20 results). App-specific logs showed successful wallpaper and pack requests, with no unhandled app exception observed during these checks. The APK is available locally at `awg_wallpaper/build/app/outputs/apk/debug/app-debug.apk`.

Flutter regression tests cover thumbnail fallback, slow optional API requests, failed cache refresh, category pagination and lookup, stale search/category responses, clearing search, debounce, and safe toggle retries. Backend tests exercise the real wallpaper route with a controlled database boundary for category predicates, pagination limits, and stable ordering.

Run from `awg_wallpaper`: `flutter test` and `flutter analyze`.

Run from `awg-backend`: `npm test` (builds TypeScript and runs Node's built-in test runner).

## Release checks

App and backend fixes were pushed to GitHub main as commit `3bee864`. Live backend deployment was not verified; the requested publication was a GitHub push. Further device testing is needed for gallery permissions, home/lock wallpaper application, background scheduling, purchases, and detailed visual comparison. No measured release-mode device speedup or comprehensive bug-free certification is claimed.
