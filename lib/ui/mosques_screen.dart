import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/mosques.dart';
import '../data/location.dart';
import '../data/mosque_finder.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

enum _Phase { locating, searching, done, error }

/// Nearest mosques around the user's current position.
class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key});

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen> {
  _Phase _phase = _Phase.locating;
  List<Mosque> _mosques = const [];
  String Function(S)? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.locating);
    try {
      final here = await currentLocation();
      if (!mounted) return;
      setState(() => _phase = _Phase.searching);
      final found = await MosqueFinder().nearby(here.lat, here.lng);
      if (!mounted) return;
      setState(() {
        _mosques = found;
        _phase = _Phase.done;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = switch (e.problem) {
          LocationProblem.unavailable => (S s) => s.locUnavailable,
          _ => (S s) => s.locDenied,
        };
        _phase = _Phase.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = (S s) => s.searchFailed;
        _phase = _Phase.error;
      });
    }
  }

  Future<void> _directions(Mosque m) => launchUrl(
        Uri.parse('https://www.google.com/maps/dir/?api=1'
            '&destination=${m.lat},${m.lng}&travelmode=walking'),
        mode: LaunchMode.externalApplication,
      );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget body;
    switch (_phase) {
      case _Phase.locating:
      case _Phase.searching:
        body = Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_phase == _Phase.locating ? s.locating : s.searchingMosques),
          ]),
        );
      case _Phase.error:
        body = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!(s), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: Text(s.retry)),
            ]),
          ),
        );
      case _Phase.done:
        body = _mosques.isEmpty
            ? Center(child: Text(s.noMosques))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  for (final m in _mosques)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.mosque, color: WColors.mosqueGreen),
                        title: Text(m.displayName(s.ar) ?? s.unnamedMosque),
                        subtitle: Text(s.distance(m.distanceM)),
                        trailing: IconButton(
                          tooltip: s.directions,
                          icon: const Icon(Icons.directions_walk),
                          onPressed: () => _directions(m),
                        ),
                        onTap: () => _directions(m),
                      ),
                    ),
                  const SizedBox(height: 8),
                  NoteBox(icon: Icons.info_outline, text: s.mosquesNote),
                ],
              );
    }
    return Scaffold(
      appBar: AppBar(title: Text(s.nearestMosque)),
      body: SafeArea(child: body),
    );
  }
}
