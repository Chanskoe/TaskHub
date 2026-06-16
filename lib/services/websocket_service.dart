import 'dart:async';
import 'dart:convert';
import 'package:task_hub/services/api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _streamController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get taskStream => _streamController.stream;

  void connect(String userId) {
    final baseHttpUrl = ApiService().baseUrl; 
  
    final String wsUrl = '${baseHttpUrl.replaceFirst('http://', 'ws://')}/ws/$userId';
        
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    _channel!.stream.listen(
      (data) {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        _streamController.add(decoded);
      },
      onError: (err) => print("WS Error: $err"),
      onDone: () => print("WS Connection Closed"),
    );
  }

  void sendAction(String action, Map<String, dynamic> data) {
    if (_channel != null) {
      final payload = {"action": action, ...data};
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
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