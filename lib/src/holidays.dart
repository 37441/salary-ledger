/// 节假日信息：名称与默认倍率。
class HolidayInfo {
  final String name;

  /// 该日的默认倍率：3.0（法定）或 2.0（调休/假日剩余）。
  final double rate;

  const HolidayInfo(this.name, this.rate);
}

/// 一段放假安排：从 [start] 到 [end]（含两端）。
///
/// [tripleOffsets] 为该区间内 3 倍（法定假日）的相对天数（0-based，
/// 即距 start 的天数），其余天按 2 倍计。
class HolidaySpan {
  final String name;
  final DateTime start;
  final DateTime end;
  final List<int> tripleOffsets;

  const HolidaySpan(this.name, this.start, this.end, this.tripleOffsets);

  bool contains(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

  /// 返回该日倍率：三倍日 3，其余 2。
  double rateFor(DateTime d) {
    final idx = d.difference(start).inDays;
    return tripleOffsets.contains(idx) ? 3.0 : 2.0;
  }
}

/// 调休上班日（补班日）：周末上班，强制按工作日倍率 1.5。
class WorkAdjustment {
  final DateTime date;

  const WorkAdjustment(this.date);
}

/// 国家法定节假日与调休安排表。
///
/// 数据来源：国务院办公厅历年《关于部分节假日安排的通知》。
/// - 2024 年：国办发明电〔2023〕7 号
/// - 2025 年：国办发明电〔2024〕12 号（2024-11 修订放假办法，春节/劳动节各增 1 天法定假）
/// - 2026 年：国办发明电〔2025〕7 号
/// - 2027~2030 年：官方尚未发布，以下为占位推算（春节按新办法除夕起 4 天法定），
///   官方发布后请按实际通知更新。
class HolidayDb {
  static final Map<int, List<HolidaySpan>> _spans = {
    2024: [
      HolidaySpan('元旦', DateTime(2024, 1, 1), DateTime(2024, 1, 1), [0]),
      HolidaySpan('春节', DateTime(2024, 2, 10), DateTime(2024, 2, 17), [0, 1, 2]),
      HolidaySpan('清明', DateTime(2024, 4, 4), DateTime(2024, 4, 6), [0]),
      HolidaySpan('劳动节', DateTime(2024, 5, 1), DateTime(2024, 5, 5), [0]),
      HolidaySpan('端午', DateTime(2024, 6, 8), DateTime(2024, 6, 10), [2]),
      HolidaySpan('中秋', DateTime(2024, 9, 15), DateTime(2024, 9, 17), [2]),
      HolidaySpan('国庆', DateTime(2024, 10, 1), DateTime(2024, 10, 7), [0, 1, 2]),
    ],
    2025: [
      HolidaySpan('元旦', DateTime(2025, 1, 1), DateTime(2025, 1, 1), [0]),
      HolidaySpan('春节', DateTime(2025, 1, 28), DateTime(2025, 2, 4), [0, 1, 2, 3]),
      HolidaySpan('清明', DateTime(2025, 4, 4), DateTime(2025, 4, 6), [0]),
      HolidaySpan('劳动节', DateTime(2025, 5, 1), DateTime(2025, 5, 5), [0, 1]),
      HolidaySpan('端午', DateTime(2025, 5, 31), DateTime(2025, 6, 2), [0]),
      HolidaySpan('国庆', DateTime(2025, 10, 1), DateTime(2025, 10, 5), [0, 1, 2]),
      HolidaySpan('中秋', DateTime(2025, 10, 6), DateTime(2025, 10, 6), [0]),
      HolidaySpan('国庆', DateTime(2025, 10, 7), DateTime(2025, 10, 8), []),
    ],
    2026: [
      HolidaySpan('元旦', DateTime(2026, 1, 1), DateTime(2026, 1, 3), [0]),
      HolidaySpan('春节', DateTime(2026, 2, 15), DateTime(2026, 2, 23), [1, 2, 3, 4]),
      HolidaySpan('清明', DateTime(2026, 4, 4), DateTime(2026, 4, 6), [1]),
      HolidaySpan('劳动节', DateTime(2026, 5, 1), DateTime(2026, 5, 5), [0, 1]),
      HolidaySpan('端午', DateTime(2026, 6, 19), DateTime(2026, 6, 21), [0]),
      HolidaySpan('中秋', DateTime(2026, 9, 25), DateTime(2026, 9, 27), [0]),
      HolidaySpan('国庆', DateTime(2026, 10, 1), DateTime(2026, 10, 7), [0, 1, 2]),
    ],
    2027: [
      HolidaySpan('元旦', DateTime(2027, 1, 1), DateTime(2027, 1, 3), [0]),
      HolidaySpan('春节', DateTime(2027, 2, 5), DateTime(2027, 2, 12), [0, 1, 2, 3]),
      HolidaySpan('清明', DateTime(2027, 4, 3), DateTime(2027, 4, 5), [2]),
      HolidaySpan('劳动节', DateTime(2027, 5, 1), DateTime(2027, 5, 5), [0, 1]),
      HolidaySpan('端午', DateTime(2027, 6, 9), DateTime(2027, 6, 9), [0]),
      HolidaySpan('中秋', DateTime(2027, 9, 15), DateTime(2027, 9, 15), [0]),
      HolidaySpan('国庆', DateTime(2027, 10, 1), DateTime(2027, 10, 7), [0, 1, 2]),
    ],
    2028: [
      HolidaySpan('元旦', DateTime(2028, 1, 1), DateTime(2028, 1, 3), [0]),
      HolidaySpan('春节', DateTime(2028, 1, 25), DateTime(2028, 2, 1), [0, 1, 2, 3]),
      HolidaySpan('清明', DateTime(2028, 4, 4), DateTime(2028, 4, 4), [0]),
      HolidaySpan('劳动节', DateTime(2028, 5, 1), DateTime(2028, 5, 5), [0, 1]),
      HolidaySpan('端午', DateTime(2028, 5, 28), DateTime(2028, 5, 28), [0]),
      HolidaySpan('国庆·中秋', DateTime(2028, 10, 1), DateTime(2028, 10, 8), [0, 1, 2]),
    ],
    2029: [
      HolidaySpan('元旦', DateTime(2029, 1, 1), DateTime(2029, 1, 1), [0]),
      HolidaySpan('春节', DateTime(2029, 2, 12), DateTime(2029, 2, 19), [0, 1, 2, 3]),
      HolidaySpan('清明', DateTime(2029, 4, 4), DateTime(2029, 4, 4), [0]),
      HolidaySpan('劳动节', DateTime(2029, 5, 1), DateTime(2029, 5, 5), [0, 1]),
      HolidaySpan('端午', DateTime(2029, 6, 16), DateTime(2029, 6, 16), [0]),
      HolidaySpan('中秋', DateTime(2029, 9, 22), DateTime(2029, 9, 22), [0]),
      HolidaySpan('国庆', DateTime(2029, 10, 1), DateTime(2029, 10, 7), [0, 1, 2]),
    ],
    2030: [
      HolidaySpan('元旦', DateTime(2030, 1, 1), DateTime(2030, 1, 1), [0]),
      HolidaySpan('春节', DateTime(2030, 2, 2), DateTime(2030, 2, 9), [0, 1, 2, 3]),
      HolidaySpan('清明', DateTime(2030, 4, 5), DateTime(2030, 4, 5), [0]),
      HolidaySpan('劳动节', DateTime(2030, 5, 1), DateTime(2030, 5, 5), [0, 1]),
      HolidaySpan('端午', DateTime(2030, 6, 5), DateTime(2030, 6, 5), [0]),
      HolidaySpan('中秋', DateTime(2030, 9, 12), DateTime(2030, 9, 12), [0]),
      HolidaySpan('国庆', DateTime(2030, 10, 1), DateTime(2030, 10, 7), [0, 1, 2]),
    ],
  };

  /// 调休上班日（补班日），仅收录官方已发布的年份。
  static final Map<int, List<WorkAdjustment>> _workAdjustments = {
    2024: [
      WorkAdjustment(DateTime(2024, 2, 4)),
      WorkAdjustment(DateTime(2024, 2, 18)),
      WorkAdjustment(DateTime(2024, 4, 7)),
      WorkAdjustment(DateTime(2024, 4, 28)),
      WorkAdjustment(DateTime(2024, 5, 11)),
      WorkAdjustment(DateTime(2024, 9, 14)),
      WorkAdjustment(DateTime(2024, 9, 29)),
      WorkAdjustment(DateTime(2024, 10, 12)),
    ],
    2025: [
      WorkAdjustment(DateTime(2025, 1, 26)),
      WorkAdjustment(DateTime(2025, 2, 8)),
      WorkAdjustment(DateTime(2025, 4, 27)),
      WorkAdjustment(DateTime(2025, 9, 28)),
      WorkAdjustment(DateTime(2025, 10, 11)),
    ],
    2026: [
      WorkAdjustment(DateTime(2026, 1, 4)),
      WorkAdjustment(DateTime(2026, 2, 14)),
      WorkAdjustment(DateTime(2026, 2, 28)),
      WorkAdjustment(DateTime(2026, 5, 9)),
      WorkAdjustment(DateTime(2026, 9, 20)),
      WorkAdjustment(DateTime(2026, 10, 10)),
    ],
  };

  /// 查询某日节假日信息；非节假日返回 null。
  static HolidayInfo? infoFor(int year, int month, int day) {
    final spans = _spans[year];
    if (spans == null) return null;
    final DateTime d = DateTime(year, month, day);
    for (final span in spans) {
      if (span.contains(d)) {
        return HolidayInfo(span.name, span.rateFor(d));
      }
    }
    return null;
  }

  /// 是否法定 3 倍节假日。
  static bool isTripleHoliday(int year, int month, int day) {
    final info = infoFor(year, month, day);
    return info != null && info.rate == 3.0;
  }

  /// 是否 2 倍节假日（调休/假日剩余，区别于周末的 2 倍）。
  static bool isDoubleHoliday(int year, int month, int day) {
    final info = infoFor(year, month, day);
    return info != null && info.rate == 2.0;
  }

  /// 是否调休上班日（补班日）。
  static bool isWorkAdjustment(int year, int month, int day) {
    final list = _workAdjustments[year];
    if (list == null) return false;
    final d = DateTime(year, month, day);
    for (final wa in list) {
      if (wa.date.year == d.year &&
          wa.date.month == d.month &&
          wa.date.day == d.day) {
        return true;
      }
    }
    return false;
  }

  /// 是否周末（周六/周日）。
  static bool isWeekend(int year, int month, int day) {
    final w = DateTime(year, month, day).weekday;
    return w == DateTime.saturday || w == DateTime.sunday;
  }

  /// 该日默认倍率：调休补班按工作日 1.5；节假日按表（3 或 2）；
  /// 周末 2 倍；工作日 1.5 倍。
  static double defaultRate(int year, int month, int day) {
    if (isWorkAdjustment(year, month, day)) return 1.5;
    final info = infoFor(year, month, day);
    if (info != null) return info.rate;
    return isWeekend(year, month, day) ? 2.0 : 1.5;
  }

  /// 倍率显示文案。
  static String rateLabel(double rate) {
    if (rate == 3.0) return '3倍';
    if (rate == 2.0) return '2倍';
    return '1.5倍';
  }
}