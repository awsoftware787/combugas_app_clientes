import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/verification_screen.dart';
import '../../features/direcciones/screens/direccion_form_screen.dart';
import '../../features/direcciones/screens/direcciones_screen.dart';
import '../../features/pedidos/screens/carrito_screen.dart';
import '../../features/pedidos/screens/confirmacion_screen.dart';
import '../../features/pedidos/screens/pedido_guardado_screen.dart';
import '../../features/pedidos/models/create_order.dart';
import '../../features/pedidos/screens/pedido_screen.dart';
import '../../features/pedidos/screens/mis_pedidos_screen.dart';
import '../../features/pedidos/screens/pedido_detalle_screen.dart';
import '../../features/pedidos/data/evaluacion_pendiente_service.dart';
import '../../shared/widgets/migration_placeholder_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/login'),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/pedido', builder: (context, state) => const PedidoScreen()),
    GoRoute(
      path: '/carrito',
      builder: (context, state) => const CarritoScreen(),
    ),
    GoRoute(
      path: '/confirmacion',
      builder: (context, state) => const ConfirmacionScreen(),
    ),
    GoRoute(
      path: '/pedido-guardado',
      builder:
          (context, state) =>
              PedidoGuardadoScreen(result: state.extra as CreateOrderResult?),
    ),
    GoRoute(
      path: '/calificacion',
      builder: (context, state) {
        final pending = state.extra as EvaluacionPendiente?;
        return MigrationPlaceholderScreen(
          title: 'Calificar servicio',
          message:
              pending == null
                  ? 'La calificación se migrará en un loop posterior.'
                  : 'Pedido ${pending.pedidoId}\n${pending.descripcionDireccion}\n\nLa calificación se migrará en un loop posterior.',
        );
      },
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
      path: '/perfil',
      builder:
          (context, state) => const MigrationPlaceholderScreen(
            title: 'Perfil',
            message: 'Perfil se migrará en un loop posterior.',
          ),
    ),
    GoRoute(
      path: '/carburaciones',
      builder:
          (context, state) => const MigrationPlaceholderScreen(
            title: 'Carburaciones',
            message: 'Carburaciones se migrará en un loop posterior.',
          ),
    ),
    GoRoute(
      path: '/mis-pedidos',
      builder: (context, state) => const MisPedidosScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder:
              (context, state) => PedidoDetalleScreen(
                pedidoId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
        ),
      ],
    ),
    GoRoute(
      path: '/seguimiento/:id',
      builder:
          (context, state) => MigrationPlaceholderScreen(
            title: 'Seguimiento del pedido',
            message:
                'Pedido ${state.pathParameters['id']}. El seguimiento se migrará en el siguiente loop.',
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
