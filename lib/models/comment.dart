class CommentModel {
  final String id;
  final String text;
  final DateTime registrationDateTime;
  final String idOfMember;
  final String idOfTask;
  final String userNickname;

  CommentModel({
    required this.id,
    required this.text,
    required this.registrationDateTime,
    required this.idOfMember,
    required this.idOfTask,
    required this.userNickname,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      text: json['text'] as String,
      registrationDateTime: DateTime.parse(json['registration_date_time'] as String),
      idOfMember: json['id_of_member'] as String,
      idOfTask: json['id_of_task'] as String,
      userNickname: json['user_nickname'] ?? 'Пользователь',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'registration_date_time': registrationDateTime.toIso8601String(),
      'id_of_member': idOfMember,
      'id_of_task': idOfTask,
      'user_nickname': userNickname,
    };
  }
}