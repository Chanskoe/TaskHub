import 'package:flutter/material.dart';
import 'package:task_hub/models/task.dart';
import 'package:task_hub/widgets/task/task_checkbox.dart';
import '../../theme/theme.dart';

class CalendarTaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const CalendarTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = task.isCompleted ? AppColors.darkGray : AppColors.darkBlue;
    final timeString = task.getHourMinute();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: TextStyle(
                fontSize: AppSizes.caption,
                fontWeight: FontWeight.w300,
                color: textColor,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                TaskCheckbox(
                  isCompleted: task.isCompleted,
                  isOverdue: task.isOverdue(),
                  onTap: onToggle,
                ),
                if (task.isOverdue() && !task.isCompleted && task.getOverdueDaysText().isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    task.getOverdueDaysText(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: AppColors.red,
                    ),
                  ),
                ],
                const Spacer(),
                if (timeString.isNotEmpty)
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: textColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}