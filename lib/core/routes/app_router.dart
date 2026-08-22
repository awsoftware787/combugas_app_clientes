import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/verification_screen.dart';
import '../../features/auth/screens/cuenta_suspendida_screen.dart';
import '../../features/direcciones/screens/direccion_form_screen.dart';
import '../../features/direcciones/screens/direcciones_screen.dart';
import '../../features/pedidos/screens/carrito_screen.dart';
import '../../features/pedidos/screens/confirmacion_screen.dart';
import '../../features/pedidos/screens/pedido_guardado_screen.dart';
import '../../features/pedidos/models/create_order.dart';
import '../../features/pedidos/screens/pedido_screen.dart';
import '../../features/pedidos/screens/mis_pedidos_screen.dart';
import '../../features/pedidos/screens/pedido_detalle_screen.dart';
import '../../features/pedidos/screens/seguimiento_pedido_screen.dart';
import '../../features/pedidos/data/evaluacion_pendiente_service.dart';
import '../../features/pedidos/screens/calificacion_screen.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/productos/screens/productos_screen.dart';
import '../../features/carburaciones/screens/carburaciones_screen.dart';
import '../../shared/widgets/app_exit_guard.dart';
import '../startup/session_gate_screen.dart';
import 'session_route_guard.dart';

Widget _private(Widget child) => SessionRouteGuard.private(child: child);
Widget _publicOnly(Widget child) => SessionRouteGuard.publicOnly(child: child);
Widget _root(Widget child) => AppExitGuard(child: child);

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SessionGateScreen()),
    GoRoute(
      path: '/login',
      builder: (context, state) => _publicOnly(const LoginScreen()),
    ),
    GoRoute(
      path: '/productos',
      builder: (context, state) => _root(const ProductosRouteScreen()),
    ),
    GoRoute(
      path: '/pedido',
      builder: (context, state) => _private(_root(const PedidoScreen())),
    ),
    GoRoute(
      path: '/carrito',
      builder: (context, state) => _private(const CarritoScreen()),
    ),
    GoRoute(
      path: '/confirmacion',
      builder: (context, state) => _private(const ConfirmacionScreen()),
    ),
    GoRoute(
      path: '/pedido-guardado',
      builder:
          (context, state) => _private(
            PedidoGuardadoScreen(result: state.extra as CreateOrderResult?),
          ),
    ),
    GoRoute(
      path: '/calificacion',
      builder:
          (context, state) => _private(
            CalificacionScreen(pendiente: state.extra as EvaluacionPendiente?),
          ),
    ),
    GoRoute(
      path: '/direcciones',
      builder: (context, state) => _private(_root(const DireccionesScreen())),
    ),
    GoRoute(
      path: '/direcciones/nueva',
      builder: (context, state) => _private(const DireccionFormScreen()),
    ),
    GoRoute(
      path: '/direcciones/editar/:id',
      builder:
          (context, state) => _private(
            DireccionFormScreen(
              direccionId: int.tryParse(state.pathParameters['id'] ?? ''),
            ),
          ),
    ),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegisterScreen(),
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
      builder: (context, state) => _private(const PerfilScreen()),
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => _private(const PerfilScreen()),
    ),
    GoRoute(
      path: '/carburaciones',
      builder: (context, state) => _root(const CarburacionesScreen()),
    ),
    GoRoute(
      path: '/mis-pedidos',
      builder: (context, state) => _private(_root(const MisPedidosScreen())),
      routes: [
        GoRoute(
          path: ':id',
          builder:
              (context, state) => _private(
                PedidoDetalleScreen(
                  pedidoId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                ),
              ),
        ),
      ],
    ),
    GoRoute(
      path: '/seguimiento/:id',
      builder:
          (context, state) => _private(
            SeguimientoPedidoScreen(
              pedidoId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
    ),
    GoRoute(
      path: '/cuenta-bloqueada',
      builder:
          (context, state) => CuentaSuspendidaScreen(
            reason: state.extra as String? ?? 'Cuenta suspendida.',
          ),
    ),
  ],
);
