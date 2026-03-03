import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/donation_model.dart';
import '../models/organization_model.dart';

class ReceiptGenerator {
  static Future<Uint8List> generateReceipt(
    DonationModel donation, {
    OrganizationModel? organization,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(donation.date);
    final format = PdfPageFormat.a4;

    // Professional Fintech Palette
    final primaryColor = PdfColor.fromHex('#111827'); // Slate 900
    final accentColor = PdfColor.fromHex('#15803D'); // Emerald 700
    final secondaryTextColor = PdfColor.fromHex('#6B7280'); // Slate 500
    final borderColor = PdfColor.fromHex('#E5E7EB'); // Slate 200
    final surfaceColor = PdfColor.fromHex('#F9FAFB'); // Slate 50

    String orgName = (organization != null && organization.name.isNotEmpty)
        ? organization.name
        : (donation.organizationName ?? 'ORGANIZATION NAME');

    String orgAddress =
        (organization != null && organization.address.isNotEmpty)
        ? '${organization.address}, ${organization.district}, ${organization.state} ${organization.pinCode}'
        : '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(48),
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoBytes != null)
                          pw.Container(
                            width: 60,
                            height: 60,
                            margin: const pw.EdgeInsets.only(bottom: 12),
                            child: pw.Image(pw.MemoryImage(logoBytes)),
                          ),
                        pw.Text(
                          orgName,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        if (orgAddress.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4),
                            child: pw.SizedBox(
                              width: 250,
                              child: pw.Text(
                                orgAddress,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'DONATION RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        _buildHeaderLabelValue(
                          'Receipt #',
                          donation.receiptNo,
                          primaryColor,
                          secondaryTextColor,
                        ),
                        _buildHeaderLabelValue(
                          'Date',
                          dateStr,
                          primaryColor,
                          secondaryTextColor,
                        ),
                        if (organization?.registrationNumber != null)
                          _buildHeaderLabelValue(
                            'Reg No',
                            organization!.registrationNumber,
                            primaryColor,
                            secondaryTextColor,
                          ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 48),

                // Bill To Section
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILL TO',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: secondaryTextColor,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      donation.donorName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      donation.donorMobile,
                      style: pw.TextStyle(fontSize: 11, color: primaryColor),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),

                // Breakdown Table
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: primaryColor, width: 1),
                        ),
                      ),
                      children: [
                        _buildTableCell(
                          'DESCRIPTION',
                          isHeader: true,
                          color: primaryColor,
                        ),
                        _buildTableCell(
                          'MODE',
                          isHeader: true,
                          color: primaryColor,
                        ),
                        _buildTableCell(
                          'AMOUNT',
                          isHeader: true,
                          align: pw.TextAlign.right,
                          color: primaryColor,
                        ),
                      ],
                    ),
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: borderColor, width: 0.5),
                        ),
                      ),
                      children: [
                        _buildTableCell(
                          donation.donationType ?? 'Donation',
                          color: primaryColor,
                        ),
                        _buildTableCell(
                          donation.paymentMode.toUpperCase(),
                          color: primaryColor,
                        ),
                        _buildTableCell(
                          'Rs ${donation.amount.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: pw.BoxDecoration(
                        color: surfaceColor,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          pw.Text(
                            'Rs ${donation.amount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Notes
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: surfaceColor,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'AMOUNT IN WORDS: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryTextColor,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '${_convertNumberToWords(donation.amount.toInt()).toUpperCase()} RUPEES ONLY',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 64),

                // Signature & Seal
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(width: 150, height: 1, color: borderColor),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'AUTHORIZED BY',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: secondaryTextColor,
                          ),
                        ),
                        pw.Text(
                          donation.collectorName?.toUpperCase() ??
                              'ADMINISTRATOR',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (organization != null)
                      pw.Container(
                        width: 100,
                        height: 100,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor, width: 1),
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'OFFICIAL SEAL',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: borderColor,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderLabelValue(
    String label,
    String value,
    PdfColor textColor,
    PdfColor labelColor,
  ) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 10,
            color: labelColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            color: textColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    required PdfColor color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static String _convertNumberToWords(int number) {
    if (number == 0) return 'zero';

    final units = [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen',
    ];
    final tens = [
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety',
    ];

    if (number < 20) return units[number];
    if (number < 100) {
      return tens[number ~/ 10] +
          (number % 10 != 0 ? ' ${units[number % 10]}' : '');
    }
    if (number < 1000) {
      return '${units[number ~/ 100]} hundred${number % 100 != 0
              ? ' and ${_convertNumberToWords(number % 100)}'
              : ''}';
    }
    if (number < 100000) {
      return '${_convertNumberToWords(number ~/ 1000)} thousand${number % 1000 != 0
              ? ' ${_convertNumberToWords(number % 1000)}'
              : ''}';
    }
    if (number < 10000000) {
      return '${_convertNumberToWords(number ~/ 100000)} lakh${number % 100000 != 0
              ? ' ${_convertNumberToWords(number % 100000)}'
              : ''}';
    }
    return number.toString(); // Fallback for very large numbers
  }
}
