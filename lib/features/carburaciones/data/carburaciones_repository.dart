import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../direcciones/data/direccion_repository.dart';
import '../../direcciones/data/direcciones_soap_service.dart';
import '../models/carburacion.dart';

abstract interface class CarburacionesRepositoryContract {
  Future<List<Carburacion>> getCarburaciones();
}

final class CarburacionesRepository implements CarburacionesRepositoryContract {
  const CarburacionesRepository(this._service);
  final DireccionesService _service;

  @override
  Future<List<Carburacion>> getCarburaciones() => _service.getCarburaciones();
}

final carburacionesRepositoryProvider = Provider<
  CarburacionesRepositoryContract
>((ref) => CarburacionesRepository(ref.watch(direccionesSoapServiceProvider)));
