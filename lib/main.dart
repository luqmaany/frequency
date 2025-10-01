import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'screens/home_screen.dart';
import 'services/theme_provider.dart';
import 'services/storage_service.dart';
import 'data/category_registry.dart';
import 'services/purchase_service.dart';

// Set to true to use Firebase Emulators for local development
// This gives you unlimited free reads/writes!
const bool USE_EMULATOR = false;

// IMPORTANT: For multiple devices, set your computer's local IP here
// Find it by running: ipconfig (Windows) or ifconfig (Mac/Linux)
// Example: '192.168.1.100'
//
// Special cases:
// - 'localhost' = Only works for apps running on the same computer as emulator
// - '10.0.2.2' = Auto-used for Android emulators (points to host machine)
// - Your local IP = Use for physical devices on same WiFi network
const String EMULATOR_HOST = 'localhost'; // Change this for physical devices!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent duplicate Firebase app initialization
  if (Firebase.apps.isEmpty) {
    // On iOS/macOS this uses GoogleService-Info.plist bundled in the app
    await Firebase.initializeApp();
  }

  // Connect to Firebase Emulator in debug mode
  if (USE_EMULATOR && kDebugMode) {
    try {
      // Determine the correct host based on platform
      String host = EMULATOR_HOST;

      // Android emulators need special IP to reach host machine
      if (defaultTargetPlatform == TargetPlatform.android &&
          EMULATOR_HOST == 'localhost') {
        host = '10.0.2.2';
        debugPrint('📱 Detected Android - using 10.0.2.2 for emulator access');
      }

      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      debugPrint('🔥 Connected to Firestore Emulator on $host:8080');
      debugPrint('💰 All reads/writes are FREE in emulator mode!');
    } catch (e) {
      debugPrint('⚠️ Failed to connect to emulator: $e');
      debugPrint('   Make sure emulator is running: firebase emulators:start');
      debugPrint('   For physical devices, set EMULATOR_HOST to your PC\'s IP');
    }
  }
  await CategoryRegistry.loadDynamicCategories();
  await PurchaseService.init();
  // Try background restore without blocking startup; ignore errors offline
  // No unawaited available; fire-and-forget
  // ignore: discarded_futures
  PurchaseService.restorePurchases();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // Hide status/navigation bars globally for the whole app
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  debugPrint('=== App Starting ===');
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize default names on first run
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StorageService.initializeDefaultNames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = ref.watch(darkThemeProvider);

    return MaterialApp(
      title: 'Frequency',
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Colors.amber,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20), // Add some spacing
            FloatingActionButton(
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
