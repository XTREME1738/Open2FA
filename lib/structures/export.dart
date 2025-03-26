import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open2fa/database.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/pages/settings/export_encrypted.dart';
import 'package:open2fa/structures/account.dart';

abstract class ExportBase {
  Future<Export> generate(
    String fromJsonString, {
    String? decryptionPassword,
  }) => throw UnimplementedError();
  static bool checkFormatString(String jsonString) =>
      throw UnimplementedError();
}

class Export {
  List<Account> accounts;
  Export({required this.accounts});

  static Future<String> _requestPassword(BuildContext context) async {
    if (context.mounted) {
      return await Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => const SettingsEncryptedExportPage(),
            ),
          )
          .then((value) async {
            if (value != null) {
              return value as String;
            } else {
              throw ArgumentError(t('error.password_required'));
            }
          })
          .catchError((e) {
            logger.e(t('error.import_fail', args: ['']), error: e);
            throw e;
          });
    }
    throw ArgumentError(t('error.password_required'));
  }

  static Future import(
    ExportBase exportType,
    BuildContext context, {
    bool encrypted = false,
  }) async {
    try {
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
        Export export;
        if (encrypted) {
          // ignore: use_build_context_synchronously
          final password = await _requestPassword(context);
          export = await exportType.generate(
            json,
            decryptionPassword: password,
          );
        } else {
          export = await exportType.generate(json);
        }
        for (final account in export.accounts) {
          DatabaseManager.addOrUpdateAccount(await account.encrypt());
        }
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t('settings.import_success'))));
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop(1);
        }
      }
    } catch (e) {
      logger.e(t('error.import_fail', args: ['']), error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('error.import_fail', args: [e.toString()]))),
        );
      }
    }
  }
}
