import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/database.dart';
import 'package:open2fa/i18n.dart';
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

  static Future<Export> decrypt(
    EncryptedExport encryptedExport,
    String password,
  ) async {
    final key = await Crypto.deriveKeyFromPassword(
      password,
      encryptedExport.salt,
    );
    final encrypted = SecretBox(
      base64Decode(encryptedExport.encryptedAccounts),
      nonce: base64Decode(encryptedExport.nonce),
      mac: Mac(base64Decode(encryptedExport.mac)),
    );
    final decryptedData = await Crypto.decryptWithKey(
      encrypted,
      SecretKey(key),
    );
    final decrypted = json.decode(decryptedData);
    final accounts = List<Account>.from(
      decrypted.map((x) => Account.fromJson(x)),
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
        map['iv'] is String &&
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
      nonce: json['iv'],
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
