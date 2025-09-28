// ignore_for_file: avoid_print
import 'package:flutter/material.dart';

class TommyLogger {
  TommyLogger._();
  static final TommyLogger _instance = TommyLogger._();
  static TommyLogger get logger => _instance;

  BuildContext? _context; // not "late final"
  LogLevel _logLevel = LogLevel.info;

  void init(BuildContext context, LogLevel logLevel) {
    _context ??= context;
    _logLevel = logLevel;
  }

  void trace(String s, int millis) => _showMessage(s, millis, LogLevel.trace, Colors.blueGrey);
  void debug(String s, int millis) => _showMessage(s, millis, LogLevel.debug, Colors.lightBlue);
  void info (String s, int millis) => _showMessage(s, millis, LogLevel.info,  Colors.green);
  void warn (String s, int millis) => _showMessage(s, millis, LogLevel.warn,  Colors.orangeAccent);
  void error(String s, int millis) => _showMessage(s, millis, LogLevel.error, Colors.redAccent);
  void fatal(String s, int millis) => _showMessage(s, millis, LogLevel.fatal, Colors.red);

  void _showMessage(String s, int millis, LogLevel logLevel, Color colour) {
    if (_context != null) {
      if (logLevel <= _logLevel) {
        final bar = SnackBar(content: Text(s), duration: Duration(milliseconds: millis), backgroundColor: colour);
        ScaffoldMessenger.of(_context!).showSnackBar(bar);
      }
    } else {
      print("[WARNING]: if you see this message, TommyLogger is not initialized properly. Call TommyLogger.instance.init(context) inside 'Scaffold' widget");
      print("$s");
    }
  }
}

enum LogLevel implements Comparable<LogLevel> {
  off  (priority: 0),
  fatal(priority: 1),
  error(priority: 2),
  warn (priority: 3),
  info (priority: 4),
  debug(priority: 5),
  trace(priority: 6),
  all  (priority: 7),
  ;

  const LogLevel({required this.priority});

  final int priority;

  @override
  int compareTo(LogLevel other) => priority - other.priority;

  bool operator > (LogLevel other) => compareTo(other) > 0;
  bool operator < (LogLevel other) => compareTo(other) < 0;
  bool operator >=(LogLevel other) => compareTo(other) >= 0;
  bool operator <=(LogLevel other) => compareTo(other) <= 0;
}
