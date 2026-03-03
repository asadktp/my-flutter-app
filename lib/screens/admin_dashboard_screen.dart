import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/donation_model.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../providers/donation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';
import '../providers/expense_provider.dart';
import '../services/export_service.dart';
import '../widgets/web_sidebar.dart';
import '../models/salary_payment_model.dart';
import '../widgets/export_dialog.dart';
import '../widgets/double_back_to_close.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import 'donor_history_screen.dart';
import 'admin_expenses_screen.dart';
import 'user_management_screen.dart';
import 'organization_settings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ── Filter state ─────────────────────────────────────────────────────────
  String? _selectedCollectorId; // null = All Collectors
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Pagination ───────────────────────────────────────────────────────────
  static const int _pageSize = 20;
  bool _hasMore = true;
  bool _loadingMore = false;
  final List<DonationModel> _pagedDonations = [];
  String? _lastLoadedOrgId;

  int _selectedIndex = 0;

  // ── Collectors list for dropdown ─────────────────────────────────────────
  List<UserModel> _collectors = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orgId = _organizationId;
    if (orgId.isNotEmpty && orgId != _lastLoadedOrgId) {
      _lastLoadedOrgId = orgId;
      _loadCollectors();
      _loadFirstPage();
    }
  }

  String get _organizationId =>
      Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser?.organizationId ??
      '';

  // ── Load collectors for dropdown (Real-time stream) ─────────────────────
  StreamSubscription? _collectorsSub;

  void _loadCollectors() {
    if (_organizationId.isEmpty) return;

    _collectorsSub?.cancel();
    _collectorsSub = FirebaseFirestore.instance
        .collection('users')
        .where('organizationId', isEqualTo: _organizationId)
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
    _donationsSub?.cancel();
    super.dispose();
  }

  // ── Build filtered Firestore query ────────────────────────────────────────
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('donations')
        .where('organizationId', isEqualTo: _organizationId)
        .orderBy('date', descending: true);

    if (_selectedCollectorId != null) {
      q = q.where('collectorId', isEqualTo: _selectedCollectorId);
    }
    if (_startDate != null) {
      q = q.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!),
      );
    }
    if (_endDate != null) {
      final endOfDay = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }
    return q;
  }

  // ── Pagination (Real-time Stream) ──────────────────────────────────────────
  StreamSubscription? _donationsSub;
  int _currentLimit = _pageSize;

  Future<void> _loadFirstPage() async {
    if (_organizationId.isEmpty) return;
    setState(() {
      _currentLimit = _pageSize;
      _pagedDonations.clear();
      _hasMore = true;
    });
    _listenToDonations();
    // Artificial delay to let the refreshing indicator show briefly
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _loadNextPage() {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _currentLimit += _pageSize;
    });
    _listenToDonations();
  }

  void _listenToDonations() {
    _donationsSub?.cancel();

    // Build query with the _currentLimit
    Query<Map<String, dynamic>> q = _buildQuery().limit(_currentLimit);

    _donationsSub = q.snapshots().listen(
      (snap) {
        if (!mounted) return;

        final docs = snap.docs
            .map((d) => DonationModel.fromJson(d.data(), d.id))
            .toList();

        setState(() {
          _pagedDonations.clear();
          _pagedDonations.addAll(docs);
          _loadingMore = false;
          // If we received fewer docs than our requested limit, we've hit the end
          _hasMore = docs.length == _currentLimit;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _loadingMore = false);
        debugPrint('[AdminDashboard] Stream error: $e');
      },
    );
  }

  void _applyFilters() {
    _loadFirstPage();
  }

  void _clearFilters() {
    setState(() {
      _selectedCollectorId = null;
      _startDate = null;
      _endDate = null;
    });
    _loadFirstPage();
  }

  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Provider.of<OrganizationProvider>(context, listen: false).clear();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  // ── Date picker helper ────────────────────────────────────────────────────
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: child!,
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final donationProvider = Provider.of<DonationProvider>(context);
    final orgProvider = Provider.of<OrganizationProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final currentUser = authProvider.currentUser;
    final fmt = NumberFormat('#,##,###');

    return DoubleBackToClose(
      child: Scaffold(
        drawer: const WebSidebar(currentRoute: '/admin'),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                orgProvider.orgName.isNotEmpty
                    ? orgProvider.orgName
                    : 'Admin Dashboard',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                DateFormat('EEEE, MMM dd').format(DateTime.now()),
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Responsive(
          mobile: _buildCurrentPage(
            authProvider,
            donationProvider,
            orgProvider,
            expenseProvider,
            currentUser,
            fmt,
          ),
          desktop: Row(
            children: [
              const WebSidebar(currentRoute: '/admin'),
              Expanded(
                child: _buildCurrentPage(
                  authProvider,
                  donationProvider,
                  orgProvider,
                  expenseProvider,
                  currentUser,
                  fmt,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/donor-history'),
          elevation: 0,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.history_rounded),
          label: const Text(
            'History',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
        bottomNavigationBar: Responsive.isDesktop(context)
            ? null
            : BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppTheme.primary,
                unselectedItemColor: Colors.grey,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history_rounded),
                    label: 'Donors',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long_rounded),
                    label: 'Expenses',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_alt_rounded),
                    label: 'Users',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCurrentPage(
    AuthProvider authProvider,
    DonationProvider donationProvider,
    OrganizationProvider orgProvider,
    ExpenseProvider expenseProvider,
    UserModel? currentUser,
    NumberFormat fmt,
  ) {
    switch (_selectedIndex) {
      case 0:
        return _buildMainContent(
          authProvider,
          donationProvider,
          orgProvider,
          expenseProvider,
          currentUser,
          fmt,
        );
      case 1:
        return DonorHistoryScreen(isEmbedded: true);
      case 2:
        return AdminExpensesScreen(isEmbedded: true);
      case 3:
        return UserManagementScreen(isEmbedded: true);
      case 4:
        return OrganizationSettingsScreen(isEmbedded: true);
      default:
        return _buildMainContent(
          authProvider,
          donationProvider,
          orgProvider,
          expenseProvider,
          currentUser,
          fmt,
        );
    }
  }

  Widget _buildMainContent(
    AuthProvider authProvider,
    DonationProvider donationProvider,
    OrganizationProvider orgProvider,
    ExpenseProvider expenseProvider,
    UserModel? currentUser,
    NumberFormat fmt,
  ) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isDesktop(context) ? 48 : 20,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting & Header ───────────────────────────
                  // ── Greeting & Header ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      if (Responsive.isDesktop(context))
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              backgroundImage:
                                  orgProvider.organization?.logoUrl != null &&
                                      orgProvider
                                          .organization!
                                          .logoUrl!
                                          .isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      orgProvider.organization!.logoUrl!,
                                    )
                                  : null,
                              child:
                                  orgProvider.organization?.logoUrl == null ||
                                      orgProvider.organization!.logoUrl!.isEmpty
                                  ? const Icon(
                                      Icons.business,
                                      color: AppTheme.primary,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Subscription Status ──────────────────────────────
                  _buildSubscriptionCard(orgProvider),
                  const SizedBox(height: 24),

                  // ── Summary Cards ────────────────────────────────────
                  _buildSummaryCards(donationProvider, expenseProvider, fmt),
                  const SizedBox(height: 24),

                  // ── Quick Actions ────────────────────────────────────
                  _sectionHeader('Quick Actions'),
                  const SizedBox(height: 12),
                  _buildActionCards(context, donationProvider),
                  const SizedBox(height: 28),

                  // ── Donations with Filters ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionHeader('Donations'),
                      if (_selectedCollectorId != null ||
                          _startDate != null ||
                          _endDate != null)
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  _buildFiltersRow(context),
                  const SizedBox(height: 16),

                  // ── Donation List ────────────────────────────────────
                  _buildDonationList(fmt),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Summary Cards ─────────────────────────────────────────────────────────
  Widget _buildSummaryCards(
    DonationProvider p,
    ExpenseProvider ep,
    NumberFormat fmt,
  ) {
    final totalApprovedExpenses = ep.expenses
        .where((e) => e.status == 'approved')
        .fold(0.0, (acc, e) => acc + e.amount);
    final netCollection = p.totalCollection - totalApprovedExpenses;

    return GridView.count(
      crossAxisCount: Responsive.isDesktop(context) ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: Responsive.isDesktop(context) ? 1.35 : 1.4,
      children: [
        _metricCard(
          'Total Donations',
          'Rs. ${fmt.format(p.totalCollection)}',
          Icons.account_balance_wallet,
          AppTheme.success,
          trend: '+12.5%',
          isPositive: true,
        ),
        _metricCard(
          'Approved Expenses',
          'Rs. ${fmt.format(totalApprovedExpenses)}',
          Icons.outbond,
          Colors.red.shade400,
          trend: '+5.2%',
          isPositive: false,
        ),
        _metricCard(
          'Net Collection',
          'Rs. ${fmt.format(netCollection)}',
          Icons.savings,
          Colors.green.shade700,
          trend: '+8.1%',
          isPositive: true,
        ),
        _metricCard(
          'Total Donors',
          '${p.uniqueDonorsCount}',
          Icons.groups,
          Colors.blue.shade500,
          trend: '+24',
          isPositive: true,
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(OrganizationProvider op) {
    final o = op.organization;
    if (o == null) return const SizedBox.shrink();

    final endDate = o.subscriptionEndDate;
    final isExpired = endDate.isBefore(DateTime.now());
    final isSuspended =
        o.status == 'suspended' || o.subscriptionStatus == 'Suspended';
    final isActuallyExpired =
        o.status == 'expired' || o.subscriptionStatus == 'Expired' || isExpired;

    final statusColor = isSuspended || isActuallyExpired
        ? Colors.red
        : Colors.green;
    final statusText = isSuspended
        ? 'SUSPENDED'
        : (isActuallyExpired ? 'EXPIRED' : 'ACTIVE');
    final df = DateFormat('MMM dd, yyyy');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.stars_rounded, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Subscription',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPlanDetailColumn(
                  'Plan',
                  o.subscriptionPlan.toUpperCase(),
                  Icons.layers_outlined,
                ),
              ),
              Expanded(
                child: _buildPlanDetailColumn(
                  'Start',
                  df.format(o.subscriptionStartDate),
                  Icons.calendar_today_outlined,
                ),
              ),
              Expanded(
                child: _buildPlanDetailColumn(
                  'Expiry',
                  df.format(endDate),
                  Icons.event_busy_outlined,
                  textColor: isExpired ? Colors.red : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDetailColumn(
    String label,
    String value,
    IconData icon, {
    Color? textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // Simplified _metricCard with trend indicators and TextTheme
  Widget _metricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? trend,
    bool? isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              if (trend != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isPositive!
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: isPositive ? AppTheme.success : AppTheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'vs last month',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(String format) async {
    final ExportFilterOptions? opts = await showDialog<ExportFilterOptions>(
      context: context,
      builder: (_) =>
          ExportDialog(collectors: _collectors, exportFormat: format),
    );

    if (opts == null || !mounted) return; // User cancelled

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final endOfDay = DateTime(
        opts.endDate.year,
        opts.endDate.month,
        opts.endDate.day,
        23,
        59,
        59,
      );

      List<DonationModel>? donations;
      List<ExpenseModel>? expenses;
      List<SalaryPaymentModel>? salaries;

      if (opts.reportType == 'both' || opts.reportType == 'donations') {
        Query<Map<String, dynamic>> dq = FirebaseFirestore.instance
            .collection('donations')
            .where('organizationId', isEqualTo: _organizationId)
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(opts.startDate),
            )
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .orderBy('date', descending: true);

        if (opts.collectorId != null) {
          dq = dq.where('collectorId', isEqualTo: opts.collectorId);
        }

        final dSnap = await dq.get();
        donations = dSnap.docs
            .map((d) => DonationModel.fromJson(d.data(), d.id))
            .toList();
      }

      if (opts.reportType == 'both' || opts.reportType == 'expenses') {
        Query<Map<String, dynamic>> eq = FirebaseFirestore.instance
            .collection('expenses')
            .where('organizationId', isEqualTo: _organizationId)
            .where(
              'expenseDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(opts.startDate),
            )
            .where(
              'expenseDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
            )
            .orderBy('expenseDate', descending: true);

        if (opts.collectorId != null) {
          eq = eq.where('collectorId', isEqualTo: opts.collectorId);
        }

        final eSnap = await eq.get();
        expenses = eSnap.docs
            .map((e) => ExpenseModel.fromJson(e.data(), e.id))
            .toList();
      }

      if (opts.reportType == 'salaries') {
        Query<Map<String, dynamic>> sq = FirebaseFirestore.instance
            .collection('salaryPayments')
            .where('organizationId', isEqualTo: _organizationId)
            .where(
              'paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(opts.startDate),
            )
            .where(
              'paymentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
            )
            .orderBy('paymentDate', descending: true);

        if (opts.collectorId != null) {
          // Salaries usually aren't per-collector in the same way, but we can filter if needed.
          // For now, let's assume all salaries since it's an admin report.
        }

        final sSnap = await sq.get();
        salaries = sSnap.docs
            .map((s) => SalaryPaymentModel.fromJson(s.data(), s.id))
            .toList();
      }

      if (!mounted) return;
      Navigator.pop(context); // hide loading

      if ((donations == null || donations.isEmpty) &&
          (expenses == null || expenses.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data found for selected filters.')),
        );
        return;
      }

      if (format == 'Excel') {
        if (opts.reportType == 'salaries' && salaries != null) {
          await ExportService.exportSalaryReportToExcel(
            salaryPayments: salaries,
            startDate: opts.startDate,
            endDate: opts.endDate,
            organizationId: _organizationId,
          );
        } else {
          await ExportService.exportToExcel(
            donations: donations,
            expenses: expenses,
          );
        }
      } else if (format == 'PDF') {
        if (opts.reportType == 'salaries' && salaries != null) {
          await ExportService.exportSalaryReportToPdf(
            salaryPayments: salaries,
            startDate: opts.startDate,
            endDate: opts.endDate,
            organizationId: _organizationId,
          );
        } else {
          await ExportService.exportToPdf(
            donations: donations,
            expenses: expenses,
            organizationId: _organizationId,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // hide loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
    }
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildActionCards(BuildContext context, DonationProvider dp) {
    final actions = [
      _actionCard(
        'Manage',
        Icons.manage_accounts,
        () => Navigator.pushNamed(context, '/manage-users'),
      ),
      _actionCard(
        'Settings',
        Icons.settings_suggest,
        () => Navigator.pushNamed(context, '/org-settings'),
      ),
      _actionCard(
        'Add Collector',
        Icons.person_add_alt_1,
        () => Navigator.pushNamed(context, '/add-collector'),
      ),
      _actionCard('Excel', Icons.table_chart, () {
        _handleExport('Excel');
      }),
      _actionCard('PDF', Icons.picture_as_pdf, () {
        _handleExport('PDF');
      }),
      _actionCard(
        'Donors',
        Icons.history,
        () => Navigator.pushNamed(context, '/donor-history'),
      ),
      _actionCard(
        'Expenses',
        Icons.receipt_long,
        () => Navigator.pushNamed(context, '/admin-expenses'),
      ),
      _actionCard(
        'Add Exp',
        Icons.add_circle,
        () => Navigator.pushNamed(context, '/institution-accounts'),
      ),
    ];

    if (Responsive.isDesktop(context)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: actions
              .map(
                (a) => Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: SizedBox(width: 100, child: a),
                ),
              )
              .toList(),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.start,
      children: actions
          .map(
            (a) => SizedBox(
              width: (MediaQuery.of(context).size.width - 64) / 4,
              child: a,
            ),
          )
          .toList(),
    );
  }

  // ── Filters Row (Mobile) ───────────────────────────────────────────────────
  Widget _buildFiltersRow(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yy');
    final isDesktop = Responsive.isDesktop(context);

    final collectorDropdown = Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _selectedCollectorId,
          hint: const Text('All Collectors'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Collectors'),
            ),
            ..._collectors.map((c) {
              final total = Provider.of<DonationProvider>(
                context,
                listen: false,
              ).getDonationsByCollector(c.id).fold(0.0, (s, d) => s + d.amount);
              return DropdownMenuItem<String?>(
                value: c.id,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      'Rs.${NumberFormat('#,##,###').format(total)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (val) {
            setState(() {
              _selectedCollectorId = val;
            });
            _applyFilters();
          },
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(flex: 3, child: collectorDropdown),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _pickDate(true),
              child: _dateChip(
                _startDate == null
                    ? 'Start Date'
                    : dateFormat.format(_startDate!),
                Icons.calendar_today,
                _startDate != null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _pickDate(false),
              child: _dateChip(
                _endDate == null ? 'End Date' : dateFormat.format(_endDate!),
                Icons.calendar_today,
                _endDate != null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Filter'),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Collector dropdown
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primary.withAlpha(50)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _selectedCollectorId,
              hint: const Text('All Collectors'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Collectors'),
                ),
                ..._collectors.map((c) {
                  // Calculate total amount for this collector
                  final total =
                      Provider.of<DonationProvider>(context, listen: false)
                          .getDonationsByCollector(c.id)
                          .fold(0.0, (s, d) => s + d.amount);
                  return DropdownMenuItem<String?>(
                    value: c.id,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          'Rs.${NumberFormat('#,##,###').format(total)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedCollectorId = val;
                });
                _applyFilters();
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Date range row
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(true),
                child: _dateChip(
                  _startDate == null
                      ? 'Start Date'
                      : dateFormat.format(_startDate!),
                  Icons.calendar_today,
                  _startDate != null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(false),
                child: _dateChip(
                  _endDate == null ? 'End Date' : dateFormat.format(_endDate!),
                  Icons.calendar_today,
                  _endDate != null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Filter'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateChip(String text, IconData icon, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withAlpha(50),
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: selected
            ? Theme.of(context).colorScheme.primary.withAlpha(20)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Donation List ─────────────────────────────────────────────────────────
  Widget _buildDonationList(NumberFormat fmt) {
    if (_pagedDonations.isEmpty && _loadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_pagedDonations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppTheme.textSecondary.withAlpha(80),
              ),
              const SizedBox(height: 12),
              Text(
                'No donations found',
                style: TextStyle(
                  color: AppTheme.textSecondary.withAlpha(180),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Filtered total badge
        if (_selectedCollectorId != null ||
            _startDate != null ||
            _endDate != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.success.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.success.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, color: AppTheme.success, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_pagedDonations.length} records shown — Total: Rs.${fmt.format(_pagedDonations.fold(0.0, (s, d) => s + d.amount))}',
                  style: const TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pagedDonations.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => _donationCard(_pagedDonations[i], fmt),
        ),

        // Load More / End
        const SizedBox(height: 16),
        if (_hasMore)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadingMore ? null : _loadNextPage,
              icon: _loadingMore
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: Text(_loadingMore ? 'Loading...' : 'Load More'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppTheme.primary.withAlpha(80)),
              ),
            ),
          )
        else
          Text(
            '— End of results (${_pagedDonations.length} total) —',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(150),
              fontSize: 12,
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _donationCard(DonationModel d, NumberFormat fmt) {
    final isToday =
        d.date.day == DateTime.now().day &&
        d.date.month == DateTime.now().month &&
        d.date.year == DateTime.now().year;
    final dateStr = isToday
        ? 'Today, ${DateFormat('hh:mm a').format(d.date)}'
        : DateFormat('dd MMM, hh:mm a').format(d.date);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 18,
        ),
      ),
      title: Text(d.donorName, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(
        '$dateStr · ${d.paymentMode} · ${d.collectorName ?? "Admin"}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        'Rs.${fmt.format(d.amount)}',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
    title,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );
}
