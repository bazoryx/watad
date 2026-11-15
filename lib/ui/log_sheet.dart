import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/prayer_times.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

/// Opens the "where did you pray?" choices: a bottom sheet on narrow
/// screens, a centered dialog with the three main choices side by side on
/// the inner foldable screen.
Future<void> showLogSheet(BuildContext context, DateTime day, Prayer prayer) {
  final content = _LogSheet(day: dayOf(day), prayer: prayer);
  if (isWide(context)) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: WColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: content,
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: WColors.background,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => content,
  );
}

enum _Look { primary, gold, outline }

class _LogSheet extends StatelessWidget {
  final DateTime day;
  final Prayer prayer;
  const _LogSheet({required this.day, required this.prayer});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final wide = isWide(context);
    final current = app.logFor(day, prayer)?.status;
    final time = PrayerTimesService.forDay(app.city, day)[prayer]!;
    final isToday = day == dayOf(DateTime.now());
    final dateLabel = isToday ? '' : '${day.day} ${s.monthName(day.month)} · ';

    void pick(LogStatus st) {
      app.setLog(day, prayer, st);
      Navigator.of(context).pop();
    }

    final mosque = _Choice(
      look: _Look.primary,
      icon: Icons.mosque,
      title: s.atMosque,
      sub: s.atMosqueSub,
      selected: current == LogStatus.mosque,
      onTap: () => pick(LogStatus.mosque),
    );
    final home = _Choice(
      look: _Look.gold,
      icon: Icons.home_outlined,
      title: s.atHome,
      sub: s.atHomeSub,
      selected: current == LogStatus.home,
      onTap: () => pick(LogStatus.home),
    );
    final qada = _Choice(
      look: _Look.outline,
      icon: Icons.history,
      title: s.qada,
      sub: s.qadaSub,
      selected: current == LogStatus.qada,
      onTap: () => pick(LogStatus.qada),
    );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, wide ? 22 : 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$dateLabel${s.prayer(prayer)} · ${formatTime(time, s)}',
                        style: const TextStyle(fontSize: 13, color: WColors.inkMuted)),
                    Text(s.wherePrayed(prayer),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ]),
            const SizedBox(height: 14),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: mosque),
                    const SizedBox(width: 10),
                    Expanded(child: home),
                    const SizedBox(width: 10),
                    Expanded(child: qada),
                  ],
                ),
              )
            else ...[
              mosque,
              const SizedBox(height: 10),
              home,
              const SizedBox(height: 10),
              qada,
            ],
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _SmallChoice(
                  label: s.lateQada,
                  sub: s.lateQadaSub,
                  selected: current == LogStatus.lateQada,
                  onTap: () => pick(LogStatus.lateQada),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallChoice(
                  label: s.missed,
                  sub: '',
                  selected: current == LogStatus.missed,
                  onTap: () => pick(LogStatus.missed),
                ),
              ),
            ]),
            if (app.isExcused(day)) ...[
              const SizedBox(height: 10),
              NoteBox(icon: Icons.ac_unit, text: s.excusedDay),
            ],
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined, color: WColors.mosqueGreen),
              title: Text(s.locationConfirm, style: const TextStyle(fontSize: 14)),
              trailing: const Switch(value: false, onChanged: null),
            ),
            if (current != null)
              TextButton.icon(
                onPressed: () {
                  app.clearLog(day, prayer);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(s.clearLog),
                style: TextButton.styleFrom(foregroundColor: WColors.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final _Look look;
  final IconData icon;
  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({
    required this.look,
    required this.icon,
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = look == _Look.primary;
    final bg = primary ? WColors.mosqueGreen : (look == _Look.gold ? WColors.surface : Colors.transparent);
    final fg = primary ? Colors.white : WColors.ink;
    final subColor = primary ? const Color(0xFFD5EBE1) : WColors.inkMuted;
    final border = switch (look) {
      _Look.primary => BorderSide(color: selected ? WColors.deepGreen : WColors.mosqueGreen, width: selected ? 3 : 2),
      _Look.gold => BorderSide(color: WColors.gold, width: selected ? 3 : 2),
      _Look.outline => BorderSide(color: selected ? WColors.gold : const Color(0xFFA8A396), width: selected ? 2.5 : 1),
    };
    final iconBox = switch (look) {
      _Look.primary => BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
      _Look.gold => BoxDecoration(color: WColors.gold, borderRadius: BorderRadius.circular(14)),
      _Look.outline => BoxDecoration(
          border: Border.all(color: WColors.gold, width: 2),
          borderRadius: BorderRadius.circular(14)),
    };
    final iconColor = switch (look) {
      _Look.primary => Colors.white,
      _Look.gold => WColors.deepGreen,
      _Look.outline => const Color(0xFF8A6A1E),
    };

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), side: border),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: iconBox,
              child: Icon(icon, size: 26, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 12.5, color: subColor)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: primary ? Colors.white : WColors.mosqueGreen),
          ]),
        ),
      ),
    );
  }
}

class _SmallChoice extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const _SmallChoice(
      {required this.label, required this.sub, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? WColors.chip : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? WColors.inkMuted : WColors.line, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (sub.isNotEmpty)
                  Text(sub,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: WColors.inkMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
