import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/web_sidebar.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  String _statusFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return Container(color: AppTheme.background, child: _buildMainContent());
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: Responsive.isDesktop(context)
          ? null
          : WebSidebar(currentRoute: '/admin-expenses'),
      appBar: AppBar(
        automaticallyImplyLeading: !Responsive.isDesktop(context),
        title: const Text('Collector Expenses'),
        actions: [
          _buildAction(
            context: context,
            label: 'Add Expense',
            icon: Icons.add_circle_outline,
            onPressed: () => Navigator.pushNamed(context, '/add-expense'),
            tooltip: 'Add New Expense',
          ),
          _buildAction(
            context: context,
            label: 'Donor History',
            icon: Icons.manage_search,
            onPressed: () => Navigator.pushNamed(context, '/donor-history'),
            tooltip: 'Donor History',
          ),
          _buildAction(
            context: context,
            label: 'Logout',
            icon: Icons.logout,
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (r) => false,
              );
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Responsive(
          mobile: _buildMainContent(),
          desktop: Row(
            children: [
              WebSidebar(currentRoute: '/admin-expenses'),
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(child: _buildExpenseList()),
      ],
    );
  }

  Widget _buildAction({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    if (Responsive.isDesktop(context)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          style:
              TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.hovered)) {
                    return Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08);
                  }
                  if (states.contains(WidgetState.pressed)) {
                    return Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12);
                  }
                  return null;
                }),
              ),
        ),
      );
    } else {
      return IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        color: Theme.of(context).colorScheme.primary,
      );
    }
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by collector name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).scaffoldBackgroundColor
                  : AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'pending', 'approved', 'rejected']
                  .map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(
                          status == 'All' ? 'All' : status.toUpperCase(),
                          style: TextStyle(
                            color: _statusFilter == status
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        selected: _statusFilter == status,
                        selectedColor: AppTheme.primary,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).scaffoldBackgroundColor
                            : AppTheme.background,
                        onSelected: (selected) {
                          setState(() {
                            _statusFilter = status;
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.expenses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        var filteredExpenses = provider.expenses.where((e) {
          final matchesStatus =
              _statusFilter == 'All' || e.status == _statusFilter.toLowerCase();
          final matchesSearch =
              e.collectorName != null &&
              e.collectorName!.toLowerCase().contains(_searchQuery);
          return matchesStatus && (_searchQuery.isEmpty || matchesSearch);
        }).toList();

        if (filteredExpenses.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No expenses found.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredExpenses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final expense = filteredExpenses[index];
            return _ExpenseAdminCard(expense: expense);
          },
        );
      },
    );
  }
}

class _ExpenseAdminCard extends StatelessWidget {
  final ExpenseModel expense;

  const _ExpenseAdminCard({required this.expense});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _updateStatus(BuildContext context, String newStatus) async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    try {
      await provider.updateExpenseStatus(expense.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Expense marked as $newStatus')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(expense.status);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.collectorName ?? 'Unknown Collector',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${expense.category}',
                        style: TextStyle(
                          // Removed const from TextStyle
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rs. ${NumberFormat('#,##,###').format(expense.amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(expense.expenseDate),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    expense.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (expense.description != null &&
                expense.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).scaffoldBackgroundColor
                      : AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  expense.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
            if (expense.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(context, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
