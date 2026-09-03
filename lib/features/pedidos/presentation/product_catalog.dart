import '../models/producto.dart';

/// Agrupación y orden únicos para el catálogo de Pedido y Productos.
final class ProductCatalogGroup {
  const ProductCatalogGroup({
    required this.key,
    required this.title,
    required this.products,
  });

  final String key;
  final String title;
  final List<Producto> products;

  bool get isStationary =>
      products.length == 1 && products.single.id == ProductoIds.estacionario;
}

List<ProductCatalogGroup> buildProductCatalog(List<Producto> products) {
  // Compatibilidad visual temporal hasta que el backend exponga orden_visual.
  // Los IDs conocidos conservan su posición; ningún ID desconocido se filtra.
  const legacyOrder = <int, int>{
    ProductoIds.cilindro30: 10,
    ProductoIds.cilindro45: 20,
    ProductoIds.estacionario: 30,
    ProductoIds.garrafonNatural: 40,
    ProductoIds.garrafonAlcalino: 50,
    ProductoIds.sixNatural: 60,
    ProductoIds.sixAlcalino: 70,
    20: 80,
  };
  final indexed =
      products.indexed.toList()..sort((left, right) {
        final leftOrder = legacyOrder[left.$2.id] ?? 1000 + left.$1;
        final rightOrder = legacyOrder[right.$2.id] ?? 1000 + right.$1;
        return leftOrder.compareTo(rightOrder);
      });
  final ordered = indexed.map((item) => item.$2).toList(growable: false);
  final consumed = <int>{};

  List<Producto> ids(List<int> values) {
    final matches = <Producto>[];
    for (final id in values) {
      for (final product in ordered) {
        if (product.id == id) matches.add(product);
      }
    }
    consumed.addAll(matches.map((product) => product.id));
    return matches;
  }

  final groups = <ProductCatalogGroup>[];

  void add(String key, String title, List<Producto> matches) {
    if (matches.isEmpty) return;
    consumed.addAll(matches.map((product) => product.id));
    groups.add(ProductCatalogGroup(key: key, title: title, products: matches));
  }

  add(
    'cilindros',
    'Gas en cilindro',
    ids([ProductoIds.cilindro30, ProductoIds.cilindro45]),
  );
  add('estacionario', 'Gas estacionario', ids([ProductoIds.estacionario]));
  add(
    'garrafon-natural',
    'Garrafón de agua natural',
    ids([ProductoIds.garrafonNatural]),
  );
  add(
    'garrafon-alcalino',
    'Garrafón de agua alkalina',
    ids([ProductoIds.garrafonAlcalino]),
  );
  add('six-natural', 'Six de agua natural', ids([ProductoIds.sixNatural]));
  add('six-alcalino', 'Six de agua alkalina', ids([ProductoIds.sixAlcalino]));
  add(
    'bultos',
    'Croquetas por bulto',
    ordered.where((product) => product.esCroqueta && product.esBulto).toList(),
  );
  add(
    'bolsas',
    'Croquetas por bolsa',
    ordered.where((product) => product.esCroqueta && product.esBolsa).toList(),
  );

  // Los productos futuros se agrupan con los metadatos del servicio. Si el
  // backend aún no los envía, se conserva un grupo genérico sin ocultarlos.
  final dynamicGroups = <String, List<Producto>>{};
  final dynamicTitles = <String, String>{};
  for (final product in ordered.where((item) => !consumed.contains(item.id))) {
    final typeName = product.tipoProducto?.trim();
    final key =
        product.tipoProductoId != null
            ? 'tipo-${product.tipoProductoId}'
            : typeName?.isNotEmpty == true
            ? 'tipo-${typeName!.toLowerCase()}'
            : 'servicio-${product.servicioId}';
    dynamicGroups.putIfAbsent(key, () => <Producto>[]).add(product);
    dynamicTitles[key] = typeName?.isNotEmpty == true ? typeName! : 'Productos';
  }
  for (final entry in dynamicGroups.entries) {
    add(entry.key, dynamicTitles[entry.key]!, entry.value);
  }

  return groups;
}
