import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/widgets/searchable_dropdown_form_field.dart';
import '../models/catalogos_direccion.dart';
import '../models/direccion.dart';
import '../models/direccion_request.dart';

typedef DireccionMapBuilder =
    Widget Function({
      required LatLng position,
      required ValueChanged<LatLng> onPositionChanged,
    });

class DireccionForm extends StatefulWidget {
  const DireccionForm({
    super.key,
    this.initial,
    required this.loadColonias,
    required this.loadCalles,
    required this.loadCerradas,
    required this.saving,
    required this.onSave,
    this.onDeactivate,
    this.mapBuilder,
  });
  final Direccion? initial;
  final Future<List<Colonia>> Function() loadColonias;
  final Future<List<Calle>> Function(int) loadCalles;
  final Future<List<Cerrada>> Function(int) loadCerradas;
  final bool saving;
  final Future<void> Function(DireccionRequest) onSave;
  final Future<void> Function()? onDeactivate;
  final DireccionMapBuilder? mapBuilder;
  @override
  State<DireccionForm> createState() => _DireccionFormState();
}

class _DireccionFormState extends State<DireccionForm> {
  static const _fallback = LatLng(25.548597, -103.4719567);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _number;
  List<Colonia> _colonias = const [];
  List<Calle> _calles = const [];
  List<Cerrada> _cerradas = const [];
  Colonia? _colonia;
  Calle? _calle;
  Cerrada? _cerrada;
  late LatLng _position;
  bool _loadingCatalogs = true;
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _description = TextEditingController(text: initial?.descripcion ?? '');
    _number = TextEditingController(text: initial?.numeroExterior ?? '');
    _position =
        initial != null && (initial.latitud != 0 || initial.longitud != 0)
            ? LatLng(initial.latitud, initial.longitud)
            : _fallback;
    _load();
    if (initial == null) _locate();
  }

  @override
  void dispose() {
    _description.dispose();
    _number.dispose();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final colonias = await widget.loadColonias();
      Colonia? selected;
      if (widget.initial != null) {
        for (final item in colonias) {
          if (item.id == widget.initial!.idColonia) {
            selected = item;
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _colonias = colonias;
        _colonia = selected;
      });
      if (selected != null) await _loadDependent(selected.id);
    } finally {
      if (mounted) setState(() => _loadingCatalogs = false);
    }
  }

  Future<void> _loadDependent(int id) async {
    final values = await Future.wait([
      widget.loadCalles(id),
      widget.loadCerradas(id),
    ]);
    final calles = values[0] as List<Calle>;
    final cerradas = values[1] as List<Cerrada>;
    Calle? calle;
    Cerrada? cerrada;
    if (widget.initial != null) {
      for (final item in calles) {
        if (item.id == widget.initial!.idCalle) {
          calle = item;
          break;
        }
      }
      for (final item in cerradas) {
        if (item.id == widget.initial!.idCerrada) {
          cerrada = item;
          break;
        }
      }
    }
    if (mounted) {
      setState(() {
        _calles = calles;
        _cerradas = cerradas;
        _calle = calle;
        _cerrada = cerrada;
      });
    }
  }

  Future<void> _locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = LatLng(position.latitude, position.longitude));
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(_position, 16));
    } catch (_) {}
  }

  Future<void> _geocode() async {
    if (_colonia == null || _calle == null || _number.text.trim().isEmpty) {
      return;
    }
    try {
      final query =
          '${_calle!.descripcion} ${_number.text}, ${_colonia!.descripcion}, ${_colonia!.ciudad}, ${_colonia!.estado}';
      final locations = await locationFromAddress(query);
      if (locations.isEmpty || !mounted) return;
      setState(
        () =>
            _position = LatLng(
              locations.first.latitude,
              locations.first.longitude,
            ),
      );
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(_position, 16));
    } catch (_) {}
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      DireccionRequest(
        descripcion: _description.text.trim().toUpperCase(),
        idColonia: _colonia!.id,
        idCerrada: _cerrada?.id ?? 1,
        idCalle: _calle!.id,
        numero: _number.text.trim(),
        latitud: _position.latitude,
        longitud: _position.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCatalogs) {
      return const Center(child: CircularProgressIndicator());
    }
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Identificador del domicilio',
                  ),
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Debe especificar una descripción para el domicilio'
                              : null,
                ),
                const SizedBox(height: 12),
                SearchableDropdownFormField<Colonia>(
                  key: const ValueKey('direccion-colonia'),
                  value: _colonia,
                  items: _colonias,
                  itemLabel: (value) => value.descripcion,
                  labelText: 'Colonia',
                  enabled: !widget.saving,
                  onChanged: (value) async {
                    setState(() {
                      _colonia = value;
                      _calle = null;
                      _cerrada = null;
                      _calles = const [];
                      _cerradas = const [];
                    });
                    await _loadDependent(value.id);
                    await _geocode();
                  },
                  validator:
                      (v) =>
                          v == null
                              ? 'No se reconoce la colonia especificada'
                              : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Cerrada>(
                  value: _cerrada,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Cerrada (opcional)',
                  ),
                  items:
                      _cerradas
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(v.descripcion),
                            ),
                          )
                          .toList(),
                  onChanged:
                      widget.saving
                          ? null
                          : (v) => setState(() => _cerrada = v),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: SearchableDropdownFormField<Calle>(
                        key: const ValueKey('direccion-calle'),
                        value: _calle,
                        items: _calles,
                        itemLabel: (value) => value.descripcion,
                        labelText: 'Calle',
                        enabled: !widget.saving && _colonia != null,
                        onChanged: (value) {
                          setState(() => _calle = value);
                          _geocode();
                        },
                        validator:
                            (v) =>
                                v == null
                                    ? 'No se reconoce la calle especificada'
                                    : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _number,
                        decoration: const InputDecoration(labelText: 'Número'),
                        onEditingComplete: _geocode,
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Debe especificar un número de domicilio válido'
                                    : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubicación de entrega',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        widget.mapBuilder?.call(
                          position: _position,
                          onPositionChanged:
                              (value) => setState(() => _position = value),
                        ) ??
                        _DireccionMap(
                          position: _position,
                          onMapCreated: (controller) => _map = controller,
                          onPositionChanged:
                              (value) => setState(() => _position = value),
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Arrastra el marcador o mantén presionado el mapa para ajustar la ubicación.',
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (widget.onDeactivate != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onPressed: widget.saving ? null : widget.onDeactivate,
                      icon: const Icon(Icons.block),
                      label: const Text('Desactivar'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: widget.saving ? null : _submit,
                    icon:
                        widget.saving
                            ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DireccionMap extends StatelessWidget {
  const _DireccionMap({
    required this.position,
    required this.onMapCreated,
    required this.onPositionChanged,
  });

  final LatLng position;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<LatLng> onPositionChanged;

  @override
  Widget build(BuildContext context) => GoogleMap(
    initialCameraPosition: CameraPosition(target: position, zoom: 16),
    myLocationButtonEnabled: true,
    myLocationEnabled: true,
    scrollGesturesEnabled: true,
    zoomGesturesEnabled: true,
    rotateGesturesEnabled: true,
    tiltGesturesEnabled: true,
    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
      Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
    },
    onMapCreated: onMapCreated,
    markers: {
      Marker(
        markerId: const MarkerId('domicilio'),
        position: position,
        draggable: true,
        onDragEnd: onPositionChanged,
      ),
    },
    onLongPress: onPositionChanged,
  );
}
