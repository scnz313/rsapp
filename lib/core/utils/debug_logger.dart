
import 'package:flutter/foundation.dart';

class DebugLogger {
  static bool enableLogs = true;
  
  static void auth(String message) {
    if (enableLogs) {
      debugPrint('🔐 AUTH: $message');
    }
  }
  
  static void route(String message) {
    if (enableLogs) {
      debugPrint('🛣️ ROUTE: $message');
    }
  }
  
  static void provider(String message) {
    if (enableLogs) {
      debugPrint('🔄 PROVIDER: $message');
    }
  }
  
  static void error(String message, [Object? error]) {
    if (enableLogs) {
      debugPrint('❌ ERROR: $message${error != null ? ' - $error' : ''}');
    }
  }
  
  static void info(String message) {
    if (enableLogs) {
      debugPrint('ℹ️ INFO: $message');
    }
  }
}
