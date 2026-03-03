import 'dart:async';
import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'screens/app_lock_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/collector_dashboard_screen.dart';
import 'screens/donation_entry_screen.dart';
import 'screens/donor_history_screen.dart';
import 'package:provider/provider.dart';
import 'screens/user_management_screen.dart';
import 'screens/organization_settings_screen.dart';
import 'screens/collector_creation_screen.dart';
import 'screens/collector_profile_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/admin_expenses_screen.dart';
import 'screens/institution_accounts_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/donation_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/organization_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/institution_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Main] Firebase initialized successfully');
  } catch (e) {
    debugPrint('[Main] Firebase initialization FAILED: $e');
    // Run app with an error UI so the spinner never freezes
    runApp(_FirebaseErrorApp(error: e.toString()));
    return;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DonationProvider>(
          create: (_) => DonationProvider(),
          update: (_, auth, donation) =>
              donation!..updateAuth(auth.currentUser),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider(),
          update: (_, auth, expense) => expense!..updateAuth(auth.currentUser),
        ),
        ChangeNotifierProxyProvider<AuthProvider, InstitutionProvider>(
          create: (_) => InstitutionProvider(),
          update: (_, auth, inst) => inst!..updateAuth(auth.currentUser),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, OrganizationProvider>(
          create: (_) => OrganizationProvider(),
          update: (_, auth, org) {
            final id = auth.currentUser?.organizationId ?? '';
            if (id.isNotEmpty) org!.loadOrganization(id);
            return org!;
          },
        ),
      ],
      child: const DonationApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DonationApp extends StatefulWidget {
  const DonationApp({super.key});

  @override
  State<DonationApp> createState() => _DonationAppState();
}

class _DonationAppState extends State<DonationApp> {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 30), () {
      _logoutUser();
    });
  }

  void _logoutUser() {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      final auth = Provider.of<AuthProvider>(ctx, listen: false);
      if (auth.currentUser != null) {
        auth.logout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Logged out due to 30 minutes of inactivity.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetTimer,
      onPanDown: (_) => _resetTimer(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Donation Management',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/login',
          routes: {
            '/login': (context) => LoginScreen(),
            '/lock': (context) => AppLockScreen(),
            '/admin': (context) => AdminDashboardScreen(),
            '/admin-expenses': (context) => AdminExpensesScreen(),
            '/institution-accounts': (context) => InstitutionAccountsScreen(),
            '/collector': (context) => CollectorDashboardScreen(),
            '/add-donation': (context) => DonationEntryScreen(),
            '/add-expense': (context) => AddExpenseScreen(),
            '/donor-history': (context) => DonorHistoryScreen(),
            '/manage-users': (context) => UserManagementScreen(),
            '/org-settings': (context) => OrganizationSettingsScreen(),
            '/add-collector': (context) => CollectorCreationScreen(),
            '/profile': (context) => CollectorProfileScreen(),
          },
        ),
      ),
    );
  }
}

/// Fallback app shown when Firebase fails to initialize.
/// Prevents infinite spinner on startup.
class _FirebaseErrorApp extends StatelessWidget {
  final String error;
  const _FirebaseErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F766E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, color: Colors.white, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Firebase Not Configured',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please add google-services.json to android/app/ and restart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
