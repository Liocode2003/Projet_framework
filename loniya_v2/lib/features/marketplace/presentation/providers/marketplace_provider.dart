import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database/database_service.dart';
import '../../../../core/services/encryption/aes_encryption_service.dart';
import '../../../../core/services/encryption/encryption_provider.dart';
import '../../data/datasources/content_download_service.dart';
import '../../data/datasources/marketplace_local_datasource.dart';
import '../../data/repositories/marketplace_repository_impl.dart';
import '../../domain/entities/content_entity.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../domain/usecases/get_all_contents_usecase.dart';
import '../../domain/usecases/filter_contents_usecase.dart';
import '../../domain/usecases/download_content_usecase.dart';
import '../../domain/usecases/get_downloaded_contents_usecase.dart';
import '../../domain/usecases/delete_content_usecase.dart';

// ─── Infrastructure providers ─────────────────────────────────────────────────
final contentDownloadServiceProvider = Provider<ContentDownloadService>((ref) {
  return ContentDownloadService(ref.read(encryptionServiceProvider));
});

final marketplaceLocalDataSourceProvider =
    Provider<MarketplaceLocalDataSource>((ref) {
  return MarketplaceLocalDataSource(
    ref.read(databaseServiceProvider),
    ref.read(contentDownloadServiceProvider),
  );
});

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepositoryImpl(ref.read(marketplaceLocalDataSourceProvider));
});

// ─── Use case providers ───────────────────────────────────────────────────────
final getAllContentsUseCaseProvider = Provider(
  (ref) => GetAllContentsUseCase(ref.read(marketplaceRepositoryProvider)),
);
final filterContentsUseCaseProvider = Provider(
  (ref) => FilterContentsUseCase(ref.read(marketplaceRepositoryProvider)),
);
final downloadContentUseCaseProvider = Provider(
  (ref) => DownloadContentUseCase(ref.read(marketplaceRepositoryProvider)),
);
final getDownloadedContentsUseCaseProvider = Provider(
  (ref) => GetDownloadedContentsUseCase(ref.read(marketplaceRepositoryProvider)),
);
final deleteContentUseCaseProvider = Provider(
  (ref) => DeleteContentUseCase(ref.read(marketplaceRepositoryProvider)),
);

// ─── Filter state ─────────────────────────────────────────────────────────────
class MarketplaceFilter {
  final String? subject;
  final String? gradeLevel;
  final String? type;
  final String? query;
  final bool showDownloadedOnly;

  const MarketplaceFilter({
    this.subject,
    this.gradeLevel,
    this.type,
    this.query,
    this.showDownloadedOnly = false,
  });

  MarketplaceFilter copyWith({
    String? subject,
    String? gradeLevel,
    String? type,
    String? query,
    bool? showDownloadedOnly,
    bool clearSubject = false,
    bool clearGrade = false,
    bool clearType = false,
  }) =>
      MarketplaceFilter(
        subject: clearSubject ? null : (subject ?? this.subject),
        gradeLevel: clearGrade ? null : (gradeLevel ?? this.gradeLevel),
        type: clearType ? null : (type ?? this.type),
        query: query ?? this.query,
        showDownloadedOnly: showDownloadedOnly ?? this.showDownloadedOnly,
      );

  bool get hasActiveFilters =>
      subject != null ||
      gradeLevel != null ||
      type != null ||
      (query != null && query!.isNotEmpty) ||
      showDownloadedOnly;
}

final marketplaceFilterProvider =
    StateProvider<MarketplaceFilter>((ref) => const MarketplaceFilter());

// ─── Filtered content list ────────────────────────────────────────────────────
final marketplaceContentsProvider =
    FutureProvider.autoDispose<List<ContentEntity>>((ref) async {
  final filter = ref.watch(marketplaceFilterProvider);
  final useCase = ref.read(filterContentsUseCaseProvider);

  final result = await useCase(
    subject: filter.subject,
    gradeLevel: filter.gradeLevel,
    type: filter.type,
    query: filter.query,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (list) => filter.showDownloadedOnly
        ? list.where((c) => c.isDownloaded).toList()
        : list,
  );
});

// ─── Single content detail ────────────────────────────────────────────────────
final contentDetailProvider =
    FutureProvider.autoDispose.family<ContentEntity, String>((ref, id) async {
  final repo = ref.read(marketplaceRepositoryProvider);
  final result = await repo.getContentById(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (entity) => entity,
  );
});

// ─── Download progress per content id ────────────────────────────────────────
final downloadProgressProvider =
    StateProvider.family<double?, String>((ref, id) => null);

// ─── Download notifier ────────────────────────────────────────────────────────
final downloadNotifierProvider =
    StateNotifierProvider<DownloadNotifier, Map<String, _DownloadState>>(
  (ref) => DownloadNotifier(ref),
);

enum _DownloadStatus { idle, downloading, done, error }

class _DownloadState {
  final _DownloadStatus status;
  final double progress;
  final String? error;
  const _DownloadState({
    this.status = _DownloadStatus.idle,
    this.progress = 0,
    this.error,
  });
}

class DownloadNotifier extends StateNotifier<Map<String, _DownloadState>> {
  final Ref _ref;
  DownloadNotifier(this._ref) : super({});

  bool isDownloading(String id) =>
      state[id]?.status == _DownloadStatus.downloading;

  double getProgress(String id) => state[id]?.progress ?? 0;

  Future<void> download(String contentId) async {
    if (isDownloading(contentId)) return;

    state = {
      ...state,
      contentId: const _DownloadState(status: _DownloadStatus.downloading),
    };

    final result = await _ref.read(downloadContentUseCaseProvider).call(
      contentId,
      onProgress: (p) {
        state = {
          ...state,
          contentId: _DownloadState(
              status: _DownloadStatus.downloading, progress: p),
        };
      },
    );

    result.fold(
      (failure) => state = {
        ...state,
        contentId: _DownloadState(
            status: _DownloadStatus.error, error: failure.message),
      },
      (_) {
        state = {
          ...state,
          contentId:
              const _DownloadState(status: _DownloadStatus.done, progress: 1),
        };
        // Invalidate list so it refreshes
        _ref.invalidate(marketplaceContentsProvider);
      },
    );
  }

  Future<void> delete(String contentId) async {
    await _ref.read(deleteContentUseCaseProvider).call(contentId);
    state = {
      ...state,
      contentId: const _DownloadState(status: _DownloadStatus.idle),
    };
    _ref.invalidate(marketplaceContentsProvider);
  }
}

// Convenience helpers exposed to UI
extension DownloadStateExt on _DownloadState {
  bool get isIdle       => status == _DownloadStatus.idle;
  bool get isDownloading => status == _DownloadStatus.downloading;
  bool get isDone       => status == _DownloadStatus.done;
  bool get hasError     => status == _DownloadStatus.error;
}
