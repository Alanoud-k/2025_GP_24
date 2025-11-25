/*import 'package:flutter/material.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // أنيميشن ظهور الشعار
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _opacity = 1.0);
    });

    // الانتقال بعد 3 ثواني
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/mobile');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Background
      backgroundColor: const Color(0xFF37C4BE),
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(seconds: 1),
          opacity: _opacity,
          curve: Curves.easeInOut,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            // 🟢 هذا هو الشعار
            child: Image.asset(
              'assets/logo/hassalaLogo.png', // ← تأكد من المسار
              width: 400, // ← هذا السطر اللي نعدّله
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}*/
import 'dart:async';
import 'package:flutter/material.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  double _opacity = 0.0;
  double _rotation = 0.0;

  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;

  // Coin animations
  late AnimationController _coinController;
  late Animation<Offset> _coinSlide;
  late Animation<double> _coinScale;

  // Typing effect
  String slogan = "For Smarter Children...";
  String displayedText = "";
  int index = 0;

  @override
  void initState() {
    super.initState();

    // Logo Animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2300),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Coin Animation
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _coinSlide = Tween<Offset>(
      begin: const Offset(0, -0.85),
      end: const Offset(-0.30, -0.05),
    ).animate(
      CurvedAnimation(
        parent: _coinController,
        curve: Curves.easeOutBack,
      ),
    );

    _coinScale = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _coinController,
        curve: Curves.easeIn,
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _opacity = 1.0);
      _controller.forward();
      _coinController.forward();
      _startRotationAnimation();
      _startTypingEffect(); // ← START TYPING EFFECT
    });

    // Navigate to next view
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/mobile');
      }
    });
  }

  // Typing animation function
  void _startTypingEffect() {
    Future.delayed(const Duration(milliseconds: 800), () {
      Timer.periodic(const Duration(milliseconds: 55), (timer) {
        if (index < slogan.length) {
          setState(() {
            displayedText += slogan[index];
            index++;
          });
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _startRotationAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _rotation = 0.1);

      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() => _rotation = -0.1);

        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          setState(() => _rotation = 0.0);
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF37C4BE),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF37C4BE).withOpacity(0.8),
                    const Color(0xFF2A9D8F),
                  ],
                ),
              ),
            ),
          ),

          // Slogan typing text
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.22,
            child: Text(
              displayedText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Falling coin
          SlideTransition(
            position: _coinSlide,
            child: ScaleTransition(
              scale: _coinScale,
              child: Image.asset(
                "assets/logo/coin.png",
                width: 90,
              ),
            ),
          ),

          // Logo animation
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _opacity,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _bounceAnimation,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    tween: Tween(begin: 0.0, end: _rotation),
                    builder: (context, rotation, child) {
                      return Transform.rotate(
                        angle: rotation,
                        child: child,
                      );
                    },
                    child: Image.asset(
                      'assets/logo/hassalaLogo.png',
                      width: 500,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


