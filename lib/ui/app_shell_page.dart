import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/core/player/mini_player.dart';

import 'home/home_page.dart';
import 'search/search_page.dart';
import 'library/library_page.dart';
import 'settings/settings_page.dart';

abstract class AppShellController {
  void pushPage(Widget page);
  void popPage();
  BuildContext get context;
}

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  static AppShellController of(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppShellState>();
    assert(state != null, 'AppShellPage not found in widget tree');
    return state!;
  }

  @override
  State<AppShellPage> createState() => _AppShellState();
}

class _AppShellState extends State<AppShellPage>
    implements AppShellController {

  @override
  BuildContext get context => super.context;

  String? _fullscreenRoute;

  int _currentTab = 0;

  final List<Widget> _tabs = const [
    HomePage(),
    SearchPage(),
    LibraryPage(),
    SettingsPage(),
  ];

  // One Navigator key per tab
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
  List.generate(4, (_) => GlobalKey<NavigatorState>());

  // Stable navigators (created once)
  late final List<Widget> _tabNavigators;

  @override
  void initState() {
    super.initState();

    _tabNavigators = List.generate(
      _tabs.length,
          (index) => Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => _tabs[index],
          );
        },
      ),
    );
  }

  /* ---------------- NAVIGATION API ---------------- */

  @override
  void pushPage(Widget page) {
    final routeName = page.runtimeType.toString();

    final isFullscreen =
        routeName == 'FullPlayerPage' ||
            routeName == 'LyricsPage';

    if (isFullscreen) {
      setState(() {
        _fullscreenRoute = routeName;
      });
    }

    _navigatorKeys[_currentTab]
        .currentState!
        .push(MaterialPageRoute(builder: (_) => page))
        .then((_) {
      if (isFullscreen) {
        setState(() {
          _fullscreenRoute = null;
        });
      }
    });
  }


  @override
  void popPage() {
    final navigator = _navigatorKeys[_currentTab].currentState!;
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /* ---------------- EXIT DIALOG ---------------- */

  Future<void> _showExitDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1D22),
          title: const Text(
            'Leaving Rhythmax?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'What would you like to do?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () async {
                    await globalPlayer.stop();
                    SystemNavigator.pop();
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Stay',
                style: TextStyle(color: Colors.cyanAccent),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /* ---------------- BACK HANDLING ---------------- */

  void _onBackInvoked(bool didPop, Object? result) {
    if (didPop) return;

    final navigator = _navigatorKeys[_currentTab].currentState!;

    // 1️⃣ Pop inner route first
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    // 2️⃣ Not on Home → switch to Home
    if (_currentTab != 0) {
      setState(() => _currentTab = 0);
      return;
    }

    // 3️⃣ On Home root → exit
    _showExitDialog();
  }

  /* ---------------- FULLSCREEN CHECK ---------------- */

  bool _shouldHideBottomBar() {
    return _fullscreenRoute != null;
  }


  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBackInvoked,
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1D22),

        body: IndexedStack(
          index: _currentTab,
          children: _tabNavigators,
        ),

        bottomNavigationBar: _shouldHideBottomBar()
            ? null
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            const Divider(height: 0, color: Colors.white24),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (index) {
        if (_currentTab == index) {
          // Pop to root of that tab
          _navigatorKeys[index]
              .currentState!
              .popUntil((route) => route.isFirst);
        } else {
          setState(() => _currentTab = index);
        }
      },
      type: BottomNavigationBarType.shifting,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.white30,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
