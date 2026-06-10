import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app_assets.dart';

/// GetX Translations backed by JSON files in assets/lang/.
///
/// Load with [AppTranslations.load()] before runApp(), then pass the instance
/// to GetMaterialApp.translations.
class AppTranslations extends Translations {
  AppTranslations._({
    required Map<String, String> en,
    required Map<String, String> ar,
    required Map<String, String> hi,
    required Map<String, String> gu,
  })  : _en = en,
        _ar = ar,
        _hi = hi,
        _gu = gu;

  final Map<String, String> _en;
  final Map<String, String> _ar;
  final Map<String, String> _hi;
  final Map<String, String> _gu;

  static Future<AppTranslations> load() async {
    return AppTranslations._(
      en: await _loadJson(AppAssets.langEn),
      ar: await _loadJson(AppAssets.langAr),
      hi: await _loadJson(AppAssets.langHi),
      gu: await _loadJson(AppAssets.langGu),
    );
  }

  static Future<Map<String, String>> _loadJson(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': _en,
        'ar_SA': _ar,
        'hi_IN': _hi,
        'gu_IN': _gu,
      };
}
