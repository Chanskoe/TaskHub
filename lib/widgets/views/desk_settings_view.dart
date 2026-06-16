import 'dart:async';

import 'package:flutter/material.dart';
import 'package:task_hub/models/desk.dart';
import 'package:task_hub/services/websocket_service.dart';
import '../../theme/theme.dart';
import '../sidebar_search_bar.dart';

class DeskSettingsView extends StatefulWidget {
  final DeskModel desk;
  final String currentUserId;
  final VoidCallback onDeskUpdated;

  const DeskSettingsView({
    super.key,
    required this.desk,
    required this.currentUserId,
    required this.onDeskUpdated,
  });

  @override
  State<DeskSettingsView> createState() => _DeskSettingsViewState();
}

class _DeskSettingsViewState extends State<DeskSettingsView> {
  late TextEditingController _deskTitleController;

  @override
  void initState() {
    super.initState();
    _deskTitleController = TextEditingController(text: widget.desk.title);
  }

  @override
  void dispose() {
    _deskTitleController.dispose();
    super.dispose();
  }

  void _renameDesk(String newTitle) {
    if (newTitle.trim().isEmpty || newTitle == widget.desk.title) return;
    WebSocketService().sendAction('rename_desk', {
      'desk_id': widget.desk.id,
      'title': newTitle,
    });
    widget.onDeskUpdated();
  }

  void _deleteDesk() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить доску?'),
        content: const Text('Все задачи в доске также будут удалены. Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      WebSocketService().sendAction('delete_desk', {'desk_id': widget.desk.id});
      widget.onDeskUpdated();
    }
  }

  void _addMember(String userId, String nickname) async {
    WebSocketService().sendAction('add_desk_member', {
      'desk_id': widget.desk.id,
      'user_id': userId,
    });
    widget.onDeskUpdated();
    if (mounted) Navigator.of(context).pop();
  }

  void _removeMember(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить участника?'),
        content: const Text('Этот пользователь потеряет доступ к доске.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      WebSocketService().sendAction('remove_desk_member', {
        'desk_id': widget.desk.id,
        'user_id': userId,
      });
      widget.onDeskUpdated();
    }
  }

  Future<void> _showAddMemberDialog() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isLoading = false;
    StreamSubscription<Map<String, dynamic>>? subscription;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          if (subscription == null) {
            subscription = WebSocketService().taskStream.listen((data) {
              if (data['action'] == 'search_users_result') {
                setStateDialog(() {
                  searchResults = List<Map<String, dynamic>>.from(data['users']);
                  isLoading = false;
                });
              }
            });
          }
          return AlertDialog(
            title: const Text('Добавить участника'),
            content: SizedBox(
              width: 400,
              height: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SidebarSearchBar(
                    onChanged: (query) async {
                      setStateDialog(() {
                        isLoading = true;
                        searchResults = [];
                      });
                      WebSocketService().searchUsers(query);
                    },
                  ),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Пользователи не найдены'),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: false,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          return ListTile(
                            title: Text(user['nickname']),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.green),
                              onPressed: () => _addMember(user['id'], user['nickname']),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  subscription?.cancel();
                  if (mounted) Navigator.of(dialogContext).pop();
                },
                child: const Text('Закрыть'),
              ),
            ],
          );
        },
      ),
    );
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final members = List<Map<String, dynamic>>.from(widget.desk.members);
    members.sort((a, b) {
      if (a['id'] == widget.desk.idOfAdmin) return -1;
      if (b['id'] == widget.desk.idOfAdmin) return 1;
      return (a['nickname'] as String).compareTo(b['nickname'] as String);
    });

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deskTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Название доски',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _renameDesk,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
                onPressed: _deleteDesk,
                tooltip: 'Удалить доску',
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Text(
                'Исполнители',
                style: TextStyle(fontSize: AppSizes.subHeader, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: _showAddMemberDialog,
                tooltip: 'Добавить участника',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final bool isAdmin = member['id'] == widget.desk.idOfAdmin;
                return ListTile(
                  leading: Icon(
                    isAdmin ? Icons.star : Icons.person,
                    color: isAdmin ? AppColors.yellow : AppColors.darkGray,
                  ),
                  title: Text(member['nickname']),
                  trailing: isAdmin
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _removeMember(member['id']),
                          tooltip: 'Удалить из доски',
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}