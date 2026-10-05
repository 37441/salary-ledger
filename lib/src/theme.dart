import 'package:flutter/material.dart';

/// 7 套主题（对齐原 Android 版配色）。
class AppThemes {
  static const List<String> names = [
    '珊瑚红', '薄荷绿', '暖黄', '深色', '海盐蓝', '紫藤', '石墨灰',
  ];

  static const List<Color> primary = [
    Color(0xFFB94B49), Color(0xFF12A878), Color(0xFFF6821E),
    Color(0xFF517094), Color(0xFF2B84BC), Color(0xFF7E5FBE),
    Color(0xFF4A5460),
  ];

  static const List<Color> accent = [
    Color(0xFFD75F59), Color(0xFF36C68D), Color(0xFFFFB831),
    Color(0xFF7EA5CC), Color(0xFF4EB2CD), Color(0xFFB17DD3),
    Color(0xFF6B7989),
  ];

  /// 浅色主题页面背景统一为冷灰白 #F5F6F8（参考设计图 1），
  /// 深色主题（索引 3）保持深色。
  static const List<Color> page = [
    Color(0xFFF5F6F8), Color(0xFFF5F6F8), Color(0xFFF5F6F8),
    Color(0xFF12171F), Color(0xFFF5F6F8), Color(0xFFF5F6F8),
    Color(0xFFF5F6F8),
  ];

  static const List<Color> hero = [
    Color(0xFFFCE8E5), Color(0xFFDFF7EB), Color(0xFFFFEBC4),
    Color(0xFF222C39), Color(0xFFDEF1FA), Color(0xFFEDE2F8),
    Color(0xFFE2E8EE),
  ];

  static const List<Color> panel = [
    Colors.white, Colors.white, Colors.white,
    Color(0xFF1C232E), Colors.white, Colors.white, Colors.white,
  ];

  /// 主题 3 为深色。
  static bool isDark(int theme) => theme == 3;

  static const Color textMainLight = Color(0xFF191F26);
  static const Color textMutedLight = Color(0xFF7E8791);
  static const Color textMainDark = Color(0xFFEEF2F6);
  static const Color textMutedDark = Color(0xFFA6B0BC);

  static Color textMain(int theme) =>
      isDark(theme) ? textMainDark : textMainLight;

  static Color textMuted(int theme) =>
      isDark(theme) ? textMutedDark : textMutedLight;

  static Color border(int theme) =>
      isDark(theme) ? const Color(0xFF3F5B47) : const Color(0xFFE0E6DC);

  static Color softThemeColor(int theme) {
    switch (theme) {
      case 0:
        return const Color(0xFFF8E7E5);
      case 1:
        return const Color(0xFFDBF5EB);
      case 2:
        return const Color(0xFFFFEDCC);
      case 3:
        return const Color(0xFF2E3949);
      case 4:
        return const Color(0xFFDBEFF9);
      case 5:
        return const Color(0xFFEDE2F8);
      default:
        return const Color(0xFFE2E8EE);
    }
  }
}

/// 业务配色（与主题无关的固定语义色）。
class AppColors {
  /// 3 倍法定节假日：粉色标签。
  static const Color tripleHoliday = Color(0xFFE05E7D);

  /// 2 倍节假日（调休/假日剩余）：蓝色标签，与粉色、周末橙黄区分。
  static const Color doubleHoliday = Color(0xFF4A90D9);

  /// 周末 2 倍：橙黄。
  static const Color weekend = Color(0xFFD67B29);

  /// 调休上班日（补班日）：青绿，与粉色/蓝色/橙黄区分。
  static const Color workAdjustment = Color(0xFF2E9E8F);

  /// 休息日：灰。
  static const Color rest = Color(0xFF8B90A0);

  /// 纯请假：紫。
  static const Color leave = Color(0xFF7E66BE);

  /// 危险/删除。
  static const Color danger = Color(0xFFBE4343);

  /// 保存绿。
  static const Color save = Color(0xFF26C4A6);
}
