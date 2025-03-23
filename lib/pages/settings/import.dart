import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open2fa/database.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/structures/export.dart';

class SettingsImportPage extends ConsumerWidget {
  const SettingsImportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(t('settings.import'))),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.import_open2fa')),
                subtitle: Text(t('settings.import_open2fa_desc')),
                onTap: () async {
                  try {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
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
                      final export = Export.fromJson(json);
                      for (final account in export.accounts) {
                        DatabaseManager.addOrUpdateAccount(
                          await account.encrypt(),
                        );
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t('settings.import_success'))),
                        );
                        Navigator.of(context).pop(1);
                      }
                    }
                  } catch (e) {
                    logger.e(t('error.import_fail'), error: e);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t('error.import_fail'))),
                      );
                    }
                  }
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.import_encrypted_open2fa')),
                subtitle: Text(t('settings.import_encrypted_open2fa_desc')),
                trailing: Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
