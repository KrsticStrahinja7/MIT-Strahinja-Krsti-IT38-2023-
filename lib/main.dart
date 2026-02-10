import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/seasons_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/login_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await FirebaseMessaging.instance.requestPermission();
  } catch (_) {
    // ignore
  }

  if (kDebugMode) {
    final host = kIsWeb
        ? 'localhost'
        : (defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost');
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<AuthProvider, OrdersProvider>(
          create: (_) => OrdersProvider(),
          update: (_, auth, orders) {
            final p = orders ?? OrdersProvider();
            p.setUser(uid: auth.uid, isAdmin: auth.isAdmin);
            return p;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (_) => WishlistProvider(),
          update: (_, auth, wishlist) {
            final p = wishlist ?? WishlistProvider();
            p.setUser(auth.uid);
            return p;
          },
        ),
        ChangeNotifierProvider(create: (_) => SeasonsProvider()..load()),
      ],
      child: MaterialApp(
        title: 'F1Pass',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.redAccent,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
          ),
          cardColor: const Color(0xFF121212),
        ),
        home: const RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<AuthProvider, bool>((p) => p.isLoggedIn);
    final isAdmin = context.select<AuthProvider, bool>((p) => p.isAdmin);
    final cartCount = context.select<CartProvider, int>((p) => p.totalItems);
    final navIndex = context.select<NavigationProvider, int>((p) => p.index);

    final pages = <Widget>[
      const HomeScreen(),
      const SearchScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminScreen(),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    final effectiveIndex = navIndex >= pages.length ? 0 : navIndex;
    if (effectiveIndex != navIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<NavigationProvider>().setIndex(effectiveIndex);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const _LogoTitle(),
        centerTitle: true,
        actions: [
          if (!isLoggedIn)
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text('Login'),
            )
          else ...[
            IconButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
              },
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              tooltip: 'Korpa',
            ),
            IconButton(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                context.read<NavigationProvider>().reset();
                context.read<CartProvider>().clear();
                context.read<OrdersProvider>().clear();
                context.read<WishlistProvider>().clear();
              },
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
        ],
      ),
      body: pages[effectiveIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: effectiveIndex,
        onTap: (i) => context.read<NavigationProvider>().setIndex(i),
        items: items,
      ),
    );
  }
}

class _LogoTitle extends StatelessWidget {
  const _LogoTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.sports_motorsports, size: 24),
        SizedBox(width: 8),
        Text('F1Pass', style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
