import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/subscription_provider.dart';

class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine status from provider
    final provider = context.watch<SubscriptionProvider>();
    final isPro = provider.isPro;
    final expiresDate = DateTime.now().add(const Duration(days: 30)); // Mock date

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Subscription', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.gold, Color(0xFFFFB700)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.black),
                  const SizedBox(height: 16),
                  const Text(
                    'PRO PLAN ACTIVE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Renews on ${expiresDate.day}/${expiresDate.month}/${expiresDate.year}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoTile('Plan', 'Yearly Pro'),
            _buildInfoTile('Status', 'Active'),
            _buildInfoTile('Next Billing Date', '${expiresDate.day}/${expiresDate.month}/${expiresDate.year}'),
            _buildInfoTile('Payment Method', 'Google Play'),
            
            const Spacer(),
            
            OutlinedButton(
              onPressed: () {
                // Mock cancel
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please manage subscription in Google Play Store')),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Cancel Subscription',
                style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    );
  }
}
