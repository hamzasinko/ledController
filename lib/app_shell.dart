import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/disco/disco_page.dart';
import '../features/strobe/strobe_page.dart';
import '../features/racing/racing_page.dart';
import '../features/background/background_page.dart';
import '../features/presets/presets_page.dart';
import '../features/diagnostics/diagnostics_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    DiscoPage(),
    StrobePage(),
    RacingPage(),
    BackgroundPage(),
    PresetsPage(),
    DiagnosticsPage(),
  ];

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.dashboard_outlined,      activeIcon: Icons.dashboard_rounded,          label: 'Home'),
    _NavItem(icon: Icons.auto_awesome_outlined,    activeIcon: Icons.auto_awesome,               label: 'Disco'),
    _NavItem(icon: Icons.flash_on_outlined,        activeIcon: Icons.flash_on,                   label: 'Strobe'),
    _NavItem(icon: Icons.speed_outlined,           activeIcon: Icons.speed,                      label: 'Race'),
    _NavItem(icon: Icons.gradient_outlined,        activeIcon: Icons.gradient,                   label: 'BG'),
    _NavItem(icon: Icons.bookmark_outline,         activeIcon: Icons.bookmark,                   label: 'Presets'),
    _NavItem(icon: Icons.monitor_heart_outlined,   activeIcon: Icons.monitor_heart,              label: 'Diag'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: _BottomBar(
        selectedIndex: _index,
        items: _items,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? item.activeIcon : item.icon,
                          size: 22,
                          color: active
                              ? AppColors.activeBtn
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: active
                                ? AppColors.activeBtn
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
