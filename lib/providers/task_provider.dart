import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';

class TaskList extends StateNotifier<List<Task>> {
  TaskList(): super([]);

  void add(String title) {
    state = [...state, Task(title: title)];
  }

  void toggle(String id) {
    state = state.map((task) {
      if (task.id == id) {
        return Task(
          title: task.title,
          id: task.id,
          isCompleted: !task.isCompleted,
        );
      }
      return task;
    }).toList();
  }

  void edit(String id, String newTitle) {
    state = state.map((task) {
      if (task.id == id) {
        return Task(
          title: newTitle,
          id: task.id,
          isCompleted: task.isCompleted,
        );
      }
      return task;
    }).toList();
  }

  void remove(String id) {
    state = state.where((task) => task.id != id).toList();
  }
}

final taskListProvider = StateNotifierProvider<TaskList, List<Task>>((ref) {
  return TaskList();
});
