import 'dart:async';

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

typedef DireccionGeocoder = Future<LatLng?> Function(String address);
typedef DireccionCameraMover =
    Future<void> Function(LatLng position, double zoom);

String buildDireccionGeocodingQuery({
  required Colonia colonia,
  required Calle calle,
  required String numero,
}) {
  final parts = <String>[
    '${calle.descripcion.trim()} ${numero.trim()}'.trim(),
    'Colonia ${colonia.descripcion.trim()}',
    colonia.ciudad.trim(),
    colonia.estado.trim(),
    'México',
  ].where((part) => part.isNotEmpty);
  return parts.join(', ');
}

Future<LatLng?> geocodeDireccion(String address) async {
  final locations = await locationFromAddress(address);
  if (locations.isEmpty) return null;
  return LatLng(locations.first.latitude, locations.first.longitude);
}

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
    this.geocodeAddress,
    this.moveCamera,
  });
  final Direccion? initial;
  final Future<List<Colonia>> Function() loadColonias;
  final Future<List<Calle>> Function(int) loadCalles;
  final Future<List<Cerrada>> Function(int) loadCerradas;
  final bool saving;
  final Future<void> Function(DireccionRequest) onSave;
  final Future<void> Function()? onDeactivate;
  final DireccionMapBuilder? mapBuilder;
  final DireccionGeocoder? geocodeAddress;
  final DireccionCameraMover? moveCamera;
  @override
  State<DireccionForm> createState() => _DireccionFormState();
}

class _DireccionFormState extends State<DireccionForm> {
  static const _fallback = LatLng(25.548597, -103.4719567);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _number;
  late final FocusNode _numberFocus;
  List<Colonia> _colonias = const [];
  List<Calle> _calles = const [];
  List<Cerrada> _cerradas = const [];
  Colonia? _colonia;
  Calle? _calle;
  Cerrada? _cerrada;
  late LatLng _position;
  bool _loadingCatalogs = true;
  bool _geocoding = false;
  GoogleMapController? _map;
  Timer? _geocodeDebounce;
  int _geocodeRequestId = 0;
  int _addressRevision = 0;
  int _lastRequestedRevision = -1;
  int _dependentLoadId = 0;
  late String _addressNumber;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _description = TextEditingController(text: initial?.descripcion ?? '');
    _number = TextEditingController(text: initial?.numeroExterior ?? '');
    _addressNumber = _number.text.trim();
    if (initial != null) _lastRequestedRevision = _addressRevision;
    _numberFocus = FocusNode()..addListener(_onNumberFocusChanged);
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
    _numberFocus
      ..removeListener(_onNumberFocusChanged)
      ..dispose();
    _geocodeDebounce?.cancel();
    _geocodeRequestId++;
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
      if (selected != null) {
        await _loadDependent(selected.id, selectInitial: true);
      }
    } finally {
      if (mounted) setState(() => _loadingCatalogs = false);
    }
  }

  Future<void> _loadDependent(int id, {bool selectInitial = false}) async {
    final loadId = ++_dependentLoadId;
    final values = await Future.wait([
      widget.loadCalles(id),
      widget.loadCerradas(id),
    ]);
    final calles = values[0] as List<Calle>;
    final cerradas = values[1] as List<Cerrada>;
    Calle? calle;
    Cerrada? cerrada;
    if (selectInitial && widget.initial != null) {
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
    if (mounted && loadId == _dependentLoadId) {
      setState(() {
        _calles = calles;
        _cerradas = cerradas;
        _calle = calle;
        _cerrada = cerrada;
      });
    }
  }

  Future<void> _locate() async {
    final requestId = _geocodeRequestId;
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
      if (!mounted || requestId != _geocodeRequestId) return;
      setState(() => _position = LatLng(position.latitude, position.longitude));
      await _moveCamera(_position, 16);
    } catch (_) {}
  }

  Future<void> _geocode() async {
    if (_colonia == null || _calle == null || _number.text.trim().isEmpty) {
      return;
    }
    if (_lastRequestedRevision == _addressRevision) return;
    _geocodeDebounce?.cancel();
    _lastRequestedRevision = _addressRevision;
    final requestId = ++_geocodeRequestId;
    final query = buildDireccionGeocodingQuery(
      colonia: _colonia!,
      calle: _calle!,
      numero: _number.text,
    );
    setState(() => _geocoding = true);
    try {
      final position = await (widget.geocodeAddress ?? geocodeDireccion)(query);
      if (!mounted || requestId != _geocodeRequestId) return;
      if (position == null) {
        setState(() => _geocoding = false);
        _showGeocodingMessage(
          'No encontramos esa dirección. Puedes ajustar el punto manualmente.',
        );
        return;
      }
      setState(() {
        _position = position;
        _geocoding = false;
      });
      await _moveCamera(position, 18);
    } catch (_) {
      if (!mounted || requestId != _geocodeRequestId) return;
      setState(() => _geocoding = false);
      _showGeocodingMessage(
        'No fue posible ubicar la dirección. Puedes continuar y ajustar el punto manualmente.',
      );
    }
  }

  Future<void> _moveCamera(LatLng position, double zoom) async {
    final customMover = widget.moveCamera;
    if (customMover != null) {
      await customMover(position, zoom);
      return;
    }
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
  }

  void _showGeocodingMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onAddressChanged() {
    _addressRevision++;
    _geocodeRequestId++;
    _geocodeDebounce?.cancel();
    _geocoding = false;
  }

  void _onManualPositionChanged(LatLng value) {
    _geocodeRequestId++;
    _geocodeDebounce?.cancel();
    setState(() {
      _position = value;
      _geocoding = false;
    });
  }

  void _scheduleGeocode() {
    _geocodeDebounce?.cancel();
    if (_colonia == null || _calle == null || _number.text.trim().isEmpty) {
      return;
    }
    _geocodeDebounce = Timer(const Duration(milliseconds: 650), _geocode);
  }

  void _onNumberFocusChanged() {
    if (!_numberFocus.hasFocus) {
      _geocodeDebounce?.cancel();
      _geocode();
    }
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
                    if (value.id == _colonia?.id) return;
                    _onAddressChanged();
                    setState(() {
                      _colonia = value;
                      _calle = null;
                      _cerrada = null;
                      _calles = const [];
                      _cerradas = const [];
                    });
                    await _loadDependent(value.id);
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
                          if (value.id == _calle?.id) return;
                          _onAddressChanged();
                          setState(() {
                            _calle = value;
                            _geocoding = false;
                          });
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
                        key: const ValueKey('direccion-numero'),
                        controller: _number,
                        focusNode: _numberFocus,
                        decoration: const InputDecoration(labelText: 'Número'),
                        onChanged: (value) {
                          final normalized = value.trim();
                          if (normalized == _addressNumber) return;
                          _addressNumber = normalized;
                          _onAddressChanged();
                          setState(() {});
                          _scheduleGeocode();
                        },
                        onEditingComplete: _numberFocus.unfocus,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ubicación de entrega',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (_geocoding)
                      const SizedBox.square(
                        key: ValueKey('direccion-geocoding-loading'),
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        widget.mapBuilder?.call(
                          position: _position,
                          onPositionChanged: _onManualPositionChanged,
                        ) ??
                        _DireccionMap(
                          position: _position,
                          onMapCreated: (controller) => _map = controller,
                          onPositionChanged: _onManualPositionChanged,
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
