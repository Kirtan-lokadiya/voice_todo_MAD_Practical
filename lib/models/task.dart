import 'package:uuid/uuid.dart';

class Task {
  final String id;
  String title;
  bool isCompleted;

  /// Allows reuse of ID and isCompleted status
  Task({
    required this.title,
    String? id,
    bool? isCompleted,
  })  : id = id ?? const Uuid().v4(),
        isCompleted = isCompleted ?? false;
}
