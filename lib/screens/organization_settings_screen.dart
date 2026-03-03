import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/organization_provider.dart';
import '../utils/theme.dart';
import '../widgets/web_sidebar.dart';
import '../utils/responsive.dart';
import '../widgets/double_back_to_close.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  const OrganizationSettingsScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState
    extends State<OrganizationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _regNoController;
  late TextEditingController _currencyController;
  late TextEditingController _whatsappController;
  late TextEditingController _footerController;

  // New location fields
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _pinCodeController;

  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final o = Provider.of<OrganizationProvider>(
      context,
      listen: false,
    ).organization;
    final s = Provider.of<SettingsProvider>(context, listen: false).settings;

    // Org data from OrganizationProvider (Firestore) â€” no hardcoded defaults
    _nameController = TextEditingController(text: o?.name ?? '');
    _addressController = TextEditingController(text: o?.address ?? '');
    _phoneController = TextEditingController(text: o?.contactNumber ?? '');
    _emailController = TextEditingController(text: o?.email ?? '');
    _regNoController = TextEditingController(text: o?.registrationNumber ?? '');
    _whatsappController = TextEditingController(
      text: o?.whatsappNumber ?? o?.contactNumber ?? '',
    );

    _countryController = TextEditingController(text: o?.country ?? 'India');
    _stateController = TextEditingController(text: o?.state ?? '');
    _districtController = TextEditingController(text: o?.district ?? '');
    _pinCodeController = TextEditingController(text: o?.pinCode ?? '');

    // Receipt preferences from SettingsProvider (local)
    _currencyController = TextEditingController(text: s.defaultCurrency);
    _footerController = TextEditingController(text: s.receiptFooterMessage);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _regNoController.dispose();
    _currencyController.dispose();
    _whatsappController.dispose();
    _footerController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final orgProvider = Provider.of<OrganizationProvider>(
      context,
      listen: false,
    );
    if (orgProvider.organization?.status != 'active') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot upload logo. Subscription is expired or organization is suspended.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final Uint8List pickedBytes = await picked.readAsBytes();

    // Show crop dialog
    final Uint8List? croppedBytes = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CropImageDialog(imageBytes: pickedBytes),
    );

    if (croppedBytes == null) return;

    setState(() => _uploadingImage = true);

    try {
      // Upload bytes directly (web-compatible)
      final Uint8List uploadBytes = croppedBytes;

      if (uploadBytes.length > 500000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image is too large. Please choose a smaller image.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _uploadingImage = false);
        return;
      }

      final url = await orgProvider.uploadLogo(uploadBytes);

      if (mounted) {
        setState(() => _uploadingImage = false);
        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('âœ… Organization logo updated!'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    final orgProvider = Provider.of<OrganizationProvider>(
      context,
      listen: false,
    );
    if (orgProvider.organization?.status != 'active') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot save settings. Subscription is expired or organization is suspended.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      // Save org info to Firestore via OrganizationProvider
      await orgProvider.updateOrganization(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        registrationNumber: _regNoController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        country: _countryController.text.trim(),
        state: _stateController.text.trim(),
        district: _districtController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
      );

      // Save receipt preferences locally via SettingsProvider
      final sp = Provider.of<SettingsProvider>(context, listen: false);
      sp.settings.defaultCurrency = _currencyController.text.trim();
      sp.settings.receiptFooterMessage = _footerController.text.trim();
      await sp.updateSettings(sp.settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('âœ… Settings saved successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: _buildMainContent(),
      );
    }

    return DoubleBackToClose(
      child: Scaffold(
        drawer: const WebSidebar(currentRoute: '/settings'),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text(
            'Organization Settings',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: Responsive(
          mobile: _buildMainContent(),
          desktop: Row(
            children: [
              const WebSidebar(currentRoute: '/settings'),
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isDesktop(context) ? 48 : 24.0,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (Responsive.isDesktop(context)) ...[
                Text(
                  'Organization Settings',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your profile, receipt preferences, and app appearance.',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    Responsive.isDesktop(context) ? 32 : 20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<OrganizationProvider>(
                          builder: (context, orgProvider, child) {
                            final imageUrl = orgProvider.organization?.logoUrl;
                            return Center(
                              child: GestureDetector(
                                onTap: _pickAndUploadLogo,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      backgroundImage:
                                          imageUrl != null &&
                                              imageUrl.isNotEmpty
                                          ? NetworkImage(imageUrl)
                                          : null,
                                      child: _uploadingImage
                                          ? CircularProgressIndicator(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              strokeWidth: 3,
                                            )
                                          : (imageUrl == null ||
                                                imageUrl.isEmpty)
                                          ? Icon(
                                              Icons.business,
                                              size: 50,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 48),

                        _sectionTitle('Organization Details'),
                        const SizedBox(height: 24),

                        if (Responsive.isDesktop(context)) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _field(
                                  _nameController,
                                  'Organization Name',
                                  Icons.business,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _field(
                                  _regNoController,
                                  'Registration Number',
                                  Icons.numbers,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _field(
                                  _phoneController,
                                  'Contact Number',
                                  Icons.phone,
                                  keyboard: TextInputType.phone,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _field(
                                  _whatsappController,
                                  'WhatsApp Number',
                                  Icons.message,
                                  keyboard: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _field(
                            _nameController,
                            'Organization Name',
                            Icons.business,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            _regNoController,
                            'Registration Number',
                            Icons.numbers,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            _phoneController,
                            'Contact Number',
                            Icons.phone,
                            keyboard: TextInputType.phone,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            _whatsappController,
                            'WhatsApp Number',
                            Icons.message,
                            keyboard: TextInputType.phone,
                          ),
                        ],

                        const SizedBox(height: 16),
                        _field(
                          _emailController,
                          'Email Address',
                          Icons.email,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                _countryController,
                                'Country',
                                Icons.flag,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _field(
                                _stateController,
                                'State',
                                Icons.map,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                _districtController,
                                'District',
                                Icons.location_city,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _field(
                                _pinCodeController,
                                'Pin Code',
                                Icons.pin,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _field(
                          _addressController,
                          'Street Address',
                          Icons.location_on,
                          maxLines: 2,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Divider(),
                        ),

                        _sectionTitle('Receipt Preferences'),
                        const SizedBox(height: 24),

                        if (Responsive.isDesktop(context))
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: _field(
                                  _currencyController,
                                  'Default Currency (e.g. INR, USD)',
                                  Icons.money,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 2,
                                child: _field(
                                  _footerController,
                                  'Receipt Footer Message',
                                  Icons.text_snippet,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _field(
                            _currencyController,
                            'Default Currency (e.g. INR, USD)',
                            Icons.money,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            _footerController,
                            'Receipt Footer Message',
                            Icons.text_snippet,
                            maxLines: 2,
                          ),
                        ],

                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save Configuration',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: maxLines > 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Icon(icon),
            )
          : Icon(icon),
    ),
    validator: validator,
  );
}

class CropImageDialog extends StatefulWidget {
  final Uint8List imageBytes;
  const CropImageDialog({super.key, required this.imageBytes});

  @override
  State<CropImageDialog> createState() => _CropImageDialogState();
}

class _CropImageDialogState extends State<CropImageDialog> {
  final _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Crop Logo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Crop(
                  image: widget.imageBytes,
                  controller: _cropController,
                  onCropped: (image) {
                    Navigator.of(context).pop(image);
                  },
                  aspectRatio: 1 / 1,
                  maskColor: Colors.black.withValues(alpha: 0.5),
                  baseColor: Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isCropping
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isCropping
                      ? null
                      : () {
                          setState(() => _isCropping = true);
                          _cropController.crop();
                        },
                  child: _isCropping
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crop & Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
