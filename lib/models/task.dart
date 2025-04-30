import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  bool isCompleted;

  Task({required this.title})
      : id = const Uuid().v4(),
        isCompleted = false;
}
