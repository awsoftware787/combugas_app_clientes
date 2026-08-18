import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/verification_screen.dart';
import '../../features/direcciones/screens/direccion_form_screen.dart';
import '../../features/direcciones/screens/direcciones_screen.dart';
import '../../features/pedidos/screens/pedido_placeholder_screen.dart';
import '../../shared/widgets/migration_placeholder_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/login'),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/pedido',
      builder: (context, state) => const PedidoPlaceholderScreen(),
    ),
    GoRoute(
      path: '/direcciones',
      builder: (context, state) => const DireccionesScreen(),
    ),
    GoRoute(
      path: '/direcciones/nueva',
      builder: (context, state) => const DireccionFormScreen(),
    ),
    GoRoute(
      path: '/direcciones/editar/:id',
      builder:
          (context, state) => DireccionFormScreen(
            direccionId: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
    ),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegisterScreen(),
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
          (context, state) => VerificationScreen(
            accountKey: state.extra is int ? state.extra! as int : 0,
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
