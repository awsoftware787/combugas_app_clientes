import '../../../core/constants/app_assets.dart';

enum MetodoPago {
  efectivo(id: 1, descripcion: 'Efectivo', asset: AppAssets.iconCash),
  tarjeta(id: 4, descripcion: 'Tarjeta', asset: AppAssets.iconCard);

  const MetodoPago({
    required this.id,
    required this.descripcion,
    required this.asset,
  });
  final int id;
  final String descripcion;
  final String asset;
}
