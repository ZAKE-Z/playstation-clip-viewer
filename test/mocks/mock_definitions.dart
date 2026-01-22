import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:psclips/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

@GenerateNiceMocks([
  MockSpec<TokenStorage>(),
  MockSpec<Dio>(),
  MockSpec<FlutterSecureStorage>(),
])
void main() {}
