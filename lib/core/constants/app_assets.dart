/// Rutas centralizadas de los recursos visuales disponibles en tiempo de ejecución.
abstract final class AppAssets {
  static const flameLogo = 'assets/app_icon/combugas_app_icon.png';
  static const logo = 'assets/images/logos/img_logo_nombre.png';

  static const productWater = 'assets/images/products/app_slider_agua.png';
  static const productAlkalineWater =
      'assets/images/products/app_slider_agua_alkalina.png';
  static const productCylinder =
      'assets/images/products/app_slider_cilindro.png';
  static const productDogFoodBag =
      'assets/images/products/app_slider_croquetas_bolsa.png';
  static const productDogFoodBulk =
      'assets/images/products/app_slider_croquetas_bulto.png';
  static const productStationaryTank =
      'assets/images/products/app_slider_estacionario.png';
  static const productSixPack = 'assets/images/products/app_slider_six.png';
  static const productAlkalineSixPack =
      'assets/images/products/app_slider_six_alkalina.png';

  static const iconAlert = 'assets/images/icons/ic_alerta.png';
  static const iconArrowRight = 'assets/images/icons/ic_arrow_right.png';
  static const iconCall = 'assets/images/icons/ic_call.png';
  static const iconHome = 'assets/images/icons/ic_casa.png';
  static const iconDone = 'assets/images/icons/ic_done.png';
  static const iconDropdown = 'assets/images/icons/ic_dropdown.png';
  static const iconEdit = 'assets/images/icons/ic_editar.png';
  static const iconError = 'assets/images/icons/ic_error_red.png';
  static const iconExpand = 'assets/images/icons/ic_expandir.png';
  static const iconRemove = 'assets/images/icons/ic_quitar.png';
  static const iconCart = 'assets/images/icons/ic_shop_car.png';
  static const iconShowPassword = 'assets/images/icons/ic_show_pass.png';
  static const iconCashBills = 'assets/images/icons/ico_billetes.png';
  static const iconAddress = 'assets/images/icons/ico_casa.png';
  static const iconCash = 'assets/images/icons/ico_efectivo.png';
  static const iconPaypal = 'assets/images/icons/ico_paypal.png';
  static const iconCard = 'assets/images/icons/ico_tarjeta.png';

  /// Recurso seguro para productos dinámicos que todavía no tienen imagen.
  static const productFallback = iconCart;

  static const mapBothFuelTypes =
      'assets/images/map/marker_carburacionambos.png';
  static const mapGasStation = 'assets/images/map/marker_carburaciongas.png';
  static const mapHome = 'assets/images/map/marker_casa.png';
  static const mapVehicle = 'assets/images/map/marker_vehiculo.png';

  static const nextImage = 'assets/images/misc/img_derecha.png';
  static const previousImage = 'assets/images/misc/img_izquierda.png';
  static const profileImage = 'assets/images/misc/img_perfil.png';

  static const values = <String>[
    flameLogo,
    logo,
    productWater,
    productAlkalineWater,
    productCylinder,
    productDogFoodBag,
    productDogFoodBulk,
    productStationaryTank,
    productSixPack,
    productAlkalineSixPack,
    iconAlert,
    iconArrowRight,
    iconCall,
    iconHome,
    iconDone,
    iconDropdown,
    iconEdit,
    iconError,
    iconExpand,
    iconRemove,
    iconCart,
    iconShowPassword,
    iconCashBills,
    iconAddress,
    iconCash,
    iconPaypal,
    iconCard,
    mapBothFuelTypes,
    mapGasStation,
    mapHome,
    mapVehicle,
    nextImage,
    previousImage,
    profileImage,
  ];
}
