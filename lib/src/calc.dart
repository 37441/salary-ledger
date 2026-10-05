import 'holidays.dart';
import 'models.dart';
import 'storage.dart';

/// 薪资与汇总计算（对齐原 Android 版公式）。
class SalaryCalc {
  final AppStore store;

  SalaryCalc(this.store);

  /// 小时工资 = (底薪 + 底薪×绩效%) / 21.75 / 8。
  double hourlyWage() {
    final base = store.baseSalary * (1 + store.performanceRate / 100);
    return base / 21.75 / 8;
  }

  /// 底薪对应的小时工资（请假扣薪用）。
  double baseHourWage() => store.baseSalary / 21.75 / 8;

  /// 单条记录实际倍率：手动覆盖优先，否则按日期规则。
  double rateForRecord(int year, int month, int day, DayRecord r) {
    if (r.rateOverride > 0) return r.rateOverride;
    final defaultRate = defaultRateFor(year, month, day);
    return r.holiday ? 3.0 : defaultRate;
  }

  double defaultRateFor(int year, int month, int day) =>
      HolidayDb.defaultRate(year, month, day);

  MonthSummary summarizeMonth(int year, int month) {
    final s = MonthSummary();
    final wage = hourlyWage();
    final baseHour = baseHourWage();

    store.records.forEach((key, r) {
      if (!key.startsWith(AppStore.monthKey(year, month))) return;
      if (r.rest) return;
      s.leaveHours += r.leaveHours;
      final day = parseDay(key);
      final rate = rateForRecord(year, month, day, r);
      final pay = r.hours * wage * rate;
      s.totalHours += r.hours;
      s.overtimePay += pay;
      if (rate == 1.5) {
        s.h15 += r.hours;
        s.pay15 += pay;
      } else if (rate == 2.0) {
        s.h20 += r.hours;
        s.pay20 += pay;
      } else {
        s.h30 += r.hours;
        s.pay30 += pay;
      }
    });

    // 2 倍加班抵扣请假。
    s.leaveOffsetHours = s.leaveHours < s.h20 ? s.leaveHours : s.h20;
    if (s.leaveOffsetHours > 0) {
      final offsetPay = s.leaveOffsetHours * wage * 2.0;
      s.h20 -= s.leaveOffsetHours;
      s.pay20 -= offsetPay;
      s.totalHours -= s.leaveOffsetHours;
      s.overtimePay -= offsetPay;
    }
    s.leaveSalaryHours =
        s.leaveHours - s.leaveOffsetHours < 0 ? 0 : s.leaveHours - s.leaveOffsetHours;
    s.leaveSalaryDeduction = s.leaveSalaryHours * baseHour;

    final ym = AppStore.monthKey(year, month);
    s.deductionTotal = sumFinance(ym, true);
    s.subsidyTotal = sumFinance(ym, false);
    s.grossIncome = store.baseSalary +
        store.baseSalary * store.performanceRate / 100 +
        s.overtimePay +
        s.subsidyTotal;
    s.estimatedIncome = s.grossIncome - s.deductionTotal - s.leaveSalaryDeduction;
    return s;
  }

  YearSummary summarizeYear(int year) {
    final ys = YearSummary();
    for (var m = 1; m <= 12; m++) {
      final ms = summarizeMonth(year, m);
      ys.hours += ms.totalHours;
      ys.h15 += ms.h15;
      ys.h20 += ms.h20;
      ys.h30 += ms.h30;
      ys.overtimePay += ms.overtimePay;
      ys.leaveHours += ms.leaveHours;
      ys.leaveSalaryDeduction += ms.leaveSalaryDeduction;
      ys.deductions += ms.deductionTotal;
      ys.subsidies += ms.subsidyTotal;
      // 空月不累计实算，避免把无记录的月份记成底薪。
      if (!(ms.totalHours == 0 &&
          ms.overtimePay == 0 &&
          ms.deductionTotal == 0 &&
          ms.subsidyTotal == 0 &&
          ms.leaveHours == 0)) {
        ys.estimatedIncome += ms.estimatedIncome;
      }
    }
    return ys;
  }

  Map<String, double> ensureFinanceMap(String ym, bool isDeduction) {
    final root = isDeduction ? store.deductions : store.subsidies;
    final map = root[ym];
    if (map != null) return map;
    final defaults = isDeduction
        ? const ['五险一金', '饭费', '税费']
        : const ['工龄', '电工补贴', '计件补贴'];
    final newMap = <String, double>{for (final d in defaults) d: 0.0};
    root[ym] = newMap;
    return newMap;
  }

  double sumFinance(String ym, bool isDeduction) {
    final map = ensureFinanceMap(ym, isDeduction);
    return map.values.fold(0.0, (a, b) => a + b);
  }

  static int parseDay(String key) {
    try {
      return int.parse(key.substring(8, 10));
    } catch (_) {
      return 1;
    }
  }

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}