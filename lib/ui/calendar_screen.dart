import 'package:flutter/material.dart';
import '../core/models.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'log_sheet.dart';
import 'widgets/common.dart';

/// Color-coded month: five dots per day (one per prayer). Tapping a day
/// shows its prayers, which can be edited back to the install day.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = dayOf(now);
  }

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final now = DateTime.now();
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;

    final header = Row(children: [
      IconButton(
        tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
        onPressed: () => _shift(-1),
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Text('${s.monthName(_month.month)} ${_month.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      IconButton(
        tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
        onPressed: isCurrentMonth ? null : () => _shift(1),
        icon: const Icon(Icons.chevron_right),
      ),
    ]);

    final grid = Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: _MonthGrid(
          month: _month,
          selected: _selected,
          onSelect: (d) => setState(() => _selected = d),
        ),
      ),
    );
    const legend = _Legend();
    final details = _DayDetails(day: _selected);
    final stats = _MonthStats(month: _month);

    if (!isWide(context)) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            header,
            grid,
            const SizedBox(height: 10),
            legend,
            const SizedBox(height: 12),
            details,
            const SizedBox(height: 12),
            stats,
          ],
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ListView(children: [header, grid, const SizedBox(height: 10), legend]),
            ),
            const SizedBox(width: 28),
            Expanded(
              flex: 2,
              child: ListView(children: [
                const SizedBox(height: 48),
                details,
                const SizedBox(height: 12),
                stats,
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _MonthGrid({required this.month, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final today = dayOf(DateTime.now());
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Weeks start on Saturday (Gulf). Dart weekday: Mon=1 ... Sun=7.
    final offset = (first.weekday + 1) % 7;

    return Column(children: [
      Row(
        children: [
          for (final w in s.weekdaysShort)
            Expanded(
              child: Text(w,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: WColors.inkMuted)),
            ),
        ],
      ),
      const SizedBox(height: 6),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.82,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: [
          for (var i = 0; i < offset; i++) const SizedBox.shrink(),
          for (var d = 1; d <= daysInMonth; d++)
            _DayCell(
              day: DateTime(month.year, month.month, d),
              isToday: DateTime(month.year, month.month, d) == today,
              isSelected: DateTime(month.year, month.month, d) == selected,
              tracked: app.canLog(DateTime(month.year, month.month, d)),
              onTap: onSelect,
            ),
        ],
      ),
    ]);
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool tracked;
  final ValueChanged<DateTime> onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.tracked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Material(
      color: isSelected ? WColors.greenTint : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: WColors.mosqueGreen, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(day),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${day.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday
                      ? WColors.mosqueGreen
                      : (tracked ? WColors.ink : WColors.missed),
                )),
            const SizedBox(height: 4),
            if (tracked)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final p in Prayer.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.75),
                      child: OutcomeDot(app.outcomeFor(day, p), size: 5),
                    ),
                ],
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget item(SlotOutcome o, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutcomeDot(o, size: 10),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 11.5, color: WColors.inkMuted)),
          ],
        );
    return Wrap(spacing: 14, runSpacing: 6, children: [
      item(SlotOutcome.mosque, s.legendMosque),
      item(SlotOutcome.home, s.legendHome),
      item(SlotOutcome.qada, s.legendQada),
      item(SlotOutcome.missed, s.legendMissed),
      item(SlotOutcome.excused, s.legendExcused),
    ]);
  }
}

class _DayDetails extends StatelessWidget {
  final DateTime day;
  const _DayDetails({required this.day});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final today = dayOf(DateTime.now());
    final title = '${day.day} ${s.monthName(day.month)} ${day.year}';

    Widget body;
    if (day.isAfter(today)) {
      body = Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(s.futureDay, style: const TextStyle(color: WColors.inkMuted)));
    } else if (day.isBefore(app.startDay)) {
      body = Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(s.beforeStart, style: const TextStyle(color: WColors.inkMuted)));
    } else {
      body = Column(children: [
        for (final p in Prayer.values)
          InkWell(
            onTap: app.canLogSlot(day, p) ? () => showLogSheet(context, day, p) : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: WColors.line))),
              child: Row(children: [
                OutcomeDot(app.outcomeFor(day, p)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(s.prayer(p),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                Text(s.outcome(app.outcomeFor(day, p) ?? SlotOutcome.pending),
                    style: const TextStyle(fontSize: 12.5, color: WColors.inkMuted)),
                if (app.canLogSlot(day, p))
                  const Icon(Icons.chevron_right, size: 20, color: WColors.inkMuted),
              ]),
            ),
          ),
      ]);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            body,
          ],
        ),
      ),
    );
  }
}

class _MonthStats extends StatelessWidget {
  final DateTime month;
  const _MonthStats({required this.month});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    var mosque = 0, home = 0, qada = 0, missed = 0;
    final days = DateTime(month.year, month.month + 1, 0).day;
    for (var d = 1; d <= days; d++) {
      final day = DateTime(month.year, month.month, d);
      for (final p in Prayer.values) {
        switch (app.outcomeFor(day, p)) {
          case SlotOutcome.mosque:
            mosque++;
          case SlotOutcome.home:
            home++;
          case SlotOutcome.qada:
          case SlotOutcome.lateQada:
            qada++;
          case SlotOutcome.missed:
            missed++;
          default:
            break;
        }
      }
    }
    Widget tile(String label, int n, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: WColors.background, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text('$n', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c)),
              Text(label, style: const TextStyle(fontSize: 11.5, color: WColors.inkMuted)),
            ]),
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.monthStats, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
              tile(s.legendMosque, mosque, WColors.mosqueGreen),
              const SizedBox(width: 8),
              tile(s.legendHome, home, const Color(0xFF8A6A1E)),
              const SizedBox(width: 8),
              tile(s.legendQada, qada, const Color(0xFF8A6A1E)),
              const SizedBox(width: 8),
              tile(s.legendMissed, missed, WColors.inkMuted),
            ]),
          ],
        ),
      ),
    );
  }
}
