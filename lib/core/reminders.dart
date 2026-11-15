import 'models.dart';
import 'prayer_times.dart';

/// The three moments a reminder can fire for one prayer.
enum ReminderKind { before, adhan, iqama }

/// Adhan voices shipped in the first version. The audio files themselves
/// are added with the native build; for now only the choice is stored.
enum AdhanVoice { makkah, madinah }

/// What the user asked to be reminded about.
class ReminderSettings {
  final bool enabled;
  final Set<Prayer> prayers;

  /// Minutes before the adhan for the early reminder; 0 turns it off.
  final int minutesBefore;
  final bool iqamaReminder;
  final AdhanVoice voice;

  ReminderSettings({
    required this.enabled,
    required Set<Prayer> prayers,
    required this.minutesBefore,
    required this.iqamaReminder,
    required this.voice,
  }) : prayers = Set.unmodifiable(prayers);

  factory ReminderSettings.defaults() => ReminderSettings(
        enabled: true,
        prayers: Prayer.values.toSet(),
        minutesBefore: 15,
        iqamaReminder: true,
        voice: AdhanVoice.makkah,
      );

  ReminderSettings copyWith({
    bool? enabled,
    Set<Prayer>? prayers,
    int? minutesBefore,
    bool? iqamaReminder,
    AdhanVoice? voice,
  }) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        prayers: prayers ?? this.prayers,
        minutesBefore: minutesBefore ?? this.minutesBefore,
        iqamaReminder: iqamaReminder ?? this.iqamaReminder,
        voice: voice ?? this.voice,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'prayers': prayers.map((p) => p.name).toList(),
        'minutesBefore': minutesBefore,
        'iqamaReminder': iqamaReminder,
        'voice': voice.name,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> j) {
    final d = ReminderSettings.defaults();
    final names = (j['prayers'] as List?)?.cast<String>();
    return ReminderSettings(
      enabled: j['enabled'] as bool? ?? d.enabled,
      prayers: names == null
          ? d.prayers
          : Prayer.values.where((p) => names.contains(p.name)).toSet(),
      minutesBefore: j['minutesBefore'] as int? ?? d.minutesBefore,
      iqamaReminder: j['iqamaReminder'] as bool? ?? d.iqamaReminder,
      voice: AdhanVoice.values.firstWhere(
        (v) => v.name == j['voice'],
        orElse: () => d.voice,
      ),
    );
  }
}

/// One notification to show at [time].
class ReminderEvent {
  final Prayer prayer;
  final ReminderKind kind;
  final DateTime time;

  const ReminderEvent(this.prayer, this.kind, this.time);

  /// Stable id for the notification (same slot, same id, so rescheduling
  /// replaces instead of duplicating). Fits in 32 bits.
  int get id =>
      ((time.year % 100) * 10000 + time.month * 100 + time.day) * 100 +
      prayer.index * 10 +
      kind.index;
}

/// The reminders to schedule from [now] for the next [days] days
/// (today included), sorted by time. Only future events are returned.
List<ReminderEvent> planReminders(
  City city,
  ReminderSettings settings,
  DateTime now, {
  int days = 3,
}) {
  if (!settings.enabled) return const [];
  final events = <ReminderEvent>[];
  var day = dayOf(now);
  for (var i = 0; i < days; i++) {
    final times = PrayerTimesService.forDay(city, day);
    for (final p in Prayer.values) {
      if (!settings.prayers.contains(p)) continue;
      final adhanTime = times[p]!;
      if (settings.minutesBefore > 0) {
        events.add(ReminderEvent(p, ReminderKind.before,
            adhanTime.subtract(Duration(minutes: settings.minutesBefore))));
      }
      events.add(ReminderEvent(p, ReminderKind.adhan, adhanTime));
      if (settings.iqamaReminder) {
        events.add(ReminderEvent(p, ReminderKind.iqama,
            adhanTime.add(Duration(minutes: kIqamaMinutes[p]!))));
      }
    }
    day = nextDay(day);
  }
  events.removeWhere((e) => !e.time.isAfter(now));
  events.sort((a, b) => a.time.compareTo(b.time));
  return events;
}

/// Hands the planned reminders to the platform. The first (web) build
/// uses [NoopScheduler]; the iPhone/Android build plugs in local
/// notifications here without touching the rest of the app.
abstract class ReminderScheduler {
  Future<void> schedule(List<ReminderEvent> events);
}

class NoopScheduler implements ReminderScheduler {
  @override
  Future<void> schedule(List<ReminderEvent> events) async {}
}
