import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/network_peer.dart';

/// UDP-based local network discovery.
///
/// Teacher: broadcasts JSON announce packets every [_intervalSec] seconds on
/// port [discoveryPort] using subnet broadcast (255.255.255.255).
///
/// Student: binds on [discoveryPort] and emits [NetworkPeer] events via stream.
///
/// Packet format:
/// {"type":"loniya_teacher","id":"<uuid>","name":"<name>","ip":"<ip>","port":8080}
class DiscoveryService {
  static const int discoveryPort = 44444;
  static const int _intervalSec = 2;
  static const String _packetType = 'loniya_teacher';

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  StreamController<NetworkPeer>? _peerController;

  Stream<NetworkPeer> get peerStream =>
      _peerController?.stream ?? const Stream.empty();

  // ── Teacher: broadcast ────────────────────────────────────────────────────

  Future<void> startBroadcasting({
    required String teacherId,
    required String teacherName,
    required int serverPort,
  }) async {
    await stopBroadcasting();

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    _socket = socket;

    final ip = await _localIp();
    final bytes = utf8.encode(jsonEncode({
      'type': _packetType,
      'id': teacherId,
      'name': teacherName,
      'ip': ip,
      'port': serverPort,
    }));

    _broadcastTimer = Timer.periodic(
      const Duration(seconds: _intervalSec),
      (_) {
        try {
          socket.send(
              bytes, InternetAddress('255.255.255.255'), discoveryPort);
        } catch (_) {}
      },
    );
  }

  Future<void> stopBroadcasting() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
  }

  // ── Student: listen ───────────────────────────────────────────────────────

  Future<void> startListening() async {
    await stopListening();
    _peerController = StreamController<NetworkPeer>.broadcast();

    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
    );
    socket.broadcastEnabled = true;
    _socket = socket;

    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null) return;
      try {
        final data =
            jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
        if (data['type'] != _packetType) return;
        _peerController?.add(NetworkPeer(
          id: data['id'] as String,
          name: data['name'] as String,
          ip: data['ip'] as String,
          port: data['port'] as int,
          isTeacher: true,
          discoveredAt: DateTime.now(),
        ));
      } catch (_) {}
    });
  }

  Future<void> stopListening() async {
    _socket?.close();
    _socket = null;
    await _peerController?.close();
    _peerController = null;
  }

  Future<void> dispose() async {
    await stopBroadcasting();
    await stopListening();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String> _localIp() async {
    try {
      final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (!ip.startsWith('127.') && !ip.startsWith('169.254.')) {
            return ip;
          }
        }
      }
    } catch (_) {}
    return '0.0.0.0';
  }
}
