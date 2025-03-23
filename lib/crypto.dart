import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:open2fa/database.dart';
import 'package:open2fa/i18n.dart';

class Crypto {
  static SecretKey? _encryptionKey;
  static final _algorithm = Argon2id(
    memory: 9216,
    iterations: 4,
    parallelism: 1,
    hashLength: 32,
  );

  static Future<String> getHashingSalt() async {
    final storage = FlutterSecureStorage();
    final hasSalt = await storage.containsKey(key: 'password_salt');
    if (hasSalt) {
      return (await storage.read(key: 'password_salt'))!;
    } else {
      final salt = await generateSecure();
      await storage.write(key: 'password_salt', value: salt);
      return salt;
    }
  }

  static Future<String> getEncryptionSalt() async {
    final storage = FlutterSecureStorage();
    final hasSalt = await storage.containsKey(key: 'encryption_key_salt');
    if (hasSalt) {
      return (await storage.read(key: 'encryption_key_salt'))!;
    } else {
      final salt = await generateSecure();
      await storage.write(key: 'encryption_key_salt', value: salt);
      return salt;
    }
  }

  static Future<SecretBox> encrypt(String data) async {
    if (_encryptionKey == null) {
      throw ArgumentError(t('error.encryption_key_not_set'));
    }
    return encryptWithKey(data, _encryptionKey!);
  }

  static Future<SecretBox> encryptWithKey(String data, SecretKey key) async {
    if (data.isEmpty) {
      throw ArgumentError(t('error.invalid_data_length'));
    }
    final algorithm = Xchacha20.poly1305Aead();
    final encrypted = await algorithm.encrypt(
      data.codeUnits,
      secretKey: _encryptionKey!,
      nonce: base64Decode(await generateSecure(length: 24)),
    );
    return encrypted;
  }

  static Future<String> decrypt(SecretBox encrypted) async {
    if (_encryptionKey == null) {
      throw ArgumentError(t('error.encryption_key_not_set'));
    }
    return decryptWithKey(encrypted, _encryptionKey!);
  }

  static Future<String> decryptWithKey(
    SecretBox encrypted,
    SecretKey key,
  ) async {
    final algorithm = Xchacha20.poly1305Aead();
    final decrypted = await algorithm.decrypt(
      encrypted,
      secretKey: _encryptionKey!,
    );
    return String.fromCharCodes(decrypted);
  }

  static Future getEncryptionKey() async {
    final storage = FlutterSecureStorage();
    final hasKey = await storage.containsKey(key: 'encryption_key');
    if (hasKey) {
      _encryptionKey = SecretKey(
        base64Decode((await storage.read(key: 'encryption_key'))!),
      );
    } else {
      throw ArgumentError(t('error.encryption_key_not_set'));
    }
  }

  static Future deleteEncryptionKey() async {
    final storage = FlutterSecureStorage();
    await storage.delete(key: 'encryption_key_salt');
    await storage.delete(key: 'encryption_key');
  }

  static Future unlockVaultWithBiometrics() async {
    final localAuth = LocalAuthentication();
    await checkBiometricsAvailable();
    final authenticated = await localAuth.authenticate(
      localizedReason: t('auth.unlock_with_biometrics'),
      options: AuthenticationOptions(
        sensitiveTransaction: true,
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
    if (!authenticated) {
      throw ArgumentError(t('error.biometrics_failed'));
    }
    final storage = FlutterSecureStorage();
    final hasKey = await storage.containsKey(key: 'encryption_key');
    if (!hasKey) {
      throw ArgumentError(t('error.encryption_key_not_set'));
    }
    await getEncryptionKey();
    await DatabaseManager.connect();
    await DatabaseManager.setupEncryption(_encryptionKey!);
  }

  static lockVault() {
    _encryptionKey = null;
    DatabaseManager.close();
  }

  static Future<bool> areBiometricsEnabled() async {
    try {
      await checkBiometricsAvailable();
    } catch (_) {
      await setBiometricsEnabled(false);
      return false;
    }
    final storage = FlutterSecureStorage();
    return await storage.containsKey(key: 'bio_auth_enabled');
  }

  static Future<bool> isAuthRequired() async {
    final storage = FlutterSecureStorage();
    return await storage.containsKey(key: 'password_hash') &&
        !(await storage.containsKey(key: 'no_auth'));
  }

  static Future setupNoAuth() async {
    final storage = FlutterSecureStorage();
    await storage.delete(key: 'password_hash');
    await storage.delete(key: 'password_salt');
    await deleteEncryptionKey();
    final previousEncryptionKey = _encryptionKey;
    _encryptionKey = null;
    final password = await generateSecure();
    final key = await deriveKeyFromPassword(
      password,
      await getEncryptionSalt(),
    );
    await storage.write(key: 'no_auth_pass', value: password);
    await storage.write(key: 'no_auth', value: 'true');
    await DatabaseManager.connect();
    await DatabaseManager.setupEncryption(_encryptionKey!);
    _encryptionKey = SecretKey(key);
    if (previousEncryptionKey != null) {
      await DatabaseManager.reEncryptAll(previousEncryptionKey);
    }
  }

  static Future unlockVaultNoAuth() async {
    final storage = FlutterSecureStorage();
    final password = await storage.read(key: 'no_auth_pass');
    if (password == null) {
      throw ArgumentError(t('error.no_auth_pass_not_set'));
    }
    final key = await deriveKeyFromPassword(
      password,
      await getEncryptionSalt(),
    );
    _encryptionKey = SecretKey(key);
    await DatabaseManager.connect();
    await DatabaseManager.setupEncryption(_encryptionKey!);
  }

  static Future unlockVaultWithPassword(String password) async {
    if (password.isEmpty) {
      throw ArgumentError(t('error.password_required'));
    }
    if (password.length < 8) {
      throw ArgumentError(t('error.password_invalid'));
    }
    if (!await comparePassword(password)) {
      throw ArgumentError(t('error.password_invalid'));
    }
    final key = await deriveKeyFromPassword(
      password,
      await getEncryptionSalt(),
    );
    _encryptionKey = SecretKey(key);
    await DatabaseManager.connect();
    await DatabaseManager.setupEncryption(_encryptionKey!);
  }

  static Future setupPasswordAuth(String password) async {
    final hash = base64Encode(
      await deriveKeyFromPassword(password, await getHashingSalt()),
    );
    final storage = FlutterSecureStorage();
    await storage.delete(key: 'no_auth_pass');
    await storage.delete(key: 'no_auth');
    await storage.write(key: 'password_hash', value: hash);
    final key = await deriveKeyFromPassword(
      password,
      await getEncryptionSalt(),
    );
    final previousEncryptionKey = _encryptionKey;
    _encryptionKey = SecretKey(key);
    final encryptSuccess = await DatabaseManager.setupEncryption(
      _encryptionKey!,
    );
    if (!encryptSuccess) {
      throw ArgumentError(t('error.db_encryption_failed'));
    }
    if (previousEncryptionKey != null) {
      await DatabaseManager.reEncryptAll(previousEncryptionKey);
    }
  }

  static Future setBiometricsEnabled(bool enabled) async {
    final storage = FlutterSecureStorage();
    if (enabled) {
      await storage.write(
        key: 'encryption_key',
        value: base64Encode(await _encryptionKey!.extractBytes()),
      );
      await storage.write(key: 'bio_auth_enabled', value: 'true');
    } else {
      await storage.delete(key: 'encryption_key');
      await storage.delete(key: 'bio_auth_enabled');
    }
  }

  static Future checkBiometricsAvailable() async {
    final localAuth = LocalAuthentication();
    final hasBiometrics =
        await localAuth.canCheckBiometrics &&
        await localAuth.isDeviceSupported();
    if (hasBiometrics) {
      final biometrics = await localAuth.getAvailableBiometrics();
      if (biometrics.isEmpty) {
        throw ArgumentError(t('error.biometrics_not_available'));
      }
    } else {
      throw ArgumentError(t('error.biometrics_not_supported'));
    }
  }

  static Future<bool> comparePassword(String password) async {
    final storage = FlutterSecureStorage();
    final storedHash = await storage.read(key: 'password_hash');
    if (storedHash == null) {
      return false;
    }

    final hash = base64Encode(
      await deriveKeyFromPassword(password, await getHashingSalt()),
    );
    return hash == storedHash;
  }

  static Future<String> keyToEncodedHash(
    List<int> key,
    String encodedSalt,
  ) async {
    return "\$argon2id\$v=${_algorithm.version}\$m=${_algorithm.memory},t=${_algorithm.iterations},p=${_algorithm.parallelism}\$${base64Encode(key)}\$$encodedSalt";
  }

  static Future<List<int>> deriveKeyFromPassword(
    String password,
    String salt,
  ) async {
    final secretKey = await _algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt.codeUnits,
    );

    final keyBytes = await secretKey.extractBytes();
    return keyBytes;
  }

  static Future<List<int>> deriveKeyFromKey(SecretKey key, String salt) async {
    final secretKey = await _algorithm.deriveKey(
      secretKey: key,
      nonce: salt.codeUnits,
    );

    final keyBytes = await secretKey.extractBytes();
    return keyBytes;
  }

  static Future<String> generateSecure({int length = 32}) {
    final random = SecretKeyData.random(length: length);
    return random.extractBytes().then((bytes) {
      return base64Encode(bytes);
    });
  }
}
