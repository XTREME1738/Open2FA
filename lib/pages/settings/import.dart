import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/structures/export.dart';
import 'package:open2fa/structures/importing/aegis.dart';
import 'package:open2fa/structures/importing/open2fa.dart';

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
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  await Export.import(
                    Open2FAExport(),
                    context,
                    encrypted: true,
                  );
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
                  await Export.import(
                    Open2FAExport(),
                    context,
                    encrypted: true,
                  );
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.import_aegis')),
                subtitle: Text(t('settings.import_aegis_desc')),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  await Export.import(
                    AegisExport(),
                    context,
                  );
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.import_encrypted_aegis')),
                subtitle: Text(t('settings.import_encrypted_aegis_desc')),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  await Export.import(
                    AegisExport(),
                    context,
                    encrypted: true,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
