import 'enums.dart';
import 'comment.dart';

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? endDateTime;
  final DateTime registrationDateTime;
  final int? runtime;
  final EImportance? importance;
  final EDifficulty? difficulty;
  final String? idOfDesk; 
  final String? kanbanColumnId;   
  final List<String> idOfMembers;
  final List<CommentModel> comments;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.endDateTime,
    required this.registrationDateTime,
    this.runtime,
    this.importance,
    this.difficulty,
    this.idOfDesk,
    this.kanbanColumnId,
    required this.idOfMembers,
    required this.comments,
  });

  bool isOverdue() {
    if (isCompleted || endDateTime == null) return false;
    return DateTime.now().isAfter(endDateTime!);
  }

  String getHourMinute() {
    final endHour = endDateTime?.hour ?? 23;
    final endMinute = endDateTime?.minute ?? 59;
    return endHour == 23 && endMinute == 59 ? "" : "$endHour:$endMinute";
  }

  String getOverdueDaysText() {
    if (endDateTime == null) return "";
    final durationDiff = DateTime.now().difference(endDateTime!);
    int days = durationDiff.inDays;
    if (days == 0 && !durationDiff.isNegative) days = 1;
    if (days <= 0) return "";
    if (days % 10 == 1 && days % 100 != 11) return "$days день";
    if ((days % 10 >= 2 && days % 10 <= 4) && (days % 100 < 10 || days % 100 >= 20)) return "$days дня";
    return "$days дней";
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
      endDateTime: json['end_date_time'] != null
          ? DateTime.parse(json['end_date_time'])
          : null,
      registrationDateTime: DateTime.parse(
          json['registration_date_time'] ?? DateTime.now().toIso8601String()),
      runtime: json['runtime'],
      importance: json['importance'] != null
          ? EImportance.values.byName(json['importance'])
          : null,
      difficulty: json['difficulty'] != null
          ? EDifficulty.values.byName(json['difficulty'])
          : null,
      idOfDesk: json['id_of_desk'],     
      kanbanColumnId: json['kanban_column_id'], 
      idOfMembers: List<String>.from(json['id_of_members'] ?? []),
      comments: (json['comments'] as List? ?? [])
          .map((c) => CommentModel.fromJson(c))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'end_date_time': endDateTime?.toIso8601String(),
      'registration_date_time': registrationDateTime.toIso8601String(),
      'runtime': runtime,
      'importance': importance?.name,
      'difficulty': difficulty?.name,
      'id_of_desk': idOfDesk,   
      'kanban_column_id': kanbanColumnId,    
      'id_of_members': idOfMembers,
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }
}