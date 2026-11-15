import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/models.dart';
import 'package:watad/core/streak_engine.dart';

const M = LogStatus.mosque, H = LogStatus.home, Q = LogStatus.qada;
const L = LogStatus.lateQada, X = LogStatus.missed;

/// Builds logs from a compact plan: day -> 5 statuses (null = not logged).
Map<String, PrayerLog> plan(Map<DateTime, List<LogStatus?>> days,
    {bool loc = false}) {
  final out = <String, PrayerLog>{};
  days.forEach((day, list) {
    for (var i = 0; i < 5; i++) {
      final s = list[i];
      if (s == null) continue;
      final log = PrayerLog(
          day: day, prayer: Prayer.values[i], status: s, locationConfirmed: loc);
      out[log.key] = log;
    }
  });
  return out;
}

StreakSummary run(Map<DateTime, List<LogStatus?>> days,
        {required DateTime today,
        List<Excuse> excuses = const [],
        bool autoFreeze = true,
        bool loc = false}) =>
    StreakEngine.compute(
      logs: plan(days, loc: loc),
      excuses: excuses,
      start: days.keys.reduce((a, b) => a.isBefore(b) ? a : b),
      today: today,
      autoFreeze: autoFreeze,
    );

void main() {
  final d1 = DateTime(2026, 11, 10), d2 = DateTime(2026, 11, 11);
  final d3 = DateTime(2026, 11, 12);

  test('every prayer at the mosque raises both streaks', () {
    final s = run({d1: [M, M, M, M, M], d2: [M, M, M, M, M]}, today: d2);
    expect([s.mosque, s.maintenance, s.score], [10, 10, 30]);
  });

  test('home resets the mosque streak only', () {
    final s = run({d1: [M, M, H, M, M]}, today: d1);
    expect([s.mosque, s.mosqueBest, s.maintenance], [2, 2, 5]);
  });

  test('qada in time keeps maintenance, late qada resets it', () {
    var s = run({d1: [H, Q, H, H, H]}, today: d1);
    expect([s.maintenance, s.mosque], [5, 0]);
    s = run({d1: [H, L, H, H, H]}, today: d1);
    expect([s.maintenance, s.maintenanceBest], [3, 3]);
  });

  test('missed resets both', () {
    final s = run({d1: [M, M, X, M, H]}, today: d1);
    expect([s.mosque, s.maintenance, s.mosqueBest, s.maintenanceBest],
        [0, 2, 2, 2]);
  });

  test("today's unlogged prayers are pending and break nothing", () {
    final s = run({d1: [M, M, M, M, M], d2: [M, null, null, null, null]},
        today: d2);
    expect([s.mosque, s.maintenance], [6, 6]);
    expect(s.outcomes[slotKey(d2, Prayer.dhuhr)], SlotOutcome.pending);
  });

  test('a forgotten past prayer is covered by a freeze', () {
    final s = run({d1: [M, M, M, M, M], d2: [M, null, M, M, M]}, today: d3);
    expect([s.mosque, s.maintenance], [9, 9]);
    expect(s.outcomes[slotKey(d2, Prayer.dhuhr)], SlotOutcome.frozen);
    expect(s.freezesLeft(d2), 1);
  });

  test('the third forgotten prayer in a month resets the streaks', () {
    final s = run({d1: [M, M, M, M, M], d2: [null, null, null, M, M]},
        today: d3);
    expect([s.mosque, s.maintenance], [2, 2]);
    expect(s.outcomes[slotKey(d2, Prayer.asr)], SlotOutcome.missed);
    expect(s.freezesLeft(d2), 0);
  });

  test('no freeze is spent when there is no streak to protect', () {
    final s = run({d1: [null, null, null, null, null]}, today: d2);
    expect(s.freezesUsed, isEmpty);
    expect(s.outcomes[slotKey(d1, Prayer.fajr)], SlotOutcome.missed);
  });

  test('freezes renew at the start of each month', () {
    final jan30 = DateTime(2027, 1, 30), jan31 = DateTime(2027, 1, 31);
    final feb1 = DateTime(2027, 2, 1);
    final s = run({
      jan30: [M, M, M, M, M],
      jan31: [null, null, M, M, M],
      feb1: [null, M, M, M, M],
    }, today: DateTime(2027, 2, 2));
    expect(s.mosque, 12);
    expect(s.outcomes[slotKey(feb1, Prayer.fajr)], SlotOutcome.frozen);
  });

  test('auto-freeze off: a forgotten prayer counts as missed', () {
    final s = run({d1: [M, M, M, M, M], d2: [M, null, M, M, M]},
        today: d3, autoFreeze: false);
    expect([s.mosque, s.maintenance], [3, 3]);
  });

  test('excuse: unlogged prayers are neutral, home keeps the mosque streak',
      () {
    final s = run(
      {d1: [M, M, M, M, M], d2: [null, H, H, null, null], d3: [M, null, null, null, null]},
      today: d3,
      excuses: [Excuse(type: ExcuseType.travel, start: d2, end: d2)],
    );
    expect([s.mosque, s.maintenance], [6, 8]);
    expect(s.outcomes[slotKey(d2, Prayer.fajr)], SlotOutcome.excused);
  });

  test('excuse: a prayer logged as missed still resets both', () {
    final s = run({d1: [M, M, M, M, M], d2: [X, null, null, null, null]},
        today: d2,
        excuses: [Excuse(type: ExcuseType.illness, start: d2)]);
    expect([s.mosque, s.maintenance], [0, 0]);
  });

  test('location confirmation adds a point', () {
    final s = run({d1: [M, null, null, null, null]}, today: d1, loc: true);
    expect(s.score, 4);
  });

  test('best numbers survive a reset', () {
    final s = run({d1: [M, M, M, M, M], d2: [X, M, null, null, null]},
        today: d2);
    expect([s.mosque, s.mosqueBest, s.maintenanceBest], [1, 5, 5]);
  });
}
