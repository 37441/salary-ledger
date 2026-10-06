import 'package:flutter/material.dart';

import '../calc.dart';
import '../dialogs.dart';
import '../holidays.dart';
import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';

/// 日历页：月度小结 + 月份切换 + 日历网格 + 批量日期面板。
class CalendarPage extends StatefulWidget {
  final AppStore store;
  final SalaryCalc calc;
  final int year;
  final int month;
  final bool multiSelectMode;
  final Set<String> selectedDates;
  final ValueChanged<int> onMonthChange; // 偏移量
  final VoidCallback onRefresh;
  final ValueChanged<bool> onMultiSelectToggle;
  final ValueChanged<Set<String>> onSelectionChange;
  final VoidCallback onExitMultiSelect;

  const CalendarPage({
    super.key,
    required this.store,
    required this.calc,
    required this.year,
    required this.month,
    required this.multiSelectMode,
    required this.selectedDates,
    required this.onMonthChange,
    required this.onRefresh,
    required this.onMultiSelectToggle,
    required this.onSelectionChange,
    required this.onExitMultiSelect,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _hoursCtrl = TextEditingController();
  String _typeLabel = '休息';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scroll.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  String get _monthTitle =>
      '${widget.year}年${widget.month}月';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = widget.calc.summarizeMonth(widget.year, widget.month);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.only(bottom: 96 + keyboardInset),
      children: [
        _summaryCard(s),
        _monthControls(),
        _calendarGrid(),
        _batchPanel(),
      ],
    );
  }

  // —— 月度小结卡 ——
  Widget _summaryCard(MonthSummary s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: heroColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: SummaryMetric('实收', '${Fmt.money(s.estimatedIncome)}元')),
          Expanded(child: SummaryMetric('加班小时', '${Fmt.hours(s.totalHours)}h')),
          Expanded(child: SummaryMetric('加班收入', '${Fmt.money(s.overtimePay)}元')),
        ],
      ),
    );
  }

  // —— 月份切换 ——
  Widget _monthControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _navButton('<', () => widget.onMonthChange(-1)),
          Expanded(
            child: CenterText(_monthTitle,
                size: 16, color: textMain(context)),
          ),
          _navButton('>', () => widget.onMonthChange(1)),
        ],
      ),
    );
  }

  Widget _navButton(String text, VoidCallback onTap) {
    return SmallButton(text, softPrimary(context), onTap,
        fontSize: 16,
        textColor: textMain(context));
  }

  // —— 日历网格 ——
  Widget _calendarGrid() {
    final y = widget.year;
    final m = widget.month;
    final first = DateTime(y, m, 1);
    // 周一为第一天；原版 Java Calendar 以周日为 1，leading = (firstDay-2) 或 6。
    final leading = first.weekday == DateTime.monday ? 0 : first.weekday - 1;
    final days = SalaryCalc.daysInMonth(y, m);

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: [
        for (var i = 0; i < leading; i++) const SizedBox.shrink(),
        for (var d = 1; d <= days; d++)
          _calendarCell(y, m, d),
      ],
    );
  }

  Widget _calendarCell(int y, int m, int d) {
    final key = AppStore.dateKey(y, m, d);
    final rec = widget.store.records[key];
    final selected = widget.selectedDates.contains(key);
    final today = _isToday(y, m, d);

    final info = HolidayDb.infoFor(y, m, d);
    final isHoliday3 = HolidayDb.isTripleHoliday(y, m, d);
    final isHoliday2 = HolidayDb.isDoubleHoliday(y, m, d);
    final isAdjust = HolidayDb.isWorkAdjustment(y, m, d);

    // 顶部行：周几 + 「节 / 班」
    var weekText = _weekName(y, m, d);
    if (info != null) weekText += ' 节';
    if (isAdjust) weekText += ' 班';

    // 底部行文字。
    String extra = '';
    if (rec != null && rec.rest) {
      extra = '休息';
    } else if (rec != null && rec.hours > 0 && rec.leaveHours > 0) {
      extra = '${Fmt.hours(rec.hours)}h 请${Fmt.hours(rec.leaveHours)}h';
    } else if (rec != null && rec.hours > 0) {
      final rate = rec.rateOverride > 0
          ? rec.rateOverride
          : HolidayDb.defaultRate(y, m, d);
      extra = '${Fmt.hours(rec.hours)}h ${HolidayDb.rateLabel(rate)}';
    } else if (rec != null && rec.leaveHours > 0) {
      extra = '请假${Fmt.hours(rec.leaveHours)}h';
    } else if (rec != null) {
      extra = '0h';
    } else if (info != null) {
      extra = info.name;
    } else if (isAdjust) {
      extra = '班';
    }

    // 文字与背景色。
    final hasRec = rec != null;
    var dayColor = textMain(context);
    var weekColor = textMuted(context);
    var extraColor = textMuted(context);
    Color? fill;

    if (hasRec) {
      final state = recordStateColor(context, y, m, d, rec);
      dayColor = state;
      extraColor = state;
      weekColor = (selected || today) ? state : textMuted(context);
      if (isAdjust) weekColor = AppColors.workAdjustment;
      fill = recordFillColor(context, state);
    } else if (isAdjust) {
      dayColor = AppColors.workAdjustment;
      extraColor = AppColors.workAdjustment;
      weekColor = AppColors.workAdjustment;
      fill = recordFillColor(context, AppColors.workAdjustment);
    } else if (isHoliday3) {
      dayColor = AppColors.tripleHoliday;
      extraColor = AppColors.tripleHoliday;
      weekColor = AppColors.tripleHoliday;
      fill = recordFillColor(context, AppColors.tripleHoliday);
    } else if (isHoliday2) {
      dayColor = AppColors.doubleHoliday;
      extraColor = AppColors.doubleHoliday;
      weekColor = AppColors.doubleHoliday;
      fill = recordFillColor(context, AppColors.doubleHoliday);
    } else if (HolidayDb.isWeekend(y, m, d)) {
      dayColor = AppColors.weekend;
      weekColor = AppColors.weekend;
      fill = selected ? softPrimary(context) : panelColor(context);
    } else {
      dayColor = selected ? primary(context) : textMain(context);
      fill = selected ? softPrimary(context) : panelColor(context);
    }

    return GestureDetector(
      onTap: () => _onCellTap(y, m, d, key),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? (hasRec
                    ? recordStateColor(context, y, m, d, rec)
                    : isAdjust
                        ? AppColors.workAdjustment
                        : primary(context))
                : today
                    ? accent(context)
                    : border(context),
            width: selected || today ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(weekText,
                  maxLines: 1,
                  style: TextStyle(fontSize: 9, color: weekColor)),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Center(
                  child: Text('$d',
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 14,
                          color: dayColor,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(extra,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: extraColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _onCellTap(int y, int m, int d, String key) {
    if (widget.multiSelectMode) {
      final next = Set<String>.from(widget.selectedDates);
      if (next.contains(key)) {
        next.remove(key);
      } else {
        next.add(key);
      }
      widget.onSelectionChange(next);
      return;
    }
    widget.onRefresh(); // 触发布局刷新（保持实例稳定）
    showDayDialog(
      context: context,
      store: widget.store,
      year: y,
      month: m,
      day: d,
      onChanged: () {
        widget.onRefresh();
      },
    );
  }

  // —— 批量日期面板 ——
  Widget _batchPanel() {
    return Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: PanelText('批量日期', size: 15, color: textMain(context)),
                ),
                SmallButton(
                  widget.multiSelectMode ? '完成' : '多选',
                  // 多选状态：淡红色背景（醒目但不刺眼）；未多选：主题浅色。
                  widget.multiSelectMode
                      ? const Color(0xFFFFE4E8)
                      : softPrimary(context),
                  () {
                    widget.onMultiSelectToggle(!widget.multiSelectMode);
                  },
                  textColor: widget.multiSelectMode
                      ? const Color(0xFFC94F66)
                      : accent(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AdaptiveRow([
              Container(
                decoration: BoxDecoration(
                  color: panelColor(context),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: border(context)),
                ),
                child: TextField(
                  controller: _hoursCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 14, color: textMain(context)),
                  onTap: () {
                    // 键盘弹出后自动滚动到菜单底部，让输入框露出键盘上方（顶栏保持不动）
                    Future.delayed(const Duration(milliseconds: 350), () {
                      if (!mounted) return;
                      if (_scroll.hasClients) {
                        _scroll.animateTo(
                          _scroll.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '小时',
                    hintStyle: TextStyle(color: textMuted(context), fontSize: 12),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
              // 类别选项栏：可点击选择（休息/倍率类别），宽度与操作按钮一致
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: panelColor(context),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      showBatchTypePicker(
                        context: context,
                        current: _typeLabel,
                        onSelect: (v) => setState(() => _typeLabel = v),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _typeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: textMain(context)),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, size: 20, color: textMuted(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ], gap: 6),
            const SizedBox(height: 8),
            // 快捷填写按钮（与工时弹窗一致），点击即批量应用
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
                        FocusManager.instance.primaryFocus?.unfocus();
                        _quickBatch(o.hours, o.rate);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          o.label,
                          style: TextStyle(
                              fontSize: 13,
                              color: accent(context),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AdaptiveRow([
              SmallButton('批量修改', AppColors.save, () {
                final h = double.tryParse(_hoursCtrl.text.trim()) ?? 0;
                _applyBatch(false, h, _typeLabel);
              },
                  textColor: Colors.white, fontSize: 12),
              SmallButton('批量删除', const Color(0xFFFFEFF1), () {
                _applyBatch(true, 0, '');
              },
                  textColor: AppColors.danger, fontSize: 12),
              SmallButton('清空', const Color(0xFFFFEFF1), () {
                showClearMonthConfirm(
                  context: context,
                  monthTitle: _monthTitle,
                  onConfirm: () => _clearMonth(),
                );
              },
                  textColor: AppColors.danger, fontSize: 12),
            ], gap: 6),
          ],
        ),
      );
  }

  /// 批量快捷填写：与工时弹窗的快捷按钮一致，对已选日期直接写入并结束多选。
  void _quickBatch(double hours, double rate) {
    final targets = List<String>.of(widget.selectedDates);
    if (targets.isEmpty) {
      showAppToast(context, '请先选择多个日期');
      return;
    }
    widget.onExitMultiSelect();
    for (final key in targets) {
      widget.store.records[key] = DayRecord(
        hours: hours,
        holiday: rate == 3.0,
        rateOverride: rate,
      );
    }
    widget.store.save();
    widget.onRefresh();
    showAppToast(context, '批量快捷填写完成');
  }

  /// 批量修改/删除：进入操作前自动结束多选（需求 3）。
  void _applyBatch(bool deleteOnly, double hours, String typeLabel) {
    final targets = List<String>.of(widget.selectedDates);
    if (targets.isEmpty) {
      showAppToast(context, '请先选择多个日期');
      return;
    }
    widget.onExitMultiSelect(); // 自动「完成」多选
    if (!deleteOnly) {
      final type = batchTypeOf(typeLabel);
      if (!type.rest && hours <= 0) {
        showAppToast(context, '请先输入加班小时');
        return;
      }
      for (final key in targets) {
        widget.store.records[key] = DayRecord(
          hours: hours,
          holiday: type.rateOverride == 3.0,
          rest: type.rest,
          rateOverride: type.rateOverride,
        );
      }
    } else {
      for (final key in targets) {
        widget.store.records.remove(key);
      }
    }
    widget.store.save();
    widget.onRefresh();
    showAppToast(context, deleteOnly ? '批量删除完成' : '批量修改完成');
  }

  void _clearMonth() {
    final ym = AppStore.monthKey(widget.year, widget.month);
    widget.store.records.removeWhere((key, _) => key.startsWith(ym));
    widget.store.save();
    widget.onExitMultiSelect();
    widget.onRefresh();
    showAppToast(context, '当前月份已清空');
  }

  static bool _isToday(int y, int m, int d) {
    final now = DateTime.now();
    return now.year == y && now.month == m && now.day == d;
  }

  static String _weekName(int y, int m, int d) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return names[DateTime(y, m, d).weekday - 1];
  }
}