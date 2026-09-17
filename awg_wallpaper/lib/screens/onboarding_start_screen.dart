import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main_screen.dart';

class OnboardingStartScreen extends StatefulWidget {
  const OnboardingStartScreen({super.key});

  @override
  State<OnboardingStartScreen> createState() => _OnboardingStartScreenState();
}

class _OnboardingStartScreenState extends State<OnboardingStartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSwipeCompleted() async {
    if (_isNavigating) return;
    _isNavigating = true;

    // Save that user has completed onboarding
    final settingsBox = Hive.box('settings');
    await settingsBox.put('has_started_app', true);

    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B2CC1),
              Color(0xFF3368A0),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient background glow orbs for depth
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4C82FF).withValues(alpha: 0.20),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: -50,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F1B85).withValues(alpha: 0.35),
                ),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // SoftSky Wordmark with subtle entrance scale
                      Transform.scale(
                        scale: _scaleAnim.value,
                        child: Image.asset(
                          'assets/images/softsky_logo.png',
                          width: (size.width * 0.54).clamp(180.0, 230.0),
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Title
                      Text(
                        'You\'re All Set!',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Explore thousands of 4K wallpapers, discover rising creators, and personalize your home screen.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.5,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Modern Frosted Glass Feature Highlights Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildFeatureRow(
                                  icon: Icons.hd_rounded,
                                  title: 'Ultra HD 4K Quality',
                                  subtitle: 'Handcrafted for high-res AMOLED displays',
                                ),
                                Divider(
                                  height: 22,
                                  color: Colors.white.withValues(alpha: 0.10),
                                  thickness: 0.8,
                                ),
                                _buildFeatureRow(
                                  icon: Icons.auto_awesome_rounded,
                                  title: 'Daily Fresh Drops',
                                  subtitle: 'New trending collections updated every day',
                                ),
                                Divider(
                                  height: 22,
                                  color: Colors.white.withValues(alpha: 0.10),
                                  thickness: 0.8,
                                ),
                                _buildFeatureRow(
                                  icon: Icons.groups_rounded,
                                  title: 'Creative Collective',
                                  subtitle: 'Follow top artists & share your own creations',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Centered "Swipe to get started" slider matching bottom bar width (256px)
                      Center(
                        child: SwipeToGetStarted(
                          onCompleted: _onSwipeCompleted,
                        ),
                      ),

                      const SizedBox(height: 38),
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

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 19),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Interactive "Swipe to get started" Pill Widget
/// Sized at 256.0 x 58.0 to match the floating bottom navigation bar
class SwipeToGetStarted extends StatefulWidget {
  final Future<void> Function() onCompleted;

  const SwipeToGetStarted({
    super.key,
    required this.onCompleted,
  });

  @override
  State<SwipeToGetStarted> createState() => _SwipeToGetStartedState();
}

class _SwipeToGetStartedState extends State<SwipeToGetStarted>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  static const double _barWidth = 256.0;
  static const double _pillHeight = 58.0;
  static const double _buttonSize = 46.0;
  static const double _padding = 6.0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isCompleted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_isCompleted) return;

    // If dragged past 55% of the bar, trigger completion
    if (_dragPosition >= maxDrag * 0.55) {
      _completeSwipe(maxDrag);
    } else {
      _resetAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
      )..addListener(() {
          setState(() {
            _dragPosition = _resetAnimation.value;
          });
        });
      _resetController.forward(from: 0.0);
    }
  }

  void _completeSwipe(double maxDrag) {
    _isCompleted = true;
    _resetAnimation = Tween<double>(begin: _dragPosition, end: maxDrag).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragPosition = _resetAnimation.value;
        });
      });
    _resetController.forward(from: 0.0).then((_) {
      widget.onCompleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    const maxDrag = _barWidth - _buttonSize - (_padding * 2);
    final progress = (_dragPosition / maxDrag).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_pillHeight / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: _pillHeight,
          width: _barWidth,
          decoration: BoxDecoration(
            color: const Color(0xFF202024).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(_pillHeight / 2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Centered label text that fades out smoothly as user drags
              Center(
                child: Opacity(
                  opacity: (1.0 - progress * 1.6).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      'Swipe to get started',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE2E8F0),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),

              // Draggable circular thumb
              Positioned(
                left: _padding + _dragPosition,
                top: _padding,
                bottom: _padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) =>
                      _onDragEnd(details, maxDrag),
                  child: Container(
                    width: _buttonSize,
                    height: _buttonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF2B5CE6),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
