import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod/riverpod.dart';
import 'package:todo_app/repository/todoRepository.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

@immutable
class Todo {
  const Todo({
    required this.description,
    required this.id,
    this.completed = false,
  });

  final String id;
  final String description;
  final bool completed;

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(id: json['id'].toString(), description: json['text'], completed: json['status'] == 0 ? false : true);
  }
}

class TodoList extends StateNotifier<AsyncValue<List<Todo>>> {
  final TodoRepository;

  TodoList(this.TodoRepository) : super(const AsyncValue.loading()) {
    fetchTodos();
  }

  Future<void> fetchTodos() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await TodoRepository.fetchTodoList();
    });
  }

  Future<void> add(String description) async {
    state = await AsyncValue.guard(() async {
      Todo returned_todo = await TodoRepository.createTodo(description);
      return [...?state.value, returned_todo];
    });
  }

  Future<void> toggle(Todo todo) async {
    state = await AsyncValue.guard(() async {
      Todo returned_todo = await TodoRepository.updateTodoStatus(todo.id, !todo.completed);

      final newState = [...?state.value];
      final todoToReplaceIndex = newState.indexWhere((todo) => todo.id == returned_todo.id);

      if (todoToReplaceIndex != -1) {
        newState[todoToReplaceIndex] = Todo(
          id: returned_todo.id,
          completed: returned_todo.completed,
          description: returned_todo.description,
        );
      }

      return newState;
    });
  }

  Future<void> edit({required String id, required String description}) async {
    state = await AsyncValue.guard(() async {
      Todo returned_todo = await TodoRepository.updateTodoText(id, description);

      final newState = [...?state.value];
      final todoToReplaceIndex = newState.indexWhere((todo) => todo.id == id);

      if (todoToReplaceIndex != -1) {
        newState[todoToReplaceIndex] = Todo(
          id: returned_todo.id,
          completed: returned_todo.completed,
          description: returned_todo.description,
        );
      }

      return newState;
    });
  }
}
