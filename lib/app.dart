// The root widget of the app: MaterialApp.router with our light and dark
// themes. The router comes from get_it (see injection.dart).
//
// AuthCubit is provided here once, for the whole app:
//   context.read<AuthCubit>().signOut();
//
// The BlocListener tells the router when the user signs in or out, and the
// router then redirects (see core/routes/app_router.dart).

import 'package:brainly_life/core/routes/router_auth_state.dart';
import 'package:brainly_life/core/theme/app_theme.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/auth/logic/auth_status_mapper.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BrainlyLifeApp extends StatelessWidget {
  const BrainlyLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routerAuthState = getIt<RouterAuthState>();

    return BlocProvider<AuthCubit>.value(
      value: getIt<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) => routerAuthState.update(
          authStatusFor(state, routerAuthState.status),
        ),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Baseet',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: getIt<GoRouter>(),
        ),
      ),
    );
  }
}
