import 'models.dart';

/// Points per log (requirements doc, "السكور المقترح"). Editable later.
class ScoreTable {
  static const mosque = 3;
  static const locationBonus = 1;
  static const home = 2;
  static const qada = 1;
  static const lateQada = 1;
}

class StreakSummary {
  final int mosque;
  final int mosqueBest;
  final int maintenance;
  final int maintenanceBest;
  final int score;

  /// Outcome per slot key ("yyyy-MM-dd|fajr"), for the calendar.
  final Map<String, SlotOutcome> outcomes;

  /// Freezes used per month key ("yyyy-MM").
  final Map<String, int> freezesUsed;

  const StreakSummary({
    required this.mosque,
    required this.mosqueBest,
    required this.maintenance,
    required this.maintenanceBest,
    required this.score,
    required this.outcomes,
    required this.freezesUsed,
  });

  int freezesLeft(DateTime month) =>
      StreakEngine.freezesPerMonth - (freezesUsed[_monthKey(month)] ?? 0);
}

String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// Replays every prayer slot from [start] to [today] and computes both
/// streaks from scratch. Recomputing (instead of storing counters) means an
/// edited past log always produces correct numbers.
///
/// Rules (requirements doc, "قواعد الستريك والسكور" + "تحسينات مقترحة"):
/// * Mosque streak: +1 per prayer at the mosque. Home, qada, late qada or
///   missed resets it to 0.
/// * Maintenance streak: +1 per prayer on time (mosque or home) or made up
///   before the next prayer (qada). Late qada or missed resets it to 0.
/// * During an excuse (travel, illness, menstruation): unlogged prayers are
///   neutral, and a prayer logged at home or as qada does not reset the
///   mosque streak. A prayer logged as missed still resets both.
/// * Unlogged prayers of today are pending (late logging is allowed until
///   midnight). Unlogged prayers of past days count as missed, unless a
///   streak freeze is available that month (2 per month, used automatically).
///   A freeze is only spent when there is a streak to protect.
class StreakEngine {
  static const freezesPerMonth = 2;

  static StreakSummary compute({
    required Map<String, PrayerLog> logs,
    required List<Excuse> excuses,
    required DateTime start,
    required DateTime today,
    bool autoFreeze = true,
  }) {
    var mosque = 0, mosqueBest = 0, maint = 0, maintBest = 0, score = 0;
    final outcomes = <String, SlotOutcome>{};
    final freezes = <String, int>{};
    final lastDay = dayOf(today);

    for (var day = dayOf(start); !day.isAfter(lastDay); day = nextDay(day)) {
      final excused = excuses.any((e) => e.covers(day));
      final isToday = day == lastDay;

      for (final p in Prayer.values) {
        final key = slotKey(day, p);
        final log = logs[key];

        if (log != null) {
          switch (log.status) {
            case LogStatus.mosque:
              mosque++;
              maint++;
              score += ScoreTable.mosque +
                  (log.locationConfirmed ? ScoreTable.locationBonus : 0);
              outcomes[key] = SlotOutcome.mosque;
            case LogStatus.home:
              if (!excused) mosque = 0;
              maint++;
              score += ScoreTable.home;
              outcomes[key] = SlotOutcome.home;
            case LogStatus.qada:
              if (!excused) mosque = 0;
              maint++;
              score += ScoreTable.qada;
              outcomes[key] = SlotOutcome.qada;
            case LogStatus.lateQada:
              if (!excused) mosque = 0;
              maint = 0;
              score += ScoreTable.lateQada;
              outcomes[key] = SlotOutcome.lateQada;
            case LogStatus.missed:
              mosque = 0;
              maint = 0;
              outcomes[key] = SlotOutcome.missed;
          }
        } else if (excused) {
          outcomes[key] = SlotOutcome.excused;
        } else if (isToday) {
          outcomes[key] = SlotOutcome.pending;
        } else {
          final mk = _monthKey(day);
          final used = freezes[mk] ?? 0;
          final hasStreak = mosque > 0 || maint > 0;
          if (autoFreeze && hasStreak && used < freezesPerMonth) {
            freezes[mk] = used + 1;
            outcomes[key] = SlotOutcome.frozen;
          } else {
            mosque = 0;
            maint = 0;
            outcomes[key] = SlotOutcome.missed;
          }
        }

        if (mosque > mosqueBest) mosqueBest = mosque;
        if (maint > maintBest) maintBest = maint;
      }
    }

    return StreakSummary(
      mosque: mosque,
      mosqueBest: mosqueBest,
      maintenance: maint,
      maintenanceBest: maintBest,
      score: score,
      outcomes: outcomes,
      freezesUsed: freezes,
    );
  }
}
