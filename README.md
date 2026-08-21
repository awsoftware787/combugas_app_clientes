# Combugas Clientes

Migración Flutter de la aplicación Android de clientes de Combugas.

## Ambientes

```powershell
flutter run --dart-define-from-file=config/dev_local.json
flutter run --dart-define-from-file=config/dev.json
flutter run --dart-define-from-file=config/prod.json
```

## Google Maps para Direcciones

El formulario de alta/edición conserva el marcador arrastrable, ubicación del dispositivo y geocodificación usados por Android. La API key no se guarda en el repositorio.

Android acepta la clave mediante la variable de ambiente `MAPS_API_KEY`:

```powershell
$env:MAPS_API_KEY='TU_CLAVE'
flutter run --dart-define-from-file=config/dev.json
```

También puede agregarse sin espacios en `android/local.properties`:

```properties
MAPS_API_KEY=TU_CLAVE
```

Alternativamente, Gradle acepta `-PMAPS_API_KEY=TU_CLAVE`. La clave debe tener habilitado **Maps SDK for Android** y autorizar el `applicationId`/SHA-1 de esta aplicación.

# IOS

Para iOS, copia `ios/Flutter/Secrets.xcconfig.example` como
`ios/Flutter/Secrets.xcconfig` y reemplaza el placeholder. Este archivo está
ignorado por Git. La clave debe tener habilitado **Maps SDK for iOS** y estar
restringida al Bundle Identifier `mx.com.combugas.clientes`.

En macOS, instala los pods y compila Release con el ambiente de producción:

```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ios --no-codesign --dart-define-from-file=config/prod.json
```

La app solicita ubicación aproximada/precisa en Android y `When In Use` en iOS. Si el usuario no concede el permiso, puede seleccionar la posición manualmente en el mapa.
