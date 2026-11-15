import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/prayer_times.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'log_sheet.dart';
import 'mosques_screen.dart';
import 'widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final sum = app.summary;

    final header = Row(children: [
      Text(s.appName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: WColors.deepGreen)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: WColors.surface, borderRadius: BorderRadius.circular(999)),
        child: Text('${s.score} · ${s.points(sum.score)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WColors.inkMuted)),
      ),
    ]);

    final mosqueCard = StreakCard(
      icon: Icons.mosque,
      iconBg: WColors.mosqueGreen,
      iconFg: Colors.white,
      title: s.mosqueStreak,
      value: sum.mosque,
      unit: s.consecutivePrayers,
      footer: s.best(sum.mosqueBest),
    );
    final maintCard = StreakCard(
      icon: Icons.home_outlined,
      iconBg: WColors.gold,
      iconFg: WColors.deepGreen,
      title: s.maintenanceStreak,
      value: sum.maintenance,
      unit: s.consecutivePrayers,
      footer: '${s.mosqueOrHome} · ${s.best(sum.maintenanceBest)}',
    );
    final streaks = app.hideMosque
        ? maintCard
        : IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: mosqueCard),
              const SizedBox(width: 12),
              Expanded(child: maintCard),
            ]),
          );

    final banner = _StatusBanner();
    final tools = const _ToolsCard();
    final today = const _TodayCard();

    if (!isWide(context)) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            header,
            const SizedBox(height: 12),
            const NextPrayerCard(),
            const SizedBox(height: 12),
            streaks,
            banner,
            const SizedBox(height: 12),
            tools,
            const SizedBox(height: 12),
            today,
          ],
        ),
      );
    }

    // Inner foldable screen: two panes, with the gap on the hinge line.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(children: [
                header,
                const SizedBox(height: 12),
                const NextPrayerCard(),
                const SizedBox(height: 12),
                streaks,
                banner,
                const SizedBox(height: 12),
                tools,
              ]),
            ),
            const SizedBox(width: 28),
            Expanded(child: ListView(children: [today])),
          ],
        ),
      ),
    );
  }
}

class _ToolsCard extends StatelessWidget {
  const _ToolsCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.mosque_outlined, color: WColors.mosqueGreen),
        title: Text(s.nearestMosque),
        subtitle: Text(s.nearestMosqueSub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const MosquesScreen())),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final excuse = app.activeExcuse;
    Widget? child;
    if (excuse != null) {
      child = NoteBox(
        icon: excuseIcon(excuse.type),
        title: s.activeExcuse(s.excuseType(excuse.type)),
        text: s.streakSafe,
        background: WColors.greenTint,
        foreground: WColors.deepGreen,
        trailing: TextButton(onPressed: app.endExcuse, child: Text(s.endExcuse)),
      );
    } else {
      final left = app.summary.freezesLeft(DateTime.now());
      if (left < 2) {
        child = NoteBox(
          icon: Icons.ac_unit,
          text: s.freezesLeft(left),
          background: const Color(0xFFEAF2FA),
          foreground: const Color(0xFF2C4A66),
        );
      }
    }
    if (child == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 12), child: child);
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final today = dayOf(DateTime.now());
    final times = PrayerTimesService.forDay(app.city, today);
    final logged = Prayer.values.where((p) => app.logFor(today, p) != null).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(children: [
          SizedBox(
            height: 40,
            child: Row(children: [
              Text(s.todaysPrayers,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(s.loggedOf(logged),
                  style: const TextStyle(fontSize: 12, color: WColors.inkMuted)),
            ]),
          ),
          for (final p in Prayer.values)
            _PrayerRow(
              day: today,
              prayer: p,
              time: times[p]!,
              outcome: app.outcomeFor(today, p),
              enabled: app.canLogSlot(today, p),
            ),
        ]),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final DateTime day;
  final Prayer prayer;
  final DateTime time;
  final SlotOutcome? outcome;
  final bool enabled;

  const _PrayerRow({
    required this.day,
    required this.prayer,
    required this.time,
    required this.outcome,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final status = enabled ? s.outcome(outcome ?? SlotOutcome.pending) : '';
    return InkWell(
      onTap: enabled ? () => showLogSheet(context, day, prayer) : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: WColors.line))),
        child: Row(children: [
          OutcomeDot(outcome),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(s.prayer(prayer),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: enabled ? WColors.ink : WColors.inkMuted)),
          ),
          Text(formatTime(time, s),
              style: const TextStyle(fontSize: 13, color: WColors.inkMuted)),
          const Spacer(),
          Text(status,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: outcome == SlotOutcome.mosque
                      ? WColors.mosqueGreen
                      : WColors.inkMuted)),
          if (enabled)
            const Icon(Icons.chevron_right, size: 20, color: WColors.inkMuted),
        ]),
      ),
    );
  }
}
