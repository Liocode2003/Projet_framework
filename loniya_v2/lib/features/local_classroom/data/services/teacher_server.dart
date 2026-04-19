import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../marketplace/data/models/marketplace_item_model.dart';

/// HTTP server running on the teacher's device.
///
/// Endpoints:
///   GET /api/ping          — health check
///   GET /api/content       — list of available downloaded items (JSON)
///   GET /api/content/:id   — raw .lnc file bytes for a single item
class TeacherServer {
  static const int defaultPort = 8080;

  HttpServer? _server;
  String _teacherName = 'Enseignant';

  bool get isRunning => _server != null;
  int get port => _server?.port ?? defaultPort;

  Future<void> start({
    required String teacherName,
    int port = defaultPort,
  }) async {
    if (_server != null) return;
    _teacherName = teacherName;

    final router = Router()
      ..get('/api/ping', _ping)
      ..get('/api/content', _contentList)
      ..get('/api/content/<id>', _contentDownload);

    final handler =
        Pipeline().addMiddleware(logRequests()).addHandler(router.call);

    _server =
        await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Response _ping(Request req) => Response.ok(
        jsonEncode({'status': 'ok', 'name': _teacherName, 'version': '2.0'}),
        headers: {'Content-Type': 'application/json'},
      );

  Response _contentList(Request req) {
    final items = _downloadedItems();
    final body = jsonEncode(items
        .map((i) => {
              'id': i.id,
              'title': i.title,
              'subject': i.subject,
              'grade_level': i.gradeLevel,
              'type': i.type,
              'file_size_bytes': i.fileSizeBytes,
            })
        .toList());
    return Response.ok(body,
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _contentDownload(Request req, String id) async {
    final item =
        _downloadedItems().where((i) => i.id == id).firstOrNull;

    if (item == null || item.localPath == null) {
      return Response.notFound(
        jsonEncode({'error': 'Contenu $id introuvable'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final file = File(item.localPath!);
    if (!await file.exists()) {
      return Response.notFound(
        jsonEncode({'error': 'Fichier absent du disque'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final bytes = await file.readAsBytes();
    return Response.ok(
      bytes,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': 'attachment; filename="$id.lnc"',
        'Content-Length': '${bytes.length}',
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<MarketplaceItemModel> _downloadedItems() {
    final box = Hive.box(HiveBoxes.marketplace);
    return box.values
        .cast<MarketplaceItemModel>()
        .where((i) => i.isDownloaded && i.localPath != null)
        .toList();
  }
}
