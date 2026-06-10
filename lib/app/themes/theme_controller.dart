import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Persists and applies the user's light/dark/system theme preference.
///
/// Registered as a permanent GetX service in InitialBinding. Preference is
/// stored locally with GetStorage so it survives app restarts.
class ThemeController extends GetxController {
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  static const _key = 'theme_mode';

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    GetStorage().write(_key, mode.name);
  }

  void _loadFromStorage() {
    final saved = GetStorage().read<String>(_key);
    if (saved == null) return;
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
    themeMode.value = mode;
    Get.changeThemeMode(mode);
  }
}
