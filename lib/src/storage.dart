import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// 数据存储：SharedPreferences + 旧版（原 Android 版）数据迁移。
class AppStore {
  static const String _kBase = 'baseSalary';
  static const String _kPerf = 'performanceRate';
  static const String _kTheme = 'theme';
  static const String _kRecords = 'records';
  static const String _kDeductions = 'deductions';
  static const String _kSubsidies = 'subsidies';
  static const String _kMigrated = 'legacy_migrated';
  static const String _kFontScale = 'fontScale';
  static const String _kGlassNav = 'glassNav';
  static const String _kGlassOpacity = 'glassOpacity';

  /// 主题索引变化通知（驱动整个 App 换肤）。
  final ValueNotifier<int> themeNotifier = ValueNotifier<int>(0);

  /// 字体缩放变化通知（驱动全局文字大小）。
  final ValueNotifier<double> fontScaleNotifier = ValueNotifier<double>(1.0);

  int _theme = 0;
  int get theme => _theme;
  set theme(int value) {
    if (_theme == value) return;
    _theme = value;
    themeNotifier.value = value;
  }

  /// 全局字体缩放（设置页调节）。
  double _fontScale = 1.0;
  double get fontScale => _fontScale;
  set fontScale(double value) {
    if ((_fontScale - value).abs() < 0.001) return;
    _fontScale = value;
    fontScaleNotifier.value = value;
  }

  /// 液态玻璃导航栏开关。
  bool glassNav = true;

  /// 液态玻璃透明度（0.3~0.9）。
  final ValueNotifier<double> glassOpacityNotifier = ValueNotifier<double>(0.68);
  double _glassOpacity = 0.68;
  double get glassOpacity => _glassOpacity;
  set glassOpacity(double value) {
    if ((_glassOpacity - value).abs() < 0.01) return;
    _glassOpacity = value;
    glassOpacityNotifier.value = value;
  }

  double baseSalary = 3000.0;
  double performanceRate = 25.0;
  Map<String, DayRecord> records = {};
  Map<String, Map<String, double>> deductions = {};
  Map<String, Map<String, double>> subsidies = {};

  late SharedPreferences _prefs;
  static const MethodChannel _channel =
      MethodChannel('com.salary.ledger/legacy');

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    final migrated = _prefs.getBool(_kMigrated) ?? false;
    if (!migrated) {
      await _tryMigrate();
      await _prefs.setBool(_kMigrated, true);
    }

    baseSalary = _prefs.getDouble(_kBase) ?? 3000.0;
    performanceRate = _prefs.getDouble(_kPerf) ?? 25.0;
    _fontScale = _prefs.getDouble(_kFontScale) ?? 1.0;
    glassNav = _prefs.getBool(_kGlassNav) ?? true;
    _glassOpacity = _prefs.getDouble(_kGlassOpacity) ?? 0.68;
    glassOpacityNotifier.value = _glassOpacity;
    fontScaleNotifier.value = _fontScale;
    _theme = _prefs.getInt(_kTheme) ?? 0;
    if (_theme < 0 || _theme >= 7) _theme = 0;
    themeNotifier.value = _theme;

    records = _decodeRecords(_prefs.getString(_kRecords) ?? '{}');
    deductions = _decodeFinance(_prefs.getString(_kDeductions) ?? '{}');
    subsidies = _decodeFinance(_prefs.getString(_kSubsidies) ?? '{}');
  }

  Future<void> save() async {
    _prefs.setDouble(_kBase, baseSalary);
    _prefs.setDouble(_kPerf, performanceRate);
    _prefs.setDouble(_kFontScale, fontScale);
    _prefs.setBool(_kGlassNav, glassNav);
    _prefs.setDouble(_kGlassOpacity, _glassOpacity);
    _prefs.setInt(_kTheme, theme);
    _prefs.setString(_kRecords, _encodeRecords());
    _prefs.setString(_kDeductions, _encodeFinance(deductions));
    _prefs.setString(_kSubsidies, _encodeFinance(subsidies));
  }

  /// 尝试从原 Android 版（com.salary.ledger，SharedPreferences
  /// salary_ledger_data）迁移数据。原版无数据或通道不可用则静默跳过。
  Future<void> _tryMigrate() async {
    Map<Object?, Object?>? legacy;
    try {
      legacy = await _channel.invokeMapMethod<Object?, Object?>('readLegacyData');
    } catch (_) {
      return; // 新安装、无旧数据。
    }
    if (legacy == null) return;

    final rawRecords = legacy['records'] as String? ?? '';
    final rawBase = legacy['baseSalary'] as double?;
    final rawPerf = legacy['performanceRate'] as double?;
    final rawTheme = legacy['theme'] as int?;

    if (rawRecords.isEmpty && rawBase == null) return;

    if (rawBase != null) baseSalary = rawBase;
    if (rawPerf != null) performanceRate = rawPerf;
    if (rawTheme != null && rawTheme >= 0 && rawTheme < 7) theme = rawTheme;
    records = _decodeRecords(rawRecords);
    deductions = _decodeFinance(legacy['deductions'] as String? ?? '{}');
    subsidies = _decodeFinance(legacy['subsidies'] as String? ?? '{}');
    await save();
  }

  Map<String, DayRecord> _decodeRecords(String raw) {
    final Map<String, DayRecord> out = {};
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      obj.forEach((key, value) {
        out[key] = DayRecord.fromJson((value as Map).cast<String, dynamic>());
      });
    } catch (_) {}
    return out;
  }

  String _encodeRecords() {
    final obj = <String, dynamic>{};
    records.forEach((key, r) => obj[key] = r.toJson());
    return jsonEncode(obj);
  }

  Map<String, Map<String, double>> _decodeFinance(String raw) {
    final out = <String, Map<String, double>>{};
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      obj.forEach((ym, items) {
        final map = <String, double>{};
        (items as Map).forEach((name, v) {
          map[name.toString()] = (v as num).toDouble();
        });
        out[ym] = map;
      });
    } catch (_) {}
    return out;
  }

  String _encodeFinance(Map<String, Map<String, double>> root) {
    final obj = <String, dynamic>{};
    root.forEach((ym, items) => obj[ym] = items);
    return jsonEncode(obj);
  }

  /// 导出全部数据为 JSON 字符串（含底薪/绩效/主题/记录/扣补贴）。
  String exportData() => jsonEncode({
        'baseSalary': baseSalary,
        'performanceRate': performanceRate,
        'theme': theme,
        'fontScale': fontScale,
        'glassNav': glassNav,
        'glassOpacity': glassOpacity,
        'records': {for (final e in records.entries) e.key: e.value.toJson()},
        'deductions': deductions,
        'subsidies': subsidies,
      });

  /// 从 JSON 字符串恢复数据；格式非法时抛出 [FormatException]。
  void importData(String raw) {
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      baseSalary = (obj['baseSalary'] as num?)?.toDouble() ?? 3000.0;
      performanceRate = (obj['performanceRate'] as num?)?.toDouble() ?? 25.0;
      final t = obj['theme'];
      if (t is int && t >= 0 && t < 7) theme = t;
      fontScale = (obj['fontScale'] as num?)?.toDouble() ?? 1.0;
      glassNav = obj['glassNav'] as bool? ?? true;
      _glassOpacity = (obj['glassOpacity'] as num?)?.toDouble() ?? 0.68;
      glassOpacityNotifier.value = _glassOpacity;
      records = _decodeRecords(jsonEncode(obj['records'] ?? {}));
      deductions = _decodeFinance(jsonEncode(obj['deductions'] ?? {}));
      subsidies = _decodeFinance(jsonEncode(obj['subsidies'] ?? {}));
    } catch (_) {
      throw const FormatException('备份文件格式无效');
    }
  }

  static String dateKey(int y, int m, int d) => '$y-${two(m)}-${two(d)}';

  static String monthKey(int y, int m) => '$y-${two(m)}';

  static String two(int v) => v < 10 ? '0$v' : '$v';
}