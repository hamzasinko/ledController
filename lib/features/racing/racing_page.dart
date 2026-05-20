import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/udp_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_widgets.dart';

class RacingPage extends StatefulWidget {
  const RacingPage({super.key});

  @override
  State<RacingPage> createState() => _RacingPageState();
}

class _RacingPageState extends State<RacingPage> {
  final _udp = UdpService();

  String _selectedColor = 'A'; // A, R, G, B, W
  bool _running = false;

  Future<void> _send(String cmd) async {
    final ok = await _udp.send(cmd);
    if (mounted) showStatus(context, cmd, success: ok);
  }

  Future<void> _startRace() async {
    setState(() => _running = true);
    await _send("looprace $_selectedColor y");
  }

  Future<void> _stopRace() async {
    setState(() => _running = false);
    await _send("looprace $_selectedColor n");
  }

  Future<void> _startRaceAll() async {
    setState(() => _running = true);
    await _send("looprace A y");
  }

  Future<void> _stopRaceAll() async {
    setState(() => _running = false);
    await _send("looprace A n");
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Racing Mode',
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Color selection ───────────────────────────────────────────
          AppCard(
            title: 'Race Color',
            child: Row(
              children: [
                _buildColorButton('A', 'All', AppColors.activeBtn),
                const SizedBox(width: 8),
                _buildColorButton('R', 'Red', const Color(0xFFE74C3C)),
                const SizedBox(width: 8),
                _buildColorButton('G', 'Green', const Color(0xFF38C172)),
                const SizedBox(width: 8),
                _buildColorButton('B', 'Blue', const Color(0xFF3498DB)),
                const SizedBox(width: 8),
                _buildColorButton('W', 'White', AppColors.text),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Start / Stop buttons ──────────────────────────────────────
          AppCard(
            title: 'Race Control',
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Start',
                    icon: Icons.play_arrow_rounded,
                    active: _running,
                    onTap: _running
                        ? null
                        : () {
                            _startRace();
                          },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Stop',
                    icon: Icons.stop_circle_outlined,
                    active: !_running,
                    onTap: _running
                        ? () {
                            _stopRace();
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Wide button ───────────────────────────────────────────────
          AppWideButton(
            label: _running ? 'Stop Race All' : 'Start Race All',
            icon: _running ? Icons.stop : Icons.play_arrow_rounded,
            color: _running ? AppColors.error : AppColors.activeBtn,
            onTap: () {
              if (_running) {
                _stopRaceAll();
              } else {
                _startRaceAll();
              }
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // COLOR BUTTON BUILDER
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildColorButton(String key, String label, Color color) {
    final active = _selectedColor == key;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedColor = key);

          if (_running) {
            if (key == 'A') {
              _startRaceAll();
            } else {
              _startRace();
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.35) : color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? color : color.withOpacity(0.35),
              width: active ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}