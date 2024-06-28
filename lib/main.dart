import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

part 'main.freezed.dart';

part 'main.g.dart';

// Todo 모델 정의
@freezed
class Todo with _$Todo {
  factory Todo({
    required int id,
    required String title,
    required String body,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime dueDate,
    required bool completed,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
}

// 필터링 enum 정의
enum TodoListFilterEnum { all, active, completed }

// Todo 상태 관리 클래스 정의
@Riverpod(keepAlive: true)
class TodosState extends _$TodosState {
  @override
  List<Todo> build() {
    _loadTodos();
    return [];
  }

  // Todos 로드 함수
  Future<void> _loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosString = prefs.getString('todos');
      if (todosString != null) {
        final List<dynamic> jsonList = jsonDecode(todosString);
        state = jsonList.map((json) => Todo.fromJson(json)).toList();
      }
    } catch (e) {
      print("Todos 로드 실패: $e");
    }
  }

  // Todos 저장 함수
  Future<void> _saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosString =
          jsonEncode(state.map((todo) => todo.toJson()).toList());
      await prefs.setString('todos', todosString);
    } catch (e) {
      print("Todos 저장 실패: $e");
    }
  }

  // Todo 추가 함수
  void addTodo(String title, String body, DateTime dueDate) async {
    state = [
      ...state,
      Todo(
        id: state.isEmpty
            ? 1
            : state.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: dueDate,
        completed: false,
      ),
    ];
    await _saveTodos();
  }

  // Todo 완료 토글 함수
  void toggleTodoCompleted(int id) async {
    state = state.map((todo) {
      if (todo.id == id) {
        return todo.copyWith(
          completed: !todo.completed,
          updatedAt: DateTime.now(),
        );
      }
      return todo;
    }).toList();
    await _saveTodos();
  }

  // Todo 수정 함수
  void editTodo(int id, String title, String body, DateTime dueDate) async {
    state = state.map((todo) {
      if (todo.id == id) {
        return todo.copyWith(
          title: title,
          body: body,
          updatedAt: DateTime.now(),
          dueDate: dueDate,
        );
      }
      return todo;
    }).toList();
    await _saveTodos();
  }

  // Todo 삭제 함수
  void removeTodo(int id) async {
    state = state.where((todo) => todo.id != id).toList();
    await _saveTodos();
  }

  // 전체 삭제 함수
  void removeAllTodos() async {
    state = [];
    await _saveTodos();
  }
}

// 필터링 상태 관리 클래스 정의
@riverpod
class TodoListFilter extends _$TodoListFilter {
  @override
  TodoListFilterEnum build() => TodoListFilterEnum.all;

  void setFilter(TodoListFilterEnum filter) => state = filter;
}

// 필터링된 Todos 제공 함수
@riverpod
List<Todo> filteredTodos(FilteredTodosRef ref) {
  final filter = ref.watch(todoListFilterProvider);
  final todos = ref.watch(todosStateProvider);

  switch (filter) {
    case TodoListFilterEnum.completed:
      return todos.where((todo) => todo.completed).toList();
    case TodoListFilterEnum.active:
      return todos.where((todo) => !todo.completed).toList();
    case TodoListFilterEnum.all:
    default:
      return todos;
  }
}

// 메인 함수
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/list',
      builder: (context, state) => const MainPage(),
    ),
    GoRoute(
      path: '/write',
      builder: (context, state) => const MainPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const MainPage(),
    ),
    GoRoute(
      path: '/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TodoDetailPage(key: state.pageKey, id: id);
      },
    ),
    GoRoute(
      path: '/:id/edit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TodoEditPage(key: state.pageKey, id: id);
      },
    ),
  ],
);

// 메인 앱 위젯 정의
class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
    );
  }
}

// 스플래시 스크린 정의
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      context.go('/list');
    });

    return const Scaffold(
      body: Center(
        child: Icon(Icons.task_alt, size: 100, color: Colors.blue),
      ),
    );
  }
}

class MainPage extends HookConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);
    final pages = [
      const TodoListPage(),
      const TodoWritePage(),
      const SettingsPage()
    ];

    return Scaffold(
      body: pages[selectedIndex.value],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex.value,
        onTap: (index) {
          selectedIndex.value = index;
          switch (index) {
            case 0:
              context.go('/list');
              break;
            case 1:
              context.go('/write');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '할 일 목록'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: '할 일 추가'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

// 할 일 목록 페이지 정의
class TodoListPage extends HookConsumerWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodosProvider);
    final filter = ref.watch(todoListFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('할 일 목록'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(
                  label: const Text('전체'),
                  selected: filter == TodoListFilterEnum.all,
                  onSelected: (_) => ref
                      .read(todoListFilterProvider.notifier)
                      .setFilter(TodoListFilterEnum.all),
                ),
                FilterChip(
                  label: const Text('진행 중'),
                  selected: filter == TodoListFilterEnum.active,
                  onSelected: (_) => ref
                      .read(todoListFilterProvider.notifier)
                      .setFilter(TodoListFilterEnum.active),
                ),
                FilterChip(
                  label: const Text('완료'),
                  selected: filter == TodoListFilterEnum.completed,
                  onSelected: (_) => ref
                      .read(todoListFilterProvider.notifier)
                      .setFilter(TodoListFilterEnum.completed),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(todo.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(todo.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('기한: ${todo.dueDate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: todo.completed,
                    onChanged: (_) => ref
                        .read(todosStateProvider.notifier)
                        .toggleTodoCompleted(todo.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.go('/${todo.id}/edit'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('삭제 확인'),
                          content: const Text('정말로 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('삭제'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref
                            .read(todosStateProvider.notifier)
                            .removeTodo(todo.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('할 일이 삭제되었습니다.')),
                        );
                      }
                    },
                  ),
                ],
              ),
              onTap: () => context.go('/${todo.id}'),
            ),
          );
        },
      ),
    );
  }
}

// 할 일 상세 페이지 정의
class TodoDetailPage extends HookConsumerWidget {
  final int id;

  const TodoDetailPage({required this.id, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(todosStateProvider).firstWhere((t) => t.id == id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('할 일 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('삭제 확인'),
                  content: const Text('정말로 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(todosStateProvider.notifier).removeTodo(todo.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('할 일이 삭제되었습니다.')),
                );
                context.go('/list');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('제목: ${todo.title}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('내용:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(todo.body, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('생성일: ${todo.createdAt}',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('수정일: ${todo.updatedAt}',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('기한: ${todo.dueDate.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('완료 여부: ',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Checkbox(
                  value: todo.completed,
                  onChanged: (_) => ref
                      .read(todosStateProvider.notifier)
                      .toggleTodoCompleted(todo.id),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/$id/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('수정하기'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('삭제 확인'),
                    content: const Text('정말로 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(todosStateProvider.notifier).removeTodo(todo.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('할 일이 삭제되었습니다.')),
                  );
                  context.go('/list');
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('삭제하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 할 일 추가 페이지 정의
class TodoWritePage extends HookConsumerWidget {
  const TodoWritePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final bodyController = useTextEditingController();
    final dueDate = useState(DateTime.now());
    final titleFocusNode = useFocusNode();
    final bodyFocusNode = useFocusNode();

    return Scaffold(
      appBar: AppBar(title: const Text('할 일 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              focusNode: titleFocusNode,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: bodyController,
                focusNode: bodyFocusNode,
                decoration: const InputDecoration(
                  labelText: '내용',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: dueDate.value,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('ko', 'KR'),
                );
                if (selectedDate != null) {
                  dueDate.value = selectedDate;
                }
              },
              child: Text(
                  '기한: ${dueDate.value.toLocal().toString().split(' ')[0]}'),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제목을 입력하세요.')),
                  );
                  titleFocusNode.requestFocus();
                  return;
                }
                if (bodyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('내용을 입력하세요.')),
                  );
                  bodyFocusNode.requestFocus();
                  return;
                }
                ref.read(todosStateProvider.notifier).addTodo(
                      titleController.text,
                      bodyController.text,
                      dueDate.value,
                    );
                titleController.clear();
                bodyController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('할 일이 추가되었습니다.')),
                );
                context.go('/list');
              },
              icon: const Icon(Icons.add),
              label: const Text('추가하기'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
}

// 할 일 수정 페이지 정의
class TodoEditPage extends HookConsumerWidget {
  final int id;

  const TodoEditPage({required this.id, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(todosStateProvider).firstWhere((t) => t.id == id);
    final titleController = useTextEditingController(text: todo.title);
    final bodyController = useTextEditingController(text: todo.body);
    final dueDate = useState(todo.dueDate);
    final titleFocusNode = useFocusNode();
    final bodyFocusNode = useFocusNode();

    return Scaffold(
      appBar: AppBar(title: const Text('할 일 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              focusNode: titleFocusNode,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: bodyController,
                focusNode: bodyFocusNode,
                decoration: const InputDecoration(
                  labelText: '내용',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: dueDate.value,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('ko', 'KR'),
                );
                if (selectedDate != null) {
                  dueDate.value = selectedDate;
                }
              },
              child: Text(
                  '기한: ${dueDate.value.toLocal().toString().split(' ')[0]}'),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제목을 입력하세요.')),
                  );
                  titleFocusNode.requestFocus();
                  return;
                }
                if (bodyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('내용을 입력하세요.')),
                  );
                  bodyFocusNode.requestFocus();
                  return;
                }
                ref.read(todosStateProvider.notifier).editTodo(
                      id,
                      titleController.text,
                      bodyController.text,
                      dueDate.value,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('할 일이 수정되었습니다.')),
                );
                context.go('/list');
              },
              icon: const Icon(Icons.save),
              label: const Text('수정하기'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('삭제 확인'),
                    content: const Text('정말로 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(todosStateProvider.notifier).removeTodo(id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('할 일이 삭제되었습니다.')),
                  );
                  context.go('/list');
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('삭제하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 설정 페이지 정의
class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('전체 삭제 확인'),
                content: const Text('정말로 모든 할 일을 삭제하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('삭제'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              ref.read(todosStateProvider.notifier).removeAllTodos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모든 할 일이 삭제되었습니다.')),
              );
            }
          },
          icon: const Icon(Icons.delete),
          label: const Text('전체 삭제'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 50),
            backgroundColor: Colors.red,
          ),
        ),
      ),
    );
  }
}
