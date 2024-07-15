import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/repository/todoRepository.dart';
import 'package:todo_app/todo.dart';

final repositoryProvider = Provider((ref) => TodoRepository());

final todoListProvider = StateNotifierProvider<TodoList, AsyncValue<List<Todo>>>((ref) {
  final repository = ref.read(repositoryProvider);

  return TodoList(repository);
});

enum TodoListFilter {
  all,
  active,
  completed,
}

final todoListFilter = StateProvider((_) => TodoListFilter.all);

final uncompletedTodosCount = Provider<int>((ref) {
  final count = ref.watch(todoListProvider).value?.where((todo) => !todo.completed).length;
  return count ?? 0;
});

final filteredTodos = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoListFilter);
  final todos = ref.watch(todoListProvider).valueOrNull;

  if (todos != null) {
    switch (filter) {
      case TodoListFilter.completed:
        return todos.where((todo) => todo.completed).toList();
      case TodoListFilter.active:
        return todos.where((todo) => !todo.completed).toList();
      case TodoListFilter.all:
        return todos;
    }
  } else {
    return [];
  }
});
