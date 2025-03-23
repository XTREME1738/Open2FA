import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/pages/setup/auth.dart';
import 'package:open2fa/prefs.dart';

class SetupThemePage extends ConsumerStatefulWidget {
  const SetupThemePage({super.key});

  @override
  ConsumerState<SetupThemePage> createState() => _SetupThemePageState();
}

class _SetupThemePageState extends ConsumerState<SetupThemePage> {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final useDynamicColourNotifier = ref.read(themeUseDynamicProvider.notifier);
    final useDynamicColour = ref.watch(themeUseDynamicProvider);
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t('settings.select_theme'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                t('settings.theme_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              RadioListTile(
                title: Text(t('settings.theme_light')),
                value: ThemeMode.light,
                groupValue: themeMode,
                onChanged: (value) {
                  themeNotifier.state = value as ThemeMode;
                  Prefs.setTheme(value);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              RadioListTile(
                title: Text(t('settings.theme_dark')),
                value: ThemeMode.dark,
                groupValue: themeMode,
                onChanged: (value) {
                  themeNotifier.state = value as ThemeMode;
                  Prefs.setTheme(value);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              RadioListTile(
                title: Text(t('settings.theme_system')),
                value: ThemeMode.system,
                groupValue: themeMode,
                onChanged: (value) {
                  themeNotifier.state = value as ThemeMode;
                  Prefs.setTheme(value);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SwitchListTile(
                title: Text(t('settings.theme_material_you')),
                value: useDynamicColour,
                onChanged: (value) {
                  useDynamicColourNotifier.state = value;
                  Prefs.setUseDynamicColour(value);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                heroTag: null,
                child: Icon(Icons.arrow_back),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) {
                        return SetupAuthPage();
                      },
                    ),
                  );
                },
                heroTag: null,
                child: Icon(Icons.arrow_forward),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
