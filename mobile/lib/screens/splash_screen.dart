import 'dart:async';
import 'dart:math' as math;
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

  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;

  late AnimationController _textController;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  late AnimationController _barController;
  late Animation<double> _barProgress;

  late AnimationController _arcController;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _barProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOut),
    );

    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _runSequence();
    _navigateToNext();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _iconController.forward();
    _barController.forward();
    await Future.delayed(const Duration(milliseconds: 550));
    _textController.forward();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2800));
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
    _barController.dispose();
    _arcController.dispose();
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF0F2A4A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle background rings
            Positioned(
              top: -size.width * 0.35,
              right: -size.width * 0.25,
              child: _Ring(size: size.width * 0.85, opacity: 0.05),
            ),
            Positioned(
              bottom: -size.width * 0.45,
              left: -size.width * 0.3,
              child: _Ring(size: size.width * 1.0, opacity: 0.04),
            ),

            // Main content
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon + arc
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _iconController,
                            _arcController,
                          ]),
                          builder: (context, _) {
                            return SizedBox(
                              width: 136,
                              height: 136,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: _iconFade.value * 0.45,
                                    child: Transform.rotate(
                                      angle: _arcController.value * 2 * math.pi,
                                      child: CustomPaint(
                                        size: const Size(132, 132),
                                        painter: _ArcPainter(),
                                      ),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: _iconFade.value,
                                    child: Transform.scale(
                                      scale: _iconScale.value,
                                      child: Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.16),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome_outlined,
                                          size: 44,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 36),

                        // Title + subtitle
                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textFade,
                            child: Column(
                              children: [
                                const Text(
                                  'RFP Agent',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Procurement, automated.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w300,
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

                // Bottom bar
                Padding(
                  padding: EdgeInsets.only(
                    left: 48,
                    right: 48,
                    bottom: MediaQuery.of(context).padding.bottom + 48,
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _barProgress,
                        builder: (context, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Container(
                              height: 2,
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.1),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _barProgress.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PPRA-COMPLIANT  •  GOVERNMENT OF PAKISTAN',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.2),
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final double opacity;
  const _Ring({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const segmentAngle = 0.4;
    const gapCount = 4;
    const stepAngle = 2 * math.pi / gapCount;

    for (int i = 0; i < gapCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * stepAngle,
        segmentAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}