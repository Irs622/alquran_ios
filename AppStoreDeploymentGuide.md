# App Store Deployment Guide

## 1. Setup and Preparation
1. Open `alquran/alquran.xcodeproj` in Xcode.
2. Select the production target and ensure the correct bundle identifier is set.
3. Confirm the Apple Developer team is selected in Signing & Capabilities.
4. Set the build configuration to `Release` for archive builds.
5. Confirm the app uses the latest supported iOS SDK and compiles cleanly.

## 2. Offline and Privacy Readiness
1. Verify `Resources/QuranSample.json` is bundled and available for offline use.
2. Confirm caching and persistence logic is robust through app launches.
3. Confirm `Info.plist` contains required usage descriptions for any permissions.
4. Validate that the app does not request unnecessary permissions.
5. Confirm the privacy policy URL is live and referenced in App Store Connect.

## 3. Build and Test
1. Clean the build folder: `Product > Clean Build Folder`.
2. Run unit tests for `alquran` and `Tests`.
3. Run UI tests for search, audio, and offline flows.
4. Test on a physical device for App Store–like performance.
5. Use `Instruments` to verify memory and CPU behavior.

## 4. Archive and Upload
1. Choose `Product > Archive`.
2. Once archived, click `Distribute App`.
3. Choose `App Store Connect` and follow the upload flow.
4. Validate the archive in Xcode before upload.
5. Upload the archive and confirm the build appears in App Store Connect.

## 5. App Store Connect Configuration
1. Add version-specific release notes and description.
2. Set the app category, keywords, and support URL.
3. Add a privacy policy URL and any required compliance information.
4. Upload screenshots for supported device sizes.
5. Complete export compliance and content rating sections.
6. Confirm the App Privacy questionnaire is accurate.

## 6. Release and Monitoring
1. Submit the app for review.
2. Monitor the build processing status.
3. Address App Review feedback quickly if needed.
4. After approval, verify the live app and listing.
5. Monitor analytics and crash reporting for the first 24–72 hours.
6. Plan hotfix updates if any issues appear.

## 7. Recommended Deployment Tools
- Use Xcode’s Organizer for archive validation and submission.
- Optionally add Fastlane for repeatable build and upload automation.
- Add `Scripts/` for release version stamping and changelog generation.
- Use a crash reporting service such as Firebase Crashlytics or Sentry.
