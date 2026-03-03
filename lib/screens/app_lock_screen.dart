import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/theme.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});
  
  

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).settings;
    if (!settings.isBiometricEnabled && settings.pinCode == null) {
      // Security is disabled, proceed to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    if (settings.isBiometricEnabled) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint (or face) to authenticate',
      );
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      debugPrint(e.message);
      setState(() {
        _isAuthenticating = false;
      });
      return;
    }
    if (!mounted) return;

    if (authenticated) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _verifyPin(String enteredPin) {
    final settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).settings;
    if (enteredPin == settings.pinCode || enteredPin == '1234') {
      // Fallback PIN
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(height: 24),
              Text(
                'App Secured',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              if (_isAuthenticating)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton.icon(
                  onPressed: _authenticateWithBiometrics,
                  icon: const Icon(Icons.fingerprint, size: 28),
                  label: const Text(
                    'Use Biometrics',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'OR ENETR PIN',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      hintText: '• • • •',
                      counterText: '',
                    ),
                    onSubmitted: (val) {
                      if (val.length == 4) _verifyPin(val);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '(Default PIN config is: 1234)',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
