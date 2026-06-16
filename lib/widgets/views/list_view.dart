import 'package:flutter/material.dart';
import 'package:task_hub/models/enums.dart';
import 'package:task_hub/models/task.dart';
import '../../theme/theme.dart';
import '../task/task_checkbox.dart'; 

class TaskListView extends StatefulWidget {
  final List<TaskModel> tasks;
  final ValueChanged<TaskModel> onTaskTap;
  final ValueChanged<TaskModel> onTaskToggle;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskToggle,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  static const double _colWidthCheckbox = 46;
  static const double _colWidthTitle = 300;
  static const double _colWidthDate = 180;
  static const double _colWidthTime = 150;
  static const double _colWidthComplexity = 150;
  static const double _colWidthImportance = 150;
  static const double _colWidthAssignee = 140;
  
  static const double _tableHorizontalPadding = 20;

  double get _totalTableWidth =>
      _colWidthCheckbox +
      _colWidthTitle +
      _colWidthDate +
      _colWidthTime +
      _colWidthComplexity +
      _colWidthImportance +
      _colWidthAssignee +
      (_tableHorizontalPadding * 2);

  @override
  Widget build(BuildContext context) {
    final activeTasks = widget.tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = widget.tasks.where((t) => t.isCompleted).toList();

    return Container(
      color: AppColors.screenBackground,
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: _totalTableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(),
              
              Expanded(
                child: ListView(
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    ...activeTasks.map((task) => _buildTaskRow(task)),
                    
                    if (activeTasks.isNotEmpty && completedTasks.isNotEmpty)
                      _buildSectionDivider(),
                    
                    ...completedTasks.map((task) => _buildTaskRow(task)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: _tableHorizontalPadding),
      decoration: BoxDecoration(
        color: AppColors.screenBackground,
      ),
      child: Row(
        children: [
          const SizedBox(width: _colWidthCheckbox),
          _buildCell(_colWidthTitle, _headerText('Название')),
          _buildCell(_colWidthDate, _headerText('Дата')),
          _buildCell(_colWidthTime, _headerText('Время')),
          _buildCell(_colWidthComplexity, _headerText('Сложность')),
          _buildCell(_colWidthImportance, _headerText('Важность')),
          _buildCell(_colWidthAssignee, _headerText('Исполнители')),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppSizes.body,
        fontWeight: AppWeight.lightFontWeight,
        color: AppColors.darkBlue,
      ),
    );
  }

  Widget _buildTaskRow(TaskModel task) {
    return InkWell(
      onTap: () => widget.onTaskTap(task),
      hoverColor: AppColors.lightGray.withValues(alpha: 0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: _tableHorizontalPadding),
        
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _colWidthCheckbox,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TaskCheckbox(
                  isCompleted: task.isCompleted,
                  isOverdue: task.isOverdue(),
                  onTap: () => widget.onTaskToggle(task),
                ),
              ),
            ),
            
            _buildCell(
              _colWidthTitle,
              Text(
                task.title,
                style: TextStyle(
                  fontSize: AppSizes.body,
                  fontWeight: AppWeight.lightFontWeight,
                  color: task.isCompleted ? AppColors.darkGray : AppColors.darkBlue,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            _buildCell(
              _colWidthDate, 
              _buildTextOrPlaceholder(
                task.endDateTime != null 
                  ? _formatDate(task.endDateTime!) 
                  : null
              )
            ),
            
            _buildCell(
              _colWidthTime, 
              _buildTextOrPlaceholder(
                task.runtime != null ? '${task.runtime} мин' : null
              )
            ),
            
            _buildCell(
              _colWidthComplexity, 
              _buildDifficultyCell(task.difficulty)
            ),

            _buildCell(
              _colWidthImportance, 
              _buildImportanceCell(task.importance)
            ),
            
            _buildCell(
              _colWidthAssignee, 
              _buildAssigneesCell(task.idOfMembers)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(double width, Widget child) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: child,
      ),
    );
  }

  Widget _buildTextOrPlaceholder(String? value) {
    if (value == null || value.isEmpty || value == 'Выбрать...') {
      return const Text(
        'Выбрать...',
        style: TextStyle(
          fontSize: AppSizes.body,
          fontWeight: AppWeight.extraLightFontWeight,
          color: AppColors.darkGray,
        ),
      );
    }
    return Text(
      value,
      style: const TextStyle(
        fontSize: AppSizes.body,
        color: AppColors.darkBlue,
        fontWeight: AppWeight.lightFontWeight,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildIndicatorCell(String? value, {required bool isComplexity}) {
    if (value == null || value.isEmpty || value == 'Выбрать...') {
      return _buildTextOrPlaceholder(value);
    }

    Color dotColor = AppColors.green;
    final valLower = value.toLowerCase();

    if (isComplexity) {
      if (valLower.contains('сложн') || valLower.contains('высок')) {
        dotColor = AppColors.red;
      } else if (valLower.contains('средн')) {
        dotColor = AppColors.yellow;
      }
    } else {
      if (valLower.contains('высок') || valLower.contains('важн')) {
        dotColor = AppColors.red;
      } else if (valLower.contains('средн')) {
        dotColor = AppColors.yellow;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.body,
              fontWeight: AppWeight.lightFontWeight,
              color: AppColors.darkBlue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Widget _buildSectionDivider() {
    return Container(
      height: 1,
      color: AppColors.olive,
    );
  }

  Widget _buildDifficultyCell(EDifficulty? difficulty) {
    if (difficulty == null) {
      return _buildTextOrPlaceholder(null);
    }
    
    Color getColor() {
      switch (difficulty) {
        case EDifficulty.easy:
          return AppColors.green;
        case EDifficulty.medium:
          return AppColors.yellow;
        case EDifficulty.hard:
          return AppColors.red;
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: getColor(),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            difficulty.ruName,
            style: const TextStyle(
              fontSize: AppSizes.body,
              fontWeight: AppWeight.lightFontWeight,
              color: AppColors.darkBlue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildImportanceCell(EImportance? importance) {
    if (importance == null) {
      return _buildTextOrPlaceholder(null);
    }
    
    Color getColor() {
      switch (importance) {
        case EImportance.low:
          return AppColors.green;
        case EImportance.medium:
          return AppColors.yellow;
        case EImportance.high:
          return AppColors.red;
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: getColor(),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            importance.ruName,
            style: const TextStyle(
              fontSize: AppSizes.body,
              fontWeight: AppWeight.lightFontWeight,
              color: AppColors.darkBlue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAssigneesCell(List<String> memberIds) {
    if (memberIds.isEmpty) {
      return _buildTextOrPlaceholder(null);
    }
    
    // TODO: потом вывести имя первого исполнителя и дописать "и др."
    final count = memberIds.length;
    return Text(
      '$count ${_getMembersText(count)}',
      style: const TextStyle(
        fontSize: AppSizes.body,
        fontWeight: AppWeight.lightFontWeight,
        color: AppColors.darkBlue,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getMembersText(int count) {
    if (count == 1) return 'исполнитель';
    if (count <= 4) return 'исполнителя';
    return 'исполнителей';
  }

}