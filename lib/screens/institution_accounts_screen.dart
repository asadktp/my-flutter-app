import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';
import '../providers/institution_provider.dart';
import '../providers/donation_provider.dart';
import '../providers/expense_provider.dart';
import '../models/institution_income_model.dart';
import '../models/org_expense_model.dart';
import '../models/teacher_model.dart';
import '../models/salary_payment_model.dart';
import '../models/user_model.dart';
import '../models/donation_model.dart';
import '../models/expense_model.dart';
import '../services/export_service.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/web_sidebar.dart';
import 'package:intl/intl.dart';

class InstitutionAccountsScreen extends StatefulWidget {
  const InstitutionAccountsScreen({super.key});

  @override
  State<InstitutionAccountsScreen> createState() =>
      _InstitutionAccountsScreenState();
}

class _InstitutionAccountsScreenState extends State<InstitutionAccountsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _listStartDate;
  late DateTime _listEndDate;

  // Export Tab Dropdowns
  String _exportReportType = 'all';
  String? _exportCollectorId;
  List<UserModel> _collectors = [];
  StreamSubscription? _collectorsSub;

  // Report Section Selection
  String _selectedReportTab =
      'Financial Ledger'; // Options: 'Financial Ledger', 'Salary Reports'
  String _salaryReportMode =
      'Monthly'; // Options: 'Monthly', 'Yearly', 'Custom'
  final int _salaryReportYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _listEndDate = DateTime.now();
    _listStartDate = DateTime.now().subtract(const Duration(days: 30));
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCollectors();
    });
  }

  void _loadCollectors() {
    final organizationId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.organizationId;

    if (organizationId == null || organizationId.isEmpty) return;

    _collectorsSub?.cancel();
    _collectorsSub = FirebaseFirestore.instance
        .collection('users')
        .where('organizationId', isEqualTo: organizationId)
        .where('role', isEqualTo: 'collector')
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() {
            _collectors = snap.docs
                .map((d) => UserModel.fromJson(d.data(), d.id))
                .where((c) => c.status == 'active')
                .toList();
          });
        });
  }

  @override
  void dispose() {
    _collectorsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickListDate(bool isStart) async {
    final initial = isStart ? _listStartDate : _listEndDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _listStartDate = picked;
          if (_listEndDate.isBefore(_listStartDate)) {
            _listEndDate = _listStartDate;
          }
        } else {
          _listEndDate = picked;
          if (_listStartDate.isAfter(_listEndDate)) {
            _listStartDate = _listEndDate;
          }
        }
      });
    }
  }

  Widget _buildListFilterAndExportRow(
    String title, {
    required VoidCallback onExportPdf,
    required VoidCallback onExportExcel,
    required Widget actionButton,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onExportPdf,
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    tooltip: 'Export PDF',
                  ),
                  IconButton(
                    onPressed: onExportExcel,
                    icon: const Icon(Icons.table_view, color: Colors.green),
                    tooltip: 'Export Excel',
                  ),
                  const SizedBox(width: 8),
                  actionButton,
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          isDesktop
              ? Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickListDate(true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color:
                                Theme.of(
                                  context,
                                ).inputDecorationTheme.fillColor ??
                                Theme.of(context).scaffoldBackgroundColor,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(_listStartDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'TO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickListDate(false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color:
                                Theme.of(
                                  context,
                                ).inputDecorationTheme.fillColor ??
                                Theme.of(context).scaffoldBackgroundColor,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('dd MMM yyyy').format(_listEndDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    InkWell(
                      onTap: () => _pickListDate(true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color:
                              Theme.of(
                                context,
                              ).inputDecorationTheme.fillColor ??
                              Theme.of(context).scaffoldBackgroundColor,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMM yyyy').format(_listStartDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'TO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _pickListDate(false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color:
                              Theme.of(
                                context,
                              ).inputDecorationTheme.fillColor ??
                              Theme.of(context).scaffoldBackgroundColor,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMM yyyy').format(_listEndDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgProvider = Provider.of<OrganizationProvider>(context);
    final isDesktop = Responsive.isDesktop(context);
    final titleText = orgProvider.orgName.isNotEmpty
        ? '${orgProvider.orgName} - Institution Accounts'
        : 'Institution Accounts';

    final tabBar = TabBar(
      controller: _tabController,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.5),
      indicatorColor: Theme.of(context).colorScheme.primary,
      isScrollable: !isDesktop,
      tabs: const [
        Tab(text: 'Income', icon: Icon(Icons.arrow_downward)),
        Tab(text: 'Expenses', icon: Icon(Icons.arrow_upward)),
        Tab(text: 'Salary', icon: Icon(Icons.payments_outlined)),
        Tab(text: 'Report', icon: Icon(Icons.analytics)),
      ],
    );

    final appBarActions = [
      IconButton(
        icon: const Icon(Icons.ios_share),
        onPressed: () => _showExportBottomSheet(context),
        tooltip: 'Export Report',
      ),
    ];

    return Scaffold(
      drawer: isDesktop
          ? null
          : WebSidebar(currentRoute: '/institution-accounts'),
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(titleText),
              bottom: tabBar,
              actions: appBarActions,
            ),
      body: Row(
        children: [
          if (isDesktop) WebSidebar(currentRoute: '/institution-accounts'),
          Expanded(
            child: isDesktop
                ? Scaffold(
                    appBar: AppBar(
                      title: Text(titleText),
                      bottom: tabBar,
                      automaticallyImplyLeading: false,
                      actions: appBarActions,
                    ),
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIncomeTab(),
                        _buildExpensesTab(),
                        _buildSalaryTab(),
                        _buildReportTab(),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildIncomeTab(),
                      _buildExpensesTab(),
                      _buildSalaryTab(),
                      _buildReportTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFilteredList({
    required bool isPdf,
    required bool isIncome,
    List<InstitutionIncomeModel>? filteredIncomes,
    List<OrgExpenseModel>? filteredExpenses,
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final orgId = auth.currentUser?.organizationId ?? 'Unknown';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (isPdf) {
        if (isIncome) {
          await ExportService.exportIncomeListToPdf(
            incomes: filteredIncomes!,
            startDate: _listStartDate,
            endDate: _listEndDate,
            organizationId: orgId,
          );
        } else {
          await ExportService.exportExpenseListToPdf(
            expenses: filteredExpenses!,
            startDate: _listStartDate,
            endDate: _listEndDate,
            organizationId: orgId,
          );
        }
      } else {
        await ExportService.exportIncomeExpenditureToExcel(
          donations: [],
          manualIncomes: isIncome ? filteredIncomes! : [],
          collectorExpenses: [],
          orgExpenses: !isIncome ? filteredExpenses! : [],
          startDate: _listStartDate,
          endDate: _listEndDate,
          organizationId: orgId,
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isPdf ? "PDF" : "Excel"} Report Downloaded Successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting report: $e')));
      }
    }
  }

  Widget _buildIncomeTab() {
    return Consumer<InstitutionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.incomes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final endOfDay = DateTime(
          _listEndDate.year,
          _listEndDate.month,
          _listEndDate.day,
          23,
          59,
          59,
        );

        final filteredIncomes = provider.incomes.where((i) {
          return i.incomeDate.isAfter(
                _listStartDate.subtract(const Duration(seconds: 1)),
              ) &&
              i.incomeDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
        }).toList();

        final totalIncome = filteredIncomes.fold<double>(
          0,
          (s, e) => s + e.amount,
        );

        return Column(
          children: [
            _buildListFilterAndExportRow(
              'Income',
              actionButton: IconButton.filled(
                onPressed: () => _showAddIncomeDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                ),
              ),
              onExportPdf: () => _exportFilteredList(
                isPdf: true,
                isIncome: true,
                filteredIncomes: filteredIncomes,
              ),
              onExportExcel: () => _exportFilteredList(
                isPdf: false,
                isIncome: true,
                filteredIncomes: filteredIncomes,
              ),
            ),
            Expanded(
              child: filteredIncomes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No income entries found.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredIncomes.length,
                      separatorBuilder: (context, index) =>
                          const Divider(indent: 72, height: 1),
                      itemBuilder: (context, index) {
                        final inc = filteredIncomes[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(inc.incomeCategory),
                          subtitle: Text(
                            '${DateFormat('dd MMM').format(inc.incomeDate)}${inc.description != null && inc.description!.isNotEmpty ? " • ${inc.description}" : ""}',
                          ),
                          trailing: Text(
                            'Rs.${NumberFormat("#,##,###").format(inc.amount)}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Income',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Rs. ${NumberFormat("#,##,###.00").format(totalIncome)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    return Consumer<InstitutionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.orgExpenses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final endOfDay = DateTime(
          _listEndDate.year,
          _listEndDate.month,
          _listEndDate.day,
          23,
          59,
          59,
        );

        final filteredExpenses = provider.orgExpenses.where((e) {
          return e.expenseDate.isAfter(
                _listStartDate.subtract(const Duration(seconds: 1)),
              ) &&
              e.expenseDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
        }).toList();

        final totalExpense = filteredExpenses.fold<double>(
          0,
          (s, e) => s + e.amount,
        );

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              _buildListFilterAndExportRow(
                'Expenses',
                actionButton: IconButton.filled(
                  onPressed: () => _showAddExpenseDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                  ),
                ),
                onExportPdf: () => _exportFilteredList(
                  isPdf: true,
                  isIncome: false,
                  filteredExpenses: filteredExpenses,
                ),
                onExportExcel: () => _exportFilteredList(
                  isPdf: false,
                  isIncome: false,
                  filteredExpenses: filteredExpenses,
                ),
              ),
              Expanded(
                child: filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No organization expenses found.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredExpenses.length,
                        separatorBuilder: (context, index) =>
                            const Divider(indent: 72, height: 1),
                        itemBuilder: (context, index) {
                          final exp = filteredExpenses[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: AppTheme.error,
                                size: 20,
                              ),
                            ),
                            title: Text(exp.expenseCategory),
                            subtitle: Text(
                              '${DateFormat('dd MMM').format(exp.expenseDate)}${exp.description != null && exp.description!.isNotEmpty ? " • ${exp.description}" : ""}',
                            ),
                            trailing: Text(
                              'Rs.${NumberFormat("#,##,###").format(exp.amount)}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Expenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Rs. ${NumberFormat("#,##,###.00").format(totalExpense)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.tealAccent
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Widget _buildReportTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'Financial Ledger',
                label: Text('Ledger'),
                icon: Icon(Icons.account_balance),
              ),
              ButtonSegment(
                value: 'Salary Reports',
                label: Text('Salary'),
                icon: Icon(Icons.payments),
              ),
            ],
            selected: {_selectedReportTab},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedReportTab = newSelection.first;
              });
            },
            showSelectedIcon: false,
          ),
        ),
        Expanded(
          child: _selectedReportTab == 'Financial Ledger'
              ? _buildFinancialLedger()
              : _buildSalaryReports(),
        ),
      ],
    );
  }

  Widget _buildFinancialLedger() {
    return Consumer3<InstitutionProvider, DonationProvider, ExpenseProvider>(
      builder: (context, instProvider, donProvider, expProvider, _) {
        final endOfDay = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          23,
          59,
          59,
        );
        final double totalDonations = donProvider.donations
            .where(
              (d) =>
                  d.date.isAfter(
                    _startDate.subtract(const Duration(seconds: 1)),
                  ) &&
                  d.date.isBefore(endOfDay.add(const Duration(seconds: 1))),
            )
            .fold(0.0, (acc, item) => acc + item.amount);
        final double manualIncome = instProvider.getTotalIncome(
          _startDate,
          endOfDay,
        );
        final double totalIncome = totalDonations + manualIncome;
        final double collExpenses = expProvider.expenses
            .where(
              (e) =>
                  e.status == 'approved' &&
                  e.expenseDate.isAfter(
                    _startDate.subtract(const Duration(seconds: 1)),
                  ) &&
                  e.expenseDate.isBefore(
                    endOfDay.add(const Duration(seconds: 1)),
                  ),
            )
            .fold(0.0, (acc, item) => acc + item.amount);
        final double adminExpenses = instProvider.getTotalOrgExpenses(
          _startDate,
          endOfDay,
        );
        final double totalExpenditure = collExpenses + adminExpenses;
        final double netResult = totalIncome - totalExpenditure;
        final bool isNegative = netResult < 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDateRangeHeader(),
              const SizedBox(height: 24),
              Responsive.isDesktop(context)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildLedgerColumn(
                            'Income',
                            ['Total Donations', 'Manual Income'],
                            [totalDonations, manualIncome],
                            totalIncome,
                            AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildLedgerColumn(
                            'Expenditure',
                            [
                              'Collector Expenses (Approved)',
                              'Organization Expenses',
                            ],
                            [collExpenses, adminExpenses],
                            totalExpenditure,
                            Colors.red.shade600,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildLedgerColumn(
                          'Income',
                          ['Total Donations', 'Manual Income'],
                          [totalDonations, manualIncome],
                          totalIncome,
                          AppTheme.primary,
                        ),
                        const SizedBox(height: 24),
                        _buildLedgerColumn(
                          'Expenditure',
                          [
                            'Collector Expenses (Approved)',
                            'Organization Expenses',
                          ],
                          [collExpenses, adminExpenses],
                          totalExpenditure,
                          Colors.red.shade600,
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              _buildNetResultCard(netResult, isNegative),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalaryReports() {
    return Consumer<InstitutionProvider>(
      builder: (context, provider, _) {
        final allPayments = provider.salaryPayments;
        final monthSet = <String>{};
        for (final p in allPayments) {
          monthSet.add(p.month);
        }
        final months = monthSet.toList()
          ..sort((a, b) {
            final mList = [
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December',
            ];
            final partsA = a.split(' ');
            final partsB = b.split(' ');
            if (partsA.length == 2 && partsB.length == 2) {
              final yearA = int.tryParse(partsA[1]) ?? 0;
              final yearB = int.tryParse(partsB[1]) ?? 0;
              if (yearA != yearB) return yearB.compareTo(yearA);
              return mList
                  .indexOf(partsB[0])
                  .compareTo(mList.indexOf(partsA[0]));
            }
            return b.compareTo(a);
          });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Salary Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _salaryReportMode,
                    items: ['Monthly', 'Yearly', 'Custom']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _salaryReportMode = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_salaryReportMode == 'Monthly')
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: months.map((m) {
                    final mPayments = allPayments
                        .where((p) => p.month == m)
                        .toList();
                    final mTotal = mPayments.fold<double>(
                      0,
                      (s, p) => s + p.paidAmount,
                    );
                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Download Report for $m'),
                            content: const Text(
                              'Export salary details for this month:',
                            ),
                            actions: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _exportSalaryDataByMonth(m, true);
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('PDF'),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _exportSalaryDataByMonth(m, false);
                                },
                                icon: const Icon(Icons.table_chart),
                                label: const Text('Excel'),
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: _buildSummaryTinyCard(
                        m,
                        'Rs.${NumberFormat("#,##,###").format(mTotal)}',
                        Colors.indigo,
                      ),
                    );
                  }).toList(),
                ),
              if (_salaryReportMode == 'Yearly')
                _buildYearlySalarySummary(allPayments),
              if (_salaryReportMode == 'Custom')
                _buildCustomSalarySummary(allPayments),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Export Salary Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _exportSalaryData(isPdf: true),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('PDF'),
                      ),
                      TextButton.icon(
                        onPressed: () => _exportSalaryData(isPdf: false),
                        icon: const Icon(Icons.table_chart, size: 18),
                        label: const Text('Excel'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTinyCard(String title, String value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlySalarySummary(List<SalaryPaymentModel> payments) {
    final yearTotal = payments
        .where((p) => p.paymentDate.year == _salaryReportYear)
        .fold(0.0, (s, p) => s + p.paidAmount);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Year $_salaryReportYear Total:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Rs.${NumberFormat("#,##,###").format(yearTotal)}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSalarySummary(List<SalaryPaymentModel> payments) {
    final endOfList = DateTime(
      _listEndDate.year,
      _listEndDate.month,
      _listEndDate.day,
      23,
      59,
      59,
    );
    final customTotal = payments
        .where(
          (p) =>
              p.paymentDate.isAfter(
                _listStartDate.subtract(const Duration(seconds: 1)),
              ) &&
              p.paymentDate.isBefore(endOfList.add(const Duration(seconds: 1))),
        )
        .fold(0.0, (s, p) => s + p.paidAmount);
    return Column(
      children: [
        _buildDateRangeHeader(isList: true),
        const SizedBox(height: 12),
        _buildSummaryTinyCard(
          'Period Total',
          'Rs.${NumberFormat("#,##,###").format(customTotal)}',
          AppTheme.primary,
        ),
      ],
    );
  }

  Widget _buildDateRangeHeader({bool isList = false}) {
    final start = isList ? _listStartDate : _startDate;
    final end = isList ? _listEndDate : _endDate;
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, color: AppTheme.primary),
            const SizedBox(width: 16),
            InkWell(
              onTap: () => isList ? _pickListDate(true) : _pickDate(true),
              child: Text(
                DateFormat('dd MMM yyyy').format(start),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.tealAccent
                      : AppTheme.primaryDark,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'TO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            InkWell(
              onTap: () => isList ? _pickListDate(false) : _pickDate(false),
              child: Text(
                DateFormat('dd MMM yyyy').format(end),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.tealAccent
                      : AppTheme.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetResultCard(double netResult, bool isNegative) {
    return Container(
      decoration: BoxDecoration(
        color: isNegative
            ? Colors.red.withValues(alpha: 0.05)
            : AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNegative
              ? Colors.red.withValues(alpha: 0.2)
              : AppTheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNetResultHeader(isNegative),
            _buildNetResultAmount(netResult, isNegative, 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNetResultHeader(bool isNegative) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isNegative ? 'Financial Deficit' : 'Financial Surplus',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: (isNegative ? Colors.red : AppTheme.primary).withValues(
              alpha: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isNegative
              ? 'Excess of Expenditure over Income'
              : 'Surplus Income over Expenditure',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Calculated for the selected period',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildNetResultAmount(
    double netResult,
    bool isNegative,
    double fontSize,
  ) {
    final fmt = NumberFormat('#,##,###');
    return Column(
      crossAxisAlignment: Responsive.isMobile(context)
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rs. ${fmt.format(netResult.abs())}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: isNegative
                ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.redAccent
                      : Colors.red.shade700)
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.tealAccent
                      : AppTheme.primary),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (isNegative ? Colors.red : Colors.green).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isNegative ? '- DEBIT BALANCE' : '+ CREDIT BALANCE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isNegative ? Colors.red : Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerColumn(
    String title,
    List<String> labels,
    List<double> values,
    double total,
    Color headerColor,
  ) {
    final fmt = NumberFormat('#,##,###');
    final isIncome = title.toLowerCase().contains('income');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: headerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  color: headerColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: headerColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                for (int i = 0; i < labels.length; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getLedgerIcon(labels[i]),
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rs. ${fmt.format(values[i])}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total $title',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      'Rs. ${fmt.format(total)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: headerColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLedgerIcon(String label) {
    label = label.toLowerCase();
    if (label.contains('donation')) return Icons.volunteer_activism;
    if (label.contains('manual') || label.contains('madarsa income')) {
      return Icons.account_balance_wallet;
    }
    if (label.contains('collector')) return Icons.person_outline;
    if (label.contains('organization') || label.contains('madarsa expense')) {
      return Icons.business;
    }
    return Icons.arrow_right;
  }

  void _showExportBottomSheet(BuildContext context) {
    final currentTabIndex = _tabController.index;
    final tabNames = ['Income', 'Expenses', 'Salary', 'Combined Report'];
    final currentTabName = tabNames[currentTabIndex];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
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
                    Text(
                      'Export $currentTabName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildExportOption(
                      context,
                      title: 'Download PDF Report',
                      subtitle: 'Format: Professional Document',
                      icon: Icons.picture_as_pdf,
                      iconColor: Colors.red.shade600,
                      onTap: () {
                        Navigator.pop(context);
                        _handleQuickExport(isPdf: true);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildExportOption(
                      context,
                      title: 'Download Excel Sheet',
                      subtitle: 'Format: Data for Spreadsheet',
                      icon: Icons.table_chart,
                      iconColor: Colors.green.shade600,
                      onTap: () {
                        Navigator.pop(context);
                        _handleQuickExport(isPdf: false);
                      },
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Advanced Report Settings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _exportReportType,
                      decoration: const InputDecoration(
                        labelText: 'Report Content',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Combined'),
                        ),
                        DropdownMenuItem(
                          value: 'donations',
                          child: Text('Donations Only'),
                        ),
                        DropdownMenuItem(
                          value: 'incomes',
                          child: Text('Madarsa Incomes Only'),
                        ),
                        DropdownMenuItem(
                          value: 'coll_expenses',
                          child: Text('Collector Expenses Only'),
                        ),
                        DropdownMenuItem(
                          value: 'org_expenses',
                          child: Text('Madarsa Expenses Only'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _exportReportType = val);
                        }
                      },
                    ),
                    DropdownButtonFormField<String?>(
                      initialValue: _exportCollectorId,
                      decoration: const InputDecoration(
                        labelText: 'Collector Filter',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Collectors'),
                        ),
                        ..._collectors.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _exportCollectorId = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleAdvancedExport(context);
                      },
                      icon: const Icon(Icons.file_download),
                      label: const Text('Generate Advanced Report'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _handleQuickExport({required bool isPdf}) {
    final currentTabIndex = _tabController.index;
    final instProvider = Provider.of<InstitutionProvider>(
      context,
      listen: false,
    );

    final endOfDay = DateTime(
      _listEndDate.year,
      _listEndDate.month,
      _listEndDate.day,
      23,
      59,
      59,
    );

    if (currentTabIndex == 0) {
      // Income Tab
      final filteredIncomes = instProvider.incomes.where((i) {
        return i.incomeDate.isAfter(
              _listStartDate.subtract(const Duration(seconds: 1)),
            ) &&
            i.incomeDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }).toList();
      _exportFilteredList(
        isPdf: isPdf,
        isIncome: true,
        filteredIncomes: filteredIncomes,
      );
    } else if (currentTabIndex == 1) {
      // Expenses Tab
      final filteredExpenses = instProvider.orgExpenses.where((e) {
        return e.expenseDate.isAfter(
              _listStartDate.subtract(const Duration(seconds: 1)),
            ) &&
            e.expenseDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }).toList();
      _exportFilteredList(
        isPdf: isPdf,
        isIncome: false,
        filteredExpenses: filteredExpenses,
      );
    } else if (currentTabIndex == 2) {
      // Salary Tab
      _exportSalaryData(isPdf: isPdf);
    } else {
      // Report Tab
      _handleAdvancedExport(context, isPdf: isPdf);
    }
  }

  Future<void> _exportSalaryData({required bool isPdf}) async {
    final instProvider = Provider.of<InstitutionProvider>(
      context,
      listen: false,
    );
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final orgId = auth.currentUser?.organizationId ?? 'Unknown';

    final endOfDay = DateTime(
      _listEndDate.year,
      _listEndDate.month,
      _listEndDate.day,
      23,
      59,
      59,
    );

    final filtered = instProvider.salaryPayments.where((s) {
      return s.paymentDate.isAfter(
            _listStartDate.subtract(const Duration(seconds: 1)),
          ) &&
          s.paymentDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (isPdf) {
        await ExportService.exportSalaryReportToPdf(
          salaryPayments: filtered,
          startDate: _listStartDate,
          endDate: _listEndDate,
          organizationId: orgId,
        );
      } else {
        await ExportService.exportSalaryReportToExcel(
          salaryPayments: filtered,
          startDate: _listStartDate,
          endDate: _listEndDate,
          organizationId: orgId,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isPdf ? "PDF" : "Excel"} Report Downloaded Successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _exportSalaryDataByMonth(String month, bool isPdf) async {
    final instProvider = Provider.of<InstitutionProvider>(
      context,
      listen: false,
    );
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final orgId = auth.currentUser?.organizationId ?? 'Unknown';

    final filtered = instProvider.salaryPayments
        .where((s) => s.month == month)
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (isPdf) {
        await ExportService.exportSalaryReportToPdf(
          salaryPayments: filtered,
          startDate: _listStartDate, // Not strictly used for month filter
          endDate: _listEndDate,
          organizationId: orgId,
          reportTitle: 'Salary Report - $month',
        );
      } else {
        await ExportService.exportSalaryReportToExcel(
          salaryPayments: filtered,
          startDate: _listStartDate,
          endDate: _listEndDate,
          organizationId: orgId,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isPdf ? "PDF" : "Excel"} Report for $month Downloaded Successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleAdvancedExport(
    BuildContext context, {
    bool isPdf = true,
  }) async {
    final instProvider = Provider.of<InstitutionProvider>(
      context,
      listen: false,
    );
    final donProvider = Provider.of<DonationProvider>(context, listen: false);
    final expProvider = Provider.of<ExpenseProvider>(context, listen: false);

    final endOfDay = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      23,
      59,
      59,
    );

    List<DonationModel> donations = [];
    List<InstitutionIncomeModel> manualIncomes = [];
    List<ExpenseModel> collectorExpenses = [];
    List<OrgExpenseModel> orgExpenses = [];

    if (_exportReportType == 'all' || _exportReportType == 'donations') {
      donations = donProvider.donations.where((d) {
        bool dateMatch =
            d.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
            d.date.isBefore(endOfDay.add(const Duration(seconds: 1)));
        bool collectorMatch =
            _exportCollectorId == null || d.collectorId == _exportCollectorId;
        return dateMatch && collectorMatch;
      }).toList();
    }

    if (_exportReportType == 'all' || _exportReportType == 'incomes') {
      manualIncomes = instProvider.incomes.where((i) {
        return i.incomeDate.isAfter(
              _startDate.subtract(const Duration(seconds: 1)),
            ) &&
            i.incomeDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }).toList();
    }

    if (_exportReportType == 'all' || _exportReportType == 'coll_expenses') {
      collectorExpenses = expProvider.expenses.where((e) {
        bool statusMatch = e.status == 'approved';
        bool dateMatch =
            e.expenseDate.isAfter(
              _startDate.subtract(const Duration(seconds: 1)),
            ) &&
            e.expenseDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
        bool collectorMatch =
            _exportCollectorId == null || e.collectorId == _exportCollectorId;
        return statusMatch && dateMatch && collectorMatch;
      }).toList();
    }

    if (_exportReportType == 'all' || _exportReportType == 'org_expenses') {
      orgExpenses = instProvider.orgExpenses.where((e) {
        return e.expenseDate.isAfter(
              _startDate.subtract(const Duration(seconds: 1)),
            ) &&
            e.expenseDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }).toList();
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final orgId = auth.currentUser?.organizationId ?? 'Unknown';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (isPdf) {
        await ExportService.exportIncomeExpenditureReport(
          donations: donations,
          manualIncomes: manualIncomes,
          collectorExpenses: collectorExpenses,
          orgExpenses: orgExpenses,
          startDate: _startDate,
          endDate: _endDate,
          organizationId: orgId,
        );
      } else {
        await ExportService.exportIncomeExpenditureToExcel(
          donations: donations,
          manualIncomes: manualIncomes,
          collectorExpenses: collectorExpenses,
          orgExpenses: orgExpenses,
          startDate: _startDate,
          endDate: _endDate,
          organizationId: orgId,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isPdf ? "PDF" : "Excel"} Report Downloaded Successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting: $e')));
      }
    }
  }

  // --------------------------------------------------------------------------
  // ADD DIALOGS
  // --------------------------------------------------------------------------

  static const List<String> _incomeCategories = [
    'General Donation',
    'Sadqa',
    'Zakat',
    'Lillah',
    'Imdad',
    'Fees',
    'Qurbani Skin',
    'Scrap Sale',
    'Scholarship Fund',
    'Other',
  ];

  static const List<String> _expenseCategories = [
    'Teachers\' Salary',
    'Staff Salary',
    'Lentils, Veg, Rice',
    'Flour, Milk, Ration',
    'Electricity, Water',
    'Gas, Wi-Fi',
    'Medical',
    'Construction',
    'Cleaning',
    'Stationery',
    'Events',
    'Repayments',
    'Travelling',
    'Transport',
    'Maintenance',
    'Other',
  ];

  void _showAddIncomeDialog(BuildContext screenContext) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = _incomeCategories.first;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: screenContext,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Manual Income'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (Rs.)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _incomeCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (selectedCategory == 'Other' &&
                            (val == null || val.trim().isEmpty)) {
                          return 'Description required for "Other"';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setDialogState(() => selectedDate = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final instProvider = Provider.of<InstitutionProvider>(
                      context,
                      listen: false,
                    );

                    final orgId = authProvider.currentUser?.organizationId;
                    final uid = authProvider.currentUser?.id;

                    if (orgId == null || uid == null) return;

                    final inc = InstitutionIncomeModel(
                      id: '',
                      organizationId: orgId,
                      amount: double.parse(amountCtrl.text),
                      incomeCategory: selectedCategory,
                      description: descCtrl.text.trim(),
                      incomeDate: selectedDate,
                      createdAt: DateTime.now(),
                      createdBy: uid,
                    );

                    Navigator.pop(context); // close Add Income dialog

                    showDialog(
                      context: screenContext,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      await instProvider.addIncome(inc);
                      if (screenContext.mounted) {
                        Navigator.pop(screenContext); // close loader
                        ScaffoldMessenger.of(screenContext).showSnackBar(
                          const SnackBar(
                            content: Text('Income Added Successfully!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (screenContext.mounted) {
                        Navigator.pop(screenContext); // close loader
                        ScaffoldMessenger.of(
                          screenContext,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext screenContext) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedCategory;
    DateTime selectedDate = DateTime.now();

    final categoryGroups = {
      'Salaries': ['Teachers\' Salary', 'Staff Salary'],
      'Kitchen & Food': ['Lentils, Veg, Rice', 'Flour, Milk, Ration'],
      'Utility Bills': ['Electricity, Water', 'Gas, Wi-Fi'],
      'Other Expenses': [
        'Medical',
        'Construction',
        'Cleaning',
        'Stationery',
        'Events',
        'Repayments',
        'Other',
      ],
    };

    final categoryIcons = {
      'Salaries': Icons.payments_rounded,
      'Kitchen & Food': Icons.restaurant_rounded,
      'Utility Bills': Icons.electric_bolt_rounded,
      'Other Expenses': Icons.miscellaneous_services_rounded,
    };

    showDialog(
      context: screenContext,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.add_circle_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  selectedCategory == null
                      ? 'Select Category'
                      : 'Add Expense Details',
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: selectedCategory == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Please select a category for the new expense.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: categoryGroups.keys.map((group) {
                              return InkWell(
                                onTap: () {
                                  setDialogState(
                                    () => selectedCategory =
                                        categoryGroups[group]!.first,
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 230,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.05,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            categoryIcons[group],
                                            color: AppTheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            group,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ...categoryGroups[group]!
                                          .take(2)
                                          .map(
                                            (sub) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.circle,
                                                    size: 6,
                                                    color: AppTheme.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    sub,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      )
                    : Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: _expenseCategories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedCategory = val);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Amount (Rs.)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: descCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Description (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (d != null) {
                                  setDialogState(() => selectedDate = d);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (selectedCategory != null) {
                    setDialogState(() => selectedCategory = null);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Text(selectedCategory == null ? 'Cancel' : 'Back'),
              ),
              if (selectedCategory != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final instProvider = Provider.of<InstitutionProvider>(
                        context,
                        listen: false,
                      );
                      final orgId = authProvider.currentUser?.organizationId;
                      final uid = authProvider.currentUser?.id;

                      if (orgId == null || uid == null) return;

                      final exp = OrgExpenseModel(
                        id: '',
                        organizationId: orgId,
                        amount: double.parse(amountCtrl.text),
                        expenseCategory: selectedCategory!,
                        description: descCtrl.text.trim(),
                        expenseDate: selectedDate,
                        createdAt: DateTime.now(),
                        createdBy: uid,
                      );

                      Navigator.pop(context);
                      showDialog(
                        context: screenContext,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await instProvider.addOrgExpense(exp);
                        if (screenContext.mounted) {
                          Navigator.pop(screenContext);
                          ScaffoldMessenger.of(screenContext).showSnackBar(
                            const SnackBar(
                              content: Text('Expense Added Successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (screenContext.mounted) {
                          Navigator.pop(screenContext);
                          ScaffoldMessenger.of(
                            screenContext,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SALARY TAB
  // ──────────────────────────────────────────────────────────────────────────

  // Local salary search state
  final TextEditingController _salarySearchCtrl = TextEditingController();

  Widget _buildSalaryTab() {
    return Consumer<InstitutionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.salaryPayments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final endOfDay = DateTime(
          _listEndDate.year,
          _listEndDate.month,
          _listEndDate.day,
          23,
          59,
          59,
        );

        // Date-filtered
        final dateFiltered = provider.salaryPayments.where((s) {
          return s.paymentDate.isAfter(
                _listStartDate.subtract(const Duration(seconds: 1)),
              ) &&
              s.paymentDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
        }).toList();

        return StatefulBuilder(
          builder: (context, setSalaryState) {
            final searchQuery = _salarySearchCtrl.text.trim().toLowerCase();
            final filtered = dateFiltered.where((s) {
              if (searchQuery.isEmpty) return true;
              return s.teacherName.toLowerCase().contains(searchQuery);
            }).toList();

            final totalPaid = filtered.fold<double>(
              0,
              (acc, s) => acc + s.paidAmount,
            );

            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  // ── filter + buttons row ──────────────────────────────
                  _buildListFilterAndExportRow(
                    'Salary',
                    actionButton: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filled(
                          onPressed: () => _showManageTeachersDialog(context),
                          icon: const Icon(
                            Icons.manage_accounts_rounded,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                            ),
                          ),
                          tooltip: 'Manage Teachers',
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () => _showAddSalaryDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                            ),
                          ),
                          tooltip: 'Pay Salary',
                        ),
                      ],
                    ),
                    onExportPdf: () async {
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      try {
                        await ExportService.exportSalaryReportToPdf(
                          salaryPayments: filtered,
                          startDate: _listStartDate,
                          endDate: _listEndDate,
                          organizationId:
                              auth.currentUser?.organizationId ?? '',
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Salary PDF Downloaded'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    onExportExcel: () async {
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      try {
                        await ExportService.exportSalaryReportToExcel(
                          salaryPayments: filtered,
                          startDate: _listStartDate,
                          endDate: _listEndDate,
                          organizationId:
                              auth.currentUser?.organizationId ?? '',
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Salary Excel Downloaded'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                  ),

                  // ── Name search bar ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _salarySearchCtrl,
                      onChanged: (_) => setSalaryState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by teacher name...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _salarySearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _salarySearchCtrl.clear();
                                  setSalaryState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                  ),

                  // ── Payment list ──────────────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'No salary payments found.'
                                      : 'No results for "$searchQuery".',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const Divider(indent: 72, height: 1),
                            itemBuilder: (context, index) {
                              final sal = filtered[index];
                              final isPartial =
                                  sal.paidAmount < sal.defaultSalary;
                              final statusColor = isPartial
                                  ? AppTheme.warning
                                  : AppTheme.success;

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isPartial
                                        ? Icons.pending_rounded
                                        : Icons.check_circle_rounded,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(sal.teacherName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${sal.month} • ${sal.paymentMode}'),
                                    if (sal.note != null &&
                                        sal.note!.isNotEmpty)
                                      Text(
                                        sal.note!,
                                        style: const TextStyle(fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rs.${NumberFormat("#,##,###").format(sal.paidAmount)}',
                                      style: TextStyle(
                                        color: isPartial
                                            ? AppTheme.warning
                                            : AppTheme.primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd MMM',
                                      ).format(sal.paymentDate),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Monthly Breakdown moved to Report Section

                  // ── Total footer ──────────────────────────────────────
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Salary Paid',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Rs. ${NumberFormat('#,##,###.00').format(totalPaid)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.tealAccent
                                  : Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSalaryDialog(BuildContext screenContext) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    TeacherModel? selectedTeacher;
    final now = DateTime.now();
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    String selectedMonth = '${monthNames[now.month - 1]} ${now.year}';
    DateTime selectedDate = now;
    String selectedPaymentMode = 'Cash';
    const paymentModes = ['Cash', 'Online', 'UPI', 'Check'];

    showDialog(
      context: screenContext,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final provider = Provider.of<InstitutionProvider>(
            context,
            listen: false,
          );
          final teachers = provider.teachers;
          return AlertDialog(
            title: const Text('Pay Salary'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (teachers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No teachers found. Add teachers first via "Manage Teachers".',
                          style: TextStyle(color: Colors.orange),
                        ),
                      )
                    else
                      DropdownButtonFormField<TeacherModel>(
                        initialValue: selectedTeacher,
                        decoration: const InputDecoration(
                          labelText: 'Select Teacher',
                          border: OutlineInputBorder(),
                        ),
                        items: teachers
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  '${t.name}  (Rs. ${NumberFormat('#,##,###').format(t.defaultSalary)})',
                                ),
                              ),
                            )
                            .toList(),
                        validator: (val) =>
                            val == null ? 'Please select a teacher' : null,
                        onChanged: (val) {
                          setDialogState(() {
                            selectedTeacher = val;
                            if (val != null) {
                              amountCtrl.text = val.defaultSalary
                                  .toStringAsFixed(0);
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid (Rs.)',
                        border: OutlineInputBorder(),
                        helperText: 'Auto-filled. Edit to pay partial amount.',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null) {
                          return 'Invalid number';
                        }
                        if (double.parse(val) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Payment mode dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedPaymentMode,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: paymentModes
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedPaymentMode = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(12, (i) {
                        final m = '${monthNames[i]} ${now.year}';
                        return DropdownMenuItem(value: m, child: Text(m));
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedMonth = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) {
                          setDialogState(() => selectedDate = d);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Payment Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: teachers.isEmpty
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final instProvider = Provider.of<InstitutionProvider>(
                          context,
                          listen: false,
                        );
                        final orgId = authProvider.currentUser?.organizationId;
                        final uid = authProvider.currentUser?.id;
                        if (orgId == null || uid == null) return;

                        final payment = SalaryPaymentModel(
                          id: '',
                          organizationId: orgId,
                          teacherId: selectedTeacher!.id,
                          teacherName: selectedTeacher!.name,
                          defaultSalary: selectedTeacher!.defaultSalary,
                          paidAmount: double.parse(amountCtrl.text),
                          paymentDate: selectedDate,
                          month: selectedMonth,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                          paymentMode: selectedPaymentMode,
                          createdAt: DateTime.now(),
                          createdBy: uid,
                        );

                        Navigator.pop(context);
                        showDialog(
                          context: screenContext,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          await instProvider.addSalaryPayment(payment);
                          if (screenContext.mounted) {
                            Navigator.pop(screenContext);
                            ScaffoldMessenger.of(screenContext).showSnackBar(
                              const SnackBar(
                                content: Text('Salary Recorded Successfully!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (screenContext.mounted) {
                            Navigator.pop(screenContext);
                            ScaffoldMessenger.of(screenContext).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Manage Teachers Dialog
  // ──────────────────────────────────────────────────────────────────────────
  void _showManageTeachersDialog(BuildContext screenContext) {
    showDialog(
      context: screenContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final provider = Provider.of<InstitutionProvider>(context);
          final teachers = provider.teachers;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.manage_accounts, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Manage Teachers'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (teachers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No teachers added yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: teachers.length,
                        itemBuilder: (context, i) {
                          final t = teachers[i];
                          return ListTile(
                            dense: true,
                            leading: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.indigo,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              t.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Rs. ${NumberFormat('#,##,###').format(t.defaultSalary)} / month',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.indigo,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showEditTeacherDialog(screenContext, t);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.shade400,
                                    size: 18,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete Teacher'),
                                        content: Text('Remove "${t.name}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await provider.deleteTeacher(t.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const Divider(),
                  _AddTeacherInlineForm(screenContext: screenContext),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTeacherDialog(
    BuildContext screenContext,
    TeacherModel teacher,
  ) {
    final nameCtrl = TextEditingController(text: teacher.name);
    final salaryCtrl = TextEditingController(
      text: teacher.defaultSalary.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: screenContext,
      builder: (context) => AlertDialog(
        title: const Text('Edit Teacher'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Teacher Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: salaryCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Default Salary (Rs.)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final instProvider = Provider.of<InstitutionProvider>(
                context,
                listen: false,
              );
              final updated = teacher.copyWith(
                name: nameCtrl.text.trim(),
                defaultSalary: double.parse(salaryCtrl.text),
              );
              Navigator.pop(context);
              try {
                await instProvider.updateTeacher(updated);
                if (screenContext.mounted) {
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    const SnackBar(content: Text('Teacher Updated!')),
                  );
                }
              } catch (e) {
                if (screenContext.mounted) {
                  ScaffoldMessenger.of(
                    screenContext,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

// ─── Inline "Add Teacher" form inside Manage Teachers dialog ─────────────────
class _AddTeacherInlineForm extends StatefulWidget {
  final BuildContext screenContext;
  const _AddTeacherInlineForm({required this.screenContext});

  @override
  State<_AddTeacherInlineForm> createState() => _AddTeacherInlineFormState();
}

class _AddTeacherInlineFormState extends State<_AddTeacherInlineForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Add New Teacher',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Teacher Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (val) =>
                (val == null || val.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _salaryCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Default Salary (Rs.)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              if (double.tryParse(val) == null) return 'Invalid number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _saving = true);
                      final authProvider = Provider.of<AuthProvider>(
                        widget.screenContext,
                        listen: false,
                      );
                      final instProvider = Provider.of<InstitutionProvider>(
                        widget.screenContext,
                        listen: false,
                      );
                      final orgId =
                          authProvider.currentUser?.organizationId ?? '';
                      final teacher = TeacherModel(
                        id: '',
                        organizationId: orgId,
                        name: _nameCtrl.text.trim(),
                        defaultSalary: double.parse(_salaryCtrl.text),
                        createdAt: DateTime.now(),
                      );
                      try {
                        await instProvider.addTeacher(teacher);
                        _nameCtrl.clear();
                        _salaryCtrl.clear();
                        if (widget.screenContext.mounted) {
                          ScaffoldMessenger.of(
                            widget.screenContext,
                          ).showSnackBar(
                            const SnackBar(content: Text('Teacher Added!')),
                          );
                        }
                      } catch (e) {
                        if (widget.screenContext.mounted) {
                          ScaffoldMessenger.of(
                            widget.screenContext,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: const Text('Add Teacher'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
