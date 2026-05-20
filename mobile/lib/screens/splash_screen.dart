import 'dart:async';
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

  // Fade + scale for the icon container
  late AnimationController _iconController;
  late Animation<double> _iconFade;
  late Animation<double> _iconScale;

  // Slide + fade for the text block
  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  // Continuous pulse ring behind the icon
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    // -- Icon: scale up from 0.7 + fade in over 700ms --
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );

    // -- Text: slide up from 20px below + fade in, starts 400ms after icon --
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // -- Pulse ring: repeats forever, starts after icon appears --
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _runSequence();
    _navigateToNext();
  }

  Future<void> _runSequence() async {
    // Icon appears first
    await _iconController.forward();
    // Pulse starts as icon settles
    _pulseController.repeat();
    // Text slides in shortly after
    await Future.delayed(const Duration(milliseconds: 100));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Rich Deep Blue
              Color(0xFF0F2A4A), // Navy Blue
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // -- Icon with pulse ring --
              AnimatedBuilder(
                animation: Listenable.merge([
                  _iconController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  return SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [

                        // Pulse ring — expands outward and fades
                        Opacity(
                          opacity: _pulseOpacity.value,
                          child: Transform.scale(
                            scale: _pulseScale.value,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Icon container — scales in
                        Opacity(
                          opacity: _iconFade.value,
                          child: Transform.scale(
                            scale: _iconScale.value,
                            child: Container(
                              width: 100,
                              height: 100,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_outlined,
                                size: 52,
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

              const SizedBox(height: 32),

              // -- Text block — slides up and fades in --
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      const Text(
                        'RFP Agent',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Procurement, automated.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.5,
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
    );
  }
}