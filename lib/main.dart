// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rawasi_app_n/core/utils/app_sync_service.dart';
import 'package:rawasi_app_n/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 استدعاء الـ API فور فتح التطبيق (قبل تشغيل الواجهة)
  await AppSyncService.syncExpectedDayOnAppOpen();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رواسي',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Tajawal'),
      home: const SplashView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
