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
  List<Producto> ids(List<int> values) =>
      products.where((product) => values.contains(product.id)).toList();

  final groups = <ProductCatalogGroup>[];

  void add(String key, String title, List<Producto> matches) {
    if (matches.isEmpty) return;
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
    products.where((product) => product.esCroqueta && product.esBulto).toList(),
  );
  add(
    'bolsas',
    'Croquetas por bolsa',
    products.where((product) => product.esCroqueta && product.esBolsa).toList(),
  );

  return groups;
}
