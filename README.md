# texi_passenger_app

App Flutter del pasajero Texi. Permite iniciar sesión, solicitar un viaje, seguirlo en tiempo real y gestionar perfil y soporte.

## Requisitos

- Flutter con Dart `^3.10.1` (versión fijada en `pubspec.yaml`).
- Claves de Google Maps y, si aplica, de acceso (OAuth y Turnstile). No se versionan.

## Configuración

Copia la plantilla del entorno y completa los valores:

- Desarrollo: `env.local.example` → `.env.local`
- Producción: `env.prod.example` → `.env.prod`

La app lee estas variables en compilación con `--dart-define`. El script de arranque las toma del archivo de entorno.

| Variable | Uso |
|----------|-----|
| `TEXI_APP_ENV` | `dev` o `prod`. Si se omite, debug usa dev y release usa prod. |
| `TEXI_BACKEND_BASE_URL` | Base REST y Socket.IO. Dev: `https://api.dev.taxitexi.com`. Prod: `https://api-prodtx.taxitexi.com`. |
| `GOOGLE_MAPS_API_KEY` | SDK de mapas de esta app. |
| `GOOGLE_MAPS_REST_API_KEY` | Places, geocoding y directions. Si falta, se usa la key del SDK. |
| `TURNSTILE_SITE_KEY` | Verificación en el login. |
| `GOOGLE_OAUTH_SERVER_CLIENT_ID` | Inicio de sesión con Google. |
| `TEXI_PASSENGER_MULTICHANNEL_AUTH` | Activa el login multicanal fuera de prod. En prod ya está activo. |

La key de mapas es propia de esta app (`com.taxitexi.texi_passenger_app`; en Android dev, `com.taxitexi.texi_passenger_app.dev`). En iOS debe estar autorizada para el bundle de esta app.

## Arranque

Desde la raíz de este proyecto. Local usa `.env.local`:

```powershell
.\scripts\run-with-maps-key.ps1 -Mode apk
```

Producción usa `.env.prod`:

```powershell
.\scripts\build-channel.ps1 -Channel prod -Mode apk
```

`-Mode run` abre la app en un dispositivo conectado. `-Mode appbundle` genera el paquete de tienda. En iOS, el mismo entorno se pasa con `--dart-define` al ejecutar `flutter run`.

## Estructura

| Ruta | Contenido |
|------|-----------|
| `lib/core/` | Configuración, sesión, red, router y tema. |
| `lib/features/` | Login, viaje, perfil, soporte y promociones. |
| `lib/l10n/` | Textos de la interfaz (es, en). |
| `assets/` | Iconos e imágenes. |
| `scripts/` | Arranque y builds de Android. |

## Calidad

```bash
flutter analyze
dart run tool/verify_l10n.dart
dart run tool/find_unused_l10n_keys.dart
flutter test
```
