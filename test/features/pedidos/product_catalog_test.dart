import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:combugas_clientes/features/pedidos/presentation/product_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('construye el mismo catálogo y orden usado por Pedido y Productos', () {
    const products = [
      Producto(
        id: ProductoIds.sixAlcalino,
        descripcion: 'Six alcalino',
        presentacion: 'Six',
        servicioId: ServicioIds.agua,
        precioCentavos: 100,
      ),
      Producto(
        id: ProductoIds.cilindro45,
        descripcion: 'Cilindro 45 kg',
        presentacion: '45 kg',
        servicioId: ServicioIds.gas,
        precioCentavos: 200,
      ),
      Producto(
        id: ProductoIds.estacionario,
        descripcion: 'Gas estacionario',
        presentacion: 'Litro',
        servicioId: ServicioIds.gas,
        precioCentavos: 300,
      ),
      Producto(
        id: 90,
        descripcion: 'BOLSA DE CROQUETAS',
        presentacion: 'Bolsa 4 kg',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 400,
      ),
    ];

    final catalog = buildProductCatalog(products);

    expect(catalog.map((group) => group.key), [
      'cilindros',
      'estacionario',
      'six-alcalino',
      'bolsas',
    ]);
    expect(catalog.expand((group) => group.products).toSet(), products.toSet());
    expect(catalog[1].isStationary, isTrue);
  });
}
