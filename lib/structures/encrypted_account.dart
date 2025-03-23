import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/structures/account.dart';
import 'package:otp/otp.dart';

class EncryptedAccount extends Account {
  final String nonce;
  final String mac;

  @override
  get label =>
      throw UnsupportedError(t('error.encrypted_field', args: ['label']));
  @override
  get issuer =>
      throw UnsupportedError(t('error.encrypted_field', args: ['issuer']));
  @override
  get secret =>
      throw UnsupportedError(t('error.encrypted_field', args: ['secret']));
  @override
  get categories =>
      throw UnsupportedError(t('error.encrypted_field', args: ['categories']));

  final String encryptedData;

  EncryptedAccount({
    super.id,
    required this.encryptedData,
    required super.algorithm,
    required super.digits,
    required super.interval,
    required super.counter,
    required super.isTOTP,
    required super.isGoogle,
    required this.nonce,
    required this.mac,
    required super.updatedAt,
    required super.createdAt,
  }) : super(label: '', issuer: '', secret: '', categories: const []);

  factory EncryptedAccount.fromJson(Map<String, dynamic> json) {
    return EncryptedAccount(
      encryptedData: json['encrypted_data'] as String,
      algorithm: Algorithm.values[json['algorithm'] as int],
      digits: json['digits'] as int,
      interval: json['interval'] as int,
      counter: json['counter'] as int,
      isTOTP: json['totp'] as int == 1,
      isGoogle: json['google'] as int == 1,
      nonce: json['nonce'] as String,
      mac: json['mac'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Future<Account> decrypt() async {
    final encrypted = SecretBox(
      base64Decode(encryptedData),
      nonce: base64Decode(nonce),
      mac: Mac(base64Decode(mac)),
    );
    final decryptedData = await Crypto.decrypt(encrypted);
    final decrypted = json.decode(decryptedData);
    final decryptedLabel = decrypted['label'] as String;
    final decryptedIssuer = decrypted['issuer'] as String;
    final decryptedSecret = decrypted['secret'] as String;
    final decryptedCategories = decrypted['categories'] as List<dynamic>;
    return Account(
      id: super.id,
      label: decryptedLabel,
      issuer: decryptedIssuer,
      secret: decryptedSecret,
      algorithm: super.algorithm,
      digits: super.digits,
      interval: super.interval,
      counter: super.counter,
      isTOTP: super.isTOTP,
      isGoogle: super.isGoogle,
      categories: decryptedCategories.cast<String>(),
      updatedAt: super.updatedAt,
      createdAt: super.createdAt,
    );
  }
}
