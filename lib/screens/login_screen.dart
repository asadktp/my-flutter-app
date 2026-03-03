import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';
import '../widgets/pricing_section.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isAdminLogin = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    debugPrint('[Login] Login button pressed');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final user = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        expectedRoleType: _isAdminLogin ? 'admin' : 'collector',
      );

      if (!mounted) return;

      if (user != null) {
        final orgProvider = Provider.of<OrganizationProvider>(
          context,
          listen: false,
        );
        orgProvider.loadOrganization(user.organizationId ?? '');
        debugPrint('[Login] Login success — role: ${user.role}');

        if (authProvider.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/collector');
        }
      } else if (authProvider.isReadOnly) {
        debugPrint('[Login] Subscription expired or Org Suspended');
        _showSubscriptionExpiredDialog();
      } else {
        debugPrint('[Login] Login failed — ${authProvider.lastError}');
        _showError(authProvider.lastError ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      debugPrint('[Login] Unhandled exception: $e');
      if (mounted) {
        _showError('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSubscriptionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.accent),
            const SizedBox(width: 8),
            const Text('Subscription Expired'),
          ],
        ),
        content: const Text(
          'Your organization\'s subscription has expired.\n\n'
          'Please contact your administrator to renew the subscription.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Responsive(mobile: _buildMobileLayout(), desktop: _buildWebLayout()),
          // Dark mode toggle — top right corner
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return _DarkModeToggle(themeProvider: themeProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      color: AppTheme.primary,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoSection(),
                const SizedBox(height: 48),
                _buildLoginForm(isMobile: true),
                const SizedBox(height: 32),
                const PricingSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Container(
      color: AppTheme.primary,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLogoSection(),
              const SizedBox(height: 48),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: _buildLoginForm(isMobile: false),
                ),
              ),
              const SizedBox(height: 60),
              const Opacity(
                opacity: 0.5,
                child: Divider(
                  thickness: 1,
                  color: Colors.white,
                  indent: 100,
                  endIndent: 100,
                ),
              ),
              const SizedBox(height: 24),
              const PricingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(60), width: 2),
          ),
          child: const Center(
            child: Icon(
              Icons.volunteer_activism_rounded,
              size: 45,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Donation App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Premium Management Experience',
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm({required bool isMobile}) {
    // Fields palette for the dark background
    const fieldTextColor = Color(0xFF0F172A);
    const fieldLabelColor = Color(0xFF64748B);
    const fieldPrefixColor = AppTheme.primary;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: fieldTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: fieldLabelColor),
              ),
              const SizedBox(height: 32),
              _buildRoleToggle(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(
                  color: fieldTextColor,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    color: fieldPrefixColor,
                  ),
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(
                  color: fieldTextColor,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock_person_rounded,
                    color: fieldPrefixColor,
                  ),
                  fillColor: Colors.grey.shade50,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: fieldLabelColor,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.primary,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ).copyWith(elevation: const WidgetStatePropertyAll(0)),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RolePill(
              label: 'Admin',
              isActive: _isAdminLogin,
              onTap: () => setState(() => _isAdminLogin = true),
            ),
          ),
          Expanded(
            child: _RolePill(
              label: 'Collector',
              isActive: !_isAdminLogin,
              onTap: () => setState(() => _isAdminLogin = false),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _RolePill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? AppTheme.primary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

/// Compact dark mode toggle button shown on the login screen
class _DarkModeToggle extends StatelessWidget {
  const _DarkModeToggle({required this.themeProvider});
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDarkMode;
    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: isDark ? 0.5 : 0,
              duration: const Duration(milliseconds: 500),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isDark ? 'Dark Theme' : 'Light Theme',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
