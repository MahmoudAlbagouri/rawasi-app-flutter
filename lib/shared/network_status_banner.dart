// lib/shared/network_status_banner.dart
//
// The one place "you are offline" is said. Wrapped around the whole app in
// main.dart (MaterialApp.builder), so it sits above every screen's own
// content and appears the instant NetworkStatus.isOffline flips - no screen
// has to ask for it, and no screen can show a different, wrong message
// instead (a false "يرجى تسجيل الدخول أولاً", an unexplained retry button).

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/network_status.dart';

class NetworkStatusBanner extends StatelessWidget {
  final Widget child;

  const NetworkStatusBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatus.isOffline,
      builder: (context, offline, _) {
        return Stack(
          children: [
            child,
            // Drawn on top, never pushing content down - a banner that
            // shifts the layout every time the connection blips is its own
            // kind of annoying.
            if (offline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Material(
                    color: AppColors.brandGray,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.wifi_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'لا يوجد اتصال بالإنترنت',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
