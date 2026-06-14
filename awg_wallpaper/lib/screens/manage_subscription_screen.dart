import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';

class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final isPro = provider.isPro;
    final plan = provider.currentPlan;
    final expiresDate = provider.expiryDate;

    String dateStr = 'Never';
    if (expiresDate != null) {
      dateStr = '${expiresDate.day}/${expiresDate.month}/${expiresDate.year}';
    }

    final isLifetime = plan == SubscriptionPlan.lifetime;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.getSurface(isDark).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.getTextPrimary(isDark),
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          'Subscription',
          style: TextStyle(
            color: AppTheme.getTextPrimary(isDark),
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Gold Pro Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.gold, Color(0xFFFFB700)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      size: 48, color: Colors.black),
                  const SizedBox(height: 14),
                  Text(
                    isPro ? 'PRO PLAN ACTIVE' : 'FREE PLAN',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isPro && !isLifetime)
                    Text(
                      'Renews on $dateStr',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (isLifetime)
                    const Text(
                      'Lifetime Access',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (!isPro)
                    const Text(
                      'Upgrade to unlock all features',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Info tiles container
            Container(
              decoration: BoxDecoration(
                color: AppTheme.getSurface(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    context,
                    isDark,
                    'Plan',
                    provider.getPlanName(plan),
                    isFirst: true,
                  ),
                  _buildDivider(isDark),
                  _buildInfoTile(
                    context,
                    isDark,
                    'Status',
                    isPro ? 'Active' : 'Inactive',
                    valueColor: isPro ? AppTheme.success : AppTheme.error,
                  ),
                  if (isPro && !isLifetime) ...[
                    _buildDivider(isDark),
                    _buildInfoTile(
                      context,
                      isDark,
                      'Next Billing Date',
                      dateStr,
                    ),
                  ],
                  if (isPro) ...[
                    _buildDivider(isDark),
                    _buildInfoTile(
                      context,
                      isDark,
                      'Payment Method',
                      'Google Play',
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ),

            const Spacer(),

            if (isPro)
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Please manage subscription in Google Play Store'),
                      backgroundColor: AppTheme.getSurface(isDark),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: AppTheme.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text(
                  'Cancel Subscription',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.getSurfaceVariant(isDark).withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    bool isDark,
    String label,
    String value, {
    Color? valueColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: isFirst ? 16 : 14,
        bottom: isLast ? 16 : 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.getTextMuted(isDark),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.getTextPrimary(isDark),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

