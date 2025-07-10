import 'dart:async';
import 'dart:convert';

import 'package:gadgets/modules/clipboard/domain/clipboard_message.dart';
import 'package:gadgets/shared/services/api_client_service.dart';
import 'package:gadgets/shared/services/sse_service.dart';
import 'package:http/http.dart' as http;

import 'clipboard_repository.dart';

class RemoteClipboardDataRepository extends ClipboardDataRepository {
  final ApiClientService _service;

  RemoteClipboardDataRepository({required ApiClientService service})
    : _service = service;

  Future<http.Response> _makeRequest({
    required Uri uri,
    required Future<http.Response> Function(Uri) doCall,
  }) async {
    try {
      final response = await doCall(uri);
      if (response.statusCode != 200) {
        final json = jsonDecode(response.body);
        throw ErrorMessage.fromJson(json);
      }
      return response;
    } catch (err) {
      throw ClipboardApiException(message: err.toString(), detail: err);
    }
  }

  @override
  Future<void> addMessage(ClipboardMessage message) async {
    await _makeRequest(
      uri: Uri.parse('/clipboard/data/add'),
      doCall: (uri) => _service.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: message.toJson(),
      ),
    );
  }

  @override
  Future<ClipboardScanResult> scan({
    required int timestamp,
    required int limit,
  }) async {
    final response = await _makeRequest(
      uri: Uri(
        path: '/clipboard/data/scan',
        queryParameters: {
          'limit': limit.toString(),
          'timestamp': timestamp.toString(),
        },
      ),
      doCall: _service.get,
    );
    final json = jsonDecode(response.body);
    return ClipboardScanResult.fromJson(json);
  }

  @override
  Future<void> removeMessage(String id) async {
    await _makeRequest(
      uri: Uri.parse('/clipboard/data/$id'),
      doCall: _service.delete,
    );
  }

  @override
  Future<ClipboardMessage> copy(String id) async {
    final response = await _makeRequest(
      uri: Uri.parse('/clipboard/data/$id'),
      doCall: _service.get,
    );
    final json = jsonDecode(response.body);
    return ClipboardMessage.fromJson(json);
  }

  @override
  Future<void> clear() async {
    await _makeRequest(
      uri: Uri.parse('/clipboard/data/all'),
      doCall: _service.delete,
    );
  }
}

class RemoteClipboardNotifyRepository extends ClipboardNotifyRepository {
  late final SseSession<ClipboardNotify> _session;

  RemoteClipboardNotifyRepository({required ApiClientService service}) {
    _session = service.createSseSession(
      request: SseRequest(
        uri: Uri.parse('/sse/clipboard/notify'),
        method: SseRequestMethod.get,
      ),
      clientCustomer: (client) {
        client.connectionTimeout = const Duration(days: 1);
        client.idleTimeout = const Duration(seconds: 30);
      },
      transformer: (json) => ClipboardNotify.fromJson(json),
    );
  }

  SseConnectionStatus _status = SseConnectionStatus.disconnected;

  @override
  SseConnectionStatus get status => _status;

  StreamSubscription<SseConnectionState>? _stateSubscription;

  @override
  void close() {
    _stateSubscription?.cancel();
    _session.close();
  }

  @override
  void connect() {
    _stateSubscription ??= _session.connectionState.listen((state) {
      _status = state.state;
    });
    _session.connect();
  }

  @override
  void reconnect() {
    _stateSubscription ??= _session.connectionState.listen((state) {
      _status = state.state;
    });
    _session.disconnect();
    _session.connect();
  }

  @override
  Stream<ClipboardNotify> get notifyStream => _session.event;

  @override
  Stream<SseConnectionState> get stateStream => _session.connectionState;

  @override
  void disconnect() {
    _session.disconnect();
  }
}
