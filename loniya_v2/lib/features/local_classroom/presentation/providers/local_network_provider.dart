import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/services/discovery_service.dart';
import '../../data/services/student_client.dart';
import '../../data/services/teacher_server.dart';
import '../../domain/entities/network_peer.dart';
import '../../domain/entities/shared_content.dart';

// ─── Infrastructure providers ─────────────────────────────────────────────────

final discoveryServiceProvider =
    Provider<DiscoveryService>((_) => DiscoveryService());

final teacherServerProvider =
    Provider<TeacherServer>((_) => TeacherServer());

final studentClientProvider =
    Provider<StudentClient>((_) => StudentClient());

// ─── State ────────────────────────────────────────────────────────────────────

enum NetworkRole { none, teacher, student }

enum NetworkStatus { idle, starting, running, error }

class LocalNetworkState {
  final NetworkRole role;
  final NetworkStatus status;
  final String? localIp;

  // Teacher side
  final List<NetworkPeer> connectedStudents;

  // Student side
  final List<NetworkPeer> discoveredTeachers;
  final NetworkPeer? selectedTeacher;
  final List<SharedContent> teacherContent;
  final Map<String, double> downloadProgress; // contentId → 0.0..1.0
  final Set<String> downloadedIds;

  final String? errorMessage;

  const LocalNetworkState({
    this.role = NetworkRole.none,
    this.status = NetworkStatus.idle,
    this.localIp,
    this.connectedStudents = const [],
    this.discoveredTeachers = const [],
    this.selectedTeacher,
    this.teacherContent = const [],
    this.downloadProgress = const {},
    this.downloadedIds = const {},
    this.errorMessage,
  });

  bool get isRunning => status == NetworkStatus.running;

  LocalNetworkState copyWith({
    NetworkRole? role,
    NetworkStatus? status,
    String? localIp,
    List<NetworkPeer>? connectedStudents,
    List<NetworkPeer>? discoveredTeachers,
    NetworkPeer? selectedTeacher,
    bool clearTeacher = false,
    List<SharedContent>? teacherContent,
    Map<String, double>? downloadProgress,
    Set<String>? downloadedIds,
    String? errorMessage,
    bool clearError = false,
  }) =>
      LocalNetworkState(
        role: role ?? this.role,
        status: status ?? this.status,
        localIp: localIp ?? this.localIp,
        connectedStudents:
            connectedStudents ?? this.connectedStudents,
        discoveredTeachers:
            discoveredTeachers ?? this.discoveredTeachers,
        selectedTeacher:
            clearTeacher ? null : (selectedTeacher ?? this.selectedTeacher),
        teacherContent: teacherContent ?? this.teacherContent,
        downloadProgress: downloadProgress ?? this.downloadProgress,
        downloadedIds: downloadedIds ?? this.downloadedIds,
        errorMessage:
            clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class LocalNetworkNotifier extends StateNotifier<LocalNetworkState> {
  final Ref _ref;
  StreamSubscription<NetworkPeer>? _peerSub;

  LocalNetworkNotifier(this._ref) : super(const LocalNetworkState());

  DiscoveryService get _discovery => _ref.read(discoveryServiceProvider);
  TeacherServer get _server => _ref.read(teacherServerProvider);
  StudentClient get _client => _ref.read(studentClientProvider);

  // ── Teacher ───────────────────────────────────────────────────────────────

  Future<void> startAsTeacher() async {
    if (state.isRunning) return;
    state = state.copyWith(
        role: NetworkRole.teacher, status: NetworkStatus.starting, clearError: true);
    try {
      final user = _ref.read(currentUserProvider);
      final name = user?.name ?? 'Enseignant';
      final id = user?.id ?? const Uuid().v4();

      await _server.start(teacherName: name, port: TeacherServer.defaultPort);
      await _discovery.startBroadcasting(
        teacherId: id,
        teacherName: name,
        serverPort: _server.port,
      );

      state = state.copyWith(
        status: NetworkStatus.running,
        localIp: await _localIp(),
      );
    } catch (e) {
      state = state.copyWith(
        role: NetworkRole.none,
        status: NetworkStatus.error,
        errorMessage: 'Impossible de démarrer le serveur : $e',
      );
    }
  }

  Future<void> stopTeacher() async {
    await _server.stop();
    await _discovery.stopBroadcasting();
    state = const LocalNetworkState();
  }

  // ── Student ───────────────────────────────────────────────────────────────

  Future<void> startAsStudent() async {
    if (state.isRunning) return;
    state = state.copyWith(
        role: NetworkRole.student, status: NetworkStatus.starting, clearError: true);
    try {
      await _discovery.startListening();

      // Deduplicate by teacher id, keeping most recent
      final Map<String, NetworkPeer> seen = {};
      _peerSub = _discovery.peerStream.listen((peer) {
        seen[peer.id] = peer;
        state = state.copyWith(discoveredTeachers: seen.values.toList());
      });

      state = state.copyWith(status: NetworkStatus.running);
    } catch (e) {
      state = state.copyWith(
        role: NetworkRole.none,
        status: NetworkStatus.error,
        errorMessage: 'Impossible de scanner le réseau : $e',
      );
    }
  }

  Future<void> stopStudent() async {
    await _peerSub?.cancel();
    _peerSub = null;
    await _discovery.stopListening();
    state = const LocalNetworkState();
  }

  // ── Content browsing (student) ────────────────────────────────────────────

  Future<void> selectTeacher(NetworkPeer teacher) async {
    state = state.copyWith(
        selectedTeacher: teacher, teacherContent: [], clearError: true);
    try {
      final content = await _client.fetchContentList(teacher);
      state = state.copyWith(teacherContent: content);
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de charger la liste : $e');
    }
  }

  Future<void> downloadContent(SharedContent content) async {
    final teacher = state.selectedTeacher;
    if (teacher == null) return;
    if (state.downloadedIds.contains(content.id)) return;

    state = state.copyWith(
        downloadProgress: {...state.downloadProgress, content.id: 0.0});
    try {
      await _client.downloadContent(
        teacher,
        content,
        onProgress: (p) {
          state = state.copyWith(
              downloadProgress: {...state.downloadProgress, content.id: p});
        },
      );
      final newProgress = Map<String, double>.from(state.downloadProgress)
        ..remove(content.id);
      state = state.copyWith(
        downloadProgress: newProgress,
        downloadedIds: {...state.downloadedIds, content.id},
      );
    } catch (e) {
      final newProgress = Map<String, double>.from(state.downloadProgress)
        ..remove(content.id);
      state = state.copyWith(
          downloadProgress: newProgress,
          errorMessage: 'Téléchargement échoué : ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _peerSub?.cancel();
    _discovery.dispose();
    _server.stop();
    super.dispose();
  }

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

// ─── Provider ─────────────────────────────────────────────────────────────────

final localNetworkNotifierProvider =
    StateNotifierProvider<LocalNetworkNotifier, LocalNetworkState>(
  (ref) => LocalNetworkNotifier(ref),
);
