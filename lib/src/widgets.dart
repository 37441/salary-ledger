import 'package:flutter/material.dart';

import 'holidays.dart';
import 'models.dart';
import 'theme.dart';

/// 数字格式化。
class Fmt {
  static String money(double v) => v.toStringAsFixed(2);

  static String hours(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

/// 取某一主题下的颜色。
Color primary(BuildContext c) =>
    AppThemes.primary[AppState.of(c).theme];
Color accent(BuildContext c) =>
    AppThemes.accent[AppState.of(c).theme];
Color pageColor(BuildContext c) =>
    AppThemes.page[AppState.of(c).theme];
Color heroColor(BuildContext c) =>
    AppThemes.hero[AppState.of(c).theme];
Color panelColor(BuildContext c) =>
    AppThemes.panel[AppState.of(c).theme];
Color textMain(BuildContext c) =>
    AppThemes.textMain(AppState.of(c).theme);
Color textMuted(BuildContext c) =>
    AppThemes.textMuted(AppState.of(c).theme);
Color border(BuildContext c) =>
    AppThemes.border(AppState.of(c).theme);
Color softPrimary(BuildContext c) =>
    AppThemes.softThemeColor(AppState.of(c).theme);

bool isDarkTheme(BuildContext c) =>
    AppThemes.isDark(AppState.of(c).theme);

/// 混合颜色：amount 为 overlay 占比（0~1）。
Color blendColor(Color base, Color overlay, double amount) {
  final r = base.r * (1 - amount) + overlay.r * amount;
  final g = base.g * (1 - amount) + overlay.g * amount;
  final b = base.b * (1 - amount) + overlay.b * amount;
  return Color.from(alpha: 1, red: r, green: g, blue: b);
}

/// 记录状态色：休息灰 / 纯请假紫 / 3倍粉 / 2倍节假日蓝 / 周末橙黄 / 其余主题色。
/// 节假日与补班日优先按语义色，保证填写内容前后颜色一致（不冲突）。
Color recordStateColor(
    BuildContext c, int year, int month, int day, DayRecord? rec) {
  if (rec == null) {
    // 无记录：补班青绿、3 倍节假日粉、2 倍节假日蓝、周末橙、工作日主题色。
    if (HolidayDb.isWorkAdjustment(year, month, day)) return AppColors.workAdjustment;
    if (HolidayDb.isTripleHoliday(year, month, day)) return AppColors.tripleHoliday;
    if (HolidayDb.isDoubleHoliday(year, month, day)) return AppColors.doubleHoliday;
    if (HolidayDb.isWeekend(year, month, day)) return AppColors.weekend;
    return textMain(c);
  }
  if (rec.rest) return AppColors.rest;
  if (rec.leaveHours > 0 && rec.hours <= 0) return AppColors.leave;
  // 节假日/补班语义色优先于倍率色，填写前后一致。
  if (HolidayDb.isWorkAdjustment(year, month, day)) return AppColors.workAdjustment;
  if (HolidayDb.isTripleHoliday(year, month, day)) return AppColors.tripleHoliday;
  if (HolidayDb.isDoubleHoliday(year, month, day)) return AppColors.doubleHoliday;
  final rate = rec.rateOverride > 0
      ? rec.rateOverride
      : HolidayDb.defaultRate(year, month, day);
  if (rate == 3.0) return AppColors.tripleHoliday;
  if (rate == 2.0) return AppColors.weekend;
  return primary(c);
}

/// 日历格子背景填充色（淡色）。
Color recordFillColor(BuildContext c, Color state) =>
    blendColor(panelColor(c), state, isDarkTheme(c) ? 0.22 : 0.14);

/// 统一轻提示：居中偏下的深色圆角卡片（替换系统 SnackBar，风格与整体一致）。
void showAppToast(BuildContext context, String msg) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 48,
      right: 48,
      bottom: MediaQuery.of(context).size.height * 0.38,
      child: IgnorePointer(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1500), () {
    if (entry.mounted) entry.remove();
  });
}

/// 顶部系统状态栏区域（Android 15 强制 edge-to-edge，需自行绘制底色）。
class StatusBarPad extends StatelessWidget {
  final Color color;

  const StatusBarPad(this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      height: MediaQuery.of(context).padding.top,
    );
  }
}

/// 圆角卡片容器（大圆角扁平风，参考设计图：16-24px）。
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final BorderRadius radius;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.color,
    this.radius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? panelColor(context),
        borderRadius: radius,
      ),
      child: child,
    );
  }
}

/// 面板文本行。
class PanelText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final TextAlign align;

  const PanelText(this.text,
      {super.key, this.size = 14, required this.color, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: size, color: color, height: 1.3),
      textAlign: align,
    );
  }
}

/// 标签 + 数值块。
class InfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const InfoBlock(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelText(label, size: 11, color: textMuted(context)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: PanelText(value, size: 14, color: textMain(context)),
          ),
        ],
      ),
    );
  }
}

/// 一行等分布局（窄屏自动换为纵向）。
class AdaptiveRow extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const AdaptiveRow(this.children, {super.key, this.gap = 8});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 420;
    if (narrow) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// 小按钮。
class SmallButton extends StatelessWidget {
  final String text;
  final Color bg;
  final VoidCallback onTap;
  final Color? textColor;
  final double fontSize;
  final double radius;

  const SmallButton(this.text, this.bg, this.onTap,
      {super.key, this.textColor, this.fontSize = 13, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor ?? textMain(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero 渐变卡片。
class HeroCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;

  const HeroCard(this.label, this.value, this.detail, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [heroColor(context), panelColor(context)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelText(label, size: 12, color: textMuted(context)),
          PanelText(value, size: 24, color: textMain(context)),
          PanelText(detail, size: 12, color: primary(context)),
        ],
      ),
    );
  }
}

/// 汇总指标（label 上、value 下，居中）。
class SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const SummaryMetric(this.label, this.value, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PanelText(label, size: 11, color: textMuted(context), align: TextAlign.center),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: PanelText(value,
              size: 15,
              color: valueColor ?? textMain(context),
              align: TextAlign.center),
        ),
      ],
    );
  }
}

/// 圆角小指标卡（年度汇总/工资信息网格共用）。
class YearMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const YearMetric(this.label, this.value, this.valueColor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: panelColor(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelText(label, size: 11, color: textMuted(context), align: TextAlign.center),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: PanelText(value, size: 15, color: valueColor, align: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// 居中文本。
class CenterText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;

  const CenterText(this.text, {super.key, this.size = 14, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: size, color: color),
      textAlign: TextAlign.center,
    );
  }
}

/// 供 UI 取当前应用状态（主题等）的 InheritedWidget。
class AppState extends InheritedWidget {
  final int theme;

  const AppState({super.key, required this.theme, required super.child});

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppState>()!;

  @override
  bool updateShouldNotify(AppState oldWidget) => oldWidget.theme != theme;
}
