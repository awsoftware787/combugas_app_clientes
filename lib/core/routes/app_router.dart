import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/pedidos/screens/pedido_placeholder_screen.dart';
import '../../shared/widgets/migration_placeholder_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/pedido',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/pedido'),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/pedido',
      builder: (context, state) => const PedidoPlaceholderScreen(),
    ),
    GoRoute(
      path: '/registro',
      builder:
          (context, state) => const MigrationPlaceholderScreen(
            title: 'Registro',
            message: 'El registro se migrará en el siguiente loop.',
          ),
    ),
    GoRoute(
      path: '/recuperar',
      builder:
          (context, state) => const MigrationPlaceholderScreen(
            title: 'Recuperar contraseña',
            message: 'La recuperación de contraseña aún no está migrada.',
          ),
    ),
    GoRoute(
      path: '/registro-verificacion',
      builder:
          (context, state) => const MigrationPlaceholderScreen(
            title: 'Verificar cuenta',
            message: 'La verificación se migrará en el siguiente loop.',
          ),
    ),
    GoRoute(
      path: '/perfil-pendiente',
      builder:
          (context, state) => const MigrationPlaceholderScreen(
            title: 'Perfil',
            message: 'Debes agregar una dirección. Perfil aún no está migrado.',
          ),
    ),
    GoRoute(
      path: '/cuenta-bloqueada',
      builder:
          (context, state) => MigrationPlaceholderScreen(
            title: 'Cuenta suspendida',
            message: state.extra as String? ?? 'Cuenta suspendida.',
          ),
    ),
  ],
);
