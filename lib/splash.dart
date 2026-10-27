// lib/features/splash/splash_view.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/features/home/data/home_data.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';
import 'package:rawasi_app_n/shared/app_motion.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // The background artwork settles in: a slow zoom from 106% and a fade up.
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Use the 3 s the splash is on screen: open the connection to the server
    // and load home's data now, so home appears with it ready instead of
    // starting from nothing. Fire-and-forget — the splash never waits on it.
    HomeRepo.prefetch();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.06,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (motionReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }

      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;

        // Deliberately not awaiting anything before navigating. This used to
        // await the stored-token check, so a storage failure threw here and the
        // app never left the splash. HomeView reads the session itself.
        // Fades through to home, the same way tabs switch.
        Navigator.pushReplacement(
          context,
          TabSwitchRoute(builder: (_) => const HomeView()),
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
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
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
            //         position: <slide>,
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
            //         position: <slide>,
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
            //         position: <slide>,
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
        ),
      ),
    );
  }
}
