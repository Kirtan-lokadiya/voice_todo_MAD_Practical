import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/todo.dart';

// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Provider for todo list stream
final todosStreamProvider = StreamProvider<List<Todo>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTodos();
}); 