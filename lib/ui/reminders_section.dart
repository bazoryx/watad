import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/reminders.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

/// Rows of the "reminders & adhan" card in settings.
List<Widget> reminderTiles(BuildContext context, AppState app, S s) {
  final r = app.reminders;
  final tiles = <Widget>[
    SwitchListTile(
      secondary: const Icon(Icons.notifications_active_outlined),
      title: Text(s.remindersOn),
      value: r.enabled,
      onChanged: (v) => app.reminders = r.copyWith(enabled: v),
    ),
  ];
  if (r.enabled) {
    final upcoming = app.upcomingReminders();
    final today = dayOf(DateTime.now());
    tiles.addAll([
      const Divider(height: 1, color: WColors.line),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.remindPrayers, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final p in Prayer.values)
                FilterChip(
                  label: Text(s.prayer(p)),
                  selected: r.prayers.contains(p),
                  onSelected: (on) {
                    final next = {...r.prayers};
                    if (on) {
                      next.add(p);
                    } else {
                      next.remove(p);
                    }
                    app.reminders = r.copyWith(prayers: next);
                  },
                ),
            ]),
          ],
        ),
      ),
      const Divider(height: 1, color: WColors.line),
      ListTile(
        leading: const Icon(Icons.timer_outlined),
        title: Text(s.remindBefore),
        trailing: DropdownButton<int>(
          value: r.minutesBefore,
          underline: const SizedBox.shrink(),
          items: [
            for (final m in const [0, 5, 10, 15, 30])
              DropdownMenuItem(
                value: m,
                child: Text(m == 0 ? s.off : s.minutesBefore(m)),
              ),
          ],
          onChanged: (v) {
            if (v != null) app.reminders = r.copyWith(minutesBefore: v);
          },
        ),
      ),
      const Divider(height: 1, color: WColors.line),
      SwitchListTile(
        secondary: const Icon(Icons.mosque_outlined),
        title: Text(s.iqamaReminder),
        value: r.iqamaReminder,
        onChanged: (v) => app.reminders = r.copyWith(iqamaReminder: v),
      ),
      const Divider(height: 1, color: WColors.line),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.adhanVoice, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<AdhanVoice>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: AdhanVoice.makkah, label: Text(s.voiceMakkah)),
                ButtonSegment(value: AdhanVoice.madinah, label: Text(s.voiceMadinah)),
              ],
              selected: {r.voice},
              onSelectionChanged: (v) => app.reminders = r.copyWith(voice: v.first),
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: WColors.line),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(s.upcoming, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      for (final e in upcoming)
        ListTile(
          dense: true,
          title: Text('${s.prayer(e.prayer)} · ${s.reminderKind(e.kind)}'),
          subtitle: Text(dayOf(e.time) == today ? s.todayLabel : s.tomorrowLabel,
              style: const TextStyle(fontSize: 12)),
          trailing: Text(formatTime(e.time, s),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      Padding(
        padding: const EdgeInsets.all(14),
        child: NoteBox(icon: Icons.info_outline, text: s.remindersNote),
      ),
    ]);
  }
  return tiles;
}
