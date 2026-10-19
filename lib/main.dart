import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'finsight_app.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authConfigured =
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
  if (authConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    );
  }

  runApp(FinSightApp(
    authClient: authConfigured ? Supabase.instance.client : null,
  ));
}
