import 'package:flutter/material.dart';
import 'auth/auth_factory.dart';
import 'finsight_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FinSightApp(authService: createFinSightAuth()));
}
