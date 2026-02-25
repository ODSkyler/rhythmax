import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rhythmax/core/utils/connectivity.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/core/source/source_manager.dart';
import 'package:rhythmax/core/theme/dynamic_color_helper.dart';
import 'package:rhythmax/core/source/jiosaavn/jiosaavn_source.dart';

import 'package:rhythmax/core/theme/theme_controller.dart';
import 'package:rhythmax/core/theme/theme_scope.dart';
import 'package:rhythmax/ui/app_shell_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConnectivityService.instance;

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
]);

await _registerSources();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
));

runApp(
  ChangeNotifierProvider.value(
  value: globalPlayer,
  child: const RhythmaxApp(),
  ),
 );
}

/* -------------------------------------------------------------------------- */
/*                              SOURCE SETUP                                  */
/* -------------------------------------------------------------------------- */

Future<void> _registerSources() async {
 final sourceManager = SourceManager.instance;
 sourceManager.registerSource(JioSaavnSource());

 await sourceManager.restoreLastSource();
}

/* -------------------------------------------------------------------------- */
/*                                   APP                                      */
/* -------------------------------------------------------------------------- */

class RhythmaxApp extends StatefulWidget {
 const RhythmaxApp({super.key});

@override
State<RhythmaxApp> createState() => _RhythmaxAppState();
}

class _RhythmaxAppState extends State<RhythmaxApp> {
 final ThemeController _themeController = ThemeController();
 String? _lastTrackId;

@override
void initState() {
 super.initState();
 globalPlayer.addListener(_handleTrackChange);
}

void _handleTrackChange() {
 final track = globalPlayer.currentTrack;
 if (track == null) return;

if (_lastTrackId == track.id) return;
    _lastTrackId = track.id;

if (!_themeController.dynamicThemeEnabled) return;

extractAccentFromImage(track.artworkUrl ?? '').then((color) {
 if (color == null) return;
   _themeController.setDynamicAccent(color);
  });
}

@override
void dispose() {
  globalPlayer.removeListener(_handleTrackChange);
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return AnimatedBuilder(
  animation: _themeController,
  builder: (context, _) {
 final bg = _themeController.backgroundColor;

SystemChrome.setSystemUIOverlayStyle(
 SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: bg,
  systemNavigationBarIconBrightness: Brightness.light,
 ),
);

return ThemeScope(
 controller: _themeController,
   child: AnimatedTheme(
   duration: const Duration(milliseconds: 350),
   curve: Curves.easeInOut,
   data: ThemeData(
     appBarTheme: AppBarTheme(
     backgroundColor: Colors.transparent,
       surfaceTintColor: Colors.transparent,
       centerTitle: true,
 ),
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: bg,
  fontFamily: 'Poppins',
  colorScheme: ColorScheme.dark(
  surface: bg,
  primary: _themeController.accentColor,
  secondary: _themeController.accentColor,
  ),
),
child: const AppShellWrapper(),
     ),
    );
   },
  );
 }
}

class AppShellWrapper extends StatelessWidget {
const AppShellWrapper({super.key});

@override
Widget build(BuildContext context) {
  return MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: Theme.of(context),
  home: const AppShellPage(),
  );
 }
}
