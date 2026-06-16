import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class TaskCheckbox extends StatefulWidget {
  final bool isCompleted;
  final bool isOverdue;
  final VoidCallback? onTap;

  const TaskCheckbox({
    super.key,
    required this.isCompleted,
    required this.isOverdue,
    this.onTap,
  });

  @override
  State<TaskCheckbox> createState() => _TaskCheckboxState();
}

class _TaskCheckboxState extends State<TaskCheckbox> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color checkboxColor = AppColors.gray;
    if (widget.isCompleted) {
      checkboxColor = AppColors.green;
    } else if (widget.isOverdue) {
      checkboxColor = AppColors.red;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: checkboxColor,
              width: 1.5,
            ),
            color: widget.isCompleted ? AppColors.green : Colors.transparent,
          ),
          child: Center(
            child: _buildCheckboxIcon(checkboxColor),
          ),
        ),
      ),
    );
  }

  Widget? _buildCheckboxIcon(Color color) {
    if (widget.isCompleted) {
      return const Icon(Icons.check, size: 12, color: Colors.white);
    }
    if (_isHovered) {
      return Icon(Icons.check, size: 12, color: color.withValues(alpha: 0.7));
    }
    return null;
  }
}