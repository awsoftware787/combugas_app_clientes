import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../pedidos/widgets/pedido_drawer.dart';
import '../controllers/carburaciones_controller.dart';
import '../models/carburacion.dart';

typedef CarburacionesMapBuilder = Widget Function(List<Carburacion> values);

final carburacionesLocationProvider = Provider<Future<Position?> Function()>(
  (_) => () async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition();
  },
);

class CarburacionesScreen extends ConsumerStatefulWidget {
  const CarburacionesScreen({super.key, this.mapBuilder});
  final CarburacionesMapBuilder? mapBuilder;

  @override
  ConsumerState<CarburacionesScreen> createState() =>
      _CarburacionesScreenState();
}

class _CarburacionesScreenState extends ConsumerState<CarburacionesScreen> {
  Position? _position;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(carburacionesControllerProvider.notifier).load();
      try {
        final position = await ref.read(carburacionesLocationProvider)();
        if (mounted) setState(() => _position = position);
      } catch (_) {
        // La ubicación es opcional; los puntos deben seguir visibles.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carburacionesControllerProvider);
    ref.listen(carburacionesControllerProvider, (previous, next) {
      if (next.error != null &&
          next.carburaciones.isNotEmpty &&
          next.error != previous?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });
    return Scaffold(
      drawer: const PedidoDrawer(),
      appBar: AppBar(
        title: const Text('Carburaciones'),
        actions: [
          IconButton(
            tooltip: 'Actualizar carburaciones',
            onPressed:
                state.refreshing
                    ? null
                    : () => ref
                        .read(carburacionesControllerProvider.notifier)
                        .load(refresh: true),
            icon:
                state.refreshing
                    ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (state.status) {
        CarburacionesStatus.idle || CarburacionesStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        CarburacionesStatus.error => _CarburacionesError(
          message: state.error ?? 'No fue posible cargar las carburaciones.',
          onRetry:
              () => ref.read(carburacionesControllerProvider.notifier).load(),
        ),
        CarburacionesStatus.ready when state.carburaciones.isEmpty => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No hay carburaciones disponibles.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    () => ref
                        .read(carburacionesControllerProvider.notifier)
                        .load(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        CarburacionesStatus.ready =>
          widget.mapBuilder?.call(state.carburaciones) ??
              _CarburacionesMap(
                values: state.carburaciones,
                position: _position,
              ),
      },
    );
  }
}

class _CarburacionesMap extends StatefulWidget {
  const _CarburacionesMap({required this.values, required this.position});
  final List<Carburacion> values;
  final Position? position;

  @override
  State<_CarburacionesMap> createState() => _CarburacionesMapState();
}

class _CarburacionesMapState extends State<_CarburacionesMap> {
  BitmapDescriptor _gasIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _bothIcon = BitmapDescriptor.defaultMarkerWithHue(
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
      size: const Size(50, 50),
    );
    final icons = await Future.wait([
      BitmapDescriptor.asset(configuration, AppAssets.mapGasStation, width: 35),
      BitmapDescriptor.asset(
        configuration,
        AppAssets.mapBothFuelTypes,
        width: 50,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _gasIcon = icons.first;
      _bothIcon = icons.last;
    });
  }

  @override
  Widget build(BuildContext context) {
    const lagoon = LatLng(25.565089, -103.452291);
    final target =
        widget.position == null
            ? lagoon
            : LatLng(widget.position!.latitude, widget.position!.longitude);
    return GoogleMap(
      key: const ValueKey('carburaciones-map'),
      initialCameraPosition: CameraPosition(target: target, zoom: 12),
      mapToolbarEnabled: false,
      myLocationEnabled: widget.position != null,
      myLocationButtonEnabled: widget.position != null,
      markers: {
        for (var index = 0; index < widget.values.length; index++)
          Marker(
            markerId: MarkerId('carburacion-$index'),
            position: LatLng(
              widget.values[index].latitud,
              widget.values[index].longitud,
            ),
            icon: widget.values[index].esSoloGas ? _gasIcon : _bothIcon,
            infoWindow: InfoWindow(title: widget.values[index].descripcion),
          ),
      },
    );
  }
}

class _CarburacionesError extends StatelessWidget {
  const _CarburacionesError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: AppColors.accent),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
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
