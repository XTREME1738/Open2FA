import 'dart:convert';
import 'dart:io';

import 'package:open2fa/structures/category.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/structures/account.dart';
import 'package:open2fa/structures/encrypted_account.dart';
import 'package:otp/otp.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqlite3/sqlite3.dart';

class DatabaseManager {
  static final _instance = DatabaseManager._internal();
  bool _connected = false;
  bool _decrypted = false;
  late Database _db;

  DatabaseManager._internal();

  factory DatabaseManager() {
    return _instance;
  }

  Future<String> _getSalt() async {
    final storage = FlutterSecureStorage();
    final hasSalt = await storage.containsKey(key: 'sqlcipher_salt');
    if (hasSalt) {
      return (await storage.read(key: 'sqlcipher_salt'))!;
    } else {
      final salt = await Crypto.generateSecure();
      await storage.write(key: 'sqlcipher_salt', value: salt);
      return salt;
    }
  }

  void _deleteSalt() async {
    final storage = FlutterSecureStorage();
    await storage.delete(key: 'sqlcipher_salt');
  }

  Future<String> _getDatabasesPath() async {
    final dbName = 'open2fa.db';
    String dbPath;
    if (Platform.isIOS) {
      dbPath = join((await getLibraryDirectory()).path, dbName);
    } else if (Platform.isLinux || Platform.isWindows) {
      dbPath = join(Directory.current.path, dbName);
    } else if (Platform.isAndroid) {
      dbPath = join(await sqflite.getDatabasesPath(), dbName);
    } else {
      throw UnsupportedError(t('error.unsupported_platform'));
    }
    return dbPath;
  }

  Future _connect() async {
    final dbPath = await _getDatabasesPath();
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }
    _db = sqlite3.open(dbPath);
    _connected = true;
  }

  static Future connect() async {
    if (_instance._connected) return;
    await _instance._connect();
  }

  static Future<bool> setupEncryption(SecretKey encryptionKey) async {
    if (!_instance._connected) {
      await connect();
    }
    if (_instance._db.select('PRAGMA cipher_version;').isEmpty) {
      throw StateError(t('error.sqlcipher_not_available'));
    }
    final salt = await _instance._getSalt();
    final key = base64Encode(
      await Crypto.deriveKeyFromKey(encryptionKey, salt),
    );
    final query = _instance._db.prepare('PRAGMA key = "$key";');
    try {
      query.execute();
    } on SqliteException catch (e) {
      if (e.message.contains('file is not a database')) {
        return false;
      }
      logger.e('Failed to setup encryption: $e');
      rethrow;
    }
    _instance._decrypted = true;
    _instance._initDB();
    return true;
  }

  static void close() {
    if (_instance._connected) {
      _instance._db.dispose();
      _instance._connected = false;
      _instance._decrypted = false;
    } else {
      // No need to make this anything more than a debug log, it doesn't break anything or indicate a problem, just a no-op
      logger.d('Database close was called, but the database was not connected');
    }
  }

  void _initDB() {
    if (!_connected) {
      throw StateError(t('error.db_not_connected'));
    }
    _db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        encrypted_data TEXT NOT NULL,
        algorithm INTEGER NOT NULL,
        digits INTEGER NOT NULL,
        interval INTEGER NOT NULL,
        counter INTEGER NOT NULL,
        totp INTEGER NOT NULL,
        google INTEGER NOT NULL,
        nonce TEXT,
        mac TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    _db.execute('''
	  CREATE TABLE IF NOT EXISTS categories (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		encrypted_data TEXT NOT NULL,
    nonce TEXT,
    mac TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	  );
	''');
  }

  static Future<List<Category>> getCategories() async {
    if (!_instance._connected) {
      throw StateError(t('error.db_not_connected'));
    }
    if (!_instance._decrypted) {
      throw StateError(t('error.db_not_decrypted'));
    }
    final query = _instance._db.prepare('SELECT * FROM categories;');
    final categories = <Category>[];
    for (final row in query.select()) {
      final decryptedName = await Crypto.decrypt(
        SecretBox(
          base64Decode(row['encrypted_data'] as String),
          nonce: base64Decode(row['nonce'] as String),
          mac: Mac(base64Decode(row['mac'] as String)),
        ),
      );
      categories.add(
        Category(
          id: row['id'] as int,
          name: decryptedName,
          updatedAt: DateTime.parse(row['updated_at'] as String),
          createdAt: DateTime.parse(row['created_at'] as String),
        ),
      );
    }
    return categories;
  }

  static Future<List<Account>> getAccounts() async {
    if (!_instance._connected) {
      throw StateError(t('error.db_not_connected'));
    }
    if (!_instance._decrypted) {
      throw StateError(t('error.db_not_decrypted'));
    }
    final query = _instance._db.prepare('SELECT * FROM accounts;');
    final accounts = <Account>[];
    for (final row in query.select()) {
      accounts.add(
        await EncryptedAccount(
          id: row['id'] as int,
          encryptedData: row['encrypted_data'] as String,
          algorithm: Algorithm.values[row['algorithm'] as int],
          digits: row['digits'] as int,
          interval: row['interval'] as int,
          counter: row['counter'] as int,
          isTOTP: row['totp'] as int == 1,
          isGoogle: row['google'] as int == 1,
          nonce: row['nonce'] as String,
          mac: row['mac'] as String,
          updatedAt: DateTime.parse(row['updated_at'] as String),
          createdAt: DateTime.parse(row['created_at'] as String),
        ).decrypt(),
      );
    }
    return accounts;
  }

  static Future reEncryptAll(SecretKey previousKey) async {
    if (!_instance._connected) {
      throw StateError(t('error.db_not_connected'));
    }
    final accounts = await getAccounts();
    final categories = await getCategories();
    for (final account in accounts) {
      try {
        final encrypted = await account.encrypt();
        final query = _instance._db.prepare(
          'UPDATE accounts SET secret = ?, nonce = ?, mac = ? WHERE id = ?;',
        );
        query.execute([
          encrypted.secret,
          encrypted.nonce,
          encrypted.mac,
          account.id,
        ]);
      } catch (e) {
        rethrow;
      }
    }
    for (final category in categories) {
      try {
        final encrypted = await Crypto.encrypt(category.name);
        final query = _instance._db.prepare(
          'UPDATE categories SET encrypted_data = ?, nonce = ?, mac = ? WHERE id = ?;',
        );
        query.execute([
          base64Encode(encrypted.cipherText),
          base64Encode(encrypted.nonce),
          base64Encode(encrypted.mac.bytes),
          category.id,
        ]);
      } catch (e) {
        rethrow;
      }
    }
  }

  static Future<bool> addOrUpdateCategory(Category category) async {
    if (!_instance._connected) {
      throw StateError(t('error.db_not_connected'));
    }
    final query = _instance._db.prepare(
      'INSERT INTO categories (encrypted_data, nonce, mac, updated_at) VALUES (?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET encrypted_data = excluded.encrypted_data, nonce = excluded.nonce, mac = excluded.mac, updated_at = excluded.updated_at;',
    );
    final encryptedName = await Crypto.encrypt(category.name);
    query.execute([
      encryptedName.cipherText,
      base64Encode(encryptedName.nonce),
      base64Encode(encryptedName.mac.bytes),
      category.updatedAt.toIso8601String(),
    ]);
    return true;
  }

  static void addAccount(EncryptedAccount account) {
    if (!_instance._connected) {
      throw StateError(t('error.db_not_connected'));
    }
    final query = _instance._db.prepare(
      'INSERT INTO accounts (encrypted_data, algorithm, digits, interval, counter, totp, google, nonce, mac, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
    );
    query.execute([
      account.encryptedData,
      account.algorithm.index,
      account.digits,
      account.interval,
      account.counter,
      account.isTOTP ? 1 : 0,
      account.isGoogle ? 1 : 0,
      account.nonce,
      account.mac,
      DateTime.now().toIso8601String(),
    ]);
  }

  static void addOrUpdateAccount(EncryptedAccount account) {
    if (!_instance._connected) {
      throw StateError(t('error.db_not_connected'));
    }
    if (account.id == -1) {
      addAccount(account);
      return;
    }
    final query = _instance._db.prepare(
      'UPDATE accounts SET encrypted_data = ?, algorithm = ?, digits = ?, interval = ?, counter = ?, totp = ?, google = ?, nonce = ?, mac = ?, updated_at = ? WHERE id = ?;',
    );
    query.execute([
      account.encryptedData,
      account.algorithm.index,
      account.digits,
      account.interval,
      account.counter,
      account.isTOTP ? 1 : 0,
      account.isGoogle ? 1 : 0,
      account.nonce,
      account.mac,
      DateTime.now().toIso8601String(),
      account.id,
    ]);
  }

  static void removeCategory(int id) {
    if (!_instance._connected) {
      throw StateError(t('error.db_not_connected'));
    }
    final query = _instance._db.prepare('DELETE FROM categories WHERE id = ?;');
    query.execute([id]);
  }

  static void removeAccount(int id) {
    if (!_instance._connected) {
      throw StateError(t('error.db_not_connected'));
    }
    final query = _instance._db.prepare('DELETE FROM accounts WHERE id = ?;');
    query.execute([id]);
  }

  static void removeAllAccounts() {
    if (!_instance._connected) {
      throw StateError(t('error.db_not_connected'));
    }
    final query = _instance._db.prepare('DROP TABLE accounts;');
    query.execute();
    _instance._initDB();
  }

  static Future removeDatabase() async {
    if (_instance._connected) {
      _instance._db.dispose();
      _instance._connected = false;
      _instance._decrypted = false;
    }
    _instance._deleteSalt();
    await File(await _instance._getDatabasesPath()).delete();
  }
}
