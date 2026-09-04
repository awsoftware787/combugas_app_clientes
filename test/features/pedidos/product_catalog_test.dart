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
      'producto-90',
    ]);
    expect(catalog.expand((group) => group.products).toSet(), products.toSet());
    expect(catalog[1].isStationary, isTrue);
  });

  test('muestra un producto nuevo sin reconocer su ID', () {
    const product = Producto(
      id: 25,
      descripcion: 'CROQUETAS PARA GATO 15 KG',
      presentacion: '15 KG',
      servicioId: 9,
      precioCentavos: 34000,
      tipoProductoId: 4,
      tipoProducto: 'Alimento para mascota',
      urlIcono: 'https://servidor/Images/productos/croquetas_gato.png',
    );

    final catalog = buildProductCatalog(const [product]);

    expect(catalog, hasLength(1));
    expect(catalog.single.key, 'producto-25');
    expect(catalog.single.title, 'CROQUETAS PARA GATO 15 KG');
    expect(catalog.single.products.single, same(product));
  });

  test('crea una tarjeta por cada croqueta aunque compartan tipo', () {
    const products = [
      Producto(
        id: 25,
        descripcion: 'ALIMENTO ADULTO 20 KG',
        presentacion: '20 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 34000,
        tipoProductoId: 4,
        tipoProducto: 'Alimento para mascota',
      ),
      Producto(
        id: 26,
        descripcion: 'ALIMENTO CACHORRO 15 KG',
        presentacion: '15 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 36000,
        tipoProductoId: 4,
        tipoProducto: 'Alimento para mascota',
      ),
      Producto(
        id: 27,
        descripcion: 'ALIMENTO GATO 10 KG',
        presentacion: '10 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 32000,
        tipoProductoId: 4,
        tipoProducto: 'Alimento para mascota',
      ),
    ];

    final catalog = buildProductCatalog(products);

    expect(catalog, hasLength(3));
    expect(catalog.map((group) => group.key), [
      'producto-25',
      'producto-26',
      'producto-27',
    ]);
    expect(
      catalog,
      everyElement(
        predicate<ProductCatalogGroup>((group) => group.products.length == 1),
      ),
    );
  });

  test(
    'ordena los grupos por servicio y conserva el orden dentro de cada uno',
    () {
      const products = [
        Producto(
          id: 90,
          descripcion: 'Producto del servicio 9',
          presentacion: 'Unidad',
          servicioId: 9,
          precioCentavos: 100,
          tipoProductoId: 51,
          tipoProducto: 'Servicio nueve',
        ),
        Producto(
          id: 50,
          descripcion: 'Segundo producto del servicio 2',
          presentacion: 'Unidad',
          servicioId: 2,
          precioCentavos: 100,
          tipoProductoId: 51,
          tipoProducto: 'Segundo grupo',
        ),
        Producto(
          id: ProductoIds.cilindro30,
          descripcion: 'Cilindro 30 kg',
          presentacion: '30 kg',
          servicioId: ServicioIds.gas,
          precioCentavos: 100,
        ),
        Producto(
          id: 40,
          descripcion: 'Primer producto del servicio 2',
          presentacion: 'Unidad',
          servicioId: 2,
          precioCentavos: 100,
          tipoProductoId: 41,
          tipoProducto: 'Primer grupo',
        ),
        Producto(
          id: ProductoIds.garrafonNatural,
          descripcion: 'Garrafón natural',
          presentacion: '20 L',
          servicioId: ServicioIds.agua,
          precioCentavos: 100,
        ),
      ];

      final catalog = buildProductCatalog(products);

      expect(catalog.map((group) => group.products.first.servicioId), [
        1,
        2,
        2,
        3,
        9,
      ]);
      expect(
        catalog
            .where((group) => group.products.first.servicioId == 2)
            .map((group) => group.title),
        ['Segundo grupo', 'Primer grupo'],
      );
    },
  );
}
