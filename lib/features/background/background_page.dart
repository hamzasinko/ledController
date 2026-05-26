import 'package:flutter/material.dart';

import '../../core/network/udp_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_widgets.dart';

class BackgroundPage extends StatefulWidget {
  const BackgroundPage({super.key});

  @override
  State<BackgroundPage> createState() => _BackgroundPageState();
}

class _BackgroundPageState extends State<BackgroundPage> {
  final _udp = UdpService();

  int r = 255;
  int g = 180;
  int b = 120;
  int w = 0;

  int fadeFrom = 50;
  int fadeTo = 200;

  String _pad3(int v) => v.toString().padLeft(3, '0');

  Future<void> _send(String cmd) async {
    await _udp.send(cmd);
    if (mounted) showStatus(context, "Command sent");
  }

  Future<void> _applyBackground() async {
    final cmd =
        "setBG ${_pad3(r)} ${_pad3(g)} ${_pad3(b)} ${_pad3(w)} ${_pad3(fadeFrom)} ${_pad3(fadeTo)}";
    await _send(cmd);
  }

  Future<void> _turnOff() async {
    await _send("setBgOff");
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Background",
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          AppCard(
            title: "Preview",
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Color.fromARGB(
                  255,
                  (r + w).clamp(0, 255),
                  (g + w).clamp(0, 255),
                  (b + w).clamp(0, 255),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          AppCard(
            title: "RGBW",
            child: Column(
              children: [
                AppSlider(
                  label: "Red",
                  value: r.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  displayValue: (v) => _pad3(v.toInt()),
                  onChanged: (v) => setState(() => r = v.toInt()),
                ),
                AppSlider(
                  label: "Green",
                  value: g.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  displayValue: (v) => _pad3(v.toInt()),
                  onChanged: (v) => setState(() => g = v.toInt()),
                ),
                AppSlider(
                  label: "Blue",
                  value: b.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  displayValue: (v) => _pad3(v.toInt()),
                  onChanged: (v) => setState(() => b = v.toInt()),
                ),
                AppSlider(
                  label: "White",
                  value: w.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  displayValue: (v) => _pad3(v.toInt()),
                  onChanged: (v) => setState(() => w = v.toInt()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          AppCard(
            title: "Fade",
            child: Column(
              children: [
                AppSlider(
                  label: "Fade From",
                  value: fadeFrom.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  displayValue: (v) => _pad3(v.toInt()),
                  onChanged: (v) => setState(() => fadeFrom = v.toInt()),
                ),
                AppSlider(
                  label: "Fade To",
                  value: fadeTo.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  displayValue: (v) => _pad3(v.toInt()),
                  onChanged: (v) => setState(() => fadeTo = v.toInt()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          AppCard(
            title: "Actions",
            child: Column(
              children: [
                AppWideButton(
                  label: "Apply Background",
                  icon: Icons.check_circle_outline,
                  onTap: _applyBackground,
                ),
                const SizedBox(height: 12),
                AppWideButton(
                  label: "Background Off",
                  icon: Icons.power_settings_new,
                  color: Colors.redAccent,
                  onTap: _turnOff,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}