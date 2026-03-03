import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/donation_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/double_back_to_close.dart';
import '../widgets/web_sidebar.dart';

// Import screens to use as content
import 'donor_history_screen.dart';
import 'add_expense_screen.dart';
import 'collector_profile_screen.dart';
import '../widgets/empty_state.dart';
import '../models/donation_model.dart';

class CollectorDashboardScreen extends StatefulWidget {
  const CollectorDashboardScreen({super.key});

  @override
  State<CollectorDashboardScreen> createState() =>
      _CollectorDashboardScreenState();
}

class _CollectorDashboardScreenState extends State<CollectorDashboardScreen> {
  int _selectedIndex = 0;

  void _logout(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBackToClose(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: Responsive.isDesktop(context)
            ? null
            : WebSidebar(currentRoute: '/collector'),
        body: SafeArea(
          child: Responsive.isDesktop(context)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WebSidebar(currentRoute: '/collector'),
                    Expanded(child: _buildCurrentPage()),
                  ],
                )
              : _buildCurrentPage(),
        ),
        bottomNavigationBar: Responsive.isDesktop(context)
            ? null
            : Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Theme.of(context).cardTheme.color,
                  selectedItemColor: AppTheme.primary,
                  unselectedItemColor: AppTheme.textSecondary,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_rounded),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history_rounded),
                      label: 'History',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long_rounded),
                      label: 'Expenses',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.pushNamed(context, '/add-donation');
                },
                backgroundColor: AppTheme.primary,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'NEW DONATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildMainDashboard(context);
      case 1:
        return const DonorHistoryScreen(isEmbedded: true);
      case 2:
        return const AddExpenseScreen(isEmbedded: true);
      case 3:
        return const CollectorProfileScreen(isEmbedded: true);
      default:
        return _buildMainDashboard(context);
    }
  }

  Widget _buildMainDashboard(BuildContext context) {
    final donationProvider = Provider.of<DonationProvider>(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Responsive.isDesktop(context)
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildStatsCard(context)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildExpensesCard(context)),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatsCard(context),
                          const SizedBox(height: 20),
                          _buildExpensesCard(context),
                        ],
                      ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'My Recent Collections',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRecentCollections(
                  donationProvider.donations.take(10).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = Provider.of<AuthProvider>(context).currentUser;
    return AppBar(
      leading: !Responsive.isDesktop(context)
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user?.fullName ?? 'Collector',
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
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Logout',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final donationProvider = Provider.of<DonationProvider>(context);
    final fmt = NumberFormat('#,##,###');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COLLECTION',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 10,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_rounded,
                color: AppTheme.primary,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rs.${fmt.format(donationProvider.totalCollection)}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 12,
                color: AppTheme.success,
              ),
              const SizedBox(width: 4),
              const Text(
                '+12.5%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
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
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat(
                'Today',
                'Rs.${fmt.format(donationProvider.todayCollection)}',
                AppTheme.primary,
              ),
              const SizedBox(width: 24),
              _buildMiniStat(
                'Month',
                'Rs.${fmt.format(donationProvider.thisMonthCollection)}',
                AppTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesCard(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final fmt = NumberFormat('#,##,###');

    final now = DateTime.now();
    final todayExpenses = expenseProvider.expenses
        .where(
          (e) =>
              e.expenseDate.year == now.year &&
              e.expenseDate.month == now.month &&
              e.expenseDate.day == now.day &&
              e.status == 'approved',
        )
        .fold(0.0, (acc, e) => acc + e.amount);

    final totalExpenses = expenseProvider.expenses
        .where((e) => e.status == 'approved')
        .fold(0.0, (acc, e) => acc + e.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXPENSES',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 10,
                ),
              ),
              const Icon(
                Icons.trending_down_rounded,
                color: Colors.pink,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rs.${fmt.format(totalExpenses)}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.trending_down_rounded,
                size: 12,
                color: AppTheme.error,
              ),
              const SizedBox(width: 4),
              const Text(
                '+5.2%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.error,
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
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat(
                'Today',
                'Rs.${fmt.format(todayExpenses)}',
                Colors.pink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCollections(List<DonationModel> donations) {
    if (donations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'No Collections Found',
          message: 'Your recent donations will appear here.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: donations.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final d = donations[index];
        final formattedDate = DateFormat('dd MMM, hh:mm a').format(d.date);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.primary,
              size: 18,
            ),
          ),
          title: Text(
            d.donorName,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(
            '$formattedDate · ${d.donationType ?? "Donation"}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Text(
            'Rs.${d.amount.toInt()}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }
}
