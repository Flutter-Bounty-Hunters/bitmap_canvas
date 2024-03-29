// ignore_for_file: avoid_print

import 'package:logging/logging.dart' as logging;

class LogNames {
  /// Logs lifecycle events within a `BitmapCanvas`.
  static const canvasLifecycle = 'bitmapcanvas.lifecycle';

  /// Logs lifecycle events within a `BitmapPaint` widget.
  static const paintLifecycle = 'bitmappaint.lifecycle';
}

final canvasLifecycleLog = logging.Logger(LogNames.canvasLifecycle);

final paintLifecycleLog = logging.Logger(LogNames.paintLifecycle);

final _activeLoggers = <logging.Logger>{};

void initAllLogs(logging.Level level) {
  initLoggers(level, {logging.Logger.root});
}

void initLoggers(logging.Level level, Set<logging.Logger> loggers) {
  logging.hierarchicalLoggingEnabled = true;

  for (final logger in loggers) {
    if (!_activeLoggers.contains(logger)) {
      print('Initializing logger: ${logger.name}');
      logger
        ..level = level
        ..onRecord.listen(printLog);

      _activeLoggers.add(logger);
    }
  }
}

void deactivateLoggers(Set<logging.Logger> loggers) {
  for (final logger in loggers) {
    if (_activeLoggers.contains(logger)) {
      print('Deactivating logger: ${logger.name}');
      logger.clearListeners();

      _activeLoggers.remove(logger);
    }
  }
}

void printLog(logging.LogRecord record) {
  print(
      '(${record.time.second}.${record.time.millisecond.toString().padLeft(3, '0')}) ${record.loggerName} > ${record.level.name}: ${record.message}');
}
