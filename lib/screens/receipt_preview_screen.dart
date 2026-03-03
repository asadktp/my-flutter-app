import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../models/donation_model.dart';
import '../providers/organization_provider.dart';
import '../services/receipt_generator.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({super.key, required this.donation});

  final DonationModel donation;

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  bool _isExporting = false;

  Future<void> _shareViaWhatsApp() async {
    setState(() => _isExporting = true);
    try {
      final organization = Provider.of<OrganizationProvider>(
        context,
        listen: false,
      ).organization;
      final pdfBytes = await ReceiptGenerator.generateReceipt(
        widget.donation,
        organization: organization,
      );

      if (kIsWeb) {
        // On web, trigger browser download/print dialog instead
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Receipt_${widget.donation.receiptNo}.pdf',
        );
      } else {
        await Share.shareXFiles(
          [
            XFile.fromData(
              pdfBytes,
              mimeType: 'application/pdf',
              name: 'Receipt_${widget.donation.receiptNo}.pdf',
            ),
          ],
          text:
              'Thank you for your donation of Rs.${widget.donation.amount} to the Foundation. Please find your receipt attached.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareViaEmail() async {
    setState(() => _isExporting = true);
    try {
      final organization = Provider.of<OrganizationProvider>(
        context,
        listen: false,
      ).organization;
      final pdfBytes = await ReceiptGenerator.generateReceipt(
        widget.donation,
        organization: organization,
      );

      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Receipt_${widget.donation.receiptNo}.pdf',
        );
      } else {
        await Share.shareXFiles(
          [
            XFile.fromData(
              pdfBytes,
              mimeType: 'application/pdf',
              name: 'Receipt_${widget.donation.receiptNo}.pdf',
            ),
          ],
          subject: 'Donation Receipt: ${widget.donation.receiptNo}',
          text:
              'Dear ${widget.donation.donorName},\n\nThank you for your generous donation of Rs.${widget.donation.amount}. Please find your official receipt attached.\n\nWarm regards,\nThe Foundation',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing via email: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _isExporting ? null : () => _showExportOptions(context),
            tooltip: 'Export options',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: Consumer<OrganizationProvider>(
                  builder: (context, orgProvider, child) {
                    return PdfPreview(
                      build: (format) => ReceiptGenerator.generateReceipt(
                        widget.donation,
                        organization: orgProvider.organization,
                      ),
                      allowSharing: true, // Restored sharing
                      allowPrinting: true,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      pdfFileName: 'Receipt_${widget.donation.receiptNo}.pdf',
                      loadingWidget: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Export Receipt',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.message, color: Color(0xFF25D366)),
                  ),
                  title: const Text('Share via WhatsApp'),
                  subtitle: Text(widget.donation.donorMobile),
                  onTap: () {
                    Navigator.pop(context);
                    _shareViaWhatsApp();
                  },
                ),
                if (widget.donation.email != null &&
                    widget.donation.email!.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.email, color: Colors.blue),
                    ),
                    title: const Text('Send via Email'),
                    subtitle: Text(widget.donation.email!),
                    onTap: () {
                      Navigator.pop(context);
                      _shareViaEmail();
                    },
                  ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download, color: Colors.grey),
                  ),
                  title: const Text('Download PDF'),
                  onTap: () async {
                    Navigator.pop(context);
                    final organization = Provider.of<OrganizationProvider>(
                      context,
                      listen: false,
                    ).organization;
                    final pdfBytes = await ReceiptGenerator.generateReceipt(
                      widget.donation,
                      organization: organization,
                    );
                    await Printing.sharePdf(
                      bytes: pdfBytes,
                      filename: 'Receipt_${widget.donation.receiptNo}.pdf',
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
