import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/web_sidebar.dart';
import '../utils/responsive.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final organizationId = authProvider.currentUser?.organizationId ?? '';

        final content = Responsive(
          mobile: _buildMainContent(context, organizationId),
          desktop: Row(
            children: [
              WebSidebar(currentRoute: '/user-management'),
              Expanded(child: _buildMainContent(context, organizationId)),
            ],
          ),
        );

        if (isEmbedded) {
          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Expanded(child: _buildMainContent(context, organizationId)),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: WebSidebar(currentRoute: '/user-management'),
          appBar: Responsive.isDesktop(context)
              ? null
              : AppBar(title: const Text('Manage Collectors')),
          body: content,
          floatingActionButton: Responsive.isDesktop(context)
              ? null
              : organizationId.isEmpty
              ? null
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('organizations')
                      .doc(organizationId)
                      .snapshots(),
                  builder: (context, orgSnapshot) {
                    final isReadOnly = authProvider.isReadOnly;
                    final orgData =
                        orgSnapshot.data?.data() as Map<String, dynamic>?;
                    final status = orgData?['status'] ?? 'active';

                    final isOrgActive = !isReadOnly && status == 'active';

                    return FloatingActionButton.extended(
                      onPressed: isOrgActive
                          ? () => Navigator.pushNamed(context, '/add-collector')
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cannot add collectors. Subscription is expired or organization is suspended.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                      backgroundColor: isOrgActive
                          ? AppTheme.primary
                          : Colors.grey,
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text(
                        'Add Collector',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, String organizationId) {
    if (organizationId.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verifying organization...'),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'collector')
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // If it's a permission error, maybe wait or show a more friendly message
          final errorStr = snapshot.error.toString();
          if (errorStr.contains('permission-denied')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_person_outlined,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You do not have permission to view collectors for this organization, or your session has expired.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('Re-login'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading collectors:\n$errorStr',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_off,
                  size: 80,
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No collectors yet.\nTap + to add one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
                if (Responsive.isDesktop(context)) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/add-collector'),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add First Collector'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        final collectors = docs
            .map(
              (d) => UserModel.fromJson(d.data() as Map<String, dynamic>, d.id),
            )
            .toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Responsive.isDesktop(context))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Collectors',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add, block, or remove donation collectors.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/add-collector'),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Collector'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: Responsive.isDesktop(context) ? 0 : 20,
                    ),
                    itemCount: collectors.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) =>
                        _CollectorCard(collector: collectors[index]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CollectorCard extends StatelessWidget {
  final UserModel collector;

  const _CollectorCard({required this.collector});

  Future<void> _toggleBlock(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (collector.status == 'blocked') {
        await authProvider.unblockCollector(collector.id);
      } else {
        await authProvider.blockCollector(collector.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              collector.status == 'blocked'
                  ? '"${collector.fullName}" unblocked.'
                  : '"${collector.fullName}" blocked.',
            ),
            backgroundColor: collector.status == 'blocked'
                ? AppTheme.success
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = collector.status == 'blocked';
    final createdDate = DateFormat('dd MMM yyyy').format(collector.createdAt);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — avatar + name + status badge
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isBlocked
                      ? Colors.red.shade100
                      : AppTheme.primaryLight.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    color: isBlocked ? Colors.red : AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collector.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (collector.designation != null &&
                          collector.designation!.isNotEmpty)
                        Text(
                          collector.designation!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isBlocked
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isBlocked
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Text(
                    isBlocked ? 'Blocked' : 'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isBlocked
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details row
            Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  collector.mobile,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Joined $createdDate',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),

            // Action buttons row - More prominent
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isBlocked
                    ? Colors.green.withValues(alpha: 0.05)
                    : Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBlocked
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                ),
              ),
              child: InkWell(
                onTap: () => _toggleBlock(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isBlocked
                            ? Icons.lock_open_rounded
                            : Icons.block_rounded,
                        size: 20,
                        color: isBlocked
                            ? Colors.green.shade700
                            : Colors.orange.shade900,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isBlocked
                            ? 'UNBLOCK THIS COLLECTOR'
                            : 'BLOCK THIS COLLECTOR',
                        style: TextStyle(
                          color: isBlocked
                              ? Colors.green.shade700
                              : Colors.orange.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
