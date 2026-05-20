import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/udp_service.dart';
import 'settings_sheet.dart';

/// Drop-in scaffold every feature page uses.
///
/// Usage:
/// ```dart
/// return AppScaffold(
///   title: 'Disco',
///   child: YourPageContent(),
/// );
/// ```
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  Future<void> _confirmAllOff(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sidebar,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Turn everything off?',
            style: GoogleFonts.inter(
                color: AppColors.text, fontWeight: FontWeight.w600)),
        content: Text('This sends "allOff" to the Arduino.',
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('ALL OFF',
                style: GoogleFonts.inter(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) UdpService().send('allOff');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopNavBar(title: title, onReset: () => _confirmAllOff(context)),
            const _NavDivider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top nav bar ────────────────────────────────────────────────────────────

class _TopNavBar extends StatelessWidget {
  final String title;
  final VoidCallback onReset;

  const _TopNavBar({required this.title, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      color: AppColors.sidebar,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // App icon
          _AppIcon(),
          const SizedBox(width: 12),

          // Page title
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // Reset (all off) button
          _NavIconButton(
            icon: Icons.power_settings_new_rounded,
            color: AppColors.error,
            tooltip: 'All Off',
            onTap: onReset,
          ),
          const SizedBox(width: 4),

          // Settings button
          _NavIconButton(
            icon: Icons.settings_outlined,
            color: AppColors.textSecondary,
            tooltip: 'Settings',
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => const SettingsSheet(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            'assets/images/logo-mini.png',
          fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _NavIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.inactiveBtn,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _NavDivider extends StatelessWidget {
  const _NavDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.divider.withOpacity(0.5));
  }
}
