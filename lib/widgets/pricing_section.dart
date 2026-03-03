import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PricingSection extends StatelessWidget {
  const PricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAFAFC), // very light gray/purple
            Colors.white,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Choose a Subscription Plan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Transparent pricing for Madaris of all sizes',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 64),
          Wrap(
            spacing: 24,
            runSpacing: 48,
            alignment: WrapAlignment.center,
            children: [
              _PricingCard(
                title: 'BASIC',
                subtitle: 'Free (30 Days Trial)',
                price: 'Free',
                period: '/ 30 Days',
                features: const [
                  '1 Admin',
                  '2 Collectors',
                  '50 Donations per month',
                  'Basic Dashboard',
                  'Donation History',
                  'Read-only after trial expiry',
                  'Email Support',
                ],
                onSelect: () => _showActivationDialog(context, 'Basic'),
                isPremium: false,
                buttonText: 'Start Trial',
              ),
              _PricingCard(
                title: 'PREMIUM',
                subtitle: 'Best balance for standard operational needs',
                price: '₹2,499',
                period: '/ Year',
                originalPrice: '₹4,199',
                discountBadge: '40% OFF',
                badgeColor: Colors.green.shade600,
                ribbonText: 'Most Popular',
                ribbonColor: const Color(0xFF6B4EA1),
                features: const [
                  '1 Admin',
                  'Up to 10 Collectors',
                  '5,000 Donations per year',
                  'Advanced Dashboard',
                  'Monthly & Yearly Reports',
                  'Collector Monitoring',
                  'Export Reports (PDF/Excel)',
                  'Renewal Reminder Alerts',
                  'WhatsApp Support',
                  'No Ads',
                  'Subscription Enforcement',
                  'Basic Analytics',
                ],
                onSelect: () => _showActivationDialog(context, 'Premium'),
                isPremium: true,
                buttonText: 'Get Premium',
              ),
              _PricingCard(
                title: 'ENTERPRISE',
                subtitle: 'Unlimited scale and control for large Madaris',
                price: '₹9,999',
                period: '/ Year',
                originalPrice: '₹19,999',
                discountBadge: '50% OFF',
                badgeColor: Colors.red.shade600,
                ribbonText: 'Best Value',
                ribbonColor: Colors.deepOrange,
                features: const [
                  'Up to 5 Admins',
                  'Unlimited Collectors',
                  'Unlimited Donations',
                  'Advanced Analytics',
                  'Branch-wise Management',
                  'Custom Reports',
                  'Audit Logs Access',
                  'Custom Branding',
                  'Dedicated Support',
                  'Early Feature Access',
                ],
                onSelect: () => _showActivationDialog(context, 'Enterprise'),
                isPremium: false,
                buttonText: 'Contact Sales',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showActivationDialog(BuildContext context, String planName) {
    const Color brandPurple = Color(0xFF6B4EA1);

    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Material(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(32),
              child: SelectionArea(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activate $planName Plan',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'To activate this plan for your organization, please contact us at:',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildContactItem(
                        context: context,
                        icon: Icons.brightness_1,
                        iconColor: Colors.green,
                        label: 'WhatsApp: ',
                        value: '+91-7017164578',
                      ),
                      const SizedBox(height: 12),
                      _buildContactItem(
                        context: context,
                        icon: Icons.phone,
                        iconColor: brandPurple,
                        label: 'Call Us: ',
                        value: '+91-7017164578',
                      ),
                      const SizedBox(height: 12),
                      _buildContactItem(
                        context: context,
                        icon: Icons.email_outlined,
                        iconColor: brandPurple,
                        label: 'Email: ',
                        value: 'asadktp@gmail.com',
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: brandPurple,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PricingCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final String? originalPrice;
  final String? discountBadge;
  final Color? badgeColor;
  final String? ribbonText;
  final Color? ribbonColor;
  final List<String> features;
  final VoidCallback onSelect;
  final bool isPremium;
  final String buttonText;

  const _PricingCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    this.originalPrice,
    this.discountBadge,
    this.badgeColor,
    this.ribbonText,
    this.ribbonColor,
    required this.features,
    required this.onSelect,
    required this.isPremium,
    required this.buttonText,
  });

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const Color brandPurple = Color(0xFF6B4EA1);
    final isHighlighted = widget.isPremium;
    final themeColor = isHighlighted
        ? brandPurple
        : Theme.of(context).colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 320,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(isHighlighted ? 1.05 : 1.0, isHighlighted ? 1.05 : 1.0)
          ..translate(0.0, _isHovered ? -12.0 : 0.0, 0.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isHighlighted
                      ? brandPurple.withValues(alpha: _isHovered ? 1.0 : 0.5)
                      : (_isHovered
                            ? brandPurple.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2)),
                  width: isHighlighted ? 2 : 1,
                ),
                boxShadow: [
                  if (isHighlighted || _isHovered)
                    BoxShadow(
                      color: brandPurple.withValues(
                        alpha: isHighlighted
                            ? (_isHovered ? 0.2 : 0.1)
                            : (_isHovered ? 0.1 : 0.0),
                      ),
                      blurRadius: isHighlighted ? 40 : 30,
                      spreadRadius: isHighlighted ? 4 : 0,
                      offset: Offset(0, _isHovered ? 15 : 10),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.originalPrice != null) ...[
                    Row(
                      children: [
                        Text(
                          widget.originalPrice!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        if (widget.discountBadge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget.badgeColor?.withValues(alpha: 0.1) ??
                                  Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.discountBadge!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: widget.badgeColor ?? Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ] else
                    const SizedBox(height: 28), // Placeholder for alignment
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.price,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        widget.period,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 24),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: widget.features.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: isHighlighted
                                  ? brandPurple
                                  : (widget.title == 'ENTERPRISE'
                                        ? brandPurple
                                        : Colors.grey.shade400),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.features[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: isHighlighted && index < 3
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isHighlighted
                                      ? Theme.of(context).colorScheme.onSurface
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: widget.isPremium
                        ? ElevatedButton(
                            onPressed: widget.onSelect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandPurple,
                              foregroundColor: Colors.white,
                              elevation: _isHovered ? 8 : 0,
                              shadowColor: brandPurple.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              widget.buttonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: widget.onSelect,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isHovered
                                  ? brandPurple
                                  : themeColor,
                              backgroundColor: _isHovered
                                  ? brandPurple.withValues(alpha: 0.05)
                                  : null,
                              side: BorderSide(
                                color: _isHovered
                                    ? brandPurple
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              widget.buttonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            if (widget.ribbonText != null)
              Positioned(
                top: -16,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.ribbonColor ?? brandPurple,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.ribbonColor ?? brandPurple).withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.ribbonText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
