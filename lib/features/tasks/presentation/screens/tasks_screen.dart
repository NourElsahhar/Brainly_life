import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/category_state.dart';
import 'package:brainly_life/features/tasks/logic/completed_tasks_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_list_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_list_state.dart';
import 'package:brainly_life/features/tasks/logic/task_progress_calculator.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/active_tasks_view.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/completed_tasks_view.dart';
import 'package:brainly_life/injection.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Tasks screen. Creates its Cubits, then shows [TasksView].
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<TaskListCubit>()..load()),
        BlocProvider(create: (_) => getIt<CompletedTasksCubit>()),
        BlocProvider(create: (_) => getIt<CategoryCubit>()..load()),
      ],
      child: const TasksView(),
    );
  }
}

/// Tabs (Today, Upcoming, Overdue, Completed), search, sort, and the
/// + button. Needs the three Cubits above it.
class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView>
    with SingleTickerProviderStateMixin {
  static const _activeTabs = [
    TaskBucket.today,
    TaskBucket.upcoming,
    TaskBucket.overdue,
  ];

  late final TabController _tabs = TabController(length: 4, vsync: this)
    ..addListener(_onTabChanged);
  final _searchController = TextEditingController();
  bool _searching = false;

  bool get _onCompleted => _tabs.index == _activeTabs.length;

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return; // wait until the tab really changed
    if (_onCompleted) {
      context.read<CompletedTasksCubit>().load(); // fresh every time
    } else {
      context.read<TaskListCubit>().selectTab(_activeTabs[_tabs.index]);
    }
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<TaskListCubit>().search('');
    setState(() => _searching = false);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = clock.now();
    final categories = context.select<CategoryCubit, Map<String, TaskCategory>>(
      (cubit) => switch (cubit.state) {
        CategoryLoaded(:final categories) => {
          for (final category in categories) category.id: category,
        },
        _ => const {},
      },
    );
    final counts = context.select<TaskListCubit, Map<TaskBucket, int>?>(
      (cubit) => switch (cubit.state) {
        TaskListLoaded(:final counts) => counts,
        TaskListEmpty() => const {},
        _ => null, // still loading: no numbers yet
      },
    );

    String label(String name, TaskBucket bucket) =>
        counts == null ? name : '$name ${counts[bucket] ?? 0}';

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tasks',
                  border: InputBorder.none,
                ),
                onChanged: context.read<TaskListCubit>().search,
              )
            : const Text('Tasks'),
        actions: [
          if (!_onCompleted) ...[
            IconButton(
              tooltip: _searching ? 'Close search' : 'Search',
              icon: Icon(
                _searching ? Icons.close_rounded : Icons.search_rounded,
              ),
              onPressed: _searching
                  ? _clearSearch
                  : () => setState(() => _searching = true),
            ),
            const _SortButton(),
          ],
          IconButton(
            tooltip: 'Categories',
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => context.push(AppRoutes.taskCategories),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: label('Today', TaskBucket.today)),
            Tab(text: label('Upcoming', TaskBucket.upcoming)),
            Tab(text: label('Overdue', TaskBucket.overdue)),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _onCompleted
          ? CompletedTasksView(
              categories: categories,
              now: now,
              onOpen: (task) => context.push(AppRoutes.taskPath(task.id)),
            )
          : ActiveTasksView(
              categories: categories,
              now: now,
              onClearSearch: _clearSearch,
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New task',
        onPressed: () => context.push(AppRoutes.newTask),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton();

  @override
  Widget build(BuildContext context) {
    final sort = context.select<TaskListCubit, TaskSort>(
      (cubit) => switch (cubit.state) {
        TaskListLoaded(:final sort) => sort,
        _ => TaskSort.dueDate,
      },
    );

    return PopupMenuButton<TaskSort>(
      tooltip: 'Sort',
      icon: const Icon(Icons.swap_vert_rounded),
      initialValue: sort,
      onSelected: context.read<TaskListCubit>().sortBy,
      itemBuilder: (_) => const [
        PopupMenuItem(value: TaskSort.dueDate, child: Text('Due date')),
        PopupMenuItem(value: TaskSort.priority, child: Text('Priority')),
      ],
    );
  }
}
