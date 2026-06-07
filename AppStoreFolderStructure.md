# App Store Quality Folder Structure

This is the recommended final folder structure for a production-grade Quran Companion app.

Root
- AppStoreChecklist.md
- AppStoreReleaseChecklist.md
- AppStoreDeploymentGuide.md
- AppStoreFolderStructure.md
- README.md
- .gitignore
- alquran.xcodeproj/
- alquran.xcworkspace/ (if generated)
- build/ (generated, do not commit)
- docs/ (optional for extended guides)
- Scripts/ (optional automation and release scripts)
- Localization/ (if you add additional languages)
- Tests/ (top-level UI/Integration tests)

alquran/
- alquranApp.swift
- ContentView.swift
- Assets.xcassets/
- Models/
  - QuranModels.swift
  - MockData.swift
- Services/
  - AudioPlayerService.swift
  - CacheService.swift
  - PersistenceService.swift
  - QuranAPIService.swift
  - QuranDataStore.swift
  - QuranDataValidator.swift
  - QuranRepository.swift
  - QuranSyncService.swift
  - NotificationService.swift
  - Logger.swift
  - TanzilDataImporter.swift
- ViewModels/
  - HomeViewModel.swift
  - QuranViewModel.swift
  - SearchViewModel.swift
  - SettingsViewModel.swift
  - SurahDetailViewModel.swift
  - BookmarksViewModel.swift
- Views/
  - HomeView.swift
  - QuranView.swift
  - SearchView.swift
  - SettingsView.swift
  - SurahDetailView.swift
  - BookmarksView.swift
  - MainTabView.swift
  - Components/
    - AudioPlayerControlsView.swift
    - AyahRowView.swift
    - EmptyStateView.swift
    - QuickActionButton.swift
    - SectionHeaderView.swift
    - SurahCardView.swift
    - SurahRowView.swift
- Resources/
  - QuranSample.json
  - Localization files
  - Custom fonts or sharable assets
- Utilities/
  - Theme.swift
- Tests/
  - Unit and integration tests for the app module

Recommended additions for App Store quality
- `Localization/` or `alquran/Resources/Localization/` for translated UI strings
- `docs/` for release notes, user privacy policy drafts, and app architecture
- `Scripts/` or `Fastlane/` for build automation and App Store uploads
- `UITests/` for full navigation and audio playback flows
- `Security/` for internal notes on key management and audit findings

> Keep generated artifacts like `build/` out of source control with `.gitignore`.
