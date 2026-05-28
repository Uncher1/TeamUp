import 'package:flutter/foundation.dart';

/// Base URLs for the TeamUp backend.
///
/// Android emulators reach the host machine via 10.0.2.2, not localhost.
/// Web and desktop use localhost directly. For a physical device, override
/// [host] with the machine's LAN IP.
class Config {
  static const int port = 3000;

  static String get host {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get apiBaseUrl => 'http://$host:$port/api';
  static String get socketUrl => 'http://$host:$port';
}
