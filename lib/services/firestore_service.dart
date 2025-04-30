import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/todo.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _todosCollection {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(user.uid).collection('todos');
  }

  // Add or update a todo
  Future<void> saveTodo(Todo todo) async {
    try {
      await _todosCollection.doc(todo.id).set(todo.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving todo: $e');
      }
      rethrow;
    }
  }

  // Get all todos for current user
  Stream<List<Todo>> getTodos() {
    try {
      return _todosCollection.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Todo.fromJson(data);
        }).toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting todos: $e');
      }
      rethrow;
    }
  }

  // Delete a todo
  Future<void> deleteTodo(String todoId) async {
    try {
      await _todosCollection.doc(todoId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting todo: $e');
      }
      rethrow;
    }
  }

  // Update todo completion status
  Future<void> updateTodoStatus(String todoId, bool isCompleted) async {
    try {
      await _todosCollection.doc(todoId).update({'isCompleted': isCompleted});
    } catch (e) {
      if (kDebugMode) {
        print('Error updating todo status: $e');
      }
      rethrow;
    }
  }
} 