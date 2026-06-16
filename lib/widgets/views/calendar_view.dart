import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:task_hub/models/task.dart';
import 'package:task_hub/widgets/task/task_card_v2.dart';
import '../../theme/theme.dart';

class CalendarView extends StatefulWidget {
  final List<TaskModel> tasks;
  final Function(TaskModel) onTaskTap;
  final Function(TaskModel) onTaskToggle;

  const CalendarView({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskToggle,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _currentMonth;
  final List<String> _weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<DateTime> _getDaysInMonth() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    final startOffset = firstDayOfWeek == 0 ? 6 : firstDayOfWeek - 1;

    final days = <DateTime>[];
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final daysInPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
    for (int i = startOffset; i > 0; i--) {
      days.add(DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - i + 1));
    }
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    int remaining = 42 - days.length;
    for (int i = 1; i <= remaining; i++) {
      days.add(DateTime(nextMonth.year, nextMonth.month, i));
    }
    return days;
  }

  int _taskStatusPriority(TaskModel task) {
    if (task.isOverdue() && !task.isCompleted) return 0;
    if (!task.isCompleted) return 1;
    return 2;
  }

  List<TaskModel> _getTasksForDay(DateTime day) {
    final tasksForDay = widget.tasks.where((task) {
      if (task.endDateTime == null) return false;
      final taskDate = DateTime(task.endDateTime!.year, task.endDateTime!.month, task.endDateTime!.day);
      return taskDate == day;
    }).toList();

    tasksForDay.sort((a, b) {
      final aStatus = _taskStatusPriority(a);
      final bStatus = _taskStatusPriority(b);
      if (aStatus != bStatus) return aStatus.compareTo(bStatus);
      final aDate = a.endDateTime ?? DateTime(3000);
      final bDate = b.endDateTime ?? DateTime(3000);
      return aDate.compareTo(bDate);
    });
    return tasksForDay;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    const monthNames = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    final currentMonthTitle = '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.darkBlue, size: 22),
                onPressed: _previousMonth,
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                currentMonthTitle,
                style: const TextStyle(
                  fontSize: AppSizes.body,
                  fontWeight: FontWeight.normal,
                  color: AppColors.mediumBlue,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.darkBlue, size: 22),
                onPressed: _nextMonth,
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double minCalendarWidth = 150 * 7 + 2;
              final double availableWidth = constraints.maxWidth - 12;
              final double calendarWidth = math.max(minCalendarWidth, availableWidth);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    width: calendarWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.olive, width: 1),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      children: [
                        _buildDaysOfWeekHeader(),
                        ..._buildCalendarWeeks(days),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeekHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.olive,
        border: Border(bottom: BorderSide(color: AppColors.olive, width: 1)),
      ),
      child: Row(
        children: _weekDays.map((day) {
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: AppSizes.body,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF42464C),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildCalendarWeeks(List<DateTime> days) {
    List<Widget> weeks = [];
    for (int i = 0; i < days.length; i += 7) {
      final weekDays = days.sublist(i, i + 7);
      weeks.add(
        IntrinsicHeight(
          child: Row(
            children: weekDays.map((date) {
              final isCurrentMonth = date.month == _currentMonth.month;
              return Expanded(
                child: _buildDayCell(date, isCurrentMonth),
              );
            }).toList(),
          ),
        ),
      );
    }
    return weeks;
  }

  Widget _buildDayCell(DateTime date, bool isCurrentMonth) {
    final tasksForDay = _getTasksForDay(date);
    final dayNumber = date.day;
    final textColor = isCurrentMonth ? AppColors.darkBlue : AppColors.darkGray.withOpacity(0.5);

    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.olive, width: 1),
          right: BorderSide(color: AppColors.olive, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$dayNumber',
            style: TextStyle(
              fontSize: AppSizes.caption,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          ...tasksForDay.map((task) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: CalendarTaskCard(
              task: task,
              onTap: () => widget.onTaskTap(task),
              onToggle: () => widget.onTaskToggle(task),
            ),
          )),
        ],
      ),
    );
  }
}