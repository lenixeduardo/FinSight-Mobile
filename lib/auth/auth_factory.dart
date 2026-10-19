import 'auth_service.dart';
import 'auth_factory_stub.dart'
  if (dart.library.io) 'auth_factory_io.dart' as platform;

/// Web permanece demonstração: sqflite depende de Android/iOS.
FinSightAuthService? createFinSightAuth() => platform.createFinSightAuth();
