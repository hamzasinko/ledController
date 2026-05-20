import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/udp_service.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final _udp = UdpService();

  late final TextEditingController _arduinoIpCtrl;
  late final TextEditingController _arduinoPortCtrl;
  late final TextEditingController _listenPortCtrl;

  String? _deviceIp;
  bool _loadingIp = true;

  @override
  void initState() {
    super.initState();
    _arduinoIpCtrl  = TextEditingController(text: _udp.host);
    _arduinoPortCtrl = TextEditingController(text: _udp.port.toString());
    _listenPortCtrl  = TextEditingController(text: _udp.listenPort.toString());
    _loadDeviceIp();
  }

  @override
  void dispose() {
    _arduinoIpCtrl.dispose();
    _arduinoPortCtrl.dispose();
    _listenPortCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            if (mounted) setState(() {
              _deviceIp = addr.address;
              _loadingIp = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingIp = false);
  }

  void _save() {
    final newListenPort = int.tryParse(_listenPortCtrl.text.trim()) ?? 5000;
    final portChanged = newListenPort != _udp.listenPort;

    _udp.host       = _arduinoIpCtrl.text.trim();
    _udp.port       = int.tryParse(_arduinoPortCtrl.text.trim()) ?? 7000;
    _udp.listenPort = newListenPort;

    if (portChanged) _udp.resetSocket();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inactiveBtn,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Connection Settings',
                style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppColors.text,
                )),
            const SizedBox(height: 4),
            Text(
              'Arduino replies directly to this device — no IP config needed.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // ── This device's IP (info only) ──────────────────────────────
            _SectionLabel('This device'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.inactiveBtn,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.25), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_android_outlined,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 10),
                  _loadingIp
                      ? Text('Detecting…',
                          style: GoogleFonts.sourceCodePro(
                              fontSize: 13, color: AppColors.textSecondary))
                      : Text(
                          _deviceIp ?? 'Not detected',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: _deviceIp != null
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                  const Spacer(),
                  Text(
                    'auto',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Arduino uses remoteIP() so this is handled automatically.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 20),

            // ── Arduino target ────────────────────────────────────────────
            _SectionLabel('Arduino'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                flex: 3,
                child: _Field(
                  label: 'IP Address',
                  controller: _arduinoIpCtrl,
                  hint: '192.168.0.111',
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _Field(
                  label: 'Send Port',
                  controller: _arduinoPortCtrl,
                  hint: '7000',
                  keyboard: TextInputType.number,
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // ── Listen port ───────────────────────────────────────────────
            _SectionLabel('Reply listener'),
            const SizedBox(height: 8),
            _Field(
              label: 'Listen Port (must match REPLY_PORT in sketch)',
              controller: _listenPortCtrl,
              hint: '5000',
              keyboard: TextInputType.number,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.activeBtn,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Save',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, letterSpacing: 0.8,
      ));
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboard;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: AppColors.textSecondary, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: GoogleFonts.sourceCodePro(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.sourceCodePro(
                color: AppColors.textSecondary.withOpacity(0.4)),
            filled: true,
            fillColor: AppColors.inactiveBtn,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.activeBtn, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}