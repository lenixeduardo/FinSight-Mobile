import 'auth_service.dart';
import 'local_sqlite_auth.dart';
FinSightAuthService createFinSightAuth() => LocalSqliteAuthService();
