/// Core data types for Watad. Pure Dart: no Flutter imports, so the
/// streak engine and its tests run with `dart test` as well as `flutter test`.

enum Prayer { fajr, dhuhr, asr, maghrib, isha }

/// What the user logged for one obligatory prayer.
enum LogStatus {
  /// Prayed in congregation at the mosque.
  mosque,

  /// Prayed on time at home, work, or anywhere outside the mosque.
  home,

  /// Missed on time, made up before the next prayer came in.
  qada,

  /// Made up after the next prayer came in.
  lateQada,

  /// Not prayed.
  missed,
}

/// How a slot ended up being counted (what the calendar shows).
enum SlotOutcome { mosque, home, qada, lateQada, missed, excused, frozen, pending }

enum ExcuseType { travel, illness, menstruation }

/// Calendar day with no time part. Built with DateTime(y, m, d) so day
/// arithmetic is safe across DST changes in any country.
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

DateTime nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String k) {
  final p = k.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String slotKey(DateTime day, Prayer p) => '${dayKey(day)}|${p.name}';

class PrayerLog {
  final DateTime day;
  final Prayer prayer;
  final LogStatus status;

  /// The user confirmed with location that they were at a mosque (+1 point).
  final bool locationConfirmed;

  /// Travel: prayed combined (jam') with the paired prayer.
  final bool combined;

  PrayerLog({
    required DateTime day,
    required this.prayer,
    required this.status,
    this.locationConfirmed = false,
    this.combined = false,
  }) : day = dayOf(day);

  String get key => slotKey(day, prayer);

  Map<String, dynamic> toJson() => {
        'day': dayKey(day),
        'prayer': prayer.name,
        'status': status.name,
        if (locationConfirmed) 'loc': true,
        if (combined) 'jam': true,
      };

  factory PrayerLog.fromJson(Map<String, dynamic> j) => PrayerLog(
        day: parseDayKey(j['day'] as String),
        prayer: Prayer.values.byName(j['prayer'] as String),
        status: LogStatus.values.byName(j['status'] as String),
        locationConfirmed: j['loc'] == true,
        combined: j['jam'] == true,
      );
}

class Excuse {
  final ExcuseType type;
  final DateTime start;

  /// Last day covered (inclusive). Null = still active.
  final DateTime? end;

  Excuse({required this.type, required DateTime start, DateTime? end})
      : start = dayOf(start),
        end = end == null ? null : dayOf(end);

  bool covers(DateTime day) {
    final d = dayOf(day);
    if (d.isBefore(start)) return false;
    return end == null || !d.isAfter(end!);
  }

  bool get isActive => end == null;

  Excuse endedOn(DateTime day) => Excuse(type: type, start: start, end: day);

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'start': dayKey(start),
        if (end != null) 'end': dayKey(end!),
      };

  factory Excuse.fromJson(Map<String, dynamic> j) => Excuse(
        type: ExcuseType.values.byName(j['type'] as String),
        start: parseDayKey(j['start'] as String),
        end: j['end'] == null ? null : parseDayKey(j['end'] as String),
      );
}
