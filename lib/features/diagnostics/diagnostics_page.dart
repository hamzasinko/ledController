import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/udp_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_widgets.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  final _udp = UdpService();

  Timer? _timer;

  ArduinoStatus status = ArduinoStatus.unknown;
  int pingMs = 0;

  String lastPacket = "";
  List<String> logs = [];

  final TextEditingController _rawCmd = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Listen to status updates
    _udp.statusStream.listen((s) {
      setState(() => status = s);
    });

    // Auto-refresh logs
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        logs = _udp.log;
        if (logs.isNotEmpty) lastPacket = logs.first;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _runPing() async {
    final sw = Stopwatch()..start();
    final ok = await _udp.ping();
    pingMs = ok ? sw.elapsedMilliseconds : 0;
    setState(() {});
  }

  Future<void> _sendRaw() async {
    final cmd = _rawCmd.text.trim();
    if (cmd.isEmpty) return;
    await _udp.send(cmd);
    showStatus(context, "Command sent");
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Diagnostics",
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Connection
          AppCard(
            title: "Connection",
            child: Column(
              children: [
                _infoRow("Status", status.name),
                _infoRow("Ping", pingMs == 0 ? "—" : "$pingMs ms"),
                const SizedBox(height: 12),
                AppWideButton(
                  label: "Ping",
                  icon: Icons.wifi_tethering,
                  onTap: _runPing,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Last Packet
          AppCard(
            title: "Last Packet",
            child: Text(
              lastPacket.isEmpty ? "No packets yet" : lastPacket,
              style: GoogleFonts.robotoMono(fontSize: 12),
            ),
          ),

          const SizedBox(height: 16),

          // Log Viewer
          AppCard(
            title: "Log (last 100 entries)",
            child: SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, i) {
                  return Text(
                    logs[i],
                    style: GoogleFonts.robotoMono(fontSize: 11),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Raw Command Tester
          AppCard(
            title: "Raw Command Tester",
            child: Column(
              children: [
                TextField(
                  controller: _rawCmd,
                  decoration: const InputDecoration(
                    labelText: "Enter command",
                  ),
                ),
                const SizedBox(height: 12),
                AppWideButton(
                  label: "Send Command",
                  icon: Icons.send,
                  onTap: _sendRaw,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}