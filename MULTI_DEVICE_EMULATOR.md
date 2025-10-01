# 🔌 Connecting Multiple Devices to Firebase Emulator

Yes! You can test multiplayer with multiple devices using the emulator. Here's how:

---

## 📱 **Different Device Scenarios**

### Scenario 1: Single Android Emulator on Your PC
**Current Setup:** ✅ Already configured!
- `EMULATOR_HOST = 'localhost'` 
- Auto-converts to `10.0.2.2` for Android emulators
- Just run and it works!

---

### Scenario 2: Multiple Android Emulators on Same PC
**Setup:** ✅ Already configured!
- Start multiple Android emulators
- All will use `10.0.2.2` automatically
- They'll all connect to the same Firestore emulator

**Example:**
```powershell
# Terminal 1: Start emulator
firebase emulators:start --only firestore

# Terminal 2: Start first Android emulator
flutter run -d emulator-5554

# Terminal 3: Start second Android emulator  
flutter run -d emulator-5556
```

Both emulators can join the same game session! 🎮

---

### Scenario 3: Physical Device(s) + Your PC
**Requires:** Setting your PC's local IP address

#### Step 1: Find Your PC's IP Address

**Windows:**
```powershell
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter:
```
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . . . . . . . . . : 192.168.1.100  ← This one!
```

**Mac/Linux:**
```bash
ipconfig getifaddr en0  # Usually WiFi
# or
ifconfig | grep "inet "
```

#### Step 2: Update EMULATOR_HOST in lib/main.dart

```dart
// Line 25 in lib/main.dart
const String EMULATOR_HOST = '192.168.1.100';  // Your PC's IP
```

#### Step 3: Ensure All Devices on Same WiFi
- PC running emulator: Connected to WiFi
- Physical device(s): Connected to **same WiFi network**

#### Step 4: Allow Firewall Access (Windows)

The first time, Windows may ask to allow Firebase through the firewall - **Allow it!**

Or manually add a rule:
```powershell
# Run as Administrator
netsh advfirewall firewall add rule name="Firebase Emulator" dir=in action=allow protocol=TCP localport=8080
```

#### Step 5: Run Your App

```powershell
# On PC: Start emulator
firebase emulators:start --only firestore

# Deploy to physical device
flutter run -d <your-device-id>
```

Your physical device will connect to the emulator! 📱

---

### Scenario 4: Mix of Everything
Want to test with 2 Android emulators + 2 physical phones? **You can!**

**Setup:**
1. Set `EMULATOR_HOST = '192.168.1.100'` (your PC's IP)
2. Start Firebase emulator on PC
3. Run app on all devices:
   - Android emulators will use `10.0.2.2` (auto-detected)
   - Physical devices will use `192.168.1.100`

**All devices connect to the same emulator!** 🎉

---

## 🔧 Quick Reference Card

| Device Type | EMULATOR_HOST Setting | What Happens |
|------------|----------------------|--------------|
| Android Emulator (on PC) | `'localhost'` | ✅ Auto-converts to `10.0.2.2` |
| iOS Simulator (on Mac) | `'localhost'` | ✅ Works directly |
| Physical Phone (same WiFi) | `'192.168.1.XXX'` | ✅ Uses your PC's IP |
| Multiple Emulators (same PC) | `'localhost'` | ✅ All connect via `10.0.2.2` |
| Mix (emulators + phones) | `'192.168.1.XXX'` | ✅ Emulators auto-convert, phones use IP |

---

## 🎮 Testing Multiplayer Example

Let's test a 4-player game:

**Setup:**
```dart
// lib/main.dart line 25
const String EMULATOR_HOST = '192.168.1.100'; // Your PC's IP
```

**Run:**
```powershell
# Terminal 1: Start emulator
.\start_emulator.ps1

# Terminal 2: Android Emulator 1
flutter run -d emulator-5554

# Terminal 3: Android Emulator 2
flutter run -d emulator-5556

# Terminal 4: Physical Phone 1
flutter run -d SM123456  # Your phone's device ID

# Terminal 5: Physical Phone 2
flutter run -d iPhone789  # Friend's phone
```

**Result:**
- All 4 devices connect to the same emulator
- Create a session on Device 1
- Join from Devices 2, 3, 4
- **Zero Firestore cost!** 💰

---

## 🐛 Troubleshooting

### ❌ "Failed to connect to emulator"

**Physical Device:**
1. Check both PC and phone on **same WiFi**
2. Verify PC's IP address: `ipconfig`
3. Update `EMULATOR_HOST` with correct IP
4. Check firewall allows port 8080
5. Try accessing emulator UI from phone's browser: `http://192.168.1.100:4000`

**Android Emulator:**
1. Make sure emulator is started: `firebase emulators:start`
2. Should auto-use `10.0.2.2` (check console output)
3. Try running: `adb devices` to verify emulator is running

### ❌ "Connection refused"

**Firewall blocking port 8080:**
```powershell
# Windows - run as Administrator
netsh advfirewall firewall add rule name="Firebase Emulator" dir=in action=allow protocol=TCP localport=8080
```

**Mac:**
```bash
# Usually no firewall config needed, but if blocked:
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/firebase
```

### ❌ "Can't see other players' moves"

1. Check all devices show: `🔥 Connected to Firestore Emulator`
2. Verify all using same IP/host
3. Open emulator UI (`http://localhost:4000`) to see if writes are happening
4. Check all devices have `USE_EMULATOR = true`

### ❌ "Sometimes connects to production, sometimes emulator"

You might have **mixed debug/release builds**:
- Emulator **only works in debug mode**
- Release builds always use production

**Solution:** Always use debug builds during development:
```powershell
flutter run  # Debug mode (uses emulator)
# NOT: flutter run --release  # This uses production!
```

---

## 💡 Pro Tips

### Tip 1: Quick IP Change
Create a `.env` or config file so you don't have to edit code:
```dart
// For now, just edit line 25 in lib/main.dart when switching networks
```

### Tip 2: Test On Different Networks
Can't get devices on same WiFi? Two options:
1. **Use production** (but costs money) - set `USE_EMULATOR = false`
2. **Use ngrok** to tunnel emulator port (advanced)

### Tip 3: Emulator UI is Your Friend
While testing, keep `http://localhost:4000` open to:
- See all connected sessions in real-time
- Verify writes from all devices
- Manually edit data to test edge cases

### Tip 4: Hot Restart After IP Change
After changing `EMULATOR_HOST`:
```
Press 'R' in Flutter terminal to hot restart
```
Or rebuild completely:
```powershell
flutter run
```

---

## 📊 Cost Comparison

### With Emulator (Local Testing):
| Scenario | Devices | Sessions | Reads | Writes | Cost |
|----------|---------|----------|-------|--------|------|
| Heavy testing | 4 devices | 50 games | ~50,000 | ~10,000 | **$0.00** ✅ |

### Without Emulator (Production Testing):
| Scenario | Devices | Sessions | Reads | Writes | Cost |
|----------|---------|----------|-------|--------|------|
| Heavy testing | 4 devices | 50 games | ~50,000 | ~10,000 | **~$28.80** 💸 |

**Save money, use the emulator!** 💰

---

## 🎯 Quick Start Checklist

For testing with multiple physical devices:

- [ ] Find PC's IP address: `ipconfig`
- [ ] Update `EMULATOR_HOST` in `lib/main.dart` (line 25)
- [ ] Ensure all devices on **same WiFi**
- [ ] Allow port 8080 through firewall
- [ ] Start emulator: `.\start_emulator.ps1`
- [ ] Run app on all devices: `flutter run -d <device-id>`
- [ ] Verify each device shows: `🔥 Connected to Firestore Emulator`
- [ ] Test! Create/join sessions across devices

---

**Happy multiplayer testing! 🎮🔥**

