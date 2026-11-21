import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Three grey cards while the tasks load (design: Skeleton loading card).
class TasksLoadingList extends StatelessWidget {
  const TasksLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, index) => const SkeletonCard(),
    );
  }
}
