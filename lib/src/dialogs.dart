import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'holidays.dart';
import 'models.dart';
import 'storage.dart';
import 'theme.dart';
import 'widgets.dart';

/// 工时弹窗与批量面板共用的快捷录入选项。
const List<({String label, double hours, double rate})> kQuickOptions = [
  (label: '2h · 1.5倍', hours: 2.0, rate: 1.5),
  (label: '3h · 1.5倍', hours: 3.0, rate: 1.5),
  (label: '10h · 2倍', hours: 10.0, rate: 2.0),
  (label: '11h · 2倍', hours: 11.0, rate: 2.0),
  (label: '11h · 3倍', hours: 11.0, rate: 3.0),
  (label: '0h', hours: 0.0, rate: 0.0),
];

/// 主动收起键盘并释放焦点（弹窗关闭/离开输入区时调用，避免残留输入法）。
void hideKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');
}

/// 弹窗统一容器：屏幕中央显示（需求 1）。
Future<void> showCenterDialog(BuildContext context, Widget content) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      backgroundColor: panelColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: RepaintBoundary(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: content,
          ),
        ),
      ),
    ),
  );
}

/// 弹窗标题行。
class SheetHeader extends StatelessWidget {
  final String main;
  final String sub;

  const SheetHeader(this.main, this.sub, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PanelText(main, size: 17, color: textMain(context)),
        if (sub.isNotEmpty)
          PanelText(sub, size: 12, color: textMuted(context)),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// 弹窗输入框（小数键盘）。
class AppInput extends StatelessWidget {
  final TextEditingController controller;

  const AppInput(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: panelColor(context),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border(context), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 17, color: textMain(context)),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

/// 弹窗操作按钮行。
class _SheetActions extends StatelessWidget {
  final List<Widget> actions;

  const _SheetActions(this.actions);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AdaptiveRow(actions, gap: 8),
    );
  }
}

/// 弹窗按钮。
class DialogButton extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const DialogButton(this.text, this.bg, this.fg, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(text,
              style: TextStyle(fontSize: 14, color: fg, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

double _parseDouble(String s, double def) =>
    double.tryParse(s.trim()) ?? def;

/// 日期弹窗：记录加班/请假，显示当日倍率并可手动调整（需求 1、5）。
Future<void> showDayDialog({
  required BuildContext context,
  required AppStore store,
  required int year,
  required int month,
  required int day,
  required VoidCallback onChanged,
}) async {
  final key = AppStore.dateKey(year, month, day);
  final rec = store.records[key];

  final hoursCtrl =
      TextEditingController(text: rec != null && !rec.rest && rec.hours > 0 ? Fmt.hours(rec.hours) : '');
  final leaveCtrl = TextEditingController(
      text: rec != null && !rec.rest && rec.leaveHours > 0 ? Fmt.hours(rec.leaveHours) : '');

  // 默认倍率：已有记录的手动覆盖优先，否则按日期规则。
  double rate = rec != null && rec.rateOverride > 0
      ? rec.rateOverride
      : HolidayDb.defaultRate(year, month, day);
  var selectedRate = rate;

  final info = HolidayDb.infoFor(year, month, day);
  final String dayType;
  if (HolidayDb.isWorkAdjustment(year, month, day)) {
    dayType = '调休补班（${HolidayDb.rateLabel(HolidayDb.defaultRate(year, month, day))}）';
  } else if (info != null) {
    dayType = '${info.name}（${HolidayDb.rateLabel(info.rate)}）';
  } else if (HolidayDb.isWeekend(year, month, day)) {
    dayType = '周六日';
  } else {
    dayType = '工作日';
  }

  await showCenterDialog(
    context,
    StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(key, '记录加班 · 今日$dayType'),
          // —— 倍率显示与调整（需求 5）——
          PanelText('加班工资倍数', size: 13, color: textMuted(context)),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final r in const [1.5, 2.0, 3.0])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: r == 1.5 ? 0 : 6),
                    child: Material(
                      color: selectedRate == r ? primary(context) : panelColor(context),
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => setState(() => selectedRate = r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: selectedRate == r ? primary(context) : border(context),
                            ),
                          ),
                          child: Text(
                            HolidayDb.rateLabel(r),
                            style: TextStyle(
                              fontSize: 14,
                              color: selectedRate == r ? Colors.white : textMain(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 加班/请假输入框强制同一行，两个输入框等宽。
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PanelText('加班小时', size: 13, color: textMuted(context)),
                    const SizedBox(height: 4),
                    AppInput(hoursCtrl),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PanelText('请假小时', size: 13, color: textMuted(context)),
                    const SizedBox(height: 4),
                    AppInput(leaveCtrl),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 快捷录入选项：点击即写入并关闭弹窗。
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in kQuickOptions)
                Material(
                  color: softPrimary(context),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      hideKeyboard();
                      store.records[key] = DayRecord(
                        hours: o.hours,
                        rateOverride: o.rate,
                      );
                      store.save();
                      Navigator.of(context).pop();
                      onChanged();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        o.label,
                        style: TextStyle(fontSize: 13, color: accent(context), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _SheetActions([
            // 保存与取消互换位置（此页面要求）
            DialogButton('保存', AppColors.save, Colors.white, () {
              hideKeyboard();
              final h = _parseDouble(hoursCtrl.text, 0).clamp(0.0, 1e9);
              final leave = _parseDouble(leaveCtrl.text, 0).clamp(0.0, 1e9);
              store.records[key] = DayRecord(
                hours: h.toDouble(),
                leaveHours: leave.toDouble(),
                // 与默认倍率一致则写 0（自动）；手动改过才固定写死。
                rateOverride: selectedRate == rate ? 0.0 : selectedRate,
              );
              store.save();
              Navigator.of(context).pop();
              onChanged();
            }),
            DialogButton('删除', const Color(0xFFFFEFF1), AppColors.danger, () {
              hideKeyboard();
              store.records.remove(key);
              store.save();
              Navigator.of(context).pop();
              onChanged();
            }),
            DialogButton('休息', softPrimary(context), accent(context), () {
              hideKeyboard();
              store.records[key] = DayRecord(rest: true);
              store.save();
              Navigator.of(context).pop();
              onChanged();
            }),
            DialogButton('取消', const Color(0xFFF5F6F8), primary(context), () {
              hideKeyboard();
              Navigator.of(context).pop();
            }),
          ]),
        ],
      );
    }),
  );
}

/// 工资设置弹窗。
Future<void> showSalaryDialog({
  required BuildContext context,
  required AppStore store,
  required VoidCallback onChanged,
}) async {
  final baseCtrl = TextEditingController(text: Fmt.hours(store.baseSalary));
  final perfCtrl = TextEditingController(text: Fmt.hours(store.performanceRate));

  await showCenterDialog(
    context,
    StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader('工资设置', ''),
          PanelText('底薪', size: 13, color: textMuted(context)),
          const SizedBox(height: 4),
          AppInput(baseCtrl),
          const SizedBox(height: 10),
          PanelText('绩效比例（%），例如 25 表示底薪的 25%', size: 13, color: textMuted(context)),
          const SizedBox(height: 4),
          AppInput(perfCtrl),
          const SizedBox(height: 10),
          PanelText('公式：(底薪 + 底薪 × 绩效比例) / 21.75 / 8 = 小时工资',
              size: 11, color: textMuted(context)),
          _SheetActions([
            DialogButton('取消', const Color(0xFFF5F6F8), primary(context), () {
              hideKeyboard();
              Navigator.of(context).pop();
            }),
            DialogButton('保存', AppColors.save, Colors.white, () {
              hideKeyboard();
              store.baseSalary = _parseDouble(baseCtrl.text, store.baseSalary);
              store.performanceRate = _parseDouble(perfCtrl.text, store.performanceRate);
              store.save();
              Navigator.of(context).pop();
              onChanged();
            }),
          ]),
        ],
      );
    }),
  );
}

/// 批量类别选择（需求 2：类别文字带倍率）。
Future<void> showBatchTypePicker({
  required BuildContext context,
  required String current,
  required ValueChanged<String> onSelect,
}) async {
  const options = <String>[
    '休息',
    '工作日（1.5倍工资）',
    '周六日（2倍工资）',
    '节假日（3倍工资）',
  ];
  await showCenterDialog(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('选择类别', ''),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: DialogButton(
              option,
              option == current ? softPrimary(context) : panelColor(context),
              option == current ? accent(context) : textMain(context),
              () {
                Navigator.of(context).pop();
                onSelect(option);
              },
            ),
          ),
      ],
    ),
  );
}

/// 类别 → 记录参数。
class BatchType {
  final bool rest;
  final double rateOverride;

  const BatchType({this.rest = false, this.rateOverride = 0});
}

BatchType batchTypeOf(String label) {
  switch (label) {
    case '休息':
      return const BatchType(rest: true);
    case '工作日（1.5倍工资）':
      return const BatchType(rateOverride: 1.5);
    case '周六日（2倍工资）':
      return const BatchType(rateOverride: 2.0);
    case '节假日（3倍工资）':
      return const BatchType(rateOverride: 3.0);
    default:
      return const BatchType();
  }
}

/// 清空当月确认弹窗。
Future<void> showClearMonthConfirm({
  required BuildContext context,
  required String monthTitle,
  required VoidCallback onConfirm,
}) async {
  await showCenterDialog(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader('确认清空', monthTitle),
        PanelText('将清空当前月份日历中的所有加班、请假和休息记录。', size: 14, color: textMuted(context)),
        _SheetActions([
          DialogButton('取消', const Color(0xFFF5F6F8), primary(context), () {
            Navigator.of(context).pop();
          }),
          DialogButton('确认清空', const Color(0xFFFFEFF1), AppColors.danger, () {
            Navigator.of(context).pop();
            onConfirm();
          }),
        ]),
      ],
    ),
  );
}

/// 主题选择弹窗。
Future<void> showThemePicker({
  required BuildContext context,
  required int current,
  required ValueChanged<int> onSelect,
}) async {
  await showCenterDialog(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('选择主题', ''),
        for (var i = 0; i < AppThemes.names.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: DialogButton(
              i == current ? '✓ ${AppThemes.names[i]}' : AppThemes.names[i],
              i == current ? AppThemes.softThemeColor(i) : panelColor(context),
              i == current ? AppThemes.accent[i] : textMain(context),
              () {
                Navigator.of(context).pop();
                onSelect(i);
              },
            ),
          ),
      ],
    ),
  );
}

