# 🔥 Firebase Emulator Guide

## What is the Firebase Emulator?

The Firebase Emulator Suite runs Firebase services **locally on your computer** - this means:
- ✅ **Unlimited FREE reads/writes** (no cost at all!)
- ✅ **Faster development** (no internet latency)
- ✅ **Test safely** without affecting production data
- ✅ **Work offline** completely

## Setup (One-Time)

### 1. Install Firebase CLI (if not already installed)

```powershell
npm install -g firebase-tools
```

Verify installation:
```powershell
firebase --version
```

### 2. Login to Firebase

```powershell
firebase login
```

## Daily Development Workflow

### Step 1: Start the Emulator

Open a terminal and run:

```powershell
# Option A: Use the helper script
.\start_emulator.ps1

# Option B: Run directly
firebase emulators:start --only firestore
```

You should see:
```
✔  firestore: Emulator started at http://localhost:8080
✔  All emulators ready! View status at http://localhost:4000
```

**✨ Emulator UI at: http://localhost:4000**
- View all your Firestore data
- Manually add/edit documents
- Monitor reads/writes in real-time

### Step 2: Run Your Flutter App

In a **separate terminal**:

```powershell
flutter run
```

The app will automatically connect to the emulator when:
- `USE_EMULATOR = true` (line 15 in lib/main.dart)
- Running in debug mode

You'll see this in your console:
```
🔥 Connected to Firestore Emulator on localhost:8080
💰 All reads/writes are FREE in emulator mode!
```

### Step 3: Develop Freely! 🎉

Now you can:
- Create unlimited sessions
- Test multiplayer with multiple devices/emulators
- **NO COST** for any reads/writes!

## Toggle Between Emulator and Production

### Use Emulator (Development)
Set in `lib/main.dart`:
```dart
const bool USE_EMULATOR = true;  // Line 15
```

### Use Production (Testing/Release)
Set in `lib/main.dart`:
```dart
const bool USE_EMULATOR = false;  // Line 15
```

Or just build in release mode (emulator only works in debug mode):
```powershell
flutter build apk --release
```

## Tips & Tricks

### 1. **Pre-populate Test Data**

Visit http://localhost:4000 while emulator is running:
1. Click "Firestore"
2. Create test sessions manually
3. Add test data for categories

### 2. **View Real-Time Activity**

The Emulator UI shows:
- All read/write operations
- Document contents
- Query performance

### 3. **Clear Data**

Restart the emulator to reset all data:
```powershell
# Ctrl+C to stop, then restart
firebase emulators:start --only firestore
```

### 4. **Export/Import Data**

Export emulator data:
```powershell
firebase emulators:export ./emulator-data
```

Import data:
```powershell
firebase emulators:start --import=./emulator-data
```

## Troubleshooting

### "Address already in use"
Port 8080 is taken. Kill the process:
```powershell
# Find process using port 8080
netstat -ano | findstr :8080

# Kill it (replace PID with the actual process ID)
taskkill /PID <PID> /F
```

### "Failed to connect to emulator"
1. Make sure emulator is running first
2. Check if port 8080 is accessible
3. Try restarting the emulator

### App connects to production instead of emulator
1. Check `USE_EMULATOR = true` in lib/main.dart
2. Make sure you're running in **debug mode** (not release)
3. Check console for connection messages

## Cost Savings Example

**Normal Firestore costs (without emulator):**
- 1,000 reads = $0.36
- 1,000 writes = $1.08

**With emulator during development:**
- Unlimited reads = **FREE** 💰
- Unlimited writes = **FREE** 💰

**Save ~$50-100/month** during heavy development!

## When to Use Production vs Emulator

### Use Emulator For:
- ✅ Local development
- ✅ Testing new features
- ✅ Debugging issues
- ✅ Learning/experimenting
- ✅ Running automated tests

### Use Production For:
- ✅ Beta testing with real users
- ✅ Final pre-launch testing
- ✅ Release builds
- ✅ Testing cross-device sync (when devices aren't on same network)

---

**Happy coding! 🚀**

