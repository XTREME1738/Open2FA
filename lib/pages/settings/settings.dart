import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/pages/settings/about.dart';
import 'package:open2fa/pages/settings/export.dart';
import 'package:open2fa/pages/settings/import.dart';
import 'package:open2fa/pages/vault.dart';
import 'package:open2fa/prefs.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

final autoLockTimeoutProvider = StateProvider((ref) => -1);

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _biometricsEnabled = false;
  bool _authEnabled = false;

  @override
  void initState() {
    super.initState();
    () async {
      _authEnabled = await Crypto.isAuthRequired();
      _biometricsEnabled = await Crypto.areBiometricsEnabled();
      ref.read(autoLockTimeoutProvider.notifier).state =
          await Prefs.getAutoLockTimeout();
      setState(() {});
    }();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final themeUseDynamic = ref.watch(themeUseDynamicProvider);
    final useFlagSecure = ref.watch(useFlagSecureProvider);
    final hideCodes = ref.watch(hideCodesProvider);
    final autoLockTimeout = ref.watch(autoLockTimeoutProvider);
    final autoLockString =
        autoLockTimeout == -1
            ? t('settings.auth_auto_lock_never')
            : autoLockTimeout == 0
            ? t('settings.auth_auto_lock_always')
            : '$autoLockTimeout ${t('settings.auth_auto_lock_minutes')}';
    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(t('theme')),
              subtitle: Text(t('settings.theme_desc')),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    themeMode == ThemeMode.system
                        ? t('settings.theme_system')
                        : themeMode == ThemeMode.light
                        ? t('settings.theme_light')
                        : t('settings.theme_dark'),
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(t('settings.select_theme')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            title: Text(t('settings.theme_light')),
                            value: ThemeMode.light,
                            groupValue: themeMode,
                            onChanged: (value) {
                              ref.read(themeModeProvider.notifier).state =
                                  value as ThemeMode;
                              Prefs.setTheme(value);
                              Navigator.of(context).pop();
                            },
                          ),
                          RadioListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            title: Text(t('settings.theme_dark')),
                            value: ThemeMode.dark,
                            groupValue: themeMode,
                            onChanged: (value) {
                              ref.read(themeModeProvider.notifier).state =
                                  value as ThemeMode;
                              Prefs.setTheme(value);
                              Navigator.of(context).pop();
                            },
                          ),
                          RadioListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            title: Text(t('settings.theme_system')),
                            value: ThemeMode.system,
                            groupValue: themeMode,
                            onChanged: (value) {
                              ref.read(themeModeProvider.notifier).state =
                                  value as ThemeMode;
                              Prefs.setTheme(value);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            if (Platform.isAndroid)
              SwitchListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.theme_material_you')),
                subtitle: Text(t('settings.theme_material_you_desc')),
                value: themeUseDynamic,
                onChanged: (value) {
                  ref.read(themeUseDynamicProvider.notifier).state = value;
                  Prefs.setUseDynamicColour(value);
                },
              ),
            Divider(),
            if (_authEnabled) ...[
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.auth_auto_lock')),
                subtitle: Text(t('settings.auth_auto_lock_desc')),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(autoLockString, style: TextStyle(fontSize: 16)),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(t('settings.auth_auto_lock')),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              title: Text(t('settings.auth_auto_lock_never')),
                              value: -1,
                              groupValue: autoLockTimeout,
                              onChanged: (value) {
                                ref
                                    .read(autoLockTimeoutProvider.notifier)
                                    .state = value as int;
                                Prefs.setAutoLock(value);
                                Navigator.of(context).pop();
                              },
                            ),
                            RadioListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              title: Text(t('settings.auth_auto_lock_always')),
                              value: 0,
                              groupValue: autoLockTimeout,
                              onChanged: (value) {
                                ref
                                    .read(autoLockTimeoutProvider.notifier)
                                    .state = value as int;
                                Prefs.setAutoLock(value);
                                Navigator.of(context).pop();
                              },
                            ),
                            for (final minutes in [1, 5, 10, 15, 30, 60])
                              RadioListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                title: Text(
                                  '$minutes ${t('settings.auth_auto_lock_minutes')}',
                                ),
                                value: minutes,
                                groupValue: autoLockTimeout,
                                onChanged: (value) {
                                  ref
                                      .read(autoLockTimeoutProvider.notifier)
                                      .state = value as int;
                                  Prefs.setAutoLock(value);
                                  Navigator.of(context).pop();
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              SwitchListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('settings.auth_use_biometrics')),
                subtitle: Text(t('settings.auth_use_biometrics_desc')),
                value: _biometricsEnabled,
                onChanged: (value) async {
                  if (!value) {
                    setState(() {
                      _biometricsEnabled = false;
                    });
                    return;
                  }
                  try {
                    await Crypto.checkBiometricsAvailable();
                    final localAuth = LocalAuthentication();
                    final authenticated = await localAuth.authenticate(
                      localizedReason: t('settings.auth_enable_biometrics'),
                      options: AuthenticationOptions(
                        sensitiveTransaction: true,
                        stickyAuth: true,
                        biometricOnly: true,
                      ),
                    );
                    await Crypto.setBiometricsEnabled(authenticated);
                    setState(() {
                      _biometricsEnabled = authenticated;
                    });
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        // ignore: use_build_context_synchronously
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
              ),
            ],
            SwitchListTile(
              value: useFlagSecure,
              onChanged: (value) {
                ref.read(useFlagSecureProvider.notifier).state = value;
                Prefs.setUseFlagSecure(value);
              },
              title: Text(t('settings.disable_screenshots')),
              subtitle: Text(t('settings.disable_screenshots_desc')),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SwitchListTile(
              value: hideCodes,
              onChanged: (value) {
                ref.read(hideCodesProvider.notifier).state = value;
                Prefs.setHideCodes(value);
              },
              title: Text(t('settings.hide_codes')),
              subtitle: Text(t('settings.hide_codes_desc')),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Divider(),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(t('settings.export')),
              subtitle: Text(t('settings.export_desc')),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                //   return SettingsExportPage();
                // }));
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return SettingsExportSheet();
                  },
                );
              },
            ),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(t('settings.import')),
              subtitle: Text(t('settings.import_desc')),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => SettingsImportPage(),
                      ),
                    )
                    .then((value) {
                      if (value == 1 && mounted) {
                        Navigator.of(context).pop(1);
                      }
                    });
              },
            ),
            Divider(),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(t('settings.about')),
              subtitle: Text(t('settings.about_desc')),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SettingsAboutPage()),
                );
              },
            ),
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
          ],
        ),
      ),
    );
  }
}
