import 'package:flutter/material.dart';

import '../calc.dart';
import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';

/// 整年页：年度汇总 + 12 个月卡片（点击月份跳到统计页）。
class YearPage extends StatefulWidget {
  final AppStore store;
  final SalaryCalc calc;
  final int year;
  final ValueChanged<int> onYearChange;
  final ValueChanged<int> onMonthSelected; // 跳到统计页该月
  final VoidCallback onRefresh;

  const YearPage({
    super.key,
    required this.store,
    required this.calc,
    required this.year,
    required this.onYearChange,
    required this.onMonthSelected,
    required this.onRefresh,
  });

  @override
  State<YearPage> createState() => _YearPageState();
}

class _YearPageState extends State<YearPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ys = widget.calc.summarizeYear(widget.year);
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        HeroCard(
          '年度小结',
          '${Fmt.hours(ys.hours)} 小时',
          '年度加班费 ${Fmt.money(ys.overtimePay)} 元',
        ),
        _yearControls(),
        _yearCard(ys),
        for (var m = 1; m <= 12; m++) _yearMonthCard(m),
      ],
    );
  }

  Widget _yearControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          SmallButton('<', softPrimary(context), () => widget.onYearChange(-1),
              fontSize: 16, textColor: textMain(context)),
          Expanded(
            child: CenterText('${widget.year}', size: 16, color: textMain(context)),
          ),
          SmallButton('>', softPrimary(context), () => widget.onYearChange(1),
              fontSize: 16, textColor: textMain(context)),
        ],
      ),
    );
  }

  Widget _yearCard(YearSummary ys) {
    final tm = textMain(context);
    return Panel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelText('年度汇总', size: 15, color: tm),
          PanelText('工时', size: 12, color: textMuted(context)),
          _gridRow([
            YearMetric('总加班', '${Fmt.hours(ys.hours)}h', primary(context)),
            YearMetric('1.5倍', '${Fmt.hours(ys.h15)}h', tm),
            YearMetric('2倍', '${Fmt.hours(ys.h20)}h', AppColors.weekend),
            YearMetric('3倍', '${Fmt.hours(ys.h30)}h', AppColors.tripleHoliday),
          ]),
          PanelText('工资', size: 12, color: textMuted(context)),
          _gridRow([
            YearMetric('加班费', '${Fmt.money(ys.overtimePay)}元', accent(context)),
            YearMetric('实算', '${Fmt.money(ys.estimatedIncome)}元', primary(context)),
            YearMetric('扣款', '${Fmt.money(ys.deductions)}元', AppColors.danger),
            YearMetric('补贴', '${Fmt.money(ys.subsidies)}元', accent(context)),
          ]),
          _gridRow([
            YearMetric('请假', '${Fmt.hours(ys.leaveHours)}h', tm),
            YearMetric('请假扣薪', '${Fmt.money(ys.leaveSalaryDeduction)}元', AppColors.danger),
          ]),
        ],
      ),
    );
  }

  Widget _gridRow(List<Widget> metrics) {
    final narrow = MediaQuery.of(context).size.width < 420;
    if (narrow) {
      return Wrap(
        children: [
          for (final m in metrics)
            SizedBox(width: MediaQuery.of(context).size.width / 2 - 26, child: m),
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: metrics[i]),
        ],
      ],
    );
  }

  Widget _yearMonthCard(int month) {
    final ms = widget.calc.summarizeMonth(widget.year, month);
    final display = (ms.totalHours == 0 &&
            ms.overtimePay == 0 &&
            ms.deductionTotal == 0 &&
            ms.subsidyTotal == 0 &&
            ms.leaveHours == 0)
        ? 0.0
        : ms.estimatedIncome;

    return GestureDetector(
      onTap: () => widget.onMonthSelected(month),
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: PanelText('$month月', size: 15, color: textMain(context)),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '实算 ${Fmt.money(display)}',
                    style: TextStyle(fontSize: 13, color: accent(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // 三指标一行（窄屏也不换行）
            Row(
              children: [
                _monthMetric('加班时长', '${Fmt.hours(ms.totalHours)}h'),
                _monthMetric('加班费', Fmt.money(ms.overtimePay)),
                _monthMetric('请假', '${Fmt.hours(ms.leaveHours)}h'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              style: TextStyle(fontSize: 11, color: textMuted(context))),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: TextStyle(fontSize: 13, color: textMain(context))),
          ),
        ],
      ),
    );
  }
}