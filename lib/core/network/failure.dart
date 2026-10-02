import 'package:dio/dio.dart';

/// Uniform error shape surfaced to the UI, whether it came from the network,
/// local validation, or the local database.
class Failure {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? fieldErrors;

  const Failure(this.message, {this.statusCode, this.fieldErrors});

  factory Failure.fromDioException(DioException e) {
    final response = e.response;
    if (response != null && response.data is Map) {
      final data = response.data as Map;
      final message = data['message']?.toString() ?? 'Une erreur est survenue.';
      final errors = data['errors'];
      return Failure(
        message,
        statusCode: response.statusCode,
        fieldErrors: errors is Map ? Map<String, dynamic>.from(errors) : null,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure('Le serveur met trop de temps à répondre.');
      case DioExceptionType.connectionError:
        return const Failure('Pas de connexion au serveur. Mode hors-ligne activé.');
      default:
        return Failure(e.message ?? 'Une erreur est survenue.');
    }
  }

  bool get isOffline => statusCode == null;

  @override
  String toString() => message;
}
