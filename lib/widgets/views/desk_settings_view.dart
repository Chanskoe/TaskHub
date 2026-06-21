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
          subscription ??= WebSocketService().taskStream.listen((data) {
              if (data['action'] == 'search_users_result') {
                setStateDialog(() {
                  searchResults = List<Map<String, dynamic>>.from(data['users']);
                  isLoading = false;
                });
              }
            });
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text('Добавить участника', textAlign: TextAlign.center, style: TextStyle(fontSize: AppSizes.subHeader, fontWeight: AppWeight.normalFontWeight)),
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
                      padding: EdgeInsets.all(16),
                      child: Text('Пользователи не найдены'),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: false,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _addMember(user['id'], user['nickname']),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, color: AppColors.darkGray),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        user['nickname'],
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.darkBlue,
                                          fontSize: AppSizes.body,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.add, color: AppColors.darkBlue, size: 18,),
                                  ],
                                ),
                              ),
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
                child: const Text('Закрыть', style: TextStyle(fontSize: AppSizes.body, color: AppColors.darkBlue, fontWeight: AppWeight.normalFontWeight)),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  cursorWidth: 1,                 
                  cursorHeight: 14,
                  textAlignVertical: TextAlignVertical.center,
                  controller: _deskTitleController,
                  style: const TextStyle(
                    fontSize: AppSizes.subHeader,
                    color: AppColors.darkBlue,
                    overflow: TextOverflow.ellipsis
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Введите название доски...',
                    hintStyle: TextStyle(
                    color: AppColors.darkGray, 
                    fontSize: AppSizes.search, 
                    fontWeight: AppWeight.extraLightFontWeight,
                  ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  onSubmitted: _renameDesk,
                ),
              ),
              const SizedBox(width: 8),
              if (widget.currentUserId == widget.desk.idOfAdmin) 
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.darkBlue),
                  onPressed: _deleteDesk,
                  padding: EdgeInsets.zero,
                  tooltip: 'Удалить доску',
                ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 1,
            color: AppColors.olive,
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Исполнители',
                style: TextStyle(fontSize: AppSizes.subHeader, fontWeight: AppWeight.normalFontWeight, color: AppColors.darkBlue),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20, color: AppColors.darkBlue),
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
                    color:AppColors.darkGray,
                  ),
                  title: Text(member['nickname'], overflow: TextOverflow.ellipsis,),
                  trailing: (widget.currentUserId == widget.desk.idOfAdmin && member['id'] != widget.desk.idOfAdmin)
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _removeMember(member['id']),
                          tooltip: 'Удалить из доски',
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}