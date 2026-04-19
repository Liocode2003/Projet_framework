import 'package:equatable/equatable.dart';

class NetworkPeer extends Equatable {
  final String id;
  final String name;
  final String ip;
  final int port;
  final bool isTeacher;
  final DateTime discoveredAt;

  const NetworkPeer({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.isTeacher,
    required this.discoveredAt,
  });

  String get address => 'http://$ip:$port';

  @override
  List<Object?> get props => [id, ip, port];
}
