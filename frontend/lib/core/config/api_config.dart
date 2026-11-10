import 'package:flutter/foundation.dart';

/// URL base del backend.
///
/// - Emulador Android: `10.0.2.2` es el localhost de tu PC.
/// - Celular físico: `flutter run --dart-define=API_URL=http://<IP-de-tu-PC>:3001`
/// - Producción: `--dart-define=API_URL=https://tu-dominio.com`
class ApiConfig {
  static const String _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return '$_override/api';
    if (kIsWeb) return 'http://localhost:3001/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001/api';
    }
    return 'http://localhost:3001/api';
  }
}
