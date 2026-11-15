import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/models.dart';
import 'package:watad/core/prayer_times.dart';
import 'package:watad/core/reminders.dart';

void main() {
  final dubai = cityById('dubai');
  final morning = DateTime(2026, 11, 15, 0, 5);

  test('default settings plan before, adhan and iqama for every prayer', () {
    final events = planReminders(dubai, ReminderSettings.defaults(), morning, days: 1);
    expect(events.length, 15);
    expect(events.where((e) => e.kind == ReminderKind.adhan).length, 5);
  });

  test('events are sorted and all in the future', () {
    final now = DateTime(2026, 11, 15, 13, 0);
    final events = planReminders(dubai, ReminderSettings.defaults(), now);
    for (var i = 0; i < events.length; i++) {
      expect(events[i].time.isAfter(now), isTrue);
      if (i > 0) expect(!events[i].time.isBefore(events[i - 1].time), isTrue);
    }
  });

  test('before reminder is the chosen minutes ahead of the adhan', () {
    final s = ReminderSettings.defaults().copyWith(minutesBefore: 10);
    final events = planReminders(dubai, s, morning, days: 1);
    final fajrAdhan = events.firstWhere(
        (e) => e.prayer == Prayer.fajr && e.kind == ReminderKind.adhan);
    final fajrBefore = events.firstWhere(
        (e) => e.prayer == Prayer.fajr && e.kind == ReminderKind.before);
    expect(fajrAdhan.time.difference(fajrBefore.time), const Duration(minutes: 10));
  });

  test('iqama comes after the adhan by the default gap', () {
    final events = planReminders(dubai, ReminderSettings.defaults(), morning, days: 1);
    final adhan = events.firstWhere(
        (e) => e.prayer == Prayer.maghrib && e.kind == ReminderKind.adhan);
    final iqama = events.firstWhere(
        (e) => e.prayer == Prayer.maghrib && e.kind == ReminderKind.iqama);
    expect(iqama.time.difference(adhan.time),
        Duration(minutes: kIqamaMinutes[Prayer.maghrib]!));
  });

  test('turning things off removes them', () {
    final s = ReminderSettings.defaults()
        .copyWith(minutesBefore: 0, iqamaReminder: false, prayers: {Prayer.fajr});
    final events = planReminders(dubai, s, morning, days: 1);
    expect(events.length, 1);
    expect(events.single.kind, ReminderKind.adhan);
    expect(planReminders(dubai, s.copyWith(enabled: false), morning), isEmpty);
  });

  test('settings survive a JSON round trip', () {
    final s = ReminderSettings.defaults()
        .copyWith(minutesBefore: 30, voice: AdhanVoice.madinah, prayers: {Prayer.asr});
    final back = ReminderSettings.fromJson(s.toJson());
    expect(back.minutesBefore, 30);
    expect(back.voice, AdhanVoice.madinah);
    expect(back.prayers, {Prayer.asr});
  });

  test('ids are unique across a week', () {
    final events = planReminders(dubai, ReminderSettings.defaults(), morning, days: 7);
    expect(events.map((e) => e.id).toSet().length, events.length);
  });
}
