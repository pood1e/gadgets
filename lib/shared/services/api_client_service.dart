import 'dart:convert';
import 'dart:io';

import 'package:gadgets/shared/services/sse_service.dart';
import 'package:gadgets/shared/utils/wrapped_logger.dart';
import 'package:http/http.dart' as http;

class ApiClientException {
  final Uri uri;
  final int code;
  final String message;

  ApiClientException({required this.uri, required this.code, required this.message});
}

class ApiClientService {
  final _logger = WrappedLogger();
  final String _baseUrl;
  final http.Client _client;

  ApiClientService({http.Client? client, required String baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl;

  Uri _replaceUri(Uri parts) => Uri.parse('$_baseUrl$parts');

  Future<http.Response> _makeRequest({
    required Uri uri,
    required Future<http.Response> Function(Uri) doRequest,
  }) async {
    Uri replaced = _replaceUri(uri);
    try {
      return await doRequest(replaced);
    } catch (err) {
      _logger.e("request error: $err, uri=$replaced");
      throw ApiClientException(message: err.toString(), uri: replaced, code: 0);
    }
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) =>
      _makeRequest(
        uri: uri,
        doRequest: (replaced) {
          _logger.i("do get uri=$replaced");
          return _client.get(replaced, headers: headers);
        },
      );

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => _makeRequest(
    uri: uri,
    doRequest: (replaced) {
      _logger.i("do post uri=$replaced");
      final json = body == null ? body : jsonEncode(body);
      return _client.post(replaced, headers: headers, body: json);
    },
  );

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => _makeRequest(
    uri: uri,
    doRequest: (replaced) {
      _logger.i("do delete uri=$replaced");
      final json = body == null ? body : jsonEncode(body);
      return _client.delete(replaced, headers: headers, body: json);
    },
  );

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => _makeRequest(
    uri: uri,
    doRequest: (replaced) {
      _logger.i("do put uri=$replaced");
      final json = body == null ? body : jsonEncode(body);
      return _client.put(replaced, headers: headers, body: json);
    },
  );

  /// 创建sse连接
  SseSession<T> createSseSession<T>({
    required SseRequest request,
    void Function(HttpClient)? clientCustomer,
    required T Function(dynamic) transformer,
  }) {
    _logger.i("create sse session");
    return JsonSseSession<T>(
      builder: () {
        HttpClient client = HttpClient();
        if (clientCustomer != null) {
          clientCustomer(client);
        }
        return client;
      },
      request: SseRequest(
        uri: _replaceUri(request.uri),
        method: request.method,
        headers: request.headers,
        body: request.body,
      ),
      transformer: transformer,
    );
  }

  /// 释放连接资源, sse连接的客户端自行管理
  void dispose() {
    _client.close();
  }
}
