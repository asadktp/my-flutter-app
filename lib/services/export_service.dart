import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb and debugPrint
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart'; // Added for web downloads
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/donation_model.dart';
import '../models/expense_model.dart';
import '../models/institution_income_model.dart';
import '../models/org_expense_model.dart';
import '../models/salary_payment_model.dart';
import 'package:http/http.dart' as http;

class ExportService {
  static final Map<String, Uint8List> _logoCache = {};
  // ─── EXCEL EXPORT ────────────────────────────────────────────────────────

  static Future<void> exportToExcel({
    List<DonationModel>? donations,
    List<ExpenseModel>? expenses,
  }) async {
    var excel = Excel.createExcel();

    if (donations != null && donations.isNotEmpty) {
      final sortedDonations = [...donations]
        ..sort((a, b) => b.date.compareTo(a.date));

      Sheet sheetObject = excel['Donations'];
      excel.setDefaultSheet('Donations');

      sheetObject.appendRow([
        TextCellValue('Receipt No'),
        TextCellValue('Date'),
        TextCellValue('Donor Name'),
        TextCellValue('Mobile'),
        TextCellValue('Amount'),
        TextCellValue('Payment Mode'),
        TextCellValue('Donation Type'),
        TextCellValue('Collector Name'),
        TextCellValue('Address'),
      ]);

      for (var d in sortedDonations) {
        sheetObject.appendRow([
          TextCellValue(d.receiptNo),
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(d.date)),
          TextCellValue(d.donorName),
          TextCellValue(d.donorMobile),
          DoubleCellValue(d.amount),
          TextCellValue(d.paymentMode),
          TextCellValue(d.donationType ?? ''),
          TextCellValue(d.collectorName ?? ''),
          TextCellValue(d.address ?? ''),
        ]);
      }
    }

    if (expenses != null && expenses.isNotEmpty) {
      final sortedExpenses = [...expenses]
        ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

      Sheet sheetObject = excel['Expenses'];
      if (donations == null || donations.isEmpty) {
        excel.setDefaultSheet('Expenses');
      }

      sheetObject.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Amount'),
        TextCellValue('Collector Name'),
        TextCellValue('Status'),
        TextCellValue('Description'),
      ]);

      for (var e in sortedExpenses) {
        sheetObject.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(e.expenseDate)),
          TextCellValue(e.category),
          DoubleCellValue(e.amount),
          TextCellValue(e.collectorName ?? ''),
          TextCellValue(e.status),
          TextCellValue(e.description ?? ''),
        ]);
      }
    }

    final bytes = excel.save();
    if (bytes != null) {
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: 'DonationBackup_$dateStr',
          bytes: Uint8List.fromList(bytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        await Share.shareXFiles([
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'DonationBackup_$dateStr.xlsx',
          ),
        ], text: 'Database Backup (Excel)');
      }
    }
  }

  // ─── PDF EXPORT ──────────────────────────────────────────────────────────

  /// Fetches org info from Firestore using [organizationId] and exports a
  /// professional PDF report with a branded header.
  static Future<void> exportToPdf({
    List<DonationModel>? donations,
    List<ExpenseModel>? expenses,
    String? organizationId,
  }) async {
    final sortedDonations = donations != null
        ? ([...donations]..sort((a, b) => b.date.compareTo(a.date)))
        : <DonationModel>[];

    final sortedExpenses = expenses != null
        ? ([...expenses]
            ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate)))
        : <ExpenseModel>[];

    // ── Fetch org info from Firestore ────────────────────────────────────
    String orgName = 'Donation Report';
    String orgAddress = '';
    String orgContact = '';
    String orgEmail = '';
    String? orgLogoUrl;

    if (organizationId != null && organizationId.isNotEmpty) {
      try {
        var doc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          orgName = data['name'] ?? 'Donation Report';
          orgAddress = data['address'] ?? '';
          orgContact = data['contactNumber'] ?? '';
          orgEmail = data['email'] ?? '';
          orgLogoUrl = data['logoUrl'];
        }
      } catch (_) {}
    }

    // ── Load app logo from assets ────────────────────────────────────────
    pw.ImageProvider? logoImage;
    if (orgLogoUrl != null && orgLogoUrl.isNotEmpty) {
      if (_logoCache.containsKey(orgLogoUrl)) {
        logoImage = pw.MemoryImage(_logoCache[orgLogoUrl]!);
      } else {
        try {
          final response = await http.get(Uri.parse(orgLogoUrl));
          if (response.statusCode == 200) {
            _logoCache[orgLogoUrl] = response.bodyBytes;
            logoImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (_) {}
      }
    }

    if (logoImage == null) {
      try {
        final logoBytes = await rootBundle.load('assets/logo.png');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {
        // Logo not found — skip silently
      }
    }

    // ── Build PDF ────────────────────────────────────────────────────────
    final pdf = pw.Document();

    final totalDonations = sortedDonations.fold<double>(
      0,
      (sum, d) => sum + d.amount,
    );
    final totalExpenses = sortedExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    final primaryColor = PdfColor.fromHex('#0F766E');
    final dangerColor = PdfColor.fromHex('#E11D48');
    final lightBg = PdfColor.fromHex('#F0FDF9');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          orgName: orgName,
          orgAddress: orgAddress,
          orgContact: orgContact,
          orgEmail: orgEmail,
          logoImage: logoImage,
          primaryColor: primaryColor,
          lightBg: lightBg,
          reportLabel: 'DONATION & EXPENSE REPORT',
        ),
        footer: (context) => _buildFooter(context, primaryColor),
        build: (pw.Context context) {
          final List<pw.Widget> elements = [];
          elements.add(pw.SizedBox(height: 16));

          bool hasDonations = sortedDonations.isNotEmpty;
          bool hasExpenses = sortedExpenses.isNotEmpty;

          // Build Summary Cards Row
          final List<pw.Widget> summaryCards = [];
          if (hasDonations) {
            summaryCards.add(
              _summaryCard(
                'Total Donations',
                '${sortedDonations.length}',
                primaryColor,
              ),
            );
            summaryCards.add(pw.SizedBox(width: 8));
            summaryCards.add(
              _summaryCard(
                'Total Collected',
                'Rs. ${NumberFormat('#,##,###').format(totalDonations)}',
                primaryColor,
              ),
            );
          }
          if (hasExpenses) {
            if (summaryCards.isNotEmpty) {
              summaryCards.add(pw.SizedBox(width: 8));
            }
            summaryCards.add(
              _summaryCard(
                'Total Expenses',
                'Rs. ${NumberFormat('#,##,###').format(totalExpenses)}',
                dangerColor,
              ),
            );
          }
          if (hasDonations && hasExpenses) {
            double net = totalDonations - totalExpenses;
            summaryCards.add(pw.SizedBox(width: 8));
            summaryCards.add(
              _summaryCard(
                'Net Balance',
                'Rs. ${NumberFormat('#,##,###').format(net)}',
                net >= 0 ? primaryColor : dangerColor,
              ),
            );
          }

          if (summaryCards.isEmpty) {
            summaryCards.add(
              _summaryCard(
                'Report Date',
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                primaryColor,
              ),
            );
          } else {
            summaryCards.add(pw.SizedBox(width: 8));
            summaryCards.add(
              _summaryCard(
                'Report Date',
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                primaryColor,
              ),
            );
          }

          elements.add(pw.Row(children: summaryCards));
          elements.add(pw.SizedBox(height: 20));

          if (hasDonations) {
            elements.add(
              pw.Text(
                'DONATIONS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  color: primaryColor,
                ),
              ),
            );
            elements.add(pw.SizedBox(height: 8));
            elements.add(
              pw.TableHelper.fromTextArray(
                headers: [
                  'Receipt No',
                  'Date',
                  'Donor Name',
                  'Mobile',
                  'Amount (Rs.)',
                  'Mode',
                  'Type',
                ],
                data: sortedDonations
                    .map(
                      (d) => [
                        d.receiptNo,
                        DateFormat('dd-MM-yyyy HH:mm').format(d.date),
                        d.donorName,
                        d.donorMobile,
                        NumberFormat('#,##,###').format(d.amount),
                        d.paymentMode,
                        d.donationType ?? '-',
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                oddRowDecoration: pw.BoxDecoration(color: lightBg),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
              ),
            );
            elements.add(pw.SizedBox(height: 12));
            elements.add(
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Total Donations: Rs. ${NumberFormat('#,##,###').format(totalDonations)}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
            elements.add(pw.SizedBox(height: 24));
          }

          if (hasExpenses) {
            elements.add(
              pw.Text(
                'EXPENSES',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  color: dangerColor,
                ),
              ),
            );
            elements.add(pw.SizedBox(height: 8));
            elements.add(
              pw.TableHelper.fromTextArray(
                headers: [
                  'Date',
                  'Category',
                  'Amount (Rs.)',
                  'Collector Name',
                  'Status',
                  'Description',
                ],
                data: sortedExpenses
                    .map(
                      (e) => [
                        DateFormat('dd-MM-yyyy HH:mm').format(e.expenseDate),
                        e.category,
                        NumberFormat('#,##,###').format(e.amount),
                        e.collectorName ?? '-',
                        e.status.toUpperCase(),
                        e.description ?? '-',
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: pw.BoxDecoration(color: dangerColor),
                cellStyle: const pw.TextStyle(fontSize: 8),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                oddRowDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFF1F2'),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
              ),
            );
            elements.add(pw.SizedBox(height: 12));
            elements.add(
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: dangerColor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Total Expenses: Rs. ${NumberFormat('#,##,###').format(totalExpenses)}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }

          return elements;
        },
      ),
    );

    final bytes = await pdf.save();
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'DonationReport_$dateStr.pdf',
      );
    } else {
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: 'DonationReport_$dateStr.pdf',
        ),
      ]);
    }
  }

  // ─── HEADER BUILDER ──────────────────────────────────────────────────────

  static pw.Widget _buildHeader({
    required String orgName,
    required String orgAddress,
    required String orgContact,
    required String orgEmail,
    required PdfColor primaryColor,
    required PdfColor lightBg,
    required String reportLabel,
    pw.ImageProvider? logoImage,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // App logo / org logo
          if (logoImage != null) ...[
            pw.Container(
              width: 56,
              height: 56,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                shape: pw.BoxShape.circle,
              ),
              padding: const pw.EdgeInsets.all(4),
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 14),
          ] else ...[
            pw.Container(
              width: 56,
              height: 56,
              decoration: const pw.BoxDecoration(
                color: PdfColors.white,
                shape: pw.BoxShape.circle,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                orgName.isNotEmpty ? orgName[0].toUpperCase() : 'D',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            pw.SizedBox(width: 14),
          ],

          // Org details
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  orgName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                if (orgAddress.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    orgAddress,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                  ),
                ],
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    if (orgContact.isNotEmpty) ...[
                      pw.Text(
                        '📞 $orgContact',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(width: 16),
                    ],
                    if (orgEmail.isNotEmpty)
                      pw.Text(
                        '✉ $orgEmail',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Right side — Report label
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  reportLabel,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── FOOTER BUILDER ──────────────────────────────────────────────────────

  static pw.Widget _buildFooter(pw.Context context, PdfColor primaryColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Donation Management App',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ─── SUMMARY CARD ────────────────────────────────────────────────────────

  static pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
          color: PdfColor.fromHex('#F0FDF9'),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AUDIT REPORT EXPORT ──────────────────────────────────────────────────
  static Future<void> exportIncomeExpenditureReport({
    required List<DonationModel> donations,
    required List<InstitutionIncomeModel> manualIncomes,
    required List<ExpenseModel> collectorExpenses,
    required List<OrgExpenseModel> orgExpenses,
    required DateTime startDate,
    required DateTime endDate,
    required String organizationId,
  }) async {
    final pdf = pw.Document();
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');
    final String dateRangeStr =
        '${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}';

    // Sum Calculations
    double totalDonations = donations.fold(0, (s, e) => s + e.amount);
    double totalManual = manualIncomes.fold(0, (s, e) => s + e.amount);
    double totalIncome = totalDonations + totalManual;

    double totalCollExp = collectorExpenses.fold(0, (s, e) => s + e.amount);
    double totalOrgExp = orgExpenses.fold(0, (s, e) => s + e.amount);
    double totalExpenditure = totalCollExp + totalOrgExp;

    double netResult = totalIncome - totalExpenditure;

    // Fetch org info
    String orgName = 'Institution';
    String? orgLogoUrl;

    if (organizationId.isNotEmpty) {
      try {
        var doc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          orgName = data['name'] ?? 'Institution';
          orgLogoUrl = data['logoUrl'];
        }
      } catch (_) {}
    }

    pw.ImageProvider? logoImage;
    if (orgLogoUrl != null && orgLogoUrl.isNotEmpty) {
      if (_logoCache.containsKey(orgLogoUrl)) {
        logoImage = pw.MemoryImage(_logoCache[orgLogoUrl]!);
      } else {
        try {
          final response = await http.get(Uri.parse(orgLogoUrl));
          if (response.statusCode == 200) {
            _logoCache[orgLogoUrl] = response.bodyBytes;
            logoImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (_) {}
      }
    }

    // Custom Header
    pw.Widget buildHeader() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoImage != null) ...[
            pw.Container(
              height: 60,
              width: 60,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                image: pw.DecorationImage(
                  image: logoImage,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          pw.Text(
            orgName.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'INCOME & EXPENDITURE ACCOUNT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Report Period: $dateRangeStr',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
        ],
      );
    }

    // Build side by side tables
    pw.Widget buildSideBySideTables() {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // INCOME SIDE
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: PdfColors.blue50,
                  child: pw.Center(
                    child: pw.Text(
                      'INCOME',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Donations'),
                    pw.Text('Rs. ${totalDonations.toStringAsFixed(2)}'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Manual Income'),
                    pw.Text('Rs. ${totalManual.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Divider(),
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Income:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Rs. ${totalIncome.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          // EXPENDITURE SIDE
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: PdfColors.red50,
                  child: pw.Center(
                    child: pw.Text(
                      'EXPENDITURE',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Collector Expenses'),
                    pw.Text('Rs. ${totalCollExp.toStringAsFixed(2)}'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Organization Expenses'),
                    pw.Text('Rs. ${totalOrgExp.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Divider(),
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Expenditure:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Rs. ${totalExpenditure.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    pw.Widget buildNetBalance() {
      final isSurplus = netResult >= 0;
      final color = isSurplus ? PdfColors.green800 : PdfColors.red800;
      final label = isSurplus
          ? 'NET SURPLUS (Income over Expenditure)'
          : 'EXCESS OF EXPENDITURE OVER INCOME';

      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 24),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          color: isSurplus ? PdfColors.green50 : PdfColors.red50,
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            pw.Text(
              'Rs. ${netResult.abs().toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader(),
              buildSideBySideTables(),
              buildNetBalance(),
            ],
          );
        },
      ),
    );

    // --- Detailed Tables Section ---
    pw.Widget buildSectionHeader(String title) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
        padding: const pw.EdgeInsets.all(6),
        color: PdfColors.grey200,
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      );
    }

    if (donations.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (_) => buildHeader(),
          build: (pw.Context context) {
            return [
              buildSectionHeader('Donations Detailed List'),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['Date', 'Donor Name', 'Amount', 'Collector', 'Mode'],
                data: donations.map((d) {
                  return [
                    dateFormat.format(d.date),
                    d.donorName,
                    'Rs. ${d.amount.toStringAsFixed(2)}',
                    d.collectorName ?? '-',
                    d.paymentMode,
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );
    }

    if (manualIncomes.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (_) => buildHeader(),
          build: (pw.Context context) {
            return [
              buildSectionHeader('Manual Incomes Detailed List'),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['Date', 'Category', 'Description', 'Amount'],
                data: manualIncomes.map((i) {
                  return [
                    dateFormat.format(i.incomeDate),
                    i.incomeCategory,
                    i.description ?? '-',
                    'Rs. ${i.amount.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );
    }

    if (collectorExpenses.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (_) => buildHeader(),
          build: (pw.Context context) {
            return [
              buildSectionHeader('Collector Expenses Detailed List'),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headers: [
                  'Date',
                  'Category',
                  'Description',
                  'Amount',
                  'Collector',
                ],
                data: collectorExpenses.map((e) {
                  return [
                    dateFormat.format(e.expenseDate),
                    e.category,
                    e.description ?? '-',
                    'Rs. ${e.amount.toStringAsFixed(2)}',
                    e.collectorName ?? '-',
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );
    }

    if (orgExpenses.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (_) => buildHeader(),
          build: (pw.Context context) {
            return [
              buildSectionHeader('Organization Expenses Detailed List'),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['Date', 'Category', 'Description', 'Amount'],
                data: orgExpenses.map((e) {
                  return [
                    dateFormat.format(e.expenseDate),
                    e.expenseCategory,
                    e.description ?? '-',
                    'Rs. ${e.amount.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );
    }

    // Save and Open logic
    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      // Trigger web download
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Institution_Accounts_Report.pdf',
      );
    } else {
      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Institution_Accounts_Report.pdf',
        );
      } else {
        await Share.shareXFiles([
          XFile.fromData(
            pdfBytes,
            mimeType: 'application/pdf',
            name: 'Institution_Accounts_Report.pdf',
          ),
        ]);
      }
    }
  }

  static Future<void> exportIncomeExpenditureToExcel({
    required List<DonationModel> donations,
    required List<InstitutionIncomeModel> manualIncomes,
    required List<ExpenseModel> collectorExpenses,
    required List<OrgExpenseModel> orgExpenses,
    required DateTime startDate,
    required DateTime endDate,
    required String organizationId,
  }) async {
    var excel = Excel.createExcel();

    // 0. Donations Sheet
    if (donations.isNotEmpty) {
      Sheet donationSheet = excel['Donations'];
      excel.setDefaultSheet('Donations');
      donationSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Donor Name'),
        TextCellValue('Amount (Rs)'),
        TextCellValue('Collector'),
        TextCellValue('Payment Mode'),
      ]);
      for (var d in donations) {
        donationSheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd').format(d.date)),
          TextCellValue(d.donorName),
          DoubleCellValue(d.amount),
          TextCellValue(d.collectorName ?? ''),
          TextCellValue(d.paymentMode),
        ]);
      }
    }

    // 1. Manual Income Sheet
    if (manualIncomes.isNotEmpty) {
      Sheet incomeSheet = excel['Manual Income'];
      if (donations.isEmpty) excel.setDefaultSheet('Manual Income');
      incomeSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Description'),
        TextCellValue('Amount (Rs)'),
      ]);
      for (var inc in manualIncomes) {
        incomeSheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd').format(inc.incomeDate)),
          TextCellValue(inc.incomeCategory),
          TextCellValue(inc.description ?? ''),
          DoubleCellValue(inc.amount),
        ]);
      }
    }

    // 2. Organization Expenses Sheet
    if (orgExpenses.isNotEmpty) {
      Sheet orgExpSheet = excel['Organization Expenses'];
      if (manualIncomes.isEmpty) excel.setDefaultSheet('Organization Expenses');
      orgExpSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Category'),
        TextCellValue('Description'),
        TextCellValue('Amount (Rs)'),
      ]);
      for (var exp in orgExpenses) {
        orgExpSheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd').format(exp.expenseDate)),
          TextCellValue(exp.expenseCategory),
          TextCellValue(exp.description ?? ''),
          DoubleCellValue(exp.amount),
        ]);
      }
    }

    // 3. Collector Expenses Sheet
    if (collectorExpenses.isNotEmpty) {
      Sheet collExpSheet = excel['Collector Expenses'];
      if (manualIncomes.isEmpty && orgExpenses.isEmpty) {
        excel.setDefaultSheet('Collector Expenses');
      }
      collExpSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Collector'),
        TextCellValue('Category'),
        TextCellValue('Description'),
        TextCellValue('Amount (Rs)'),
      ]);
      for (var exp in collectorExpenses) {
        collExpSheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd').format(exp.expenseDate)),
          TextCellValue(exp.collectorName ?? ''),
          TextCellValue(exp.category),
          TextCellValue(exp.description ?? ''),
          DoubleCellValue(exp.amount),
        ]);
      }
    }

    // Save Logic
    var fileBytes = excel.save();
    if (fileBytes != null) {
      if (kIsWeb) {
        // Trigger web download
        await FileSaver.instance.saveFile(
          name: 'Institution_Accounts_$organizationId',
          bytes: Uint8List.fromList(fileBytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      }
    }
  }

  // ─── SINGLE LIST EXPORTS ──────────────────────────────────────────────────

  static Future<void> exportExpenseListToPdf({
    required List<OrgExpenseModel> expenses,
    required DateTime startDate,
    required DateTime endDate,
    required String organizationId,
  }) async {
    String orgName = 'Institution Account';
    String orgAddress = '';
    String orgContact = '';
    String orgEmail = '';

    try {
      var doc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        orgName = data['name'] ?? 'Institution Account';
        orgAddress = data['address'] ?? '';
        orgContact = data['contactNumber'] ?? '';
        orgEmail = data['email'] ?? '';
      }
    } catch (_) {}

    final sortedExpenses = [...expenses]
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    final primaryColor = PdfColor.fromHex('#1A237E');
    final lightBg = PdfColor.fromHex('#EEF2FF');
    final dangerColor = PdfColor.fromHex('#C62828');

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final totalExpenses = sortedExpenses.fold<double>(
      0,
      (s, e) => s + e.amount,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(
          orgName: orgName,
          orgAddress: orgAddress,
          orgContact: orgContact,
          orgEmail: orgEmail,
          primaryColor: primaryColor,
          lightBg: lightBg,
          reportLabel: 'EXPENSE REPORT',
        ),
        footer: (ctx) => _buildFooter(ctx, primaryColor),
        build: (ctx) {
          final elements = <pw.Widget>[];

          elements.add(pw.SizedBox(height: 16));
          elements.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Expense Report',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.Text(
                  '${dateFormat.format(startDate)} – ${dateFormat.format(endDate)}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
          elements.add(pw.SizedBox(height: 12));

          // Table header
          elements.add(
            pw.Container(
              color: primaryColor,
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Date',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Description',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Category',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Amount',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          for (int i = 0; i < sortedExpenses.length; i++) {
            final e = sortedExpenses[i];
            final bg = i.isEven ? PdfColors.white : lightBg;
            elements.add(
              pw.Container(
                color: bg,
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 8,
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        dateFormat.format(e.expenseDate),
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        e.description ?? '',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        e.expenseCategory,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Rs. ${NumberFormat('#,##,###.##').format(e.amount)}',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          elements.add(pw.SizedBox(height: 8));
          elements.add(
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: dangerColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Total Expenses: Rs. ${NumberFormat('#,##,###').format(totalExpenses)}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );

          return elements;
        },
      ),
    );

    final bytes = await pdf.save();
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'ExpenseReport_$dateStr.pdf',
      );
    } else {
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: 'ExpenseReport_$dateStr.pdf',
        ),
      ]);
    }
  }

  static Future<void> exportIncomeListToPdf({
    required List<InstitutionIncomeModel> incomes,
    required DateTime startDate,
    required DateTime endDate,
    required String organizationId,
  }) async {
    String orgName = 'Institution Account';
    String orgAddress = '';
    String orgContact = '';
    String orgEmail = '';

    try {
      var doc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        orgName = data['name'] ?? orgName;
        orgAddress = data['address'] ?? '';
        orgContact = data['contactNumber'] ?? '';
        orgEmail = data['email'] ?? '';
      }
    } catch (_) {}

    pw.ImageProvider? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    final pdf = pw.Document();
    final primaryColor = PdfColor.fromHex('#0F766E');
    final lightBg = PdfColor.fromHex('#F0FDF9');
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');

    final total = incomes.fold<double>(0, (s, e) => s + e.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          orgName: orgName,
          orgAddress: orgAddress,
          orgContact: orgContact,
          orgEmail: orgEmail,
          logoImage: logoImage,
          primaryColor: primaryColor,
          lightBg: lightBg,
          reportLabel: 'INCOME REPORT',
        ),
        footer: (context) => _buildFooter(context, primaryColor),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 16),
            pw.Text(
              'INCOME REPORT',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.Text(
              'Period: ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Category', 'Description', 'Amount'],
              data: incomes
                  .map(
                    (i) => [
                      dateFormat.format(i.incomeDate),
                      i.incomeCategory,
                      i.description ?? '',
                      'Rs. ${i.amount.toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total Income: ',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.Text(
                  'Rs. ${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Income_Report_${dateFormat.format(DateTime.now())}.pdf',
      );
    } else {
      await Share.shareXFiles([
        XFile.fromData(
          pdfBytes,
          mimeType: 'application/pdf',
          name: 'Income_Report_${dateFormat.format(DateTime.now())}.pdf',
        ),
      ]);
    }
  }

  // ─── EXPENSE LIST PDF EXPORT ─────────────────────────────────────────────

  // ─── SALARY REPORT PDF ───────────────────────────────────────────────────
  static Future<void> exportSalaryReportToPdf({
    required List<SalaryPaymentModel> salaryPayments,
    required DateTime startDate,
    required DateTime endDate,
    required String organizationId,
    String? reportTitle,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final dateRangeStr =
        '${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}';
    final totalPaid = salaryPayments.fold<double>(
      0,
      (s, p) => s + p.paidAmount,
    );

    // Fetch org info
    String orgName = 'Institution';
    String? orgLogoUrl;
    if (organizationId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId)
            .get();
        if (doc.exists) {
          orgName = doc.data()?['name'] ?? 'Institution';
          orgLogoUrl = doc.data()?['logoUrl'];
        }
      } catch (_) {}
    }

    pw.ImageProvider? logoImage;
    if (orgLogoUrl != null && orgLogoUrl.isNotEmpty) {
      if (_logoCache.containsKey(orgLogoUrl)) {
        logoImage = pw.MemoryImage(_logoCache[orgLogoUrl]!);
      } else {
        try {
          final response = await http.get(Uri.parse(orgLogoUrl));
          if (response.statusCode == 200) {
            _logoCache[orgLogoUrl] = response.bodyBytes;
            logoImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (_) {}
      }
    }

    final primaryColor = PdfColor.fromHex('#4F46E5');
    final lightBg = PdfColor.fromHex('#EEF2FF');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(
          orgName: orgName,
          orgAddress: '',
          orgContact: '',
          orgEmail: '',
          logoImage: logoImage,
          primaryColor: primaryColor,
          lightBg: lightBg,
          reportLabel: 'SALARY REPORT',
        ),
        footer: (ctx) => _buildFooter(ctx, primaryColor),
        build: (ctx) {
          final elements = <pw.Widget>[];
          elements.add(pw.SizedBox(height: 16));
          elements.add(
            pw.Text(
              reportTitle ?? 'SALARY REPORT',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          );
          elements.add(pw.SizedBox(height: 4));
          elements.add(
            pw.Text(
              'Period: $dateRangeStr',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          );
          elements.add(pw.SizedBox(height: 16));
          if (salaryPayments.isEmpty) {
            elements.add(
              pw.Center(
                child: pw.Text(
                  'No salary payments in this period.',
                  style: const pw.TextStyle(color: PdfColors.grey600),
                ),
              ),
            );
          } else {
            elements.add(
              pw.TableHelper.fromTextArray(
                headers: [
                  'Teacher',
                  'Month',
                  'Standard (Rs.)',
                  'Paid (Rs.)',
                  'Date',
                  'Note',
                  'Signature',
                ],
                data: salaryPayments
                    .map(
                      (p) => [
                        p.teacherName,
                        p.month,
                        NumberFormat('#,##,###').format(p.defaultSalary),
                        NumberFormat('#,##,###').format(p.paidAmount),
                        dateFormat.format(p.paymentDate),
                        p.note ?? '-',
                        '',
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8),
                oddRowDecoration: pw.BoxDecoration(color: lightBg),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
              ),
            );
            elements.add(pw.SizedBox(height: 12));
            elements.add(
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Total Salary Paid: Rs. ${NumberFormat('#,##,###').format(totalPaid)}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }
          return elements;
        },
      ),
    );

    final bytes = await pdf.save();
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'SalaryReport_$dateStr.pdf',
      );
    } else {
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: 'SalaryReport_$dateStr.pdf',
        ),
      ]);
    }
  }

  // ─── SALARY REPORT EXCEL ─────────────────────────────────────────────────
  static Future<void> exportSalaryReportToExcel({
    required List<SalaryPaymentModel> salaryPayments,
    required DateTime startDate,
    required DateTime endDate,
    required String organizationId,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Salary Report'];
    excel.setDefaultSheet('Salary Report');

    sheet.appendRow([
      TextCellValue('Teacher'),
      TextCellValue('Month'),
      TextCellValue('Standard Salary (Rs.)'),
      TextCellValue('Paid Amount (Rs.)'),
      TextCellValue('Payment Date'),
      TextCellValue('Note'),
      TextCellValue('Signature'),
    ]);

    for (final p in salaryPayments) {
      sheet.appendRow([
        TextCellValue(p.teacherName),
        TextCellValue(p.month),
        DoubleCellValue(p.defaultSalary),
        DoubleCellValue(p.paidAmount),
        TextCellValue(DateFormat('yyyy-MM-dd').format(p.paymentDate)),
        TextCellValue(p.note ?? ''),
        TextCellValue(''),
      ]);
    }

    final totalPaid = salaryPayments.fold<double>(
      0,
      (s, p) => s + p.paidAmount,
    );
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(totalPaid),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    final bytes = excel.save();
    if (bytes != null) {
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: 'SalaryReport_$dateStr',
          bytes: Uint8List.fromList(bytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        await Share.shareXFiles([
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'SalaryReport_$dateStr.xlsx',
          ),
        ], text: 'Salary Report (Excel)');
      }
    }
  }
}
