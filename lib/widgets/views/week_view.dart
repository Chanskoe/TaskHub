import 'package:flutter/material.dart';
import 'package:task_hub/models/task.dart';
import '../task/task_column.dart';

class WeekView extends StatelessWidget {
  final Map<String, List<TaskModel>> tasks;
  final String? addingTaskToDay;
  final Function(String day) onAddTaskPressed;
  final Function(String day, String title) onTaskSubmitted;
  final VoidCallback onTaskCancelled;
  final Function(TaskModel) onTaskTap;
  final Function(TaskModel) onTaskToggle;

  const WeekView({
    super.key,
    required this.tasks,
    required this.addingTaskToDay,
    required this.onAddTaskPressed,
    required this.onTaskSubmitted,
    required this.onTaskCancelled,
    required this.onTaskTap,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: tasks.entries.map((entry) {
        return TaskColumn(
          dayTitle: entry.key,
          tasks: entry.value,
          showInlineInput: addingTaskToDay == entry.key,
          onAddTaskPressed: () => onAddTaskPressed(entry.key),
          onInlineTaskSubmitted: (title) => onTaskSubmitted(entry.key, title),
          onInlineTaskCancelled: onTaskCancelled,
          onTaskTap: onTaskTap,
          onTaskToggle: onTaskToggle,
        );
      }).toList(),
    );
  }
}