import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';

class TaskList extends StateNotifier<List<Task>> {
  TaskList(): super([]);

  void add(String title) {
    state = [...state, Task(title: title)];
  }

  void toggle(String id) {
    state = [
      for (final task in state)
        if (task.id == id)
          Task(title: task.title)
            ..isCompleted = !task.isCompleted
        else
          task,
    ];
  }
}

final taskListProvider = StateNotifierProvider<TaskList, List<Task>>((ref) {
  return TaskList();
});
