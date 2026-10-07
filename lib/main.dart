// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';
import 'package:rawasi_app_n/features/notifications/push_service.dart';
import 'package:rawasi_app_n/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // BEFORE anything reads the session: on iOS the Keychain outlives an
  // uninstall, so a reinstall would otherwise open signed in as the previous
  // owner of the phone. Awaited because PushService and the splash both go on
  // to read the token.
  await PrefHelper.clearIfFreshInstall();

  // Push notifications. init() never throws, so a Firebase problem can never
  // stop the app from starting.
  await PushService.instance.init();

  runApp(const MyApp());

  // Re-register this device if a student is already signed in. Deliberately
  // not awaited: start-up must not wait on the network.
  unawaited(PushService.instance.syncIfSignedIn());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Lets a push notification open a dialog from anywhere in the app.
      navigatorKey: PushService.navigatorKey,
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
