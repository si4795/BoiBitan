import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ChangeNotifier {
  static const String _localeKey = 'app_user_locale';
  Locale _currentLocale = const Locale('bn');

  Locale get currentLocale => _currentLocale;
  bool get isBengali => _currentLocale.languageCode == 'bn';

  LocaleNotifier() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localeKey);
    if (savedCode != null && (savedCode == 'bn' || savedCode == 'en')) {
      _currentLocale = Locale(savedCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (newLocale.languageCode != 'bn' && newLocale.languageCode != 'en') {
      return;
    }
    if (_currentLocale == newLocale) {
      return;
    }

    _currentLocale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
  }

  Future<void> toggleLocale() async {
    if (_currentLocale.languageCode == 'bn') {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('bn'));
    }
  }
}
