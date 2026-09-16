
class AppDateUtils {
  static String todayKey() {
    final n = DateTime.now().toUtc();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String weekKey() {
    final n = DateTime.now().toUtc();

    final thursday = n.add(Duration(days: 4 - n.weekday));

    final firstDayOfYear = DateTime.utc(thursday.year, 1, 1);
    var firstThursday = firstDayOfYear;
    while (firstThursday.weekday != DateTime.thursday) {
      firstThursday = firstThursday.add(const Duration(days: 1));
    }

    final diff = thursday.difference(firstThursday).inDays;
    final w = (diff / 7).floor() + 1;
    return '${thursday.year}-W${w.toString().padLeft(2, '0')}';
  }
}
