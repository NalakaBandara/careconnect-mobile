import 'package:careconnect_mobile/core/network/api_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class AppLogger {
  static void info(String area, String message, {Object? details}) =>
      _write('INFO', area, message, details: details);

  static void success(String area, String message, {Object? details}) =>
      _write('OK', area, message, details: details);

  static void warning(String area, String message, {Object? details}) =>
      _write('WARN', area, message, details: details);

  static void error(
    String area,
    String message, {
    Object? error,
    Object? details,
  }) => _write(
    'ERROR',
    area,
    message,
    details: {
      if (error != null) 'errorType': error.runtimeType.toString(),
      'context': ?details,
    },
  );

  static void _write(
    String level,
    String area,
    String message, {
    Object? details,
  }) {
    if (!kDebugMode) return;
    final prefix = '[CareConnect][$level][${area.toUpperCase()}]';
    debugPrint('$prefix $message');
    if (details != null) {
      debugPrint('$prefix   ${ApiLogger.formatPayload(details)}');
    }
  }
}

class CareConnectNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    AppLogger.info(
      'NAV',
      'PUSH ${_label(route)}',
      details: {'from': _label(previousRoute)},
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    AppLogger.info(
      'NAV',
      'POP ${_label(route)}',
      details: {'to': _label(previousRoute)},
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    AppLogger.info('NAV', 'REPLACE ${_label(oldRoute)} → ${_label(newRoute)}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    AppLogger.info('NAV', 'REMOVE ${_label(route)}');
  }

  String _label(Route<dynamic>? route) {
    if (route == null) return 'none';
    final name = route.settings.name;
    return name == null || name.isEmpty ? route.runtimeType.toString() : name;
  }
}
