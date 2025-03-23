import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static ThemeMode themeMode = ThemeMode.system;
  static bool useDynamicColour = true;
  static String language = 'en';
  static bool setupComplete = false;
  static bool useFlagSecure = false;
  static bool hideCodes = false;
  static final _noScreenshot = NoScreenshot.instance;

  static Future<ThemeMode> _getTheme() async {
    final prefs = SharedPreferencesAsync();
    final themeMode = await prefs.getString('themeMode') ?? 'system';
    if (themeMode == 'light') {
      return ThemeMode.light;
    } else if (themeMode == 'dark') {
      return ThemeMode.dark;
    } else {
      return ThemeMode.system;
    }
  }

  static Future<bool> getUseDynamicColour() async {
    final prefs = SharedPreferencesAsync();
    return await prefs.getBool('useDynamicColour') ?? true;
  }

  static Future<String> getLanguage() async {
    final prefs = SharedPreferencesAsync();
    return await prefs.getString('language') ?? 'en';
  }

  static Future<bool> getSetupComplete() async {
    final prefs = SharedPreferencesAsync();
    return await prefs.getBool('setupComplete') ?? false;
  }

  static Future setSetupComplete(bool value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setBool('setupComplete', value);
    setupComplete = value;
  }

  static Future setLanguage(String value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString('language', value);
    language = value;
  }

  static Future setTheme(ThemeMode value) async {
    final theme = value.toString().split('.').last;
    final prefs = SharedPreferencesAsync();
    await prefs.setString('themeMode', theme);
    themeMode = value;
  }

  static Future setUseDynamicColour(bool value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setBool('useDynamicColour', value);
    useDynamicColour = value;
  }

  static Future getFlagSecure() async {
    final prefs = SharedPreferencesAsync();
    return await prefs.getBool('flagSecure') ?? false;
  }

  static Future setUseFlagSecure(bool value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setBool('flagSecure', value);
    if (value) {
      await _noScreenshot.screenshotOff();
    } else {
      await _noScreenshot.screenshotOn();
    }
    useFlagSecure = value;
  }

  static Future<bool> getHideCodes() async {
    final prefs = SharedPreferencesAsync();
    return await prefs.getBool('hideCodes') ?? false;
  }

  static Future setHideCodes(bool value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setBool('hideCodes', value);
    hideCodes = value;
  }

  static Future init() async {
    final themeModeFuture = _getTheme().then((value) => themeMode = value);
    final useDynamicColourFuture = getUseDynamicColour().then(
      (value) => useDynamicColour = value,
    );
    final languageFuture = getLanguage().then((value) => language = value);
    final setupCompleteFuture = getSetupComplete().then(
      (value) => setupComplete = value,
    );
    final flagSecureFuture = getFlagSecure().then((value) {
      useFlagSecure = value;
      if (value) {
        _noScreenshot.screenshotOff();
      } else {
        _noScreenshot.screenshotOn();
      }
    });
    final hideCodesFuture = getHideCodes().then((value) => hideCodes = value);
    return Future.wait([
      themeModeFuture,
      useDynamicColourFuture,
      languageFuture,
      setupCompleteFuture,
      flagSecureFuture,
      hideCodesFuture,
    ]);
  }
}
