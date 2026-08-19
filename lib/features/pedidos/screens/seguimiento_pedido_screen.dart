import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/seguimiento_controller.dart';
import '../models/pedido_historial.dart';

typedef SeguimientoMapBuilder = Widget Function(PedidoSeguimientoInfo info);

class SeguimientoPedidoScreen extends ConsumerStatefulWidget {
  const SeguimientoPedidoScreen({
    super.key,
    required this.pedidoId,
    this.mapBuilder,
  });

  final int pedidoId;
  final SeguimientoMapBuilder? mapBuilder;

  @override
  ConsumerState<SeguimientoPedidoScreen> createState() =>
      _SeguimientoPedidoScreenState();
}

class _SeguimientoPedidoScreenState
    extends ConsumerState<SeguimientoPedidoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(seguimientoControllerProvider.notifier)
          .load(widget.pedidoId),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SeguimientoState>(seguimientoControllerProvider, (
      previous,
      next,
    ) async {
      if (next.sessionLocked && previous?.sessionLocked != true) {
        await ref.read(authControllerProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      }
    });
    final state = ref.watch(seguimientoControllerProvider);
    return Scaffold(
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text('Pedido', style: TextStyle(color: AppColors.white)),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(child: _body(state)),
            if (state.info != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: FilledButton(
                  key: const ValueKey('cancel-tracking-order'),
                  onPressed: state.canceling ? null : _confirmCancel,
                  child:
                      state.canceling
                          ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Cancelar Pedido'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(SeguimientoState state) {
    if (state.status == SeguimientoStatus.loading && state.info == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.info != null) {
      return widget.mapBuilder?.call(state.info!) ??
          _SeguimientoMap(info: state.info!);
    }
    return _SeguimientoError(
      message: state.error ?? 'No fue posible consultar el seguimiento.',
      onRetry:
          () => ref
              .read(seguimientoControllerProvider.notifier)
              .load(widget.pedidoId, refresh: true),
    );
  }

  Future<void> _confirmCancel() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Cancelar'),
            content: const Text('¿Está seguro de cancelar su pedido?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sí'),
              ),
            ],
          ),
    );
    if (accepted != true || !mounted) return;
    final success = await ref
        .read(seguimientoControllerProvider.notifier)
        .cancel(widget.pedidoId);
    if (!mounted) return;
    if (success) {
      context.pop();
      return;
    }
    final message = ref.read(seguimientoControllerProvider).error;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _SeguimientoMap extends StatefulWidget {
  const _SeguimientoMap({required this.info});
  final PedidoSeguimientoInfo info;

  @override
  State<_SeguimientoMap> createState() => _SeguimientoMapState();
}

class _SeguimientoMapState extends State<_SeguimientoMap> {
  BitmapDescriptor _homeIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _vehicleIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueAzure,
  );

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final configuration = createLocalImageConfiguration(
      context,
      size: const Size(56, 56),
    );
    final icons = await Future.wait([
      BitmapDescriptor.asset(configuration, AppAssets.mapHome, width: 48),
      BitmapDescriptor.asset(configuration, AppAssets.mapVehicle, width: 64),
    ]);
    if (!mounted) return;
    setState(() {
      _homeIcon = icons[0];
      _vehicleIcon = icons[1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final address = widget.info.direccion;
    final home = LatLng(address.latitud, address.longitud);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('domicilio'),
        position: home,
        icon: _homeIcon,
        infoWindow: InfoWindow(
          title: address.descripcion,
          snippet: address.direccionCompleta,
        ),
      ),
    };
    final vehicle = widget.info.asignaciones.firstOrNull?.vehiculo;
    if (vehicle != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('vehiculo'),
          position: LatLng(vehicle.latitud, vehicle.longitud),
          icon: _vehicleIcon,
          infoWindow: InfoWindow(title: vehicle.descripcion),
        ),
      );
    }
    return GoogleMap(
      key: const ValueKey('tracking-map'),
      initialCameraPosition: CameraPosition(target: home, zoom: 15),
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      padding: const EdgeInsets.only(bottom: 76),
      markers: markers,
    );
  }
}

class _SeguimientoError extends StatelessWidget {
  const _SeguimientoError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 52),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
