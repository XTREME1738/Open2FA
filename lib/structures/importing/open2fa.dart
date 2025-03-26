import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/database.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/structures/account.dart';
import 'package:open2fa/structures/export.dart';

class Open2FAExport extends ExportBase {
  Open2FAExport();

  @override
  Future<Export> generate(
    String fromJsonString, {
    String? decryptionPassword,
  }) async {
    if (!checkFormatString(fromJsonString)) {
      throw ArgumentError(t('error.invalid_export_format'));
    }
    final json = jsonDecode(fromJsonString);
    if (decryptionPassword != null) {
      final passwordHash = json['password_hash'];
      final salt = json['salt'];
      final nonce = json['nonce'];
      final mac = json['mac'];
      final encryptedAccounts = json['encrypted_accounts'];
      try {
        final valid = await Crypto.comparePassword(
          decryptionPassword,
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
      final key = await Crypto.deriveKeyFromPassword(decryptionPassword, salt);
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
      return Export(accounts: accounts);
    }
    return Export(
      accounts: List<Account>.from(
        json['accounts'].map((x) => Account.fromJson(x)),
      ),
    );
  }

  static bool checkFormatString(String jsonString, {bool encrypted = false}) {
    try {
      final json = jsonDecode(jsonString);
      if (encrypted) {
        return json['encrypted'] == true &&
            json['password_hash'] is String &&
            json['salt'] is String &&
            json['nonce'] is String &&
            json['mac'] is String &&
            json['encrypted_accounts'] is String;
      }
      return json['encrypted'] == false && json['accounts'] is List;
    } catch (e) {
      return false;
    }
  }

  static Future<String> create({String? password}) async {
    if (password != null) {
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
      final passwordHash = await Crypto.deriveKeyFromPassword(
        password,
        hashSalt,
      );
      final passwordHashString = await Crypto.keyToEncodedHash(
        passwordHash,
        hashSalt,
      );
      return jsonEncode({
        passwordHash: passwordHashString,
        salt: salt,
        nonce: nonce,
        mac: mac,
        encryptedAccounts: encryptedAccountsData,
      });
    }
    return jsonEncode({
      'encrypted': false,
      'accounts': await DatabaseManager.getAccounts(),
    });
  }
}
