# App Store Production Checklist

## Performance and Architecture
- [ ] Verify the app uses offline-first data flows for core Quran content.
- [ ] Confirm `QuranSample.json` fallback is available when the network is unavailable.
- [ ] Ensure view updates are efficient and avoid expensive recomputation in SwiftUI.
- [ ] Confirm audio caching and playback remain responsive during background playback.
- [ ] Use Instruments to validate memory, CPU, and disk I/O for primary workflows.

## Offline Support
- [ ] Confirm cached surah summaries and ayahs load when offline.
- [ ] Verify downloaded audio files are available in offline mode.
- [ ] Ensure search works on locally cached data when no network is available.
- [ ] Validate graceful fallback for any API failure with clear user messaging.

## Error Handling
- [ ] Implement user-friendly network error states and retry affordances.
- [ ] Confirm loading states and placeholder content are shown during slow connections.
- [ ] Verify unexpected data or decode failures do not crash the app.
- [ ] Ensure logging captures enough details for debugging without leaking private data.

## Testing
- [ ] Run unit tests for models, view models, services, and persistence.
- [ ] Verify UI tests cover key user journeys including discovery, audio playback, and offline scenarios.
- [ ] Confirm critical flows pass on physical devices and multiple simulator configurations.

## Security and Privacy
- [ ] Confirm no API keys or secrets are hardcoded in the repository.
- [ ] Verify all network communication is HTTPS and App Transport Security policies are met.
- [ ] Ensure `Info.plist` contains required privacy usage descriptions if permissions are used.
- [ ] Confirm the app only requests permissions necessary for the experience.
- [ ] Add a privacy policy URL and make it available in App Store Connect.

## App Store Compliance
- [ ] Ensure the app adheres to Apple’s App Store Review Guidelines.
- [ ] Confirm metadata and screenshots accurately represent the app experience.
- [ ] Verify the app supports the declared iOS versions and devices.
- [ ] Confirm any third-party content or services are licensed for distribution.

## Analytics and Crash Reporting
- [ ] Integrate an analytics solution for user engagement and playback events.
- [ ] Add crash reporting to capture release-stage failures.
- [ ] Confirm analytics and crash reporting respect user privacy and do not send PII.

## Release Readiness
- [ ] Validate the app bundle identifier, version, and build number.
- [ ] Confirm release build configuration, signing, and provisioning are correct.
- [ ] Ensure icons, launch screen, and app assets are production quality.
- [ ] Archive and validate the app in Xcode before upload.
- [ ] Confirm the App Store privacy questionnaire and content rating are complete.
- [ ] Review the privacy policy and support URLs in App Store Connect.
