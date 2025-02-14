import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/src/client.dart';

import 'package:todo_app/main.dart';
import 'package:todo_app/providers.dart';
import 'package:todo_app/repository/todoRepository.dart';
import 'package:todo_app/todo.dart';
import 'package:uuid/uuid.dart';

/// Mock repository
class FakeRepository implements TodoRepository {
  @override
  Client client = Client();

  @override
  Future<List<Todo>> fetchTodoList() async {
    return [
      const Todo(id: '0', description: 'hey there :)'),
    ];
  }

  @override
  Future<Todo> createTodo(String description) async {
    return Todo(id: const Uuid().v4(), description: description);
  }

  @override
  Future<Todo> updateTodoStatus(String id, bool completed) async {
    return Todo(id: id, description: "hey there :)", completed: completed);
  }

  @override
  Future<Todo> updateTodoText(String id, String text) async {
    return Todo(id: const Uuid().v4(), description: text);
  }
}

class FakeRepositoryException implements TodoRepository {
  @override
  Client client = Client();

  @override
  Future<List<Todo>> fetchTodoList() async {
    throw Exception();
  }
  
  @override
  Future<Todo> createTodo(String description) {
    throw UnimplementedError();
  }
  
  @override
  Future<Todo> updateTodoStatus(String id, bool completed) {
    throw UnimplementedError();
  }
  
  @override
  Future<Todo> updateTodoText(String id, String text) {
    throw UnimplementedError();
  }
}

void main() {
  final addTodoInput = find.byKey(addTodoKey);
  final homeComponent = find.byType(Home);

  testWidgets('Build correctly setup', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [repositoryProvider.overrideWith((ref) => FakeRepository())], child: const App()));

    // O primeiro quadro é um estado de carregamento.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Rerenderizar. TodoListProvider já deveria ter terminado de buscar todos
    await tester.pump();

    //Não carrega mais
    expect(find.byType(CircularProgressIndicator), findsNothing);

    //Encontre a entrada de texto, navegação inferior
    expect(find.byKey(addTodoKey), findsOneWidget);
    expect(find.byKey(bottomNavigationBarKey), findsOneWidget);

    // Verifica se um item de tarefa foi encontrado
    expect(find.text('hey there :)'), findsOneWidget);
  });

  testWidgets('Adds todo and renders newly created todo', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [repositoryProvider.overrideWith((ref) => FakeRepository())], child: const App()));

    // Rerenderiza para pular a animação de carregamento
    await tester.pump();

    //Digite o texto na entrada de tarefas
    await tester.enterText(addTodoInput, 'new todo');
    expect(
        find.descendant(
          of: addTodoInput,
          matching: find.text('new todo'),
        ),
        findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Input is cleared
    expect(
      find.descendant(
        of: addTodoInput,
        matching: find.text('new todo'),
      ),
      findsNothing,
    );

    //Verifica se uma nova tarefa foi adicionada
    expect(find.text('new todo'), findsOneWidget);
    expect(find.text('2 items left'), findsOneWidget);
    expect(find.text('1 items left'), findsNothing);
  });

  testWidgets('Editing a todo item', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [repositoryProvider.overrideWith((ref) => FakeRepository())], child: const App()));

    // Rerenderiza para pular a animação de carregamento
    await tester.pump();

    //Espere encontrar o item de tarefa padrão
    expect(find.text('hey there :)'), findsOneWidget);
    final firstItem = find.byType(TodoItem);

    await tester.tap(firstItem);
    //Aguarde o campo de texto aparecer
    await tester.pump();

    // Não use tester.enterText para verificar se o campo de texto está com foco automático
    tester.testTextInput.enterText('new description');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    await tester.pump();

    expect(
      find.descendant(of: firstItem, matching: find.text('hey there :)')),
      findsNothing,
    );
    expect(
      find.descendant(of: firstItem, matching: find.text('new description')),
      findsOneWidget,
    );
  });

  testWidgets('Marking todo item as done and checking it in the completed tab', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [repositoryProvider.overrideWith((ref) => FakeRepository())], child: const App()));

    // Rerenderiza para pular a animação de carregamento
    await tester.pump();

    // Obtendo o primeiro item de tarefa
    final firstItem = find.byType(TodoItem);
    final firstCheckbox = find.descendant(
      of: firstItem,
      matching: find.byType(Checkbox),
    );

    expect(
      tester.widget(firstCheckbox),
      isA<Checkbox>().having((s) => s.value, 'value', false),
    );
    expect(find.text('1 items left'), findsOneWidget);
    expect(find.text('0 items left'), findsNothing);

    //Tocando em verificado
    await tester.tap(firstCheckbox);
    await tester.pump();

    expect(
      tester.widget(firstCheckbox),
      isA<Checkbox>().having((s) => s.value, 'value', true),
    );
    expect(find.text('0 items left'), findsOneWidget);
    expect(find.text('1 items left'), findsNothing);

    // Alternando entre menus
    final bottomMenu = find.byKey(bottomNavigationBarKey);
    final allButton = find.descendant(of: bottomMenu, matching: find.byTooltip('All'));
    final activeButton = find.descendant(of: bottomMenu, matching: find.byTooltip('Active'));
    final completedButton = find.descendant(of: bottomMenu, matching: find.byTooltip('Completed'));

    // Verificando se aparece na aba concluída
    await tester.tap(completedButton);
    await tester.pump();

    expect(find.text('hey there :)'), findsOneWidget);

    // Verificando se aparece na aba ativa
    await tester.tap(activeButton);
    await tester.pump();

    expect(find.text('hey there :)'), findsNothing);

    // Verificando se aparece na aba ativa
    await tester.tap(allButton);
    await tester.pump();

    expect(find.text('hey there :)'), findsOneWidget);
    await tester.tap(homeComponent);
  });

  testWidgets('Refresh should call fetchTodo function', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [repositoryProvider.overrideWith((ref) => FakeRepository())], child: const App()));

    // Rerenderiza para pular a animação de carregamento
    await tester.pump();

    final firstItem = find.byType(TodoItem);
    await tester.fling(firstItem, const Offset(0.0, 300.0), 1000.0);

    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation
  });

  testWidgets('Show error when API fails', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [repositoryProvider.overrideWith((ref) => FakeRepositoryException())], child: const App()));

    // O primeiro quadro é um estado de carregamento.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Rerenderizar. TodoListProvider já deveria ter terminado de buscar todos
    await tester.pump();

    //Não carrega mais
    expect(find.byType(CircularProgressIndicator), findsNothing);

    //Encontre o texto do erro
    expect(find.text("Could\'nt make API request. Make sure server is running."), findsOneWidget);
  });
}
