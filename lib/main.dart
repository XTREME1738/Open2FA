import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/pages/auth.dart';
import 'package:open2fa/pages/setup/setup.dart';
import 'package:open2fa/pages/vault.dart';
import 'package:open2fa/prefs.dart';

Logger logger = Logger(
  printer: PrettyPrinter(methodCount: 3, errorMethodCount: 8),
);

Future main() async {
  runApp(const ProviderScope(child: Open2FA()));
  await I18n.loadLanguageManifest();
  I18n.load('en_gb');
}

final themeModeProvider = StateProvider((ref) => ThemeMode.system);
final themeUseDynamicProvider = StateProvider((ref) => true);
final homeProvider = StateProvider<Widget>((ref) => Column());
final usingAuthProvider = StateProvider((ref) => true);
final useFlagSecureProvider = StateProvider((ref) => true);

class Open2FA extends ConsumerStatefulWidget {
  const Open2FA({super.key});

  @override
  ConsumerState<Open2FA> createState() => _Open2FAState();
}

class _Open2FAState extends ConsumerState<Open2FA> {
  @override
  void reassemble() {
    I18n.loadLanguageManifest().then((_) {
      I18n.load(I18n.currentLanguage);
    });
    super.reassemble();
  }

  @override
  void initState() {
    super.initState();
    () async {
      ref.read(usingAuthProvider.notifier).state =
          await Crypto.isAuthRequired();
      final homeNotifier = ref.read(homeProvider.notifier);
      final usingAuth = ref.watch(usingAuthProvider);
      await Prefs.init();
      final themeMode = Prefs.themeMode;
      final useDynamicColour = Prefs.useDynamicColour;
      ref.read(themeModeProvider.notifier).state = themeMode;
      ref.read(themeUseDynamicProvider.notifier).state = useDynamicColour;
      ref.read(useFlagSecureProvider.notifier).state =
          await Prefs.getFlagSecure();
      if (Prefs.setupComplete) {
        if (usingAuth) {
          homeNotifier.state = AuthPage();
        } else {
          try {
            await Crypto.unlockVaultNoAuth();
            homeNotifier.state = VaultPage();
          } catch (e) {
            logger.e(t('error.failed_to_unlock_vault'), error: e);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t('error.failed_to_unlock_vault'))),
              );
            }
          }
        }
      } else {
        homeNotifier.state = SetupPage();
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final useDynamicColour = ref.watch(themeUseDynamicProvider);
    final home = ref.watch(homeProvider);
    return DynamicColorBuilder(
      builder: (lightColourScheme, darkColourScheme) {
        final defaultSeed = Colors.deepPurple;
        final lightSeed =
            useDynamicColour
                ? (lightColourScheme?.primary ?? defaultSeed)
                : defaultSeed;
        final darkSeed =
            useDynamicColour
                ? (darkColourScheme?.primary ?? defaultSeed)
                : defaultSeed;
        return MaterialApp(
          title: t('app_title'),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: lightSeed),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: darkSeed,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),

          themeMode: themeMode,
          home: home,
        );
      },
    );
  }
}
