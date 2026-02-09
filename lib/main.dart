import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/seasons_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/login_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
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
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<AuthProvider, bool>((p) => p.isLoggedIn);
    final isAdmin = context.select<AuthProvider, bool>((p) => p.isAdmin);
    final cartCount = context.select<CartProvider, int>((p) => p.totalItems);

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

    if (_index >= pages.length) {
      _index = pages.length - 1;
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
              onPressed: () {
                context.read<AuthProvider>().logout();
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
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
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
