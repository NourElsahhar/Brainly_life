import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/home/logic/home_cubit.dart';
import 'package:brainly_life/features/home/logic/home_state.dart';
import 'package:brainly_life/features/home/presentation/widgets/home_card_contents.dart';
import 'package:brainly_life/features/home/presentation/widgets/home_section_card.dart';
import 'package:brainly_life/injection.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Home tab. Creates the HomeCubit, then shows [HomeView].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..load(),
      child: const HomeView(),
    );
  }
}

/// The dashboard: a greeting, then one card per feature.
/// Pull down to refresh. Needs [HomeCubit] above it.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static String greeting(DateTime now) => switch (now.hour) {
    < 12 => 'Good morning',
    < 18 => 'Good afternoon',
    _ => 'Good evening',
  };

  /// Opens a full screen, then refreshes the cards when the user comes
  /// back (they may have finished a task or a focus session).
  Future<void> _open(BuildContext context, String location) async {
    final cubit = context.read<HomeCubit>();
    await context.push(location);
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cubit = context.read<HomeCubit>();
    final now = clock.now();

    return Scaffold(
      appBar: const BaseetAppBar.main(),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            children: [
              Text('${greeting(now)} 👋', style: context.text.headlineMedium),
              const SizedBox(height: AppSpacing.s1),
              Text(
                "Here's your day at a glance.",
                style: context.text.bodyMedium?.copyWith(
                  color: p.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s5),
              HomeSectionCard(
                title: "Today's tasks",
                icon: Icons.checklist_rounded,
                color: p.primary,
                card: state.tasks,
                onRetry: () => cubit.retry(HomeSection.tasks),
                onTap: () => _open(context, AppRoutes.tasks),
                builder: (_, summary) => TasksCardContent(summary: summary),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              HomeSectionCard(
                title: 'Next study session',
                icon: Icons.menu_book_rounded,
                color: p.info,
                card: state.study,
                onRetry: () => cubit.retry(HomeSection.study),
                onTap: () => context.go(AppRoutes.plan),
                builder: (_, session) =>
                    StudyCardContent(session: session, now: now),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              HomeSectionCard(
                title: 'Habits',
                icon: Icons.local_fire_department_rounded,
                color: p.teal,
                card: state.habits,
                onRetry: () => cubit.retry(HomeSection.habits),
                onTap: () => context.go(AppRoutes.habits),
                builder: (_, summary) => HabitsCardContent(summary: summary),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              HomeSectionCard(
                title: 'Focus',
                icon: Icons.timer_outlined,
                color: p.warning,
                card: state.focus,
                onRetry: () => cubit.retry(HomeSection.focus),
                onTap: () => _open(context, AppRoutes.focusPath()),
                builder: (_, summary) => FocusCardContent(summary: summary),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              HomeSectionCard(
                title: 'Tip of the day',
                icon: Icons.auto_awesome_rounded,
                color: p.primary,
                card: state.tip,
                onRetry: () => cubit.retry(HomeSection.tip),
                builder: (_, tip) => TipCardContent(tip: tip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
