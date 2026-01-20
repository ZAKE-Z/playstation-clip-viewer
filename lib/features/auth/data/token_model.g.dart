// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PsnTokens _$PsnTokensFromJson(Map<String, dynamic> json) => _PsnTokens(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  refreshExpiresAt: DateTime.parse(json['refreshExpiresAt'] as String),
);

Map<String, dynamic> _$PsnTokensToJson(_PsnTokens instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'refreshExpiresAt': instance.refreshExpiresAt.toIso8601String(),
    };
