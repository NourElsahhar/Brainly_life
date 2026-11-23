import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/category_state.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/category_editor_sheet.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The categories screen. Creates its Cubit, then shows
/// [TaskCategoriesView].
class TaskCategoriesScreen extends StatelessWidget {
  const TaskCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CategoryCubit>()..load(),
      child: const TaskCategoriesView(),
    );
  }
}

/// The user's categories: add, edit (name and colour) and delete.
/// Needs [CategoryCubit] above it.
class TaskCategoriesView extends StatelessWidget {
  const TaskCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: const BaseetAppBar.inner(title: 'Categories'),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New category',
        onPressed: () => CategoryEditorSheet.show(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) => switch (state) {
          CategoryInitial() || CategoryLoading() => const LoadingView(),
          CategoryError(:final failure) => ErrorView(
            failure: failure,
            onRetry: context.read<CategoryCubit>().load,
          ),
          CategoryLoaded(:final categories) when categories.isEmpty =>
            EmptyView(
              icon: Icons.folder_outlined,
              title: 'No categories yet',
              message: 'Group your tasks, like University or Personal.',
              actionLabel: 'Add category',
              onAction: () => CategoryEditorSheet.show(context),
            ),
          CategoryLoaded(:final categories) => ListView.separated(
            // Extra space at the bottom so the + button hides nothing.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.s4,
              AppSpacing.screenMargin,
              AppSpacing.s12 * 2,
            ),
            itemCount: categories.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.s3),
            itemBuilder: (context, index) =>
                _CategoryRow(category: categories[index]),
          ),
        },
      ),
    );
  }
}

enum _RowAction { edit, delete }

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final TaskCategory category;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete "${category.name}"?',
      message: 'Its tasks will not be deleted. They become Uncategorized.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final failure = await context.read<CategoryCubit>().delete(category);
    if (!context.mounted) return;
    if (failure == null) {
      AppSnackBar.success(context, 'Category deleted');
    } else {
      AppSnackBar.error(context, failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      compact: true,
      onTap: () => CategoryEditorSheet.show(context, category: category),
      child: Row(
        children: [
          Container(
            width: AppSpacing.s4,
            height: AppSpacing.s4,
            decoration: BoxDecoration(
              // The category colour is the user's own data.
              color: Color(category.colorValue),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Text(category.name, style: context.text.titleMedium)),
          PopupMenuButton<_RowAction>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => switch (action) {
              _RowAction.edit => CategoryEditorSheet.show(
                context,
                category: category,
              ),
              _RowAction.delete => _delete(context),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: _RowAction.edit, child: Text('Edit')),
              PopupMenuItem(value: _RowAction.delete, child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
