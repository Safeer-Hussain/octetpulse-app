import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences? _prefs;

  ThemeCubit([this._prefs]) : super(_initialTheme(_prefs));

  static ThemeMode _initialTheme(SharedPreferences? prefs) {
    if (prefs == null) return ThemeMode.dark;
    final saved = prefs.getString(AppConstants.prefThemeMode);
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.dark;
  }

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _prefs?.setString(AppConstants.prefThemeMode, next == ThemeMode.light ? 'light' : 'dark');
    emit(next);
  }

  void setTheme(ThemeMode mode) {
    _prefs?.setString(AppConstants.prefThemeMode, mode == ThemeMode.light ? 'light' : 'dark');
    emit(mode);
  }
}
