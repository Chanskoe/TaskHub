import 'package:flutter/material.dart';
import 'dart:async';
import 'package:task_hub/models/desk.dart';
import 'package:task_hub/services/websocket_service.dart';
import 'package:task_hub/models/task.dart';
import 'package:task_hub/widgets/views/desk_settings_view.dart';
import 'package:task_hub/widgets/views/kanban_view.dart';
import 'package:task_hub/widgets/views/list_view.dart';
import '../theme/theme.dart';
import '../widgets/desk_settings_bar.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/views/week_view.dart';
import '../widgets/task/task_edit_sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/views/calendar_view.dart';

class TaskScreen extends StatefulWidget {
  final String userId;
  const TaskScreen({super.key, required this.userId});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  StreamSubscription<Map<String, dynamic>>? _taskStreamSubscription;
  String _selectedSidebarItem = 'Неделя';
  String? _currentBoardName;
  List<DeskModel> _desks = [];
  String _selectedView = 'Неделя';
  TaskModel? _selectedTask;
  String? _addingTaskToDay;
  Map<String, List<TaskModel>> _weekTasks = {};

  @override
  void initState() {
    super.initState();
    WebSocketService().connect(widget.userId);
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _taskStreamSubscription = WebSocketService().taskStream.listen((data) {
      if (data['view'] == 'Неделя') {
        _parseWeekState(data['tasks']);
      }
      if (data['desks'] != null) {
        setState(() {
          _desks = (data['desks'] as List)
              .map((d) => DeskModel.fromJson(d as Map<String, dynamic>))
              .toList();
        });
      }
    });
  }

  void _createDesk(String deskTitle) {
    WebSocketService().sendAction("create_desk", {"title": deskTitle});
  }

  void _parseWeekState(Map<String, dynamic> tasksData) {
    Map<String, List<TaskModel>> parsedTasks = {};
    TaskModel? reselectedTask;
    tasksData.forEach((day, tasksList) {
      parsedTasks[day] = (tasksList as List).map((t) {
        final task = TaskModel.fromJson(t as Map<String, dynamic>);
        if (_selectedTask != null && task.id == _selectedTask!.id) {
          reselectedTask = task;
        }
        return task;
      }).toList();
    });
    setState(() {
      _weekTasks = parsedTasks;
      if (reselectedTask != null) {
        _selectedTask = reselectedTask;
      }
    });
  }

  Map<String, List<TaskModel>> _getFilteredTasks() {
    if (_currentBoardName == null) return _weekTasks;
    final currentDesk = _desks.firstWhere(
      (d) => d.title == _currentBoardName,
      orElse: () => DeskModel(id: '', title: '', idOfAdmin: '', members: []),
    );
    if (currentDesk.id.isEmpty) return {};
    Map<String, List<TaskModel>> filtered = {};
    _weekTasks.forEach((day, tasks) {
      filtered[day] = tasks.where((t) => t.idOfDesk == currentDesk.id).toList();
    });
    return filtered;
  }

  void _createTask(String dayTitle, String taskTitle) {
    final daysList = _weekTasks.keys.toList();
    final index = daysList.indexOf(dayTitle);
    DateTime? endDate;
    if (index != -1) {
      final now = DateTime.now();
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59).add(Duration(days: index));
    }
    String? currentDeskId;
    if (_currentBoardName != null) {
      final currentDesk = _desks.firstWhere(
        (d) => d.title == _currentBoardName,
        orElse: () => DeskModel(id: '', title: '', idOfAdmin: '', members: []),
      );
      if (currentDesk.id.isNotEmpty) currentDeskId = currentDesk.id;
    }
    WebSocketService().sendAction("create_task", {
      "title": taskTitle,
      "end_date_time": endDate?.toIso8601String(),
      "id_of_desk": currentDeskId,
    });
    setState(() => _addingTaskToDay = null);
  }

  @override
  void dispose() {
    _taskStreamSubscription?.cancel();
    WebSocketService().disconnect();
    super.dispose();
  }

  void _handleTaskTap(TaskModel task) {
    setState(() => _selectedTask = task);
  }

  Widget _buildBodyContent() {
    if (_selectedSidebarItem == 'Неделя' || (_currentBoardName != null && _selectedView == 'Неделя')) {
      return WeekView(
        tasks: _getFilteredTasks(),
        addingTaskToDay: _addingTaskToDay,
        onAddTaskPressed: (day) => setState(() => _addingTaskToDay = day),
        onTaskSubmitted: _createTask,
        onTaskCancelled: () => setState(() => _addingTaskToDay = null),
        onTaskTap: _handleTaskTap,
        onTaskToggle: (task) {
          WebSocketService().sendAction("update_task", {
            "id": task.id,
            "isCompleted": !task.isCompleted,
          });
        },
      );
    }

    if (_selectedSidebarItem == 'Всё время' || (_currentBoardName != null && _selectedView == 'Список')) {
      final allTasks = _getFilteredTasks().values.expand((tasks) => tasks).toList();
      allTasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        if (!a.isCompleted && !b.isCompleted) {
          final aOverdue = a.isOverdue();
          final bOverdue = b.isOverdue();
          if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
        }
        final aDate = a.endDateTime ?? DateTime(3000);
        final bDate = b.endDateTime ?? DateTime(3000);
        return aDate.compareTo(bDate);
      });
      return TaskListView(
        tasks: allTasks,
        onTaskTap: _handleTaskTap,
        onTaskToggle: (task) {
          WebSocketService().sendAction("update_task", {
            "id": task.id,
            "isCompleted": !task.isCompleted,
          });
        },
      );
    }

    if (_selectedSidebarItem == 'Канбан' || (_currentBoardName != null && _selectedView == 'Канбан')) {
      final allTasks = _getFilteredTasks().values.expand((tasks) => tasks).toList();
      final currentDesk = _desks.firstWhere(
        (d) => d.title == _currentBoardName,
        orElse: () => DeskModel(id: '', title: '', idOfAdmin: '', members: [], kanbanColumns: []),
      );
      return KanbanView(
        key: ValueKey(currentDesk.kanbanColumns.length),
        rawColumns: currentDesk.kanbanColumns,
        allDeskTasks: allTasks,
        currentUserId: widget.userId,
        currentDeskId: currentDesk.id.isNotEmpty ? currentDesk.id : null,
        onTaskUpdated: () => setState(() {}),
        onTaskTap: _handleTaskTap,
      );
    }

    if (_currentBoardName != null && _selectedView == 'Календарь') {
      final allTasks = _getFilteredTasks().values.expand((tasks) => tasks).toList();
      return CalendarView(
        tasks: allTasks,
        onTaskTap: _handleTaskTap,
        onTaskToggle: (task) {
          WebSocketService().sendAction("update_task", {
            "id": task.id,
            "isCompleted": !task.isCompleted,
          });
        },
      );
    }

    if (_selectedSidebarItem == 'Сегодня') {
      final allTasks = _getFilteredTasks().values.expand((tasks) => tasks).toList();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final todayTasks = allTasks.where((task) {
        if (task.endDateTime == null) return false;
        final taskDate = DateTime(task.endDateTime!.year, task.endDateTime!.month, task.endDateTime!.day);
        return taskDate == todayStart;
      }).toList();

      todayTasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        if (!a.isCompleted && !b.isCompleted) {
          final aOverdue = a.isOverdue();
          final bOverdue = b.isOverdue();
          if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
        }
        final aDate = a.endDateTime ?? DateTime(3000);
        final bDate = b.endDateTime ?? DateTime(3000);
        return aDate.compareTo(bDate);
      });

      return TaskListView(
        tasks: todayTasks,
        onTaskTap: _handleTaskTap,
        onTaskToggle: (task) {
          WebSocketService().sendAction("update_task", {
            "id": task.id,
            "isCompleted": !task.isCompleted,
          });
        },
      );
    }

    if (_selectedSidebarItem == 'Завтра') {
      final allTasks = _getFilteredTasks().values.expand((tasks) => tasks).toList();
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      final tomorrowTasks = allTasks.where((task) {
        if (task.endDateTime == null) return false;
        final taskDate = DateTime(task.endDateTime!.year, task.endDateTime!.month, task.endDateTime!.day);
        return taskDate == tomorrowStart;
      }).toList();

      tomorrowTasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        if (!a.isCompleted && !b.isCompleted) {
          final aOverdue = a.isOverdue();
          final bOverdue = b.isOverdue();
          if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
        }
        final aDate = a.endDateTime ?? DateTime(3000);
        final bDate = b.endDateTime ?? DateTime(3000);
        return aDate.compareTo(bDate);
      });

      return TaskListView(
        tasks: tomorrowTasks,
        onTaskTap: _handleTaskTap,
        onTaskToggle: (task) {
          WebSocketService().sendAction("update_task", {
            "id": task.id,
            "isCompleted": !task.isCompleted,
          });
        },
      );
    }

    if (_currentBoardName != null && _selectedView == 'Настройки') {
      final currentDesk = _desks.firstWhere(
        (d) => d.title == _currentBoardName,
        orElse: () => DeskModel(id: '', title: '', idOfAdmin: '', members: [], kanbanColumns: []),
      );
      if (currentDesk.id.isEmpty) return const SizedBox.shrink();
      return DeskSettingsView(
        desk: currentDesk,
        currentUserId: widget.userId,
        onDeskUpdated: () => setState(() {}),
      );
    }

    final String activeViewName = _currentBoardName != null ? _selectedView : _selectedSidebarItem;
    return Center(
      child: Text('Как вы сюда попали..?', style: const TextStyle(fontSize: 18)),
    );
  }

  void _handleSidebarSelection(String item, bool isBoard) {
    setState(() {
      _selectedSidebarItem = item;
      _currentBoardName = isBoard ? item : null;
      if (isBoard) _selectedView = 'Неделя';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    // На мобильных устройствах, если выбрана задача, показываем только панель редактирования на весь экран
    if (isMobile && _selectedTask != null) {
      return Scaffold(
        backgroundColor: AppColors.screenBackground,
        body: Column(
          children: [
            AppHeader(isLoggedIn: true, onLoginTap: () {}, onProfileTap: () {}),
            Expanded(
              child: TaskEditSidebar(
                task: _selectedTask!,
                desks: _desks,
                currentUserId: widget.userId,
                onClose: () => setState(() => _selectedTask = null),
                onUpdate: (eventPayload) {
                  final String? action = eventPayload['action'];
                  if (action != null) {
                    final data = Map<String, dynamic>.from(eventPayload)..remove('action');
                    WebSocketService().sendAction(action, data);
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    // Обычный режим (десктоп/планшет или мобильный без выбранной задачи)
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      drawer: isMobile
          ? Drawer(
              child: AppSidebar(
                selectedItem: _selectedSidebarItem,
                desks: _desks,
                onAddDeskSubmitted: _createDesk,
                onItemSelected: (item, isBoard) {
                  _handleSidebarSelection(item, isBoard);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Column(
        children: [
          AppHeader(isLoggedIn: true, onLoginTap: () {}, onProfileTap: () {}),
          Expanded(
            child: Row(
              children: [
                if (!isMobile)
                  AppSidebar(
                    selectedItem: _selectedSidebarItem,
                    desks: _desks,
                    onAddDeskSubmitted: _createDesk,
                    onItemSelected: _handleSidebarSelection,
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isMobile)
                              Builder(
                                builder: (innerContext) => IconButton(
                                  icon: const Icon(Icons.menu, color: AppColors.darkBlue, size: 20),
                                  onPressed: () => Scaffold.of(innerContext).openDrawer(),
                                ),
                              ),
                            if (_currentBoardName != null)
                              Expanded(
                                child: DeskSettingsBar(
                                  currentBoardName: _currentBoardName!,
                                  selectedView: _selectedView,
                                  onViewChanged: (v) => setState(() => _selectedView = v),
                                  onSettingsPressed: () => setState(() => _selectedView = 'Настройки'),
                                ),
                              ),
                            if (_currentBoardName == null && isMobile)
                              Container(
                                height: 35,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.olive,
                                  borderRadius: BorderRadius.circular(23),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_document, size: 18, color: AppColors.mediumBlue),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "Все задачи",
                                      style: TextStyle(
                                        fontSize: AppSizes.body,
                                        fontWeight: AppWeight.lightFontWeight,
                                        color: AppColors.darkBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (_currentBoardName != null) const SizedBox(height: 12),
                        Expanded(child: _buildBodyContent()),
                      ],
                    ),
                  ),
                ),
                if (!isMobile && _selectedTask != null)
                  Container(
                    width: 380,
                    child: TaskEditSidebar(
                      task: _selectedTask!,
                      desks: _desks,
                      currentUserId: widget.userId,
                      onClose: () => setState(() => _selectedTask = null),
                      onUpdate: (eventPayload) {
                        final String? action = eventPayload['action'];
                        if (action != null) {
                          final data = Map<String, dynamic>.from(eventPayload)..remove('action');
                          WebSocketService().sendAction(action, data);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}