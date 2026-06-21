import 'package:flutter/material.dart';
import 'package:task_hub/models/task.dart';
import 'package:task_hub/services/websocket_service.dart';
import '../../theme/theme.dart';
import '../task/task_column.dart';

class KanbanColumnData {
  final String? id;
  String title;
  List<TaskModel> tasks;
  TextEditingController controller;

  KanbanColumnData({
    this.id,
    required this.title,
    required this.tasks,
  }) : controller = TextEditingController(text: title);
}

class KanbanView extends StatefulWidget {
  final List<Map<String, dynamic>> rawColumns;
  final List<TaskModel> allDeskTasks;
  final String currentUserId;
  final String? currentDeskId;
  final VoidCallback onTaskUpdated;
  final ValueChanged<TaskModel>? onTaskTap;

  const KanbanView({
    super.key,
    required this.rawColumns,
    required this.allDeskTasks,
    required this.currentUserId,
    this.currentDeskId,
    required this.onTaskUpdated,
    this.onTaskTap,
  });

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  late List<KanbanColumnData> _columns;
  int? _inlineInputColumnIndex;

  @override
  void initState() {
    super.initState();
    _initColumns();
  }

  void _initColumns() {
    _columns = widget.rawColumns.map((colMap) {
      final colId = colMap['id'] as String;
      final colTitle = colMap['title'] as String;

      final columnTasks = widget.allDeskTasks
          .where((t) => t.kanbanColumnId == colId)
          .toList();

      return KanbanColumnData(id: colId, title: colTitle, tasks: columnTasks);
    }).toList();
    
    _columns.sort((a, b) {
      final aOrder = widget.rawColumns.firstWhere((c) => c['id'] == a.id)['order'] ?? 0;
      final bOrder = widget.rawColumns.firstWhere((c) => c['id'] == b.id)['order'] ?? 0;
      return aOrder.compareTo(bOrder);
    });
  }

  @override
  void didUpdateWidget(KanbanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initColumns();
  }

  void _addColumn() {
    if (widget.currentDeskId == null) return;
    WebSocketService().createKanbanColumn(widget.currentDeskId!, 'Новая колонка');
  }

  void _removeColumn(int index) {
    final column = _columns[index];
    for (var task in column.tasks) {
      WebSocketService().sendAction('update_task', {
        'id': task.id,
        'kanban_column_id': null,
      });
    }
    if (column.id != null) {
      WebSocketService().deleteKanbanColumn(column.id!);
    }
    setState(() {
      _columns.removeAt(index);
    });
    widget.onTaskUpdated();
  }

  void _renameColumn(int index, String newTitle) {
    final String trimmed = newTitle.trim();
    final column = _columns[index];

    if (trimmed.isEmpty) {
      _removeColumn(index);
      return;
    }
    if (column.title == trimmed) return;

    setState(() {
      column.title = trimmed;
      column.controller.text = trimmed;
    });
    
    if (column.id != null) {
      WebSocketService().updateKanbanColumn(column.id!, trimmed);
    }
    widget.onTaskUpdated();
  }

  Future<void> _showAddTaskDialog(int columnIndex) async {
    final columnId = _columns[columnIndex].id;
    final columnTitle = _columns[columnIndex].title;
    if (columnId == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Добавить задачу', style: TextStyle(
            fontSize: AppSizes.body,
            color: AppColors.darkBlue,
            fontWeight: AppWeight.lightFontWeight,
          ),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.darkBlue, size: 20),
              title: const Text('Новая задача', style: TextStyle(color: AppColors.darkBlue, fontSize: AppSizes.search)),
              onTap: () => Navigator.pop(context, {'type': 'new'}),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: AppColors.darkBlue, size: 20),
              title: const Text('Существующая задача', style: TextStyle(color: AppColors.darkBlue, fontSize: AppSizes.search)),
              onTap: () => Navigator.pop(context, {'type': 'existing'}),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    if (result['type'] == 'new') {
      setState(() {
        _inlineInputColumnIndex = columnIndex;
      });
    } else if (result['type'] == 'existing') {
      final availableTasks = widget.allDeskTasks.where((t) => t.kanbanColumnId != columnId).toList();
      
      if (availableTasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.darkBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text(
              'Задач для добавления нет',
              style: TextStyle(color: AppColors.cardBackground),
            ),
          ),
        );
        return;
      }

      final selectedTask = await showDialog<TaskModel>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Выберите задачу',
            style: TextStyle(
              fontSize: AppSizes.body,
              color: AppColors.darkBlue,
              fontWeight: AppWeight.lightFontWeight,
            ),
          ),
          content: SizedBox(
            width: 250,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableTasks.length,
              itemBuilder: (context, idx) {
                final currentTask = availableTasks[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      currentTask.title,
                      style: const TextStyle(color: AppColors.darkBlue, fontSize: AppSizes.search),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.darkBlue),
                    onTap: () => Navigator.pop(context, currentTask),
                  ),
                );
              },
            ),
          ),
        ),
      );
      if (selectedTask != null) {
        _assignTaskToColumn(selectedTask.id, columnId);
      }
    }
  }

  void _createNewTask(String columnId, String taskTitle, String columnTitle) {
    WebSocketService().sendAction('create_task', {
      'title': taskTitle,
      'kanban_column_id': columnId,
      'kanban_column_title': columnTitle,
      'id_of_desk': widget.currentDeskId,
    });
    widget.onTaskUpdated();
  }

  void _assignTaskToColumn(String taskId, String columnId) {
    WebSocketService().sendAction('update_task', {
      'id': taskId,
      'kanban_column_id': columnId,
    });
    widget.onTaskUpdated();
  }

  @override
  void dispose() {
    for (var col in _columns) {
      col.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: _columns.length + 1,
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              color: AppColors.cardBackground,
              shadowColor: AppColors.olive,
              child: child,
            );
          },
          child: child,
        );
      },

      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) {
        if (oldIndex == _columns.length) return;
        
        if (newIndex > _columns.length) {
          newIndex = _columns.length;
        }

        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = _columns.removeAt(oldIndex);
          _columns.insert(newIndex, item);

          if (_inlineInputColumnIndex == oldIndex) {
            _inlineInputColumnIndex = newIndex;
          } else if (_inlineInputColumnIndex != null) {
            if (oldIndex < _inlineInputColumnIndex! && newIndex >= _inlineInputColumnIndex!) {
              _inlineInputColumnIndex = _inlineInputColumnIndex! - 1;
            } else if (oldIndex > _inlineInputColumnIndex! && newIndex <= _inlineInputColumnIndex!) {
              _inlineInputColumnIndex = _inlineInputColumnIndex! + 1;
            }
          }
        });

        final List<Map<String, dynamic>> reorderedPayload = [];
        for (int i = 0; i < _columns.length; i++) {
          if (_columns[i].id != null) {
            reorderedPayload.add({
              'id': _columns[i].id,
              'order': i,
            });
          }
        }

        WebSocketService().sendAction('reorder_kanban_columns', {
          'columns': reorderedPayload,
        });
        
        widget.onTaskUpdated();
      },

      itemBuilder: (context, index) {
        if (index == _columns.length) {
          return Container(
            key: const ValueKey('add_column_button_key'),
            child: _buildAddColumnButton(),
          );
        }
        final column = _columns[index];
        return Container(
          key: ValueKey(column.id ?? 'column_$index'),
          child: TaskColumn(
            dayTitle: column.title,
            tasks: column.tasks,
            isEditable: true,
            titleController: column.controller,
            autoFocusTitle: column.title.isEmpty,
            onAddTaskPressed: () => _showAddTaskDialog(index),
            onDeleteColumn: () => _removeColumn(index),
            onTaskTap: widget.onTaskTap,
            onTaskToggle: (task) {
              WebSocketService().sendAction('update_task', {
                'id': task.id,
                'isCompleted': !task.isCompleted,
              });
              widget.onTaskUpdated();
            },
            onTitleChanged: (newTitle) => _renameColumn(index, newTitle),
            showInlineInput: _inlineInputColumnIndex == index,
            onInlineTaskSubmitted: (taskTitle) {
              if (column.id != null) {
                _createNewTask(column.id!, taskTitle, column.title);
              }
              setState(() {
                _inlineInputColumnIndex = null;
              });
            },
            onInlineTaskCancelled: () {
              setState(() {
                _inlineInputColumnIndex = null;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildAddColumnButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      alignment: Alignment.topLeft,
      child: InkWell(
        onTap: _addColumn,
        borderRadius: BorderRadius.circular(20),
        hoverColor: AppColors.olive.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.olive, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Добавить столбец',
            style: TextStyle(
              fontSize: AppSizes.body,
              fontWeight: AppWeight.lightFontWeight,
              color: AppColors.darkBlue,
            ),
          ),
        ),
      ),
    );
  }
}