import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../utils/theme.dart';
import '../models/donation_model.dart';
import 'package:provider/provider.dart';
import '../providers/donation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';
import 'receipt_preview_screen.dart';

import '../widgets/web_sidebar.dart';
import '../utils/responsive.dart';
import '../widgets/double_back_to_close.dart';

class DonationEntryScreen extends StatefulWidget {
  const DonationEntryScreen({super.key});

  @override
  State<DonationEntryScreen> createState() => _DonationEntryScreenState();
}

class _DonationEntryScreenState extends State<DonationEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  String _selectedPaymentMode = 'Cash';
  final List<String> _paymentModes = ['Cash', 'Online (UPI/Bank)', 'Cheque'];

  String _selectedDonationType = 'Zakat';
  final List<String> _donationTypes = [
    'Zakat',
    'Sadqa',
    'Imdad',
    'Lillah',
    'Chanda',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orgProvider = Provider.of<OrganizationProvider>(
        context,
        listen: false,
      );

      final isReadOnly = authProvider.isReadOnly;
      final orgStatus = orgProvider.organization?.status ?? 'active';

      if (isReadOnly || orgStatus != 'active') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text('Access Restricted'),
            content: Text(
              orgStatus == 'expired' || isReadOnly
                  ? 'Your subscription has expired. Please contact your administrator to renew.'
                  : 'Your organization is suspended. Please contact support.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (mounted) Navigator.pop(context);
                },
                child: Text('Go Back'),
              ),
            ],
          ),
        );
        return;
      }

      if (authProvider.currentUser?.role != 'collector') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only collectors can record donations. Admins must create a collector ID.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String receiptNo =
          'DON-${DateFormat('yyyyMMdd').format(DateTime.now())}-${Uuid().v4().substring(0, 4).toUpperCase()}';

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      final donation = DonationModel(
        id: Uuid().v4(),
        organizationId: currentUser?.organizationId ?? '',
        collectorId: currentUser?.id ?? 'unknown',
        createdByRole: 'collector',
        donorName: _nameController.text.trim(),
        donorMobile: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        paymentMode: _selectedPaymentMode,
        donationType: _selectedDonationType,
        date: _selectedDate,
        collectorName: currentUser?.fullName ?? 'Unknown Collector',
        receiptNo: receiptNo,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        organizationName: currentUser?.organizationName,
        createdAt: DateTime.now(),
      );

      try {
        // Save using Provider
        await Provider.of<DonationProvider>(
          context,
          listen: false,
        ).addDonation(donation);
      } catch (e) {
        if (mounted) {
          final snak = SnackBar(
            content: Text('Failed to save donation: $e'),
            backgroundColor: Colors.red,
          );
          ScaffoldMessenger.of(context).showSnackBar(snak);
        }
        return;
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptPreviewScreen(donation: donation),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: theme.colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMM yyyy').format(_selectedDate);

    return DoubleBackToClose(
      child: Scaffold(
        body: Responsive(
          mobile: _buildMainContent(formattedDate),
          desktop: Row(
            children: [
              const WebSidebar(currentRoute: '/add-donation'),
              Expanded(child: _buildMainContent(formattedDate)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(String formattedDate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Premium Gradient Header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(color: AppTheme.primary),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!Responsive.isDesktop(context))
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                      const Text(
                        'Record Donation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recording donation for ${DateFormat('MMMM yyyy').format(_selectedDate)}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.isDesktop(context) ? 48 : 20,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    // Floating Date Card
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Donation Date',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Donor Information'),
                                  const SizedBox(height: 24),
                                  _buildNameField(),
                                  const SizedBox(height: 20),
                                  _buildMobileField(),
                                  const SizedBox(height: 20),
                                  _buildAddressField(),
                                  const SizedBox(height: 20),
                                  _buildEmailField(),

                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Divider(height: 1),
                                  ),

                                  _buildSectionTitle('Donation Details'),
                                  const SizedBox(height: 24),
                                  _buildAmountField(),
                                  const SizedBox(height: 24),

                                  if (Responsive.isDesktop(context))
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDonationTypeField(),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: _buildPaymentModeField(),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _buildDonationTypeField(),
                                    const SizedBox(height: 20),
                                    _buildPaymentModeField(),
                                  ],
                                ],
                              ),
                            ),

                            // Bottom Action Area
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B).withAlpha(150)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _submitForm,
                                    style:
                                        ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical:
                                                Responsive.isDesktop(context)
                                                ? 20
                                                : 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 0,
                                        ).copyWith(
                                          backgroundColor:
                                              WidgetStateProperty.resolveWith((
                                                states,
                                              ) {
                                                if (states.contains(
                                                  WidgetState.disabled,
                                                )) {
                                                  return AppTheme.primary
                                                      .withAlpha(120);
                                                }
                                                return AppTheme.primary;
                                              }),
                                        ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Generate Receipt',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'A receipt will be generated automatically after submission.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Full Name',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
      validator: (value) => value!.isEmpty ? 'Please enter donor name' : null,
    );
  }

  Widget _buildMobileField() {
    return TextFormField(
      controller: _mobileController,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      decoration: const InputDecoration(
        labelText: 'Mobile Number (Optional)',
        prefixIcon: Icon(Icons.phone_outlined),
        counterText: '',
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty && value.length != 10) {
          return 'Mobile number must be 10 digits';
        }
        return null;
      },
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      maxLines: 2,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Address',
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 24.0),
          child: Icon(Icons.location_on_outlined),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email Address (Optional)',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryDark,
      ),
      decoration: InputDecoration(
        labelText: 'Amount',
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(
            Icons.currency_rupee,
            size: 28,
            color: AppTheme.primaryDark,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'An amount is required';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildDonationTypeField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedDonationType,
      decoration: InputDecoration(
        labelText: 'Donation Type',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: _donationTypes.map((type) {
        return DropdownMenuItem(value: type, child: Text(type));
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedDonationType = value!);
      },
    );
  }

  Widget _buildPaymentModeField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPaymentMode,
      decoration: InputDecoration(
        labelText: 'Payment Mode',
        prefixIcon: Icon(Icons.payment_outlined),
      ),
      items: _paymentModes.map((mode) {
        return DropdownMenuItem(value: mode, child: Text(mode));
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedPaymentMode = value!);
      },
    );
  }
}
