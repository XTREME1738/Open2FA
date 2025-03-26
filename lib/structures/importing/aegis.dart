// ignore_for_file: unused_element_parameter

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:hashlib/codecs.dart';
import 'package:hashlib/hashlib.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/structures/account.dart';
import 'package:open2fa/structures/export.dart';
import 'package:otp/otp.dart';

class _AegisExportAccountInfo {
  final String secret;
  final String algo;
  final int digits;
  final int? period;
  final int? counter;

  _AegisExportAccountInfo({
    required this.secret,
    required this.algo,
    required this.digits,
    this.period,
    this.counter,
  }) {
    if (algo != 'totp' && algo != 'hotp') {
      throw ArgumentError(t('error.invalid_export_format'));
    }
    if (algo == 'totp' && period == null) {
      throw ArgumentError(t('error.invalid_export_format'));
    }
    if (algo == 'hotp' && counter == null) {
      throw ArgumentError(t('error.invalid_export_format'));
    }
  }
}

class _AegisExportAccount {
  final String type;
  final String uuid;
  final String name;
  final String issuer;
  final _AegisExportAccountInfo info;
  final List<String> groups;

  _AegisExportAccount({
    required this.type,
    required this.uuid,
    required this.name,
    required this.issuer,
    required this.info,
    required this.groups,
  });
}

class _AegisExportHeaderParams {
  final String nonce;
  final String tag;

  _AegisExportHeaderParams({required this.nonce, required this.tag});
}

class _AegisExportHeaderSlot {
  final int type;
  final String uuid;
  final String key;
  final _AegisExportHeaderParams keyParams;
  final int? n;
  final int? r;
  final int? p;
  final String? salt;

  _AegisExportHeaderSlot({
    required this.type,
    required this.uuid,
    required this.key,
    required this.keyParams,
    this.n,
    this.r,
    this.p,
    this.salt,
  }) {
    if (type == 1) {
      if (n == null || r == null || p == null || salt == null) {
        throw ArgumentError(t('error.invalid_export_format'));
      }
    }
  }
}

class _AegisExportHeader {
  final List<_AegisExportHeaderSlot>? slots;
  final _AegisExportHeaderParams? params;

  _AegisExportHeader({this.slots, this.params});
}

abstract class _AegisExport {
  final int version;
  final _AegisExportHeader header;

  _AegisExport({required this.version, required this.header});
}

class _AegisEncryptedExport extends _AegisExport {
  final String db;

  _AegisEncryptedExport({
    required this.db,
    required super.version,
    required super.header,
  });
}

class _AegisPlainExport extends _AegisExport {
  final List<_AegisExportAccount> db;

  _AegisPlainExport({
    required this.db,
    required super.version,
    required super.header,
  });
}

class AegisExport extends ExportBase {
  AegisExport();

  static bool checkFormatString(String jsonString, {bool isEncrypted = false}) {
    try {
      if (isEncrypted) {
        jsonDecode(jsonString) as _AegisEncryptedExport;
      } else {
        jsonDecode(jsonString) as _AegisPlainExport;
      }
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  @override
  Future<Export> generate(
    String fromJsonString, {
    String? decryptionPassword,
  }) async {
    if (!checkFormatString(fromJsonString)) {
      throw ArgumentError(t('error.invalid_export_format'));
    }
    _AegisExport json = jsonDecode(fromJsonString);
    if (decryptionPassword != null) {
      json = json as _AegisEncryptedExport;
      final keySlot = json.header.slots!.firstWhere((x) => x.type == 1);
      final kdf = Scrypt(
        cost: keySlot.n!,
        blockSize: keySlot.r!,
        parallelism: keySlot.p!,
        salt: fromHex(keySlot.salt!),
        derivedKeyLength: 32,
      );
      final key = kdf.convert(decryptionPassword.codeUnits);
      final cipher = AesGcm.with256bits();
      final secretBox = SecretBox(
        fromHex(keySlot.key),
        nonce: fromHex(keySlot.keyParams.nonce),
        mac: Mac(fromHex(keySlot.keyParams.tag)),
      );
      final masterKey = await cipher.decrypt(
        secretBox,
        secretKey: SecretKey(key.bytes),
      );
      final decryptedDb = await cipher.decrypt(
        SecretBox(
          fromBase64(json.db),
          nonce: fromHex(json.header.params!.nonce),
          mac: Mac(fromHex(json.header.params!.tag)),
        ),
        secretKey: SecretKey(masterKey),
      );
      json = jsonDecode(utf8.decode(decryptedDb));
    }
    final accounts = List<Account>.from(
      (json as _AegisPlainExport).db.map(
        (x) => Account(
          label: x.name,
          issuer: x.issuer,
          secret: x.info.secret,
          algorithm: Algorithm.values.firstWhere(
            (element) => element.name == x.info.algo,
          ),
          digits: x.info.digits,
          interval: x.info.period ?? 0,
          counter: x.info.counter ?? 0,
          isTOTP: x.type == 'totp',
          isGoogle: true,
          categories: x.groups,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ),
    );
    return Export(accounts: accounts);
  }
}
