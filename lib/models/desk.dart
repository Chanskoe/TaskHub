class DeskModel {
  final String id;
  final String title;
  final String idOfAdmin;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> kanbanColumns;

  DeskModel({
    required this.id,
    required this.title,
    required this.idOfAdmin,
    required this.members,
    this.kanbanColumns = const [],
  });

  factory DeskModel.fromJson(Map<String, dynamic> json) {
    return DeskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      idOfAdmin: json['id_of_admin'] as String,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [],
      kanbanColumns: (json['kanban_columns'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'id_of_admin': idOfAdmin,
      'members': members,
      'kanban_columns': kanbanColumns
    };
  }
}