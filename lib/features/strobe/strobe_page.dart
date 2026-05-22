import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/udp_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_widgets.dart';

class StrobePage extends StatefulWidget {
  const StrobePage({super.key});

  @override
  State<StrobePage> createState() => _StrobePageState();
}

class _StrobePageState extends State<StrobePage> {
  final _udp = UdpService();

  String _selectedColor = 'A'; // A, R, G, B, W
  bool _running = false;

  double _amount = 10;     // aa (2 digits)
  double _millisOn = 5;    // xx (2 digits)
  double _millisOff = 120; // oooo (4 digits)

  // RGBW values for each color
  final Map<String, List<int>> colorMap = {
    'A': [255, 255, 255, 255],
    'R': [255, 0, 0, 0],
    'G': [0, 255, 0, 0],
    'B': [0, 0, 255, 0],
    'W': [0, 0, 0, 255],
  };

  // Padding helpers
  String _pad3(int v) => v.toString().padLeft(3, '0');
  String _pad2(int v) => v.toString().padLeft(2, '0');
  String _pad4(int v) => v.toString().padLeft(4, '0');

  Future<void> _send(String cmd) async {
    final ok = await _udp.send(cmd);
    if (mounted) showStatus(context, cmd, success: ok);
  }

  Future<void> _startStrobe() async {
    setState(() => _running = true);

    final rgbw = colorMap[_selectedColor]!;
    final r = _pad3(rgbw[0]);
    final g = _pad3(rgbw[1]);
    final b = _pad3(rgbw[2]);
    final w = _pad3(rgbw[3]);

    final aa = _pad2(_amount.toInt());
    final xx = _pad2(_millisOn.toInt());
    final oooo = _pad4(_millisOff.toInt());

    // FIRST COMMAND → RGBW intensities
    await _send("setStrobeRGBW $r $g $b $w");

    // SECOND COMMAND → timing
    await _send("strobe $aa $xx $oooo");
  }

  Future<void> _stopStrobe() async {
    setState(() => _running = false);

    await _send("setStrobeRGBW 000 000 000 000");
    await _send("strobe 00 00 0000");
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Strobe Mode',
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Color selection ───────────────────────────────────────────
          AppCard(
            title: 'Strobe Color',
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

          // ── Amount of strobes ─────────────────────────────────────────
          AppCard(
            title: 'Amount of Strobes',
            child: AppSlider(
              label: 'Amount',
              value: _amount,
              min: 1,
              max: 50,
              divisions: 49,
              displayValue: (v) => _pad2(v.toInt()),
              onChanged: (v) {
                setState(() => _amount = v);
                if (_running) _startStrobe();
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Millis ON ─────────────────────────────────────────────────
          AppCard(
            title: 'Millis ON',
            child: AppSlider(
              label: 'On Time',
              value: _millisOn,
              min: 1,
              max: 99,
              divisions: 98,
              displayValue: (v) => _pad2(v.toInt()),
              onChanged: (v) {
                setState(() => _millisOn = v);
                if (_running) _startStrobe();
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Millis OFF ────────────────────────────────────────────────
          AppCard(
            title: 'Millis OFF',
            child: AppSlider(
              label: 'Off Time',
              value: _millisOff,
              min: 1,
              max: 9999,
              divisions: 9998,
              displayValue: (v) => _pad4(v.toInt()),
              onChanged: (v) {
                setState(() => _millisOff = v);
                if (_running) _startStrobe();
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Start / Stop buttons ──────────────────────────────────────
          AppCard(
            title: 'Strobe Control',
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Start',
                    icon: Icons.play_arrow_rounded,
                    active: _running,
                    onTap: _running ? null : () => _startStrobe(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Stop',
                    icon: Icons.stop_circle_outlined,
                    active: !_running,
                    onTap: _running ? () => _stopStrobe() : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Wide button ───────────────────────────────────────────────
          AppWideButton(
            label: _running ? 'Stop Strobe' : 'Start Strobe',
            icon: _running ? Icons.stop : Icons.play_arrow_rounded,
            color: _running ? AppColors.error : AppColors.activeBtn,
            onTap: () {
              if (_running) {
                _stopStrobe();
              } else {
                _startStrobe();
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
          if (_running) _startStrobe();
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