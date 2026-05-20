import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../config/env.dart';

enum ArduinoStatus { unknown, online, offline }

class UdpService {
  static final UdpService _instance = UdpService._internal();
  factory UdpService() => _instance;
  UdpService._internal();

  String host = Env.ledHost;
  int port = Env.ledPort;

  int listenPort = Env.ledListenPort;

  RawDatagramSocket? _socket;
  final List<String> _log = [];

  final _statusController = StreamController<ArduinoStatus>.broadcast();
  Stream<ArduinoStatus> get statusStream => _statusController.stream;
  ArduinoStatus status = ArduinoStatus.unknown;

  List<String> get log => List.unmodifiable(_log);

  // ── Socket lifecycle ───────────────────────────────────────────────────────

  Future<void> _ensureSocket() async {
    if (_socket != null) return;
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        listenPort,
      );
      _addLog('✓ Socket open on port $listenPort');
    } on SocketException catch (e) {
      _addLog('✗ Cannot bind port $listenPort — $e');
      rethrow;
    }
    _socket!.listen(_onPacketReceived);
  }

  void resetSocket() {
    _socket?.close();
    _socket = null;
    _setStatus(ArduinoStatus.unknown);
    _addLog('↺ Socket reset');
  }

  // ── Incoming packet handler ────────────────────────────────────────────────

  void _onPacketReceived(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;

    final reply = String.fromCharCodes(datagram.data).trim();
    _addLog('← "$reply"  from ${datagram.address.address}:${datagram.port}');

    if (reply == 'ping') {
      _setStatus(ArduinoStatus.online);
    }
  }

  // ── Send any command ───────────────────────────────────────────────────────

  Future<bool> send(String command) async {
    try {
      await _ensureSocket();
      final data = Uint8List.fromList(command.codeUnits);
      _socket!.send(data, InternetAddress(host), port);
      _addLog('→ "$command"');
      return true;
    } catch (e) {
      _addLog('✗ "$command"  ($e)');
      return false;
    }
  }

  // ── Ping — green only if Arduino actually replies ──────────────────────────

  Future<bool> ping({int timeoutMs = 2000}) async {
    try {
      await _ensureSocket();
      _socket!.send(
        Uint8List.fromList('ping'.codeUnits),
        InternetAddress(host),
        port,
      );
      _addLog('→ "ping"  (waiting up to ${timeoutMs}ms…)');

      final completer = Completer<bool>();
      late StreamSubscription<ArduinoStatus> sub;
      sub = statusStream.listen((s) {
        if (s == ArduinoStatus.online && !completer.isCompleted) {
          completer.complete(true);
          sub.cancel();
        }
      });

      Future.delayed(Duration(milliseconds: timeoutMs), () {
        if (!completer.isCompleted) {
          completer.complete(false);
          sub.cancel();
          _setStatus(ArduinoStatus.offline);
          _addLog('✗ No reply after ${timeoutMs}ms');
        }
      });

      return await completer.future;
    } catch (e) {
      _addLog('✗ ping failed ($e)');
      _setStatus(ArduinoStatus.offline);
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setStatus(ArduinoStatus s) {
    status = s;
    _statusController.add(s);
  }

  void _addLog(String entry) {
    _log.insert(0, '[${_timestamp()}] $entry');
    if (_log.length > 100) _log.removeLast();
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _statusController.close();
    _socket?.close();
    _socket = null;
  }
}