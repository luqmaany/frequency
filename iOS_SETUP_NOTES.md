# iOS Setup Notes

## Firebase Configuration

### GoogleService-Info.plist Setup
- **IMPORTANT**: The GoogleService-Info.plist file must be manually added to the Runner target in Xcode
- Even if the file exists in `ios/Runner/` directory, it needs to be properly added to the Xcode project
- Steps to add:
  1. Download GoogleService-Info.plist from Firebase Console
  2. Open `ios/Runner.xcworkspace` in Xcode
  3. Right-click on the Runner folder in the project navigator
  4. Select "Add Files to 'Runner'"
  5. Choose the GoogleService-Info.plist file
  6. Ensure "Copy items if needed" is checked
  7. Make sure the Runner target is selected
  8. Click "Add"

### Bundle Identifier
- Changed from `com.example.convey` to `com.kataali.frequency`
- Updated in both Xcode project and Firebase options

### Firebase Options
- Updated `lib/firebase_options.dart` with correct iOS app ID: `1:178068463522:ios:bff606b5b04cb6dd185cfb`

## Build Issues Resolved

### BoringSSL-GRPC -G Flag Error
- Fixed by updating Firebase packages to newer versions:
  - Firebase: 10.25.0 → 11.15.0
  - BoringSSL-GRPC: 0.0.32 → 0.0.37
  - gRPC-Core: 1.62.5 → 1.69.0

### Xcode PIF Transfer Session Error
- Resolved by:
  1. Killing all Xcode processes
  2. Clearing Xcode derived data
  3. Running `flutter clean`
  4. Removing iOS build directories
  5. Reinstalling pods

## Current Status
✅ iOS app successfully running on iPhone 16 Plus simulator
✅ Firebase connected and working
✅ Sound service initialized
✅ DevTools available for debugging
