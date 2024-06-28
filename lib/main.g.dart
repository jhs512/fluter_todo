// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoImpl _$$TodoImplFromJson(Map<String, dynamic> json) => _$TodoImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      completed: json['completed'] as bool,
    );

Map<String, dynamic> _$$TodoImplToJson(_$TodoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'dueDate': instance.dueDate.toIso8601String(),
      'completed': instance.completed,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredTodosHash() => r'0a5ccfc649ddbbae5951395682f5fd065ad85e93';

/// See also [filteredTodos].
@ProviderFor(filteredTodos)
final filteredTodosProvider = AutoDisposeProvider<List<Todo>>.internal(
  filteredTodos,
  name: r'filteredTodosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredTodosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredTodosRef = AutoDisposeProviderRef<List<Todo>>;
String _$todosStateHash() => r'9e49a47266424209a570a9a19bbdcf2d37e75413';

/// See also [TodosState].
@ProviderFor(TodosState)
final todosStateProvider = NotifierProvider<TodosState, List<Todo>>.internal(
  TodosState.new,
  name: r'todosStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todosStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TodosState = Notifier<List<Todo>>;
String _$todoListFilterHash() => r'f19bb01fd25e22b62f3e636021ee7f33680a745a';

/// See also [TodoListFilter].
@ProviderFor(TodoListFilter)
final todoListFilterProvider =
    AutoDisposeNotifierProvider<TodoListFilter, TodoListFilterEnum>.internal(
  TodoListFilter.new,
  name: r'todoListFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todoListFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TodoListFilter = AutoDisposeNotifier<TodoListFilterEnum>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
