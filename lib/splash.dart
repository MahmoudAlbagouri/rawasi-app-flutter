// lib/features/splash/splash_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();

      Future.delayed(const Duration(seconds: 3), () async {
        if (!mounted) return;

        final isSignedIn = await isUserSignedIn();

        Widget destination;
        if (isSignedIn) {
          destination = const HomeView();
        } else {
          destination = const HomeView();
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                destination,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // تغيير الخلفية إلى صورة تحتوي على النمط الهندسي
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        // child: Center(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       // إزالة صورة kufi غير المطلوبة
        //       SlideTransition(
        //         position: _slideAnimation,
        //         child: ScaleTransition(
        //           scale: _scaleAnimation,
        //           child: FadeTransition(
        //             opacity: _opacityAnimation,
        //             child: SizedBox(
        //               width: 250, // زيادة الحجم ليتناسب مع التصميم
        //               height: 250,
        //               child: Image.asset(
        //                 'assets/images/logo.png', // استخدام الصورة الجديدة للـ R
        //                 fit: BoxFit.contain,
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //       const Gap(12),
        //       SlideTransition(
        //         position: _slideAnimation,
        //         child: FadeTransition(
        //           opacity: _opacityAnimation,
        //           child: Text(
        //             'رواسي',
        //             style: TextStyle(
        //               color: AppColors.white,
        //               fontSize: 34,
        //               fontWeight: FontWeight.bold,
        //               letterSpacing: 1.2,
        //             ),
        //           ),
        //         ),
        //       ),
        //       const Gap(8),
        //       SlideTransition(
        //         position: _slideAnimation,
        //         child: FadeTransition(
        //           opacity: _opacityAnimation,
        //           child: Text(
        //             'خليك دايماً سابق بخطوة',
        //             style: TextStyle(
        //               color: AppColors.white.withOpacity(0.95),
        //               fontSize: 18,
        //               fontWeight: FontWeight.w500,
        //               fontStyle: FontStyle.italic,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }
}
