import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/udp_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _udp = UdpService();
  bool _pinging = false;
  double _power = 100;

  @override
  void initState() {
    super.initState();
    _udp.statusStream.listen((_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ping();
    });
  }

  Future<void> _send(String cmd) async {
    final ok = await _udp.send(cmd);
    if (mounted) showStatus(context, cmd, success: ok);
  }

  Future<void> _ping() async {
    setState(() => _pinging = true);
    await _udp.ping();
    if (mounted) setState(() => _pinging = false);
  }

  Future<void> _setPower(double v) async {
    setState(() => _power = v);
    await _send('maxLedPow ${v.toInt().toString().padLeft(3, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Connection status card ─────────────────────────────────────
          AppCard(
            title: 'Connection',
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.router_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_udp.host}:${_udp.port}',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 14,
                              color: AppColors.text,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Arduino UDP target',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _PingButton(
                      loading: _pinging,
                      status: _udp.status,
                      onTap: _ping,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Power slider card ──────────────────────────────────────────
          AppCard(
            title: 'LED Power',
            child: AppSlider(
              label: 'Brightness',
              value: _power,
              min: 5,
              max: 100,
              divisions: 19,
              displayValue: (v) => '${v.toInt()}%',
              onChanged: (v) => setState(() => _power = v),
              // Apply on finger-up to avoid flooding UDP
            ),
          ),

          // ── Quick actions ──────────────────────────────────────────────
          AppCard(
            title: 'Quick Actions',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Disco',
                        icon: Icons.auto_awesome,
                        active: false,
                        onTap: () => _send('disco 08 1500'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Race All',
                        icon: Icons.speed,
                        active: false,
                        onTap: () => _send('looprace A y'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Stop All',
                        icon: Icons.stop_circle_outlined,
                        active: false,
                        onTap: () => _send('looprace A n'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final entry in [
                      ('R', const Color(0xFFE74C3C), 'setBG 255 000 000 000 000 081'),
                      ('G', const Color(0xFF38C172), 'setBG 000 255 000 000 000 081'),
                      ('B', const Color(0xFF3498DB), 'setBG 000 000 255 000 000 081'),
                      ('W', AppColors.text, 'setBG 000 000 000 255 000 081'),
                    ]) ...[
                      Expanded(
                        child: _ColorDot(
                          label: entry.$1,
                          color: entry.$2,
                          onTap: () => _send(entry.$3),
                        ),
                      ),
                      if (entry.$1 != 'W') const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Apply power button ─────────────────────────────────────────
          AppWideButton(
            label: 'Apply Power  ${_power.toInt()}%',
            icon: Icons.bolt_rounded,
            onTap: () => _setPower(_power),
          ),

          const SizedBox(height: 12),

          // ── All off ────────────────────────────────────────────────────
          AppWideButton(
            label: 'All Off',
            icon: Icons.power_settings_new_rounded,
            color: AppColors.error,
            onTap: () => _send('allOff'),
          ),

          const SizedBox(height: 16),

          // ── Recent commands log ────────────────────────────────────────
          AppCard(
            title: 'Command Log',
            child: _udp.log.isEmpty
                ? Text(
                    'No commands sent yet.',
                    style: GoogleFonts.sourceCodePro(
                        fontSize: 12, color: AppColors.textSecondary),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _udp.log.take(6).map((entry) {
                      final isError = entry.contains('✗');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          entry,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            color: isError
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Ping button ──────────────────────────────────────────────────────────────

class _PingButton extends StatelessWidget {
  final bool loading;
  final ArduinoStatus status;
  final VoidCallback onTap;

  const _PingButton(
      {required this.loading, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Dot color + label based on real reply status
    final Color dotColor;
    final String label;
    switch (status) {
      case ArduinoStatus.online:
        dotColor = AppColors.success;   // green  — got reply
        label = 'ONLINE';
      case ArduinoStatus.offline:
        dotColor = AppColors.error;     // red    — timed out, no reply
        label = 'OFFLINE';
      case ArduinoStatus.unknown:
        dotColor = AppColors.inactiveBtn; // gray — never pinged yet
        label = 'PING';
    }

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inactiveBtn,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: status == ArduinoStatus.online
                ? AppColors.success.withOpacity(0.4)
                : status == ArduinoStatus.offline
                    ? AppColors.error.withOpacity(0.4)
                    : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppColors.activeBtn),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: dotColor),
              ),
            const SizedBox(width: 7),
            Text(
              loading ? 'PINGING…' : label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: loading
                    ? AppColors.textSecondary
                    : status == ArduinoStatus.online
                        ? AppColors.success
                        : status == ArduinoStatus.offline
                            ? AppColors.error
                            : AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Color dot quick button ────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ColorDot(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35), width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}