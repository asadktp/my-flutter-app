import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/donation_model.dart';
import '../providers/donation_provider.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/double_back_to_close.dart';
import 'donation_detail_screen.dart';

class DonorHistoryScreen extends StatefulWidget {
  const DonorHistoryScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<DonorHistoryScreen> createState() => _DonorHistoryScreenState();
}

class _DonorHistoryScreenState extends State<DonorHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Column(
      children: [
        // Modern Search & Filter Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by donor name or mobile...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.primary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child: Consumer<DonationProvider>(
            builder: (context, provider, child) {
              final allDonations = provider.donations;
              List<DonationModel> displayedDonations = allDonations;

              if (_searchQuery.isNotEmpty) {
                final lowerQuery = _searchQuery.toLowerCase();
                displayedDonations = allDonations.where((d) {
                  return d.donorMobile.contains(lowerQuery) ||
                      d.donorName.toLowerCase().contains(lowerQuery);
                }).toList();
              }

              if (allDonations.isEmpty) {
                return _buildEmptyState(
                  'No donations recorded yet.',
                  Icons.history_rounded,
                );
              }

              if (displayedDonations.isEmpty) {
                return _buildEmptyState(
                  'No records match your search.',
                  Icons.search_off_rounded,
                );
              }

              return _buildResultsList(displayedDonations);
            },
          ),
        ),
      ],
    );

    if (widget.isEmbedded) return content;

    return DoubleBackToClose(
      child: Scaffold(
        body: Responsive(
          mobile: Column(
            children: [
              _buildHeader(),
              Expanded(child: content),
            ],
          ),
          desktop: Row(
            children: [
              const WebSidebar(currentRoute: '/donor-history'),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: content),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      color: isDark ? AppTheme.dSurface : AppTheme.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (!Responsive.isDesktop(context))
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (!Responsive.isDesktop(context)) const SizedBox(width: 8),
              const Text(
                'Donation History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filters coming soon')),
                  );
                },
                icon: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<DonationModel> results) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (context, index) =>
          const Divider(indent: 72, height: 1),
      itemBuilder: (context, index) {
        final donation = results[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(donation.date);

        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DonationDetailScreen(donation: donation),
              ),
            );
          },
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          title: Text(donation.donorName),
          subtitle: Text(
            '$formattedDate • ${donation.donationType ?? 'Donation'}',
          ),
          trailing: Text(
            '₹${NumberFormat('#,##,###').format(donation.amount)}',
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
