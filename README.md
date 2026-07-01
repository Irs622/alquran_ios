# Quran Companion

A production-ready SwiftUI Quran companion app with Quran API integration, audio playback, advanced search, daily verse features, notifications, caching, and resilient error handling.


## What’s included

- Quran API integration using `api.alquran.cloud`
- Offline JSON fallback for core surah content
- Full surah / single ayah audio playback
- Background playback with lock screen controls
- Advanced search across surah names, ayah text, and translations
- Daily verse generator and random verse suggestion
- Caching and persistence for offline support
- Error handling, logging, and sample unit tests

## Architecture

- `Models/` for domain data
- `ViewModels/` for state and business logic
- `Views/` for SwiftUI screens and components
- `Services/` for API, caching, audio, persistence, notifications, and logging

## Setup

1. Open `alquran/alquran.xcodeproj` in Xcode.
2. Ensure the `Resources/QuranSample.json` file is included in the target.
3. Choose an iOS Simulator and build.
4. If you want phone testing, update signing to your team and device profile.

## Notes

- API requests use a public Quran API.
- Audio playback uses remote ayah audio URLs and caches downloaded audio files.
- The app stores bookmarks, user preferences, and last read position locally.

## Production checklist
See `AppStoreChecklist.md`, `AppStoreReleaseChecklist.md`, and `AppStoreDeploymentGuide.md` for deployment and release readiness steps.
