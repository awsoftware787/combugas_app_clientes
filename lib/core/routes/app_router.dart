import 'package:go_router/go_router.dart';

import '../../shared/widgets/migration_placeholder_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MigrationPlaceholderScreen(),
    ),
  ],
);
