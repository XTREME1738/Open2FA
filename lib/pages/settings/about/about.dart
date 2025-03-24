import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open2fa/i18n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsAboutPage extends ConsumerStatefulWidget {
  const SettingsAboutPage({super.key});

  @override
  ConsumerState<SettingsAboutPage> createState() =>
      _SettingsAboutPageState();
}

class _SettingsAboutPageState
    extends ConsumerState<SettingsAboutPage> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      packageInfo = await PackageInfo.fromPlatform();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('settings.about'))),
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
                title: Text(t('settings.about.github')),
                subtitle: Text(t('settings.about.github_desc')),
                trailing: Icon(Icons.open_in_new),
                onTap: () {
                  final url = 'https://github.com/XTREME1738/Open2FA';
                  launchUrlString(url);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.about.codeberg')),
                subtitle: Text(t('settings.about.codeberg_desc')),
                trailing: Icon(Icons.open_in_new),
                onTap: () {
                  final url = 'https://codeberg.org/XTREME/Open2FA';
                  launchUrlString(url);
                },
              ),
              // ListTile(
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   title: Text(t('settings.about.fdroid')),
              //   subtitle: Text(t('settings.about.fdroid_desc')),
              //   trailing: Icon(Icons.open_in_new),
              // ),
              // ListTile(
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   title: Text(t('settings.about.gplay')),
              //   subtitle: Text(t('settings.about.gplay_desc')),
              //   trailing: Icon(Icons.open_in_new),
              // ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.about.support')),
                subtitle: Text(t('settings.about.support_desc')),
                trailing: Icon(Icons.open_in_new),
                onTap: () {
                  final url = 'https://www.buymeacoffee.com/xtremedev';
                  launchUrlString(url);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.about.license')),
                subtitle: Text(t('settings.about.license_desc')),
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.about.version')),
                subtitle: Text('${t('app_title')} v${packageInfo?.version ?? ''} (${packageInfo?.buildNumber ?? ''})'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
