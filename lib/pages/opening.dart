import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

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
    Future.delayed(const Duration(seconds: 7), () {
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
              width: 500, // ← هذا السطر اللي نعدّله
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
