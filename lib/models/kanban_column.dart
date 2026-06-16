class KanbanColumnModel {
  final String id;
  final String title;
  final int order;

  KanbanColumnModel({required this.id, required this.title, required this.order});

  factory KanbanColumnModel.fromJson(Map<String, dynamic> json) {
    return KanbanColumnModel(
      id: json['id'],
      title: json['title'],
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'order': order};
}