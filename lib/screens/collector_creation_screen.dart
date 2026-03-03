import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class CollectorCreationScreen extends StatefulWidget {
  const CollectorCreationScreen({super.key});
  
  

  @override
  State<CollectorCreationScreen> createState() =>
      _CollectorCreationScreenState();
}

class _CollectorCreationScreenState extends State<CollectorCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _designationController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _designationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveCollector() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final organizationId = authProvider.currentUser?.organizationId ?? '';

    try {
      final newCollector = UserModel(
        id: '', // Will be replaced by Firebase Auth UID in addUser()
        fullName: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        role: 'collector',
        organizationId: organizationId,
        status: 'active',
        designation: _designationController.text.trim().isEmpty
            ? null
            : _designationController.text.trim(),
        createdAt: DateTime.now(),
        username: _emailController.text.trim().split('@').first,
        organizationName: authProvider.currentUser?.organizationName,
      );

      await authProvider.addUser(newCollector, _passwordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Collector Created Successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Add New Collector')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Personal Details'),
              _field(
                _nameController,
                'Full Name',
                Icons.person,
                validator: _required,
              ),
              const SizedBox(height: 16),
              _field(
                _mobileController,
                'Mobile Number',
                Icons.phone,
                type: TextInputType.phone,
                validator: _required,
              ),
              const SizedBox(height: 16),
              _field(
                _designationController,
                'Designation (Optional)',
                Icons.badge,
              ),

              const SizedBox(height: 32),
              _sectionTitle('Login Credentials'),
              _field(
                _emailController,
                'Email Address',
                Icons.email_outlined,
                type: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email required';
                  }
                  if (!val.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _passwordField(),

              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveCollector,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
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
                        'Create Collector Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: type,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator: validator,
  );

  Widget _passwordField() => TextFormField(
    controller: _passwordController,
    obscureText: _obscurePassword,
    decoration: InputDecoration(
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    ),
    validator: (val) =>
        val == null || val.length < 6 ? 'Minimum 6 characters' : null,
  );

  String? _required(String? val) =>
      val == null || val.trim().isEmpty ? 'Required' : null;
}
