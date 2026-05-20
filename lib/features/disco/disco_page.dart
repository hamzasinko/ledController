import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/udp_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_widgets.dart';

class DiscoPage extends StatefulWidget {
  const DiscoPage({super.key});

  @override
  State<DiscoPage> createState() => _DiscoPageState();
}

class _DiscoPageState extends State<DiscoPage> {
  final _udp = UdpService();

  double _ledCount = 8;
  double _speed = 1500;
  double _blinks = 100;
  String _selectedColor = 'A';

  Future<void> _send(String cmd) async {
    final ok = await _udp.send(cmd);
    if (mounted) showStatus(context, cmd, success: ok);
  }

  String _pad4(int v) => v.toString().padLeft(4, '0');

  void _applyDisco(String mode) {
    final leds = _pad2(_ledCount.toInt());
    final ms = _pad4(_speed.toInt());
    final blinks = _pad4(_blinks.toInt());

    final cmd = "$mode $leds $ms $blinks";
    _send(cmd);
  }

  String _pad2(int v) => v.toString().padLeft(2, '0');

  Widget _buildColorButton(String key, String label, Color color) {
    final bool active = _selectedColor == key;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedColor = key);
          _applyDisco("disco$key");
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


  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Disco Mode',
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── LED amount ────────────────────────────────────────────────
          AppCard(
            title: 'LED Amount',
            child: AppSlider(
              label: 'How many LEDs',
              value: _ledCount,
              min: 1,
              max: 81,
              divisions: 80,
              displayValue: (v) => v.toInt().toString(),
              onChanged: (v) => setState(() => _ledCount = v),
            ),
          ),

          // ── Speed ─────────────────────────────────────────────────────
          AppCard(
            title: 'Speed (ms)',
            child: AppSlider(
              label: 'On-time (ms)',
              value: _speed,
              min: 50,
              max: 3000,
              divisions: 59,
              displayValue: (v) => v.toInt().toString(),
              onChanged: (v) => setState(() => _speed = v),
            ),
          ),

          // ── Blink amount ──────────────────────────────────────────────
          AppCard(
            title: 'Blink Amount',
            child: AppSlider(
              label: 'How many repeats',
              value: _blinks,
              min: 1,
              max: 9999,
              divisions: 999,
              displayValue: (v) => v.toInt().toString(),
              onChanged: (v) => setState(() => _blinks = v),
            ),
          ),

          // ── Quick color modes ─────────────────────────────────────────
          AppCard(
            title: 'Color Modes',
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

          // ── Basic disco (legacy) ──────────────────────────────────────
          AppCard(
            title: 'Basic Disco',
            child: AppWideButton(
              label: 'Start Disco',
              icon: Icons.flash_on,
              onTap: () {
                final leds = _pad2(_ledCount.toInt());
                final ms = _pad4(_speed.toInt());
                _send("disco $leds $ms");
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── Stop ──────────────────────────────────────────────────────
          AppWideButton(
            label: 'Stop Disco',
            icon: Icons.stop_circle_outlined,
            color: AppColors.error,
            onTap: () {
              _send("discoA 00 0000 0000");
              setState(() {
                _selectedColor = 'A';
              });
            }
          ),
        ],
      ),
    );
  }
}