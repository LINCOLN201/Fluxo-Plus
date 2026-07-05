abstract final class InstallmentSchedule {
  static List<DateTime> dueDates(DateTime firstDueDate, int count) {
    assert(count > 0);
    return List.generate(
      count,
      (index) => _addMonths(firstDueDate, index),
    );
  }

  static DateTime _addMonths(DateTime source, int months) {
    final targetMonth = DateTime(source.year, source.month + months);
    final lastDay = DateTime(
      targetMonth.year,
      targetMonth.month + 1,
      0,
    ).day;
    final day = source.day > lastDay ? lastDay : source.day;
    return DateTime(targetMonth.year, targetMonth.month, day);
  }
}
