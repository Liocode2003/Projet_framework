import 'package:equatable/equatable.dart';

// Base failure class
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// Offline — no internet connection
class OfflineFailure extends Failure {
  const OfflineFailure() : super('Pas de connexion internet. Mode hors-ligne activé.');
}

// Cache — local data not found
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Données locales introuvables.']);
}

// Server — remote API error
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([super.message = 'Erreur serveur.', this.statusCode]);
}

// Encryption failure
class EncryptionFailure extends Failure {
  const EncryptionFailure([super.message = 'Erreur de chiffrement des données.']);
}

// Auth failures
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Erreur d\'authentification.']);
}

class InvalidOtpFailure extends Failure {
  const InvalidOtpFailure() : super('Code OTP incorrect. Veuillez réessayer.');
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure() : super('Session expirée. Veuillez vous reconnecter.');
}

class MaxPinAttemptsFailure extends Failure {
  const MaxPinAttemptsFailure() : super('Trop de tentatives incorrectes. Compte bloqué.');
}

// Network local failures
class LocalNetworkFailure extends Failure {
  const LocalNetworkFailure([super.message = 'Erreur réseau local.']);
}

class PeerNotFoundFailure extends Failure {
  const PeerNotFoundFailure() : super('Aucun appareil trouvé sur le réseau local.');
}

class ClassroomJoinFailure extends Failure {
  const ClassroomJoinFailure([super.message = 'Impossible de rejoindre la classe.']);
}

// Sync failures
class SyncFailure extends Failure {
  const SyncFailure([super.message = 'Erreur de synchronisation.']);
}

class MaxRetriesExceededFailure extends Failure {
  const MaxRetriesExceededFailure() : super('Nombre maximum de tentatives de synchronisation atteint.');
}

// Content failures
class ContentNotFoundFailure extends Failure {
  const ContentNotFoundFailure([super.message = 'Contenu introuvable.']);
}

class DownloadFailure extends Failure {
  const DownloadFailure([super.message = 'Échec du téléchargement.']);
}

class StorageFullFailure extends Failure {
  const StorageFullFailure() : super('Espace de stockage insuffisant.');
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Unknown / unexpected
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Une erreur inattendue est survenue.']);
}
