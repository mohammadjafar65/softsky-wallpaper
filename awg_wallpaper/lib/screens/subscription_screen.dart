import 'dart:async';
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
  Timer? _countdownTimer;
  Duration _timeLeft = const Duration(hours: 11, minutes: 47, seconds: 35);

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Clear any previous errors when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().clearError();
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft.inSeconds > 0) {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        } else {
          _timeLeft = const Duration(hours: 23, minutes: 59, seconds: 59);
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
                    color: AppTheme.primary.withValues(alpha: 0.1),
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

                      const SizedBox(height: 24),

                      // Limited Time 50% Off Offer Banner
                      _buildLimitedTimeOfferBanner(),

                      const SizedBox(height: 28),

                      // Features
                      _buildFeaturesList(),

                      const SizedBox(height: 32),

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
                  color: Colors.white.withValues(alpha: 0.8),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.diamond_outlined,
              color: AppTheme.primary,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Unlock Premium',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineLarge?.color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Get unlimited access to all wallpapers,\nremove ads, and unlock 4K collections.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Unlock all Premium Collections',
      'Remove all ads',
      'Auto Wallpaper Changer',
      'Smart Day/Night Mode',
      'Batch Download Support',
      'High-speed downloads',
      'Priority 24/7 support',
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: features
            .map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: AppTheme.success, size: 16),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildLimitedTimeOfferBanner() {
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B2CC1),
            Color(0xFF2B5CE6),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF93C5FD).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B5CE6).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFFB703), size: 16),
                    SizedBox(width: 5),
                    Text(
                      'LIMITED TIME DEAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),

              // 50% OFF Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFB8500).withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  '50% OFF',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Special 50% Discount Offer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unlock all 4K wallpapers, exclusive packs & ad-free experience at half the price before this deal expires.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Countdown Clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFFFFB703), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Offer ends in: ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildTimeUnit(hours, 'h'),
                const Text(' : ',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                _buildTimeUnit(minutes, 'm'),
                const Text(' : ',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                _buildTimeUnit(seconds, 's'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$value$unit',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  String _getOriginalPrice(SubscriptionPlan plan, String currentPrice) {
    if (plan != SubscriptionPlan.annual) return '';
    final match =
        RegExp(r'([\D\s]*)([\d,]+(?:\.\d+)?)').firstMatch(currentPrice);
    if (match != null) {
      final prefix = match.group(1) ?? '₹';
      final numStr = match.group(2)?.replaceAll(',', '') ?? '';
      final val = double.tryParse(numStr);
      if (val != null) {
        final origVal = val * 2;
        final formatted = origVal == origVal.roundToDouble()
            ? origVal.toStringAsFixed(0)
            : origVal.toStringAsFixed(2);
        return '$prefix$formatted';
      }
    }
    return '₹159.99';
  }

  Widget _buildPlanCards() {
    return Column(
      children: [
        _buildPlanCard(SubscriptionPlan.monthly, false),
        const SizedBox(height: 16),
        _buildPlanCard(SubscriptionPlan.annual, true),
        const SizedBox(height: 16),
        _buildPlanCard(SubscriptionPlan.lifetime, false),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, bool isAnnual) {
    final isSelected = _selectedPlan == plan;
    final details = SubscriptionProvider.planDetails[plan]!;

    // Annual plan gets special styling
    final Color borderColor = isSelected
        ? AppTheme.primary
        : (isAnnual
            ? AppTheme.primary.withValues(alpha: 0.3)
            : Theme.of(context).dividerColor.withValues(alpha: 0.1));

    final Color backgroundColor = isSelected
        ? AppTheme.primary.withValues(alpha: 0.05)
        : Theme.of(context).cardColor;

    final price = Provider.of<SubscriptionProvider>(context, listen: false)
        .getPriceForPlan(plan);

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
                width: isSelected || isAnnual ? 2 : 1,
              ),
              boxShadow: isSelected || isAnnual
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Radio Indicator
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
                          fontSize: 18,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAnnual
                            ? 'Special 50% discount included'
                            : 'Unlock all features',
                        style: TextStyle(
                          fontSize: 13,
                          color: isAnnual
                              ? const Color(0xFFFB8500)
                              : Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                          fontWeight:
                              isAnnual ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isAnnual) ...[
                      Text(
                        _getOriginalPrice(plan, price),
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.65),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 1),
                    ],
                    Text(
                      price,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isAnnual
                            ? AppTheme.primary
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      details['period'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Savings Badge for Annual Plan
          if (isAnnual)
            Positioned(
              top: -12,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFB8500), Color(0xFFFFB703)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFB8500).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: Colors.black, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '50% OFF • LIMITED TIME',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(SubscriptionProvider provider) {
    return GestureDetector(
      onTap: _isProcessing ? null : () => _subscribe(provider),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2B5CE6),
              Color(0xFF1E45C8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2B5CE6).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_on_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  _selectedPlan == SubscriptionPlan.annual
                      ? 'Claim 50% OFF - Get Pro'
                      : 'Start Subscription',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_selectedPlan == SubscriptionPlan.annual) ...[
              const SizedBox(height: 3),
              Text(
                '⚡ Limited time 50% discount automatically applied',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
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

