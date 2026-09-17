import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/auth_service.dart';
import 'auth/auth_gate_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _bottomFade;

  bool _showSwipeToStart = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();

    // Check if user has already completed "Swipe to get started"
    final settingsBox = Hive.box('settings');
    final hasStarted = settingsBox.get('has_started_app', defaultValue: false) as bool;
    _showSwipeToStart = !hasStarted;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // If not first time, auto-navigate after standard splash duration
    if (!_showSwipeToStart) {
      _startAutoNavigation();
    }
  }

  void _configureSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _startAutoNavigation() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted || _isNavigating) return;
    _proceed();
  }

  Future<void> _onSwipeCompleted() async {
    if (_isNavigating) return;
    _isNavigating = true;

    // Mark as started in Hive persistent settings
    final settingsBox = Hive.box('settings');
    await settingsBox.put('has_started_app', true);

    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _proceed();
  }

  void _proceed() {
    if (!mounted) return;
    final isLoggedIn = AuthService().isLoggedIn;
    if (isLoggedIn) {
      _navigateToMain();
    } else {
      _navigateToAuthGate();
    }
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToAuthGate() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthGateScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          child: Column(
            children: [
              // Logo in the center
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoFade,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Image.asset(
                            'assets/images/softsky_logo.png',
                            width: size.width * 0.58,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bottom Area: only shown on first launch (one-time swipe to get started)
              if (_showSwipeToStart)
                AnimatedBuilder(
                  animation: _bottomFade,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _bottomFade,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Curated Collection & Collective',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.88),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SwipeToGetStarted(
                          onCompleted: _onSwipeCompleted,
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Subtle spacing at bottom for returning users
                const SizedBox(height: 32),
            ],
          ),
        ),
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
      // Spring back to start
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
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: _pillHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF223A57).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(_pillHeight / 2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                      fontWeight: FontWeight.w500,
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
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
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
