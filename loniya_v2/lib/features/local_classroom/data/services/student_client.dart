import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../marketplace/data/models/marketplace_item_model.dart';
import '../../domain/entities/network_peer.dart';
import '../../domain/entities/shared_content.dart';

/// HTTP client used by students to communicate with the teacher server.
class StudentClient {
  static const Duration _timeout = Duration(seconds: 10);

  /// Returns true if teacher is reachable.
  Future<bool> ping(NetworkPeer teacher) async {
    try {
      final res = await http
          .get(Uri.parse('${teacher.address}/api/ping'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the list of content available on the teacher device.
  Future<List<SharedContent>> fetchContentList(NetworkPeer teacher) async {
    final res = await http
        .get(Uri.parse('${teacher.address}/api/content'))
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Erreur ${res.statusCode} — ${teacher.name}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((j) => SharedContent.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Downloads a content item and registers it in the local Hive marketplace.
  /// Returns the saved local file path.
  Future<String> downloadContent(
    NetworkPeer teacher,
    SharedContent content, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.05);

    final request =
        http.Request('GET', Uri.parse('${teacher.address}/api/content/${content.id}'));
    final streamed = await request.send().timeout(_timeout);

    if (streamed.statusCode != 200) {
      throw Exception('Téléchargement échoué : HTTP ${streamed.statusCode}');
    }

    final total = streamed.contentLength ?? 0;
    var received = 0;
    final chunks = <List<int>>[];

    await for (final chunk in streamed.stream) {
      chunks.add(chunk);
      received += chunk.length;
      if (total > 0) {
        onProgress?.call(0.05 + 0.85 * (received / total));
      }
    }

    onProgress?.call(0.9);

    // Write to disk
    final dir = await _contentDir();
    final path = '${dir.path}/${content.id}.lnc';
    final bytes = chunks.expand((c) => c).toList();
    await File(path).writeAsBytes(bytes, flush: true);

    // Register so the learning engine sees it as downloaded
    await _register(content, path);
    onProgress?.call(1.0);

    return path;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<Directory> _contentDir() async {
    final app = await getApplicationDocumentsDirectory();
    final dir = Directory('${app.path}/loniya_contents');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _register(SharedContent c, String localPath) async {
    final box = Hive.box(HiveBoxes.marketplace);
    final existing = box.get(c.id) as MarketplaceItemModel?;
    if (existing != null && existing.isDownloaded) return;

    await box.put(
      c.id,
      MarketplaceItemModel(
        id: c.id,
        title: c.title,
        subject: c.subject,
        gradeLevel: c.gradeLevel,
        type: c.type,
        description: '',
        fileSizeBytes: c.fileSizeBytes,
        isDownloaded: true,
        localPath: localPath,
        createdAt: DateTime.now().toIso8601String(),
        authorId: 'teacher_transfer',
        tags: [],
        isEncrypted: false,
      ),
    );
  }
}
