import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/models.dart';

void main() {
  test('logs and excuses survive a save/load round trip', () {
    final log = PrayerLog(
        day: DateTime(2026, 11, 15, 13, 40),
        prayer: Prayer.asr,
        status: LogStatus.mosque,
        locationConfirmed: true);
    final back = PrayerLog.fromJson(log.toJson());
    expect(back.key, '2026-11-15|asr');
    expect(back.status, LogStatus.mosque);
    expect(back.locationConfirmed, isTrue);

    final e = Excuse(type: ExcuseType.travel, start: DateTime(2026, 11, 12));
    final e2 = Excuse.fromJson(e.endedOn(DateTime(2026, 11, 18)).toJson());
    expect(e2.covers(DateTime(2026, 11, 18)), isTrue);
    expect(e2.covers(DateTime(2026, 11, 19)), isFalse);
    expect(e.isActive, isTrue);
  });

  test('day keys are zero-padded and parse back', () {
    expect(dayKey(DateTime(2027, 2, 3)), '2027-02-03');
    expect(parseDayKey('2027-02-03'), DateTime(2027, 2, 3));
  });
}
