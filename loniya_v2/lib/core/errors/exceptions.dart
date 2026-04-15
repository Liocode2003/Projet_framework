// Custom exceptions for LONIYA V2 data layer

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Erreur de cache local.']);

  @override
  String toString() => 'CacheException: $message';
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException([this.message = 'Erreur serveur.', this.statusCode]);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException([this.message = 'Erreur de chiffrement.']);

  @override
  String toString() => 'EncryptionException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Erreur réseau.']);

  @override
  String toString() => 'NetworkException: $message';
}

class LocalNetworkException implements Exception {
  final String message;
  const LocalNetworkException([this.message = 'Erreur réseau local.']);

  @override
  String toString() => 'LocalNetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Erreur d\'authentification.']);

  @override
  String toString() => 'AuthException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

class SyncException implements Exception {
  final String message;
  const SyncException([this.message = 'Erreur de synchronisation.']);

  @override
  String toString() => 'SyncException: $message';
}

class StorageException implements Exception {
  final String message;
  const StorageException([this.message = 'Erreur de stockage.']);

  @override
  String toString() => 'StorageException: $message';
}
