import 'package:flutter/widgets.dart';
import '../core/models.dart';
import '../core/prayer_times.dart';
import '../core/reminders.dart';
import '../core/streak_engine.dart';
import '../data/repository.dart';

/// App-wide state. Every change saves to storage and recomputes the
/// streaks with [StreakEngine], so screens always show replayed numbers.
class AppState extends ChangeNotifier {
  final Repository _repo;
  final Map<String, PrayerLog> _logs;
  final List<Excuse> _excuses;
  final DateTime startDay;
  final ReminderScheduler _scheduler;

  StreakSummary? _summary;
  DateTime? _summaryDay;

  AppState(this._repo, {ReminderScheduler? scheduler})
      : _scheduler = scheduler ?? NoopScheduler(),
        _logs = _repo.loadLogs(),
        _excuses = _repo.loadExcuses(),
        startDay = _repo.startDay();

  // ---- settings ----
  City get city => cityById(_repo.cityId);
  set city(City c) {
    _repo.cityId = c.id;
    _reschedule();
    notifyListeners();
  }

  Locale get locale => Locale(_repo.locale);
  set locale(Locale l) {
    _repo.locale = l.languageCode;
    notifyListeners();
  }

  bool get autoFreeze => _repo.autoFreeze;
  set autoFreeze(bool v) {
    _repo.autoFreeze = v;
    _invalidate();
  }

  bool get hideMosque => _repo.hideMosque;
  set hideMosque(bool v) {
    _repo.hideMosque = v;
    notifyListeners();
  }

  // ---- reminders ----
  ReminderSettings get reminders => _repo.reminders;
  set reminders(ReminderSettings v) {
    _repo.reminders = v;
    _reschedule();
    notifyListeners();
  }

  /// The next reminders, for the preview in settings.
  List<ReminderEvent> upcomingReminders({int limit = 6}) =>
      planReminders(city, reminders, DateTime.now()).take(limit).toList();

  void _reschedule() {
    _scheduler.schedule(planReminders(city, reminders, DateTime.now(), days: 7));
  }

  // ---- streaks ----
  StreakSummary get summary {
    final today = dayOf(DateTime.now());
    if (_summary == null || _summaryDay != today) {
      _summary = StreakEngine.compute(
        logs: _logs,
        excuses: _excuses,
        start: startDay,
        today: today,
        autoFreeze: autoFreeze,
      );
      _summaryDay = today;
    }
    return _summary!;
  }

  PrayerLog? logFor(DateTime day, Prayer p) => _logs[slotKey(day, p)];

  SlotOutcome? outcomeFor(DateTime day, Prayer p) =>
      summary.outcomes[slotKey(day, p)];

  /// Logging is allowed for today and past days since install, never ahead.
  bool canLog(DateTime day) {
    final d = dayOf(day);
    return !d.isBefore(startDay) && !d.isAfter(dayOf(DateTime.now()));
  }

  /// Today's prayers can be logged once their adhan has come in.
  bool canLogSlot(DateTime day, Prayer p) {
    if (!canLog(day)) return false;
    final now = DateTime.now();
    if (dayOf(day) != dayOf(now)) return true;
    return !PrayerTimesService.forDay(city, day)[p]!.isAfter(now);
  }

  /// Lets screens refresh after the app comes back to the foreground
  /// (a new day may have started).
  void refresh() => notifyListeners();

  void setLog(DateTime day, Prayer p, LogStatus status) {
    if (!canLog(day)) return;
    final log = PrayerLog(day: day, prayer: p, status: status);
    _logs[log.key] = log;
    _repo.saveLogs(_logs);
    _invalidate();
  }

  void clearLog(DateTime day, Prayer p) {
    _logs.remove(slotKey(day, p));
    _repo.saveLogs(_logs);
    _invalidate();
  }

  // ---- excuses ----
  Excuse? get activeExcuse {
    final today = dayOf(DateTime.now());
    for (final e in _excuses) {
      if (e.isActive && e.covers(today)) return e;
    }
    return null;
  }

  bool isExcused(DateTime day) => _excuses.any((e) => e.covers(day));

  void startExcuse(ExcuseType type) {
    if (activeExcuse != null) return;
    _excuses.add(Excuse(type: type, start: DateTime.now()));
    _repo.saveExcuses(_excuses);
    _invalidate();
  }

  /// Ends the active excuse. Today stays covered, so prayers of today that
  /// were left unlogged during the excuse never turn into missed ones;
  /// prayers the user logs today still count as usual.
  void endExcuse() {
    final e = activeExcuse;
    if (e == null) return;
    _excuses[_excuses.indexOf(e)] = e.endedOn(dayOf(DateTime.now()));
    _repo.saveExcuses(_excuses);
    _invalidate();
  }

  void _invalidate() {
    _summary = null;
    notifyListeners();
  }
}

/// Makes [AppState] available to every widget below it and rebuilds them
/// when it changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  /// Read and rebuild when the state changes (use inside build).
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing (use inside callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
