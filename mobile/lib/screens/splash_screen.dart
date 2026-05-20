import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Icon animations
  late AnimationController _iconController;
  late Animation<double> _iconFade;
  late Animation<double> _iconScale;

  // Text animations
  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  // Pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  // Floating animation
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Icon entrance
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _iconFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeOut,
      ),
    );

    _iconScale = Tween<double>(
      begin: 0.72,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeOutBack,
      ),
    );

    // Text entrance
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _textFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Pulse ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _pulseScale = Tween<double>(
      begin: 1,
      end: 1.75,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );

    _pulseOpacity = Tween<double>(
      begin: 0.22,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );

    // Gentle floating
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    _runSequence();
    _navigateToNext();
  }

  Future<void> _runSequence() async {
    await _iconController.forward();

    _pulseController.repeat();

    await Future.delayed(const Duration(milliseconds: 120));

    _textController.forward();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2600));

    if (!mounted) return;

    final org = ref.read(authProvider);

    if (org != null) {
      context.go('/rfp/new');
    } else {
      context.go('/signup');
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF172554),
                  Color(0xFF1E3A8A),
                ],
              ),
            ),
          ),

          // Ambient glow
          Positioned(
            top: -80,
            left: -40,
            child: _buildGlow(
              size: 220,
              color: Colors.blue.withOpacity(0.16),
            ),
          ),

          Positioned(
            bottom: -120,
            right: -40,
            child: _buildGlow(
              size: 260,
              color: Colors.indigo.withOpacity(0.14),
            ),
          ),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon stack
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _iconController,
                      _pulseController,
                    ]),
                    builder: (context, child) {
                      return SizedBox(
                        width: 150,
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse ring
                            Opacity(
                              opacity: _pulseOpacity.value,
                              child: Transform.scale(
                                scale: _pulseScale.value,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.7),
                                      width: 1.8,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Glass card
                            Opacity(
                              opacity: _iconFade.value,
                              child: Transform.scale(
                                scale: _iconScale.value,
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(30),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 12,
                                      sigmaY: 12,
                                    ),
                                    child: Container(
                                      width: 108,
                                      height: 108,
                                      padding:
                                          const EdgeInsets.all(22),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.white
                                              .withOpacity(0.14),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.18),
                                            blurRadius: 30,
                                            offset:
                                                const Offset(0, 14),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 56,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 34),

                  // Text
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          const Text(
                            'RFP Agent',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.8,
                              height: 1,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Procurement, automated.',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Colors.white.withOpacity(0.72),
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const SizedBox(height: 36),

                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildGlow({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 80,
          sigmaY: 80,
        ),
        child: const SizedBox(),
      ),
    );
  }
}