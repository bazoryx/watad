import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/repository.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await Repository.open();
  runApp(WatadApp(state: AppState(repo)));
}

class WatadApp extends StatelessWidget {
  final AppState state;
  final bool googleFonts;
  const WatadApp({super.key, required this.state, this.googleFonts = true});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'وتد',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(googleFonts: googleFonts),
          locale: AppScope.of(context).locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AppShell(),
        ),
      ),
    );
  }
}
