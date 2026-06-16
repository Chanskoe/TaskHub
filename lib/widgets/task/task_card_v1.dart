import 'package:flutter/material.dart';
import 'package:task_hub/models/task.dart';
import '../../theme/theme.dart';
import 'task_checkbox.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onCheckboxTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onCheckboxTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = task.isCompleted 
        ? AppColors.darkGray 
        : AppColors.darkBlue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: AppSizes.body,
                    fontWeight: AppWeight.lightFontWeight,
                    color: textColor,
                    decoration: task.isCompleted 
                        ? TextDecoration.lineThrough 
                        : TextDecoration.none,
                    decorationColor: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
                Text(
                  task.getHourMinute(),
                  style: TextStyle(
                    fontSize: AppSizes.caption,
                    fontWeight: AppWeight.lightFontWeight,
                    color: textColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TaskCheckbox(
                    isCompleted: task.isCompleted,
                    isOverdue: task.isOverdue(),
                    onTap: onCheckboxTap,
                  ),
                  
                  if (task.isOverdue()) ...[
                    const SizedBox(width: 8),
                    Text(
                      task.getOverdueDaysText(),
                      style: const TextStyle(
                        fontSize: AppSizes.caption,
                        fontWeight: AppWeight.lightFontWeight,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ],
              ),
              if (task.runtime != null)
                Text(
                  "${task.runtime} мин.",
                  style: TextStyle(
                    fontSize: AppSizes.caption,
                    fontWeight: AppWeight.lightFontWeight,
                    color: textColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}