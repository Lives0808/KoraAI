import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../chat/chat_screen.dart';
import '../documents/documents_screen.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_screen.dart';

/// Responsive shell: bottom navigation on phones, a navigation rail on
/// tablets and desktop.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final settings = context.watch<SettingsController>();
    final needsSetup = settings.isLoaded && !settings.settings.isReady;

    final pages = const <Widget>[
      ChatScreen(),
      DocumentsScreen(),
      SettingsScreen(),
    ];

    final body = IndexedStack(index: _index, children: pages);

    if (!wide) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: <Widget>[
            NavigationDestination(
              icon: const Icon(Icons.forum_outlined),
              selectedIcon: const Icon(Icons.forum),
              label: l10n.navChat,
            ),
            NavigationDestination(
              icon: const Icon(Icons.description_outlined),
              selectedIcon: const Icon(Icons.description),
              label: l10n.navDocuments,
            ),
            NavigationDestination(
              icon: _Badged(
                show: needsSetup,
                child: const Icon(Icons.settings_outlined),
              ),
              selectedIcon: _Badged(
                show: needsSetup,
                child: const Icon(Icons.settings),
              ),
              label: l10n.navSettings,
            ),
          ],
        ),
      );
    }

    final destinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: const Icon(Icons.forum_outlined),
        selectedIcon: const Icon(Icons.forum),
        label: Text(l10n.navChat),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.description_outlined),
        selectedIcon: const Icon(Icons.description),
        label: Text(l10n.navDocuments),
      ),
      NavigationRailDestination(
        icon: _Badged(
          show: needsSetup,
          child: const Icon(Icons.settings_outlined),
        ),
        selectedIcon: _Badged(
          show: needsSetup,
          child: const Icon(Icons.settings),
        ),
        label: Text(l10n.navSettings),
      ),
    ];

    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: _BrandMark(),
            ),
            destinations: destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Marks a navigation destination with a hint dot until the app is configured.
class _Badged extends StatelessWidget {
  const _Badged({required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Badge(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      child: child,
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        'K',
        style: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }
}
