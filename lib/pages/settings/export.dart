import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/pages/settings/export_encrypted.dart';
import 'package:open2fa/structures/export.dart';

class SettingsExportSheet extends ConsumerWidget {
  const SettingsExportSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        shrinkWrap: true,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(t('settings.export'), style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(t('settings.export_encrypted')),
            subtitle: Text(t('settings.export_encrypted_desc')),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => const SettingsEncryptedExportPage(
                        encryptedExport: true,
                      ),
                ),
              );
            },
          ),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(t('settings.export_unencrypted')),
            subtitle: Text(t('settings.export_unencrypted_desc')),
            trailing: Icon(Icons.chevron_right),
            onTap: () async {
              try {
                final export = await Export.generate();
                String? outputFile = await FilePicker.platform.saveFile(
                  allowedExtensions: ['json'],
                  type: FileType.custom,
                  fileName:
                      '${t('app_title')}_${DateTime.now().toIso8601String()}.json',
                  initialDirectory: '/storage/emulated/0',
                  bytes: export.toJsonBytes(),
                );
                if (context.mounted && outputFile != null) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('settings.export_success'))),
                  );
                }
              } catch (e) {
                logger.e(t('error.export_fail'), error: e);
                if (context.mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('error.export_fail'))),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
