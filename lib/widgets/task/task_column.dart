import 'package:flutter/material.dart';
import 'package:task_hub/models/task.dart';
import '../../theme/theme.dart';
import 'task_card_v1.dart';

class TaskColumn extends StatefulWidget {
  final String dayTitle;
  final List<TaskModel> tasks;
  final bool showInlineInput;
  final ValueChanged<String>? onInlineTaskSubmitted;
  final VoidCallback? onInlineTaskCancelled;
  final VoidCallback? onAddTaskPressed;
  final ValueChanged<TaskModel>? onTaskTap;
  final ValueChanged<TaskModel>? onTaskToggle;
  final ValueChanged<String>? onTitleChanged;
  final bool autoFocusTitle;
  
  final bool isEditable;
  final TextEditingController? titleController;
  final VoidCallback? onDeleteColumn;

  const TaskColumn({
    super.key,
    required this.dayTitle,
    required this.tasks,
    this.showInlineInput = false,
    this.onInlineTaskSubmitted,
    this.onInlineTaskCancelled,
    this.onAddTaskPressed,
    this.onTaskTap,
    this.onTaskToggle,
    this.isEditable = false,
    this.titleController,
    this.onDeleteColumn,
    this.onTitleChanged,
    this.autoFocusTitle = false,
  });

  @override
  State<TaskColumn> createState() => _TaskColumnState();
}

class _TaskColumnState extends State<TaskColumn> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.showInlineInput) {
      _focusNode.requestFocus();
    }

    _titleFocusNode.addListener(_onTitleFocusChange);

    if (widget.autoFocusTitle && widget.titleController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(TaskColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showInlineInput && !oldWidget.showInlineInput) {
      _focusNode.requestFocus();
    }
    if (widget.autoFocusTitle && !oldWidget.autoFocusTitle && widget.titleController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _titleFocusNode.dispose();
    super.dispose();
  }

  String _formatDayTitle(String title) {
    if (!title.contains(', ')) return title;

    try {
      final parts = title.split(', ');
      final dayOfWeek = parts[0]; 
      final datePart = parts[1]; 

      final dateParts = datePart.split('.');
      final int day = int.parse(dateParts[0]);
      final int month = int.parse(dateParts[1]);

      const monthsRu = [
        'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
      ];

      if (month >= 1 && month <= 12) {
        return '$dayOfWeek, $day ${monthsRu[month - 1]}';
      }
    } catch (_) {
      
    }
    return title;
  }

  void _onTitleFocusChange() {
    if (!_titleFocusNode.hasFocus && widget.titleController != null && widget.onTitleChanged != null) {
      final newTitle = widget.titleController!.text.trim();
      if (newTitle.isNotEmpty && newTitle != widget.dayTitle) {
        widget.onTitleChanged!(newTitle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overdueTasks = widget.tasks.where((t) => t.isOverdue() && !t.isCompleted).toList();
    final currentUncompletedTasks = widget.tasks.where((t) => !t.isOverdue() && !t.isCompleted).toList();
    final completedTasks = widget.tasks.where((t) => t.isCompleted).toList();

    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus && widget.showInlineInput) {
          widget.onInlineTaskCancelled?.call();
          _controller.clear();
        }
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: widget.isEditable && widget.titleController != null
                        ? TextField(
                            controller: widget.titleController,
                            focusNode: _titleFocusNode,
                            style: const TextStyle(
                              fontSize: AppSizes.body, 
                              color: AppColors.darkBlue,
                              fontWeight: AppWeight.lightFontWeight
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (newTitle) {       
                              if (widget.onTitleChanged != null && newTitle.trim().isNotEmpty) {
                                widget.onTitleChanged!(newTitle.trim());
                              }
                            },
                          )
                        : Text(
                            widget.isEditable? widget.dayTitle : _formatDayTitle(widget.dayTitle),
                            style: const TextStyle(
                              fontSize: AppSizes.body, 
                              color: AppColors.darkBlue,
                              fontWeight: AppWeight.lightFontWeight
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isEditable)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.darkBlue),
                        onPressed: widget.onDeleteColumn,
                        splashRadius: 20,
                      ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 14, color: AppColors.darkBlue),
                      onPressed: widget.onAddTaskPressed,
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (widget.showInlineInput)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          cursorWidth: 1,                 
                          cursorHeight: 14,
                          controller: _controller,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            fontSize: AppSizes.search,
                            color: AppColors.darkBlue,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Название задачи...',
                            hintStyle: TextStyle(
                              color: AppColors.darkGray, 
                              fontSize: AppSizes.search, 
                              fontWeight: AppWeight.extraLightFontWeight,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              widget.onInlineTaskSubmitted?.call(val.trim());
                              _controller.clear();
                            } else {
                              widget.onInlineTaskCancelled?.call();
                            }
                          },
                        ),
                      ),
                    ),
                  ...overdueTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => widget.onTaskTap?.call(task),
                      child: TaskCard(task: task, onCheckboxTap: () => widget.onTaskToggle?.call(task)),
                    ),
                  )),
                  
                  ...currentUncompletedTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => widget.onTaskTap?.call(task),
                      child: TaskCard(task: task, onCheckboxTap: () => widget.onTaskToggle?.call(task)),
                    ),
                  )),

                  if (completedTasks.isNotEmpty && (overdueTasks.isNotEmpty || currentUncompletedTasks.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      child: Container(
                        height: 1,
                        color: AppColors.olive,
                      ),
                    ),

                  ...completedTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => widget.onTaskTap?.call(task),
                      child: TaskCard(task: task, onCheckboxTap: () => widget.onTaskToggle?.call(task)),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}