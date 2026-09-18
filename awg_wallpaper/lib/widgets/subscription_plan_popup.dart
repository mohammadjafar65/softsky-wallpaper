import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/subscription_provider.dart';
import '../screens/auth/login_screen.dart';
import '../services/auth_service.dart';

class SubscriptionPlanPopup extends StatefulWidget {
  final VoidCallback? onSubscribed;

  const SubscriptionPlanPopup({
    super.key,
    this.onSubscribed,
  });

  /// Static helper to display the popup bottom sheet cleanly anywhere in the app
  static Future<void> show(BuildContext context, {VoidCallback? onSubscribed}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => SubscriptionPlanPopup(onSubscribed: onSubscribed),
    );
  }

  @override
  State<SubscriptionPlanPopup> createState() => _SubscriptionPlanPopupState();
}

class _SubscriptionPlanPopupState extends State<SubscriptionPlanPopup> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.annual;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final cardBg = isDark ? const Color(0xFF18181D) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF6B7280);

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding + bottomInset),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row with Icon and Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Glowing Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2B5CE6), Color(0xFF1E45C8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2B5CE6).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Unlock Softsky Pro',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Enjoy 4K master quality, no ads & VIP packs',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 50% Off Limited Time Deal Badge Bar
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E284E),
                            const Color(0xFF1A1A28),
                          ]
                        : [
                            const Color(0xFFEEF2FF),
                            const Color(0xFFF3F4F6),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2B5CE6).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFB8500), Color(0xFFFFB703)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              color: Colors.black, size: 14),
                          SizedBox(width: 3),
                          Text(
                            '50% OFF DEAL',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Annual plan discounted to ₹40.0 only (Reg. ₹79.9)',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Interactive Plan Selection Cards
              _buildPlanOption(
                plan: SubscriptionPlan.annual,
                title: 'Annual Plan',
                subtitle: '50% OFF included • Billed yearly',
                originalPrice: '₹79.9',
                discountPrice: '₹40.0',
                period: '/year',
                badgeText: '50% OFF • LIMITED TIME',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildPlanOption(
                plan: SubscriptionPlan.monthly,
                title: 'Monthly Plan',
                subtitle: 'Flexible • Cancel anytime',
                originalPrice: null,
                discountPrice: '₹29.99',
                period: '/month',
                badgeText: null,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildPlanOption(
                plan: SubscriptionPlan.lifetime,
                title: 'Lifetime Plan',
                subtitle: 'One-time payment • Never expires',
                originalPrice: null,
                discountPrice: '₹299.99',
                period: 'one-time',
                badgeText: 'FOREVER',
                isDark: isDark,
              ),
              const SizedBox(height: 18),

              // Feature Highlights Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(Icons.hd_rounded,
                        'Unlock all 4K & Ultra-HD Wallpapers', isDark),
                    const SizedBox(height: 8),
                    _buildFeatureItem(Icons.block_rounded,
                        '100% Ad-Free uninterrupted experience', isDark),
                    const SizedBox(height: 8),
                    _buildFeatureItem(Icons.auto_mode_rounded,
                        'Auto Wallpaper Changer & Day/Night mode', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Primary CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.flash_on_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedPlan == SubscriptionPlan.annual
                                      ? 'Claim 50% OFF - Get Pro (₹40.0)'
                                      : _selectedPlan == SubscriptionPlan.monthly
                                          ? 'Start Monthly - ₹29.99'
                                          : 'Get Lifetime Access - ₹299.99',
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedPlan == SubscriptionPlan.annual) ...[
                              const SizedBox(height: 2),
                              Text(
                                '⚡ 50% discount automatically applied (Regular ₹79.9)',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Secondary action
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                  ),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanOption({
    required SubscriptionPlan plan,
    required String title,
    required String subtitle,
    required String? originalPrice,
    required String discountPrice,
    required String period,
    required String? badgeText,
    required bool isDark,
  }) {
    final isSelected = _selectedPlan == plan;
    final isAnnual = plan == SubscriptionPlan.annual;

    final borderColor = isSelected
        ? AppTheme.primary
        : (isAnnual
            ? AppTheme.primary.withValues(alpha: 0.35)
            : (isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08)));

    final bgColor = isSelected
        ? AppTheme.primary.withValues(alpha: isDark ? 0.12 : 0.06)
        : (isDark
            ? const Color(0xFF202026)
            : const Color(0xFFF9FAFB));

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
                width: isSelected || isAnnual ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Radio indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.25)),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Plan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isAnnual
                              ? const Color(0xFFFB8500)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : const Color(0xFF6B7280)),
                          fontSize: 11.5,
                          fontWeight:
                              isAnnual ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (originalPrice != null) ...[
                      Text(
                        originalPrice,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.45),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.45),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          discountPrice,
                          style: TextStyle(
                            color: isAnnual
                                ? AppTheme.primary
                                : (isDark ? Colors.white : const Color(0xFF111827)),
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          period,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : const Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Badge on top right
          if (badgeText != null)
            Positioned(
              top: -9,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAnnual
                        ? const [Color(0xFFFB8500), Color(0xFFFFB703)]
                        : const [Color(0xFF2B5CE6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isAnnual
                              ? const Color(0xFFFB8500)
                              : const Color(0xFF2B5CE6))
                          .withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: isAnnual ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: AppTheme.primary, size: 13),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.88)
                  : const Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubscribe() async {
    final provider = context.read<SubscriptionProvider>();
    final authService = AuthService();

    if (!authService.isLoggedIn) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final success = await provider.subscribe(_selectedPlan);
      if (mounted) setState(() => _isProcessing = false);

      if (success && mounted) {
        Navigator.pop(context);
        widget.onSubscribed?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
