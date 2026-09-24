import 'dart:developer';

class AppLogger {
  static void log(String message) {
    log(message, name: 'MayaPro');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    log(message, name: 'MayaPro', level: 1000, error: error, stackTrace: stackTrace);
  }

  static void warning(String message) {
    log(message, name: 'MayaPro', level: 900);
  }

  static void info(String message) {
    log(message, name: 'MayaPro', level: 800);
  }

  static void debug(String message) {
    log(message, name: 'MayaPro', level: 500);
  }
}