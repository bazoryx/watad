import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/prayer_times.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'reminders_section.dart';
import 'widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final excuse = app.activeExcuse;

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 6, bottom: 6),
                child: Text(title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: WColors.inkMuted)),
              ),
              Card(child: Column(children: children)),
            ],
          ),
        );

    final general = section(s.settings, [
      ListTile(
        leading: const Icon(Icons.location_city_outlined),
        title: Text(s.city),
        subtitle: Text(s.calcNote, style: const TextStyle(fontSize: 12)),
        trailing: Text(s.ar ? app.city.nameAr : app.city.nameEn,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: () => _pickCity(context),
      ),
      const Divider(height: 1, color: WColors.line),
      ListTile(
        leading: const Icon(Icons.translate),
        title: Text(s.language),
        trailing: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'ar', label: Text('العربية')),
            ButtonSegment(value: 'en', label: Text('English')),
          ],
          selected: {app.locale.languageCode},
          onSelectionChanged: (v) => app.locale = Locale(v.first),
        ),
      ),
    ]);

    final streak = section(s.maintenanceStreak, [
      SwitchListTile(
        secondary: const Icon(Icons.shield_outlined),
        title: Text(s.autoFreeze),
        subtitle: Text(
            '${s.autoFreezeSub} · ${s.freezesLeft(app.summary.freezesLeft(DateTime.now()))}',
            style: const TextStyle(fontSize: 12)),
        value: app.autoFreeze,
        onChanged: (v) => app.autoFreeze = v,
      ),
      const Divider(height: 1, color: WColors.line),
      SwitchListTile(
        secondary: const Icon(Icons.visibility_off_outlined),
        title: Text(s.hideMosque),
        subtitle: Text(s.hideMosqueSub, style: const TextStyle(fontSize: 12)),
        value: app.hideMosque,
        onChanged: (v) => app.hideMosque = v,
      ),
    ]);

    final excuses = section(s.excuses, [
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (excuse != null)
              NoteBox(
                icon: excuseIcon(excuse.type),
                title: s.activeExcuse(s.excuseType(excuse.type)),
                text: s.streakSafe,
                background: WColors.greenTint,
                foreground: WColors.deepGreen,
                trailing: TextButton(onPressed: app.endExcuse, child: Text(s.endExcuse)),
              )
            else ...[
              Text(s.startExcuse, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(children: [
                for (final t in ExcuseType.values) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 72),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => app.startExcuse(t),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(excuseIcon(t)),
                        const SizedBox(height: 4),
                        Text(s.excuseType(t), textAlign: TextAlign.center),
                      ]),
                    ),
                  ),
                  if (t != ExcuseType.values.last) const SizedBox(width: 8),
                ],
              ]),
            ],
            const SizedBox(height: 10),
            NoteBox(icon: Icons.lock_outline, text: s.excusePrivacy),
          ],
        ),
      ),
    ]);

    final reminders = section(s.remindersTitle, reminderTiles(context, app, s));

    final wide = isWide(context);
    return SafeArea(
      child: wide
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: ListView(children: [general, reminders, streak])),
                const SizedBox(width: 28),
                Expanded(child: ListView(children: [excuses])),
              ]),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [general, reminders, streak, excuses],
            ),
    );
  }

  void _pickCity(BuildContext context) {
    final app = AppScope.read(context);
    final s = S.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: WColors.background,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final c in kCities)
                ListTile(
                  title: Text(s.ar ? c.nameAr : c.nameEn),
                  trailing: c.id == app.city.id
                      ? const Icon(Icons.check, color: WColors.mosqueGreen)
                      : null,
                  onTap: () {
                    app.city = c;
                    Navigator.of(ctx).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
