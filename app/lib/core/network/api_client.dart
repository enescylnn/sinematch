import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._store, {http.Client? client}) : _client = client ?? http.Client();

  final TokenStore _store;
  final http.Client _client;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalized');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Map<String, String> _headers() {
    final token = _store.token;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _decode(await _client.get(_uri(path, query), headers: _headers()));
  }

  Future<dynamic> post(String path, {Object? body}) async {
    return _decode(await _client.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    ));
  }

  Future<dynamic> put(String path, {Object? body}) async {
    return _decode(await _client.put(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    ));
  }

  dynamic _decode(http.Response response) {
    dynamic payload;
    try {
      payload = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Sunucudan geçersiz yanıt alındı.', statusCode: response.statusCode);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic>
          ? (payload['message']?.toString() ?? 'İşlem tamamlanamadı.')
          : 'İşlem tamamlanamadı.';
      throw ApiException(message, statusCode: response.statusCode);
    }
    return payload;
  }

  void close() => _client.close();
}
