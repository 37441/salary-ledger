/// 每日加班记录。
class DayRecord {
  /// 加班小时数。
  double hours;

  /// 是否标记为节假日（旧数据字段，兼容保留）。
  bool holiday;

  /// 是否休息日（不参与统计）。
  bool rest;

  /// 请假小时数。
  double leaveHours;

  /// 手动倍率覆盖；<=0 表示按日期规则自动计算。
  double rateOverride;

  DayRecord({
    this.hours = 0.0,
    this.holiday = false,
    this.rest = false,
    this.leaveHours = 0.0,
    this.rateOverride = 0.0,
  });

  factory DayRecord.fromJson(Map<String, dynamic> json) => DayRecord(
        hours: (json['hours'] as num? ?? 0).toDouble(),
        holiday: json['holiday'] as bool? ?? false,
        rest: json['rest'] as bool? ?? false,
        leaveHours: (json['leaveHours'] as num? ?? 0).toDouble(),
        rateOverride: (json['rateOverride'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'hours': hours,
        'holiday': holiday,
        'rest': rest,
        'leaveHours': leaveHours,
        'rateOverride': rateOverride,
      };
}

/// 某月的汇总统计。
class MonthSummary {
  double totalHours = 0;
  double h15 = 0;
  double h20 = 0;
  double h30 = 0;
  double pay15 = 0;
  double pay20 = 0;
  double pay30 = 0;
  double overtimePay = 0;
  double leaveHours = 0;
  double leaveOffsetHours = 0;
  double leaveSalaryHours = 0;
  double leaveSalaryDeduction = 0;
  double deductionTotal = 0;
  double subsidyTotal = 0;
  double grossIncome = 0;
  double estimatedIncome = 0;
}

/// 某年的汇总统计。
class YearSummary {
  double hours = 0;
  double h15 = 0;
  double h20 = 0;
  double h30 = 0;
  double overtimePay = 0;
  double leaveHours = 0;
  double leaveSalaryDeduction = 0;
  double deductions = 0;
  double subsidies = 0;
  double estimatedIncome = 0;
}
