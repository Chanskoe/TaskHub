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
        title: const Text('Добавить задачу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Новая задача'),
              onTap: () => Navigator.pop(context, {'type': 'new'}),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Существующая задача'),
              onTap: () => Navigator.pop(context, {'type': 'existing'}),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    if (result['type'] == 'new') {
      final titleCtrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Название задачи'),
          content: TextField(controller: titleCtrl, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            TextButton(
              onPressed: () {
                final taskTitle = titleCtrl.text.trim();
                if (taskTitle.isNotEmpty) Navigator.pop(context, taskTitle);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ).then((taskTitle) {
        if (taskTitle is String && taskTitle.isNotEmpty) {
          _createNewTask(columnId, taskTitle, columnTitle);
        }
      });
    } else if (result['type'] == 'existing') {
      final tasksWithoutColumn = widget.allDeskTasks.where((t) => t.kanbanColumnId == null).toList();
      
      if (tasksWithoutColumn.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет доступных задач без колонки')),
        );
        return;
      }
      final selectedTask = await showDialog<TaskModel>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Выберите задачу'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tasksWithoutColumn.length,
              itemBuilder: (context, idx) => ListTile(
                title: Text(tasksWithoutColumn[idx].title),
                onTap: () => Navigator.pop(context, tasksWithoutColumn[idx]),
              ),
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
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: _columns.length + 1,
      itemBuilder: (context, index) {
        if (index == _columns.length) {
          return _buildAddColumnButton();
        }
        final column = _columns[index];
        return TaskColumn(
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
        );
      },
    );
  }

  Widget _buildAddColumnButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
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