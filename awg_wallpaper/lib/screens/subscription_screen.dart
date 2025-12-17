import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/subscription_provider.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.annual;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Clear any previous errors when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // Top Gradient Orb
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.1),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppTheme.surfaceVariant),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _restorePurchases(provider),
                            child: Text(
                              'Restore',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Header
                      _buildHeader(),

                      const SizedBox(height: 40),

                      // Features
                      _buildFeaturesList(),

                      const SizedBox(height: 40),

                      // Plans
                      _buildPlanCards(),

                      const SizedBox(height: 30),

                      // Button
                      _buildSubscribeButton(provider),

                      const SizedBox(height: 20),

                      _buildTerms(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              if (_isProcessing)
                Container(
                  color: Colors.white.withOpacity(0.8),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppTheme.gold,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Upgrade to Pro',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock all wallpapers & remove ads',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Access all premium wallpapers',
      'Ad-free experience',
      // '4K ultra HD downloads',
      'Priority support',
    ];

    return Column(
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.success, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      feature,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildPlanCards() {
    return Column(
      children: [
        _buildPlanCard(SubscriptionPlan.monthly, false),
        const SizedBox(height: 12),
        _buildPlanCard(SubscriptionPlan.annual, true),
        const SizedBox(height: 12),
        _buildPlanCard(SubscriptionPlan.lifetime, false),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, bool isBestValue) {
    final isSelected = _selectedPlan == plan;
    final details = SubscriptionProvider.planDetails[plan]!;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Theme.of(context).dividerColor.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : Theme.of(context).disabledColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (isBestValue) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Best Buy',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  details['price'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  details['period'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton(SubscriptionProvider provider) {
    return GestureDetector(
      onTap: _isProcessing ? null : () => _subscribe(provider),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).textTheme.bodyLarge?.color, // Adapt to theme
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Start Subscription',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).scaffoldBackgroundColor, // Inverse color
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return Text(
      'Recurring billing. Cancel anytime.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
    );
  }

  Future<void> _subscribe(SubscriptionProvider provider) async {
    setState(() => _isProcessing = true);

    // Check if user is logged in
    final authService = AuthService();
    if (!authService.isLoggedIn) {
      setState(() => _isProcessing = false);
      _showLoginDialog();
      return;
    }

    try {
      final success = await provider.subscribe(_selectedPlan);
      setState(() => _isProcessing = false);

      if (success && mounted) {
        // Purchase initiated successfully - wait for purchase stream updates
        // The actual success/failure will be handled by the provider
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        _showError('Subscription failed: ${e.toString()}');
      }
    }

    // Check for any errors from the provider
    if (mounted && provider.errorMessage != null) {
      _showError(provider.errorMessage!);
      provider.clearError();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _restorePurchases(SubscriptionProvider provider) async {
    setState(() => _isProcessing = true);
    await provider.restorePurchases();
    setState(() => _isProcessing = false);
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
            'You need to be logged in to upgrade to Pro. This ensures your subscription is linked to your account and can be restored on any device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Login / Signup'),
          ),
        ],
      ),
    );
  }
}
