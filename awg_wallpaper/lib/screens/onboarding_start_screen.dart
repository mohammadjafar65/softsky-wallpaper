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
              Color(0xFF1B2FBF),
              Color(0xFF2649B0),
              Color(0xFF2E59A8),
              Color(0xFF3266A1),
            ],
            stops: [0.0, 0.45, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // App Logo with glowing shadow
                  Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SoftSky Wordmark
                  Image.asset(
                    'assets/images/softsky_logo.png',
                    width: size.width * 0.52,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'You\'re All Set!',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Explore thousands of 4K wallpapers, discover rising creators, and personalize your home screen.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Features row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChip(Icons.hd_rounded, 'Ultra HD 4K'),
                      const SizedBox(width: 10),
                      _buildChip(Icons.auto_awesome_rounded, 'Daily Updates'),
                      const SizedBox(width: 10),
                      _buildChip(Icons.people_alt_rounded, 'Collective'),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Swipe to get started slider
                  SwipeToGetStarted(onCompleted: _onSwipeCompleted),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive "Swipe to get started" Pill Widget
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

  static const double _pillHeight = 60.0;
  static const double _buttonSize = 48.0;
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

    // If dragged past 65% of the bar, trigger completion
    if (_dragPosition >= maxDrag * 0.65) {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _buttonSize - (_padding * 2);
        final progress =
            maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: _pillHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF223A57).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(_pillHeight / 2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered label text that fades out as user drags
              Opacity(
                opacity: (1.0 - progress * 1.5).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    'Swipe to get started',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE2E8F0),
                      letterSpacing: 0.2,
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
                        color: Color(0xFF274AB0),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
