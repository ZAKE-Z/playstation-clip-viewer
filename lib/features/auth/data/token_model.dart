import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_model.freezed.dart';
part 'token_model.g.dart';

/// PSN OAuth tokens with expiration tracking
@freezed
abstract class PsnTokens with _$PsnTokens {
  const factory PsnTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required DateTime refreshExpiresAt,
  }) = _PsnTokens;

  factory PsnTokens.fromJson(Map<String, dynamic> json) =>
      _$PsnTokensFromJson(json);
}

/// Extension for token expiration checks
extension PsnTokensX on PsnTokens {
  /// Check if access token needs refresh (80% of TTL elapsed)
  bool get needsRefresh {
    final now = DateTime.now();
    final totalDuration = expiresAt.difference(
      refreshExpiresAt.subtract(const Duration(hours: 1)),
    );
    final threshold = expiresAt.subtract(
      Duration(seconds: (totalDuration.inSeconds * 0.2).round()),
    );
    return now.isAfter(threshold);
  }

  /// Check if access token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if refresh token is expired
  bool get isRefreshExpired => DateTime.now().isAfter(refreshExpiresAt);
}
