import 'package:flutter/material.dart';

import '../calc.dart';
import '../dialogs.dart';
import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';

/// 统计页：月度实算 + 工资信息 + 加班分组 + 扣款/补贴。
class StatsPage extends StatefulWidget {
  final AppStore store;
  final SalaryCalc calc;
  final int year;
  final int month;
  final ValueChanged<int> onMonthChange;
  final VoidCallback onRefresh;

  const StatsPage({
    super.key,
    required this.store,
    required this.calc,
    required this.year,
    required this.month,
    required this.onMonthChange,
    required this.onRefresh,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with AutomaticKeepAliveClientMixin {
  String get _monthTitle => '${widget.year}年${widget.month}月';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = widget.calc.summarizeMonth(widget.year, widget.month);
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        HeroCard(
          '月度小结 实算',
          '${Fmt.money(s.estimatedIncome)} 元',
          '总收入 ${Fmt.money(s.grossIncome)} 元  请假扣薪 ${Fmt.money(s.leaveSalaryDeduction)} 元',
        ),
        _monthControls(),
        _salaryInfoCard(s),
        AdaptiveRow([
          _overtimeExplainCard('加班时长',
              const ['1.5倍', '2倍', '3倍'],
              ['${Fmt.hours(s.h15)}小时', '${Fmt.hours(s.h20)}小时', '${Fmt.hours(s.h30)}小时'],
              [accent(context), AppColors.weekend, AppColors.tripleHoliday]),
          _overtimeExplainCard('加班费',
              const ['1.5倍', '2倍', '3倍'],
              ['${Fmt.money(s.pay15)}元', '${Fmt.money(s.pay20)}元', '${Fmt.money(s.pay30)}元'],
              [accent(context), AppColors.weekend, AppColors.tripleHoliday]),
        ], gap: 14),
        AdaptiveRow([
          _financePanel('扣款项', true),
          _financePanel('补贴项', false),
        ], gap: 8),
      ],
    );
  }

  Widget _monthControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          SmallButton('<', softPrimary(context), () => widget.onMonthChange(-1),
              fontSize: 16, textColor: textMain(context)),
          Expanded(
            child: CenterText(_monthTitle, size: 16, color: textMain(context)),
          ),
          SmallButton('>', softPrimary(context), () => widget.onMonthChange(1),
              fontSize: 16, textColor: textMain(context)),
        ],
      ),
    );
  }

  Widget _salaryInfoCard(MonthSummary s) {
    final tm = textMain(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelText('工资信息', size: 15, color: textMain(context)),
          const SizedBox(height: 6),
          _metricGrid([
            YearMetric('底薪', Fmt.money(widget.store.baseSalary), primary(context)),
            YearMetric('绩效', '${Fmt.money(widget.store.performanceRate)}%', primary(context)),
            YearMetric('小时工资', Fmt.money(widget.calc.hourlyWage()), accent(context)),
            YearMetric('加班费', Fmt.money(s.overtimePay), accent(context)),
            YearMetric('扣款', Fmt.money(s.deductionTotal), AppColors.danger),
            YearMetric('补贴', Fmt.money(s.subsidyTotal), accent(context)),
            YearMetric('总收入', Fmt.money(s.grossIncome), primary(context)),
            YearMetric('实算', Fmt.money(s.estimatedIncome), primary(context)),
            YearMetric('请假扣薪', Fmt.money(s.leaveSalaryDeduction), AppColors.danger),
            YearMetric('请假小时', '${Fmt.hours(s.leaveHours)}h', tm),
            YearMetric('2倍抵扣', '${Fmt.hours(s.leaveOffsetHours)}h', accent(context)),
            YearMetric('剩余请假', '${Fmt.hours(s.leaveSalaryHours)}h', accent(context)),
          ]),
        ],
      ),
    );
  }

  Widget _metricGrid(List<YearMetric> metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: 1.85,
      children: metrics,
    );
  }

  Widget _overtimeExplainCard(
      String title, List<String> labels, List<String> values, List<Color> colors) {
    return Panel(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelText(title, size: 14, color: textMain(context)),
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text('■',
                        style: TextStyle(fontSize: 13, color: colors[i % colors.length])),
                  ),
                  SizedBox(
                    width: 60,
                    child: PanelText(labels[i], size: 12, color: textMuted(context)),
                  ),
                  Expanded(
                    child: Text(
                      values[i],
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, color: textMain(context)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _financePanel(String label, bool isDeduction) {
    final ym = AppStore.monthKey(widget.year, widget.month);
    final map = widget.calc.ensureFinanceMap(ym, isDeduction);
    final total = map.values.fold(0.0, (a, b) => a + b);

    return Panel(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PanelText(label, size: 14, color: textMain(context)),
              ),
              GestureDetector(
                onTap: () => _syncLastMonth(isDeduction),
                child: PanelText('⇤ 同步上月', size: 12, color: accent(context)),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _editFinanceItem(isDeduction, null),
                child: PanelText('＋ 添加', size: 13, color: primary(context)),
              ),
            ],
          ),
          for (final entry in map.entries)
            InkWell(
              onTap: () => _editFinanceItem(isDeduction, entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: PanelText(entry.key, size: 13, color: textMuted(context)),
                    ),
                    Text(
                      Fmt.money(entry.value),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDeduction ? AppColors.danger : accent(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 12),
          Row(
            children: [
              Expanded(
                child: PanelText('合计', size: 13, color: textMuted(context)),
              ),
              PanelText(Fmt.money(total), size: 13,
                  color: isDeduction ? AppColors.danger : accent(context)),
            ],
          ),
        ],
      ),
    );
  }

  /// 同步上月扣款/补贴到当前月。
  void _syncLastMonth(bool isDeduction) {
    final prevY = widget.month == 1 ? widget.year - 1 : widget.year;
    final prevM = widget.month == 1 ? 12 : widget.month - 1;
    final prevKey = AppStore.monthKey(prevY, prevM);
    final src = (isDeduction ? widget.store.deductions : widget.store.subsidies)[prevKey];
    if (src == null || src.isEmpty) {
      showAppToast(context, '上月无数据可同步');
      return;
    }
    final curKey = AppStore.monthKey(widget.year, widget.month);
    final dst = widget.calc.ensureFinanceMap(curKey, isDeduction);
    dst
      ..clear()
      ..addAll(src);
    widget.store.save();
    widget.onRefresh();
    showAppToast(context, '已同步上月数据');
  }

  Future<void> _editFinanceItem(bool isDeduction, String? oldName) async {
    final ym = AppStore.monthKey(widget.year, widget.month);
    final map = widget.store;
    final drawer = isDeduction ? map.deductions : map.subsidies;
    final items = drawer.putIfAbsent(ym, () => <String, double>{});

    final nameCtrl = TextEditingController(text: oldName ?? '');
    final amountCtrl = TextEditingController(
        text: oldName != null ? Fmt.hours(items[oldName] ?? 0) : '');

    await showCenterDialog(
      context,
      StatefulBuilder(builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(oldName == null ? '添加${isDeduction ? '扣款' : '补贴'}项' : '编辑${isDeduction ? '扣款' : '补贴'}项',
                ym),
            PanelText('名称', size: 13, color: textMuted(context)),
            const SizedBox(height: 4),
            AppInput(nameCtrl),
            const SizedBox(height: 10),
            PanelText('金额', size: 13, color: textMuted(context)),
            const SizedBox(height: 4),
            AppInput(amountCtrl),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AdaptiveRow([
                DialogButton('取消', const Color(0xFFF5F6F8), primary(context), () {
                  Navigator.of(context).pop();
                }),
                if (oldName != null)
                  DialogButton('删除', const Color(0xFFFFEFF1), AppColors.danger, () {
                    items.remove(oldName);
                    widget.store.save();
                    Navigator.of(context).pop();
                    widget.onRefresh();
                  }),
                DialogButton('保存', AppColors.save, Colors.white, () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  if (oldName != null) items.remove(oldName);
                  items[name] = double.tryParse(amountCtrl.text.trim()) ?? 0;
                  widget.store.save();
                  Navigator.of(context).pop();
                  widget.onRefresh();
                }),
              ], gap: 8),
            ),
          ],
        );
      }),
    );
  }
}
