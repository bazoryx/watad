import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/prayer_times.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

bool isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWideBreakpoint;

/// Calendar colors from the design: mosque green, home gold, made-up gold
/// outline, missed light gray, excused or frozen slate blue.
class OutcomeDot extends StatelessWidget {
  final SlotOutcome? outcome;
  final double size;
  const OutcomeDot(this.outcome, {super.key, this.size = 12});

  @override
  Widget build(BuildContext context) {
    Color fill = WColors.surface;
    BoxBorder? border;
    switch (outcome) {
      case SlotOutcome.mosque:
        fill = WColors.mosqueGreen;
      case SlotOutcome.home:
        fill = WColors.gold;
      case SlotOutcome.qada:
        border = Border.all(color: WColors.gold, width: size > 8 ? 2.5 : 1.5);
      case SlotOutcome.lateQada:
        fill = WColors.goldTint;
        border = Border.all(color: WColors.gold, width: size > 8 ? 2.5 : 1.5);
      case SlotOutcome.missed:
        fill = WColors.missed;
      case SlotOutcome.excused:
      case SlotOutcome.frozen:
        fill = WColors.excused;
      case SlotOutcome.pending:
      case null:
        border = Border.all(color: WColors.missed, width: 1.5);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: border),
    );
  }
}

class StreakCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final int value;
  final String unit;
  final String footer;

  const StreakCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.value,
    required this.unit,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: iconFg),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: WColors.inkMuted)),
              ),
            ]),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: WColors.deepGreen)),
                const SizedBox(width: 6),
                Flexible(
                    child: Text(unit,
                        style: const TextStyle(
                            fontSize: 12, color: WColors.inkMuted))),
              ],
            ),
            Text(footer,
                style: const TextStyle(fontSize: 12, color: WColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}

/// Dark green header with the next prayer, a live countdown and iqama time.
class NextPrayerCard extends StatefulWidget {
  const NextPrayerCard({super.key});

  @override
  State<NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<NextPrayerCard> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final now = DateTime.now();
    final next = PrayerTimesService.next(app.city, now);
    final iqama = next.time.add(Duration(minutes: kIqamaMinutes[next.prayer]!));
    final cityName = s.ar ? app.city.nameAr : app.city.nameEn;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: WColors.deepGreen,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.nextPrayer} · $cityName',
              style: const TextStyle(fontSize: 13, color: WColors.onDarkMuted)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(s.prayer(next.prayer),
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(formatTime(next.time, s),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: WColors.goldLight)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(formatCountdown(next.time.difference(now)),
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: WColors.gold, borderRadius: BorderRadius.circular(999)),
                child: Text(s.iqamaAt(formatTime(iqama, s)),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: WColors.deepGreen)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small rounded note used for excuse / freeze / privacy messages.
class NoteBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? title;
  final Color background;
  final Color foreground;
  final Widget? trailing;

  const NoteBox({
    super.key,
    required this.icon,
    required this.text,
    this.title,
    this.background = WColors.goldTint,
    this.foreground = const Color(0xFF5A4512),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, size: 20, color: foreground),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(title!,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: foreground)),
              Text(text,
                  style: TextStyle(fontSize: 12.5, color: foreground, height: 1.5)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

IconData excuseIcon(ExcuseType t) => switch (t) {
      ExcuseType.travel => Icons.flight,
      ExcuseType.illness => Icons.healing,
      ExcuseType.menstruation => Icons.nightlight_outlined,
    };
