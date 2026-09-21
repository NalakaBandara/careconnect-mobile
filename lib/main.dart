import 'package:careconnect_mobile/app/app.dart';
import 'package:careconnect_mobile/core/logging/app_logger.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final flutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    AppLogger.error('FLUTTER', 'Framework error', error: details.exception);
    flutterErrorHandler?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('DART', 'Unhandled asynchronous error', error: error);
    return false;
  };
  AppLogger.info('APP', 'Starting CareConnect in debug mode');
  runApp(const CareConnectApp());
}
