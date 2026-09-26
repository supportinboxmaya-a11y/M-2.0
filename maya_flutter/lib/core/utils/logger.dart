import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger();

  static void log(String message) {
    _logger.i(message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message) {
    _logger.w(message);
  }

  static void info(String message) {
    _logger.i(message);
  }

  static void debug(String message) {
    _logger.d(message);
  }
}
