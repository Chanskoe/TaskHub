import 'dart:async';
import 'dart:convert';
import 'package:task_hub/services/api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _streamController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  Stream<Map<String, dynamic>> get taskStream => _streamController.stream;

  String? _userId;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  final List<Map<String, dynamic>> _pendingActions = [];

  void connect(String userId) {
    _userId = userId;
    _reconnectAttempts = 0;
    _isDisposed = false;
    _connectInternal();
  }

  bool get isConnected => _isConnected;

  void _connectInternal() {
    if (_isDisposed || _userId == null) return;
    if (_isConnecting) return;
    _isConnecting = true;

    _channel?.sink.close();
    _channel = null;

    final baseHttpUrl = ApiService().baseUrl; 
    final String wsUrl = '${baseHttpUrl.replaceFirst('http://', 'ws://')}/ws/$_userId';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    _channel!.stream.listen(
      (data) {
        _reconnectAttempts = 0;
        _isConnected = true;
        _isConnecting = false;
        _connectionStatusController.add(true);
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        _streamController.add(decoded);
        _flushPendingActions();
      },
      onError: (err) {
        _isConnected = false;
        _isConnecting = false;
        _connectionStatusController.add(false);
        print("WS Error: $err");
        _scheduleReconnect();
      },
      onDone: () {
        _isConnected = false;
        _isConnecting = false;
        _connectionStatusController.add(false);
        print("WS Connection Closed");
        _scheduleReconnect();
      },
    );
  }

  void _scheduleReconnect() {
    if (_isDisposed || _userId == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print("Max reconnect attempts reached. Stop trying.");
      return;
    }
    int delay = (1 << _reconnectAttempts) * 1000;
    if (delay > 30000) delay = 30000;
    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (!_isDisposed && _userId != null) {
        _connectInternal();
      }
    });
  }

  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
    _userId = null;
    _isConnected = false;
    _isConnecting = false;
    _connectionStatusController.add(false);
  }

  void _flushPendingActions() {
    if (_pendingActions.isEmpty) return;
    if (!_isConnected) return;
    final actions = List<Map<String, dynamic>>.from(_pendingActions);
    _pendingActions.clear();
    for (var payload in actions) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(jsonEncode(payload));
      } else {
        _pendingActions.add(payload);
        break;
      }
    }
  }

  void sendAction(String action, Map<String, dynamic> data) {
    final payload = {"action": action, ...data};
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(payload));
    } else {
      _pendingActions.add(payload);
    }
  }

  void searchUsers(String query) {
    sendAction('search_users', {'query': query});
  }

  void createKanbanColumn(String deskId, String title) {
    sendAction('create_kanban_column', {'desk_id': deskId, 'title': title});
  }
  void updateKanbanColumn(String columnId, String newTitle) {
    sendAction('update_kanban_column', {'id': columnId, 'title': newTitle});
  }
  void deleteKanbanColumn(String columnId) {
    sendAction('delete_kanban_column', {'id': columnId});
  }
  void reorderKanbanColumns(List<Map<String, dynamic>> columns) {
    sendAction('reorder_kanban_columns', {'columns': columns});
  }
}