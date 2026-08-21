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

Alternativamente, Gradle acepta `-PMAPS_API_KEY=TU_CLAVE`. La clave debe tener habilitado **Maps SDK for Android** y autorizar el `applicationId`/SHA-1 de esta aplicación. Para iOS se debe definir `GOOGLE_MAPS_API_KEY` como build setting de Xcode y habilitar **Maps SDK for iOS**.

La app solicita ubicación aproximada/precisa en Android y `When In Use` en iOS. Si el usuario no concede el permiso, puede seleccionar la posición manualmente en el mapa.
