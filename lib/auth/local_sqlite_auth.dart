import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';

import 'auth_service.dart';

/// Contas locais deste aparelho, sem sincronização remota.
/// O SQLite guarda sal e derivação de senha, nunca senha em texto puro.
class LocalSqliteAuthService implements FinSightAuthService {
  LocalSqliteAuthService({
    FlutterSecureStorage? storage,
    Future<Database> Function()? databaseFactory,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _databaseFactory = databaseFactory;

  static const _sessionKey = 'finsight.local.session.v1';
  final FlutterSecureStorage _storage;
  final Future<Database> Function()? _databaseFactory;
  Database? _database;
  final Pbkdf2 _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 180000,
    bits: 256,
  );

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await (_databaseFactory?.call() ?? _open());
    return _database!;
  }

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase('$root/finsight_local_auth_v1.db',
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE local_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE COLLATE NOCASE,
            salt TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  String _normaliseEmail(String email) => email.trim().toLowerCase();

  Future<String> _derive(String password, List<int> salt) async {
    final key = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    return base64Encode(await key.extractBytes());
  }

  bool _safeEquals(String a, String b) {
    final aa = utf8.encode(a), bb = utf8.encode(b);
    if (bb.isEmpty) return false;
    var result = aa.length ^ bb.length;
    for (var i = 0; i < aa.length; i++) {
      result |= aa[i] ^ bb[i % bb.length];
    }
    return result == 0;
  }

  void _validate(String email, String password) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(_normaliseEmail(email))) {
      throw const FinSightAuthFailure('Informe um e-mail válido.');
    }
    if (password.length < 10) {
      throw const FinSightAuthFailure(
        'Utilize uma senha com pelo menos 10 caracteres.');
    }
  }

  @override
  Future<void> signUp(String email, String password) async {
    _validate(email, password);
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final derived = await _derive(password, salt);
    final database = await _db;
    try {
      final id = await database.insert('local_users', {
        'email': _normaliseEmail(email),
        'salt': base64Encode(salt),
        'password_hash': derived,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _storage.write(key: _sessionKey, value: id.toString());
    } on DatabaseException {
      throw const FinSightAuthFailure('Este e-mail já possui conta neste aparelho.');
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    final database = await _db;
    final records = await database.query('local_users',
      columns: ['id', 'salt', 'password_hash'],
      where: 'email = ?',
      whereArgs: [_normaliseEmail(email)],
      limit: 1,
    );
    if (records.isEmpty) {
      throw const FinSightAuthFailure('E-mail ou senha inválidos neste aparelho.');
    }
    final user = records.first;
    final actual = await _derive(
      password, base64Decode(user['salt']! as String));
    if (!_safeEquals(actual, user['password_hash']! as String)) {
      throw const FinSightAuthFailure('E-mail ou senha inválidos neste aparelho.');
    }
    await _storage.write(key: _sessionKey, value: (user['id'] as int).toString());
  }

  @override
  Future<bool> restoreSession() async {
    final id = await _storage.read(key: _sessionKey);
    if (id == null || int.tryParse(id) == null) return false;
    final database = await _db;
    final users = await database.query('local_users',
      columns: ['id'], where: 'id = ?', whereArgs: [int.parse(id)],
      limit: 1);
    if (users.isEmpty) {
      await _storage.delete(key: _sessionKey);
      return false;
    }
    return true;
  }

  @override
  Future<void> signOut() => _storage.delete(key: _sessionKey);
}
