import 'package:flutter/material.dart';

class AdaptiveDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AdaptiveDestination({required this.label, required this.icon, IconData? selectedIcon})
      : selectedIcon = selectedIcon ?? icon;
}

/// Single navigation shell used by the whole authenticated app: a bottom
/// [NavigationBar] under ~700px of width (phones), a [NavigationRail]
/// above it (tablets/desktop) — same destinations, same selection state,
/// so no feature screen needs to know which form factor it's running on.
class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? railTrailingActions;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.floatingActionButton,
    this.railTrailingActions,
  });

  static const double _desktopBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Image(
                  image: AssetImage('assets/branding/logo_emblem.png'),
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              trailing: railTrailingActions != null
                  ? Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(mainAxisSize: MainAxisSize.min, children: railTrailingActions!),
                        ),
                      ),
                    )
                  : null,
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map((d) => NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label))
            .toList(),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
