# App Store Release Checklist

## Pre-Release Validation
- [ ] Increment build number and version string in Xcode (`CFBundleShortVersionString`, `CFBundleVersion`).
- [ ] Confirm all target architectures are supported for current iOS releases.
- [ ] Ensure `App Store` provisioning and code signing are configured for the production target.
- [ ] Confirm there are no unresolved warnings or deprecated APIs in the app.
- [ ] Verify App Icons and Launch Screen assets are complete and match branding.
- [ ] Verify localization support and translated strings if deploying to additional markets.
- [ ] Confirm privacy info plist keys are present for network, audio, and notification use.
- [ ] Validate that no sensitive or secret values are hardcoded.

## Testing
- [ ] Run unit tests and ensure 100% pass rate for critical service and model logic.
- [ ] Run UI tests covering:
  - app startup
  - search and discovery flows
  - offline fallback behavior
  - audio playback, pause, resume, and lock screen controls
  - settings and preferences
- [ ] Test on physical devices across supported iOS versions.
- [ ] Run `Instruments` for memory leaks, CPU spikes, and disk I/O.
- [ ] Validate offline-first behavior with flight mode and with a stale cache.
- [ ] Confirm feature gating and error states show friendly retry messages.

## App Store Connect
- [ ] Prepare release notes for this version.
- [ ] Confirm App Store metadata matches the app experience.
- [ ] Add support URLs, marketing URLs, and privacy policy URL.
- [ ] Verify screenshots and promotional art adhere to App Store guidelines.
- [ ] Set an appropriate app category and content rating.
- [ ] Confirm the privacy questionnaire is completed accurately.
- [ ] Confirm any third-party libraries are properly documented.

## Archive and Upload
- [ ] Build an Archive in Release configuration.
- [ ] Validate the archive in Xcode.
- [ ] Upload the build to App Store Connect.
- [ ] Confirm the uploaded build appears and processes successfully.

## Post-Upload
- [ ] Review App Store Connect processing status.
- [ ] Confirm App Store metadata and version information are accurate.
- [ ] Enable phased release if appropriate.
- [ ] Monitor App Store review notes and respond to reviewer questions.
- [ ] After approval, verify the live app on the App Store and begin analytics monitoring.
