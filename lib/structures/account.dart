import 'dart:convert';

import 'package:open2fa/crypto.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/structures/encrypted_account.dart';
import 'package:otp/otp.dart';

class Account {
  final int? id;
  final String label;
  final String issuer;
  final String secret;
  final Algorithm algorithm;
  final int digits;
  final int interval;
  final int counter;
  final bool isTOTP;
  final bool isGoogle;
  final List<String> categories;
  final DateTime updatedAt;
  final DateTime createdAt;

  String code = '000000';
  String nextCode = '000000';

  void _updateTOTP() {
    if (!isTOTP) {
      // Just in case
      _updateHOTP();
      return;
    }
    code = OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      interval: interval,
      length: digits,
      algorithm: algorithm,
      isGoogle: isGoogle,
    );
    nextCode = OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch + interval * 1000,
      interval: interval,
      length: digits,
      algorithm: algorithm,
      isGoogle: isGoogle,
    );
  }

  void _updateHOTP() {
    if (isTOTP) {
      // We never know
      _updateTOTP();
      return;
    }
    code = OTP.generateHOTPCodeString(
      secret,
      counter,
      length: digits,
      algorithm: algorithm,
      isGoogle: isGoogle,
    );
    nextCode = OTP.generateHOTPCodeString(
      secret,
      counter + 1,
      length: digits,
      algorithm: algorithm,
      isGoogle: isGoogle,
    );
  }

  void updateCodes() {
    if (isTOTP) {
      _updateTOTP();
    } else {
      _updateHOTP();
    }
  }

  Account({
    this.id = -1,
    required this.label,
    required this.issuer,
    required this.secret,
    this.algorithm = Algorithm.SHA1,
    this.digits = 6,
    this.interval = 30,
    this.counter = 0,
    this.isTOTP = true,
    this.isGoogle = true,
    this.categories = const [],
    required this.updatedAt,
    required this.createdAt,
  });

  static Account fromJsonString(String jsonString) {
    return fromJson(jsonDecode(jsonString));
  }

  static Account fromJson(Map<String, dynamic> json) {
    final algorithmExists = Algorithm.values.any(
      (element) => element.name == json['algorithm'],
    );
    if (!algorithmExists) {
      throw ArgumentError(
        t('error.invalid_algorithm', args: [json['algorithm']]),
      );
    }
    try {
      return Account(
        label: json['label'] as String,
        issuer: json['issuer'] as String,
        secret: json['secret'] as String,
        algorithm: Algorithm.values.firstWhere(
          (element) => element.name == json['algorithm'],
        ),
        digits: json['digits'],
        interval: json['interval'] ?? 0,
        counter: json['counter'] ?? 0,
        isTOTP: json['type'] == 'totp',
        isGoogle: json['google'],
        categories: (json['categories'] as List<dynamic>).cast<String>(),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    } catch (e) {
      throw ArgumentError(t('error.invalid_account_format', args: [e]));
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'issuer': issuer,
      'secret': secret,
      'algorithm': algorithm.name,
      'type': isTOTP ? 'totp' : 'hotp',
      'digits': digits,
      'interval': interval,
      'counter': counter,
      'google': isGoogle,
      'categories': categories,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() {
    final map = toMap();
    if (isTOTP) {
      map.remove('counter');
    } else {
      map.remove('interval');
    }
    return json.encode(map);
  }

  Future<EncryptedAccount> encrypt() async {
    final jsonData = json.encode({
      'label': label,
      'issuer': issuer,
      'secret': secret,
      'categories': categories,
    });
    final encryptedData = await Crypto.encrypt(jsonData).catchError((e) {
      throw ArgumentError(t('error.encrypt_failed', args: [e]));
    });
    return EncryptedAccount(
      id: id,
      encryptedData: base64Encode(encryptedData.cipherText),
      algorithm: algorithm,
      digits: digits,
      interval: interval,
      counter: counter,
      isTOTP: isTOTP,
      isGoogle: isGoogle,
      mac: base64Encode(encryptedData.mac.bytes),
      nonce: base64Encode(encryptedData.nonce),
      updatedAt: updatedAt,
      createdAt: createdAt,
    );
  }
}
