import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/database.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/pages/settings/export_encrypted.dart';
import 'package:open2fa/structures/account.dart';

class Export {
  bool encrypted;
  List<Account> accounts;

  Export({required this.encrypted, required this.accounts});

  static Future<Export> generate() async {
    final accounts = await DatabaseManager.getAccounts();
    return Export(encrypted: false, accounts: accounts);
  }

  static bool checkFormatString(String data) {
    try {
      final json = jsonDecode(data);
      return checkFormat(json);
    } catch (e) {
      return false;
    }
  }

  static bool checkFormat(Map<String, dynamic> json) {
    return json['encrypted'] == false && json['accounts'] is List;
  }

  factory Export.fromJson(Map<String, dynamic> json) {
    if (!checkFormat(json)) {
      throw ArgumentError(t('error.invalid_export_format'));
    }
    return Export(
      encrypted: json['encrypted'],
      accounts: List<Account>.from(
        json['accounts'].map((x) => Account.fromJson(x)),
      ),
    );
  }

  static Future<bool> import({
    bool encrypted = false,
    BuildContext? context,
  }) async {
    try {
      if (encrypted && context == null) {
        throw ArgumentError(t('error.no_build_context'));
      }
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null) {
        final bytes = result.files.single.bytes;
        if (bytes == null || bytes.isEmpty) {
          throw Exception(t('error.import_no_bytes'));
        }
        final jsonString = String.fromCharCodes(bytes);
        final json = jsonDecode(jsonString);
        Export? export = encrypted ? null : Export.fromJson(json);
        // ignore: use_build_context_synchronously
        if (context != null && context.mounted) {
          await Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => const SettingsEncryptedExportPage(),
              ),
            )
            .then(
              (value) async =>
                  export = await EncryptedExport.fromJson(json).decrypt(value!),
            )
            .catchError((e) {
              logger.e(t('error.import_fail', args: ['']), error: e);
              throw e;
            });
        }
        for (final account in export!.accounts) {
          DatabaseManager.addOrUpdateAccount(await account.encrypt());
        }
        return true;
      }
      return false;
    } catch (e) {
      logger.e(t('error.import_fail', args: ['']), error: e);
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'encrypted': encrypted,
      'accounts': List.from(accounts.map((x) => x.toMap())),
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  Uint8List toJsonBytes() {
    return utf8.encode(jsonEncode(toMap()));
  }
}

class EncryptedExport {
  String passwordHash;
  String salt;
  String nonce;
  String mac;
  String encryptedAccounts;

  EncryptedExport({
    required this.passwordHash,
    required this.salt,
    required this.nonce,
    required this.mac,
    required this.encryptedAccounts,
  });

  static Future<EncryptedExport> generate(String password) async {
    final accounts = await DatabaseManager.getAccounts();
    final salt = await Crypto.generateSecure();
    final key = await Crypto.deriveKeyFromPassword(password, salt);
    final accountsJson = jsonEncode(accounts.map((x) => x.toJson()).toList());
    final encryptedAccounts = await Crypto.encryptWithKey(
      accountsJson,
      SecretKey(key),
    );
    final nonce = base64Encode(encryptedAccounts.nonce);
    final mac = base64Encode(encryptedAccounts.mac.bytes);
    final encryptedAccountsData = base64Encode(encryptedAccounts.cipherText);
    final hashSalt = await Crypto.generateSecure();
    final passwordHash = await Crypto.deriveKeyFromPassword(password, hashSalt);
    final passwordHashString = await Crypto.keyToEncodedHash(
      passwordHash,
      hashSalt,
    );
    return EncryptedExport(
      passwordHash: passwordHashString,
      salt: salt,
      nonce: nonce,
      mac: mac,
      encryptedAccounts: encryptedAccountsData,
    );
  }

  Future<Export> decrypt(String password) async {
    try {
      final valid = await Crypto.comparePassword(
        password,
        hashToCompare: Crypto.getHashFromEncoded(passwordHash),
        salt: Crypto.getSaltFromEncoded(passwordHash),
      );
      if (!valid) {
        throw ArgumentError(t('error.password_invalid'));
      }
    } catch (e) {
      logger.e(e);
      rethrow;
    }
    final key = await Crypto.deriveKeyFromPassword(password, salt);
    final encrypted = SecretBox(
      base64Decode(encryptedAccounts),
      nonce: base64Decode(nonce),
      mac: Mac(base64Decode(mac)),
    );
    final decryptedData = await Crypto.decryptWithKey(
      encrypted,
      SecretKey(key),
    );
    final decrypted = json.decode(decryptedData);
    final accounts = List<Account>.from(
      decrypted.map((x) => Account.fromJsonString(x)),
    );
    return Export(encrypted: false, accounts: accounts);
  }

  static bool checkFormatString(String data) {
    try {
      final json = jsonDecode(data);
      return checkFormat(json);
    } catch (e) {
      return false;
    }
  }

  static bool checkFormat(Map<String, dynamic> map) {
    return map['encrypted'] == true &&
        map['password_hash'] is String &&
        map['salt'] is String &&
        map['nonce'] is String &&
        map['mac'] is String &&
        map['encrypted_accounts'] is String;
  }

  factory EncryptedExport.fromJson(Map<String, dynamic> json) {
    if (!checkFormat(json)) {
      throw ArgumentError(t('error.invalid_export_format'));
    }
    return EncryptedExport(
      passwordHash: json['password_hash'],
      salt: json['salt'],
      nonce: json['nonce'],
      mac: json['mac'],
      encryptedAccounts: json['encrypted_accounts'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'encrypted': true,
      'password_hash': passwordHash,
      'salt': salt,
      'nonce': nonce,
      'mac': mac,
      'encrypted_accounts': encryptedAccounts,
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  Uint8List toJsonBytes() {
    return utf8.encode(jsonEncode(toMap()));
  }
}
