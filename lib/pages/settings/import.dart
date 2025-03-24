import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open2fa/i18n.dart';
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
                    if (context.mounted && await Export.import()) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t('settings.import_success'))),
                      );
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop(1);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t('error.import_failed', args: [e.toString()]),
                          ),
                        ),
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
                onTap: () async {
                  try {
                    if (await Export.import(
                      encrypted: true,
                      context: context,
                    )) {
                      if (context.mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t('settings.import_success'))),
                        );
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop(1);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t('error.import_fail', args: [e.toString()]),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
