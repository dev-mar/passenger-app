# Configuración – Texi Pasajero

## Dónde cambiar cosas (todo reutilizable)

| Qué cambiar | Dónde |
|-------------|--------|
| Nombre de la app, URLs (auth, viajes), path de login | `lib/core/config/app_config.dart` |
| Colores (primario, fondo, superficie, etc.) | `lib/core/theme/app_colors.dart` |
| Tema (botones, inputs, textos) | `lib/core/theme/app_theme.dart` (usa `AppColors`) |
| Rutas de logo e icono | `lib/core/constants/app_assets.dart` |
| Rutas de navegación | `lib/core/router/app_router.dart` |
| Textos (multilenguaje) | `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb` |
| Idioma actual (es/en) | `lib/core/config/locale_provider.dart` (selector en Home) |

---

## Multilenguaje (i18n)

- **Idiomas:** Español (es) e Inglés (en).
- **Estándar:** Flutter l10n con archivos ARB. Tras editar `lib/l10n/app_es.arb` o `app_en.arb`, ejecuta `flutter gen-l10n` para regenerar `lib/gen_l10n/`.
- **Uso en código:** `AppLocalizations.of(context)!.claveTexto`.
- **Cambiar idioma:** En Home, botón de idioma (icono globo) en la AppBar abre un menú para elegir Español o English. El valor se guarda en `localeProvider` (Riverpod).

---

## Google Maps API Key

Cuando vayas a usar el mapa (pantalla Home), coloca tu key en **un solo lugar**:

### Opción recomendada: `app_config.dart`

En `lib/core/config/app_config.dart` reemplaza la constante:

```dart
static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
```

por tu key real, por ejemplo:

```dart
static const String googleMapsApiKey = 'AIza...';
```

### Android

La key ya está referenciada en el proyecto. Abre:

**`android/app/src/main/AndroidManifest.xml`**

Dentro del tag `<application>`, en la parte superior (antes de `<activity>`), verás:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

Sustituye `YOUR_GOOGLE_MAPS_API_KEY` por tu key real de Google Maps.

### iOS

La key ya está referenciada en el proyecto. Abre:

**`ios/Runner/AppDelegate.swift`**

Al inicio del método `application(didFinishLaunchingWithOptions:)` verás:

```swift
import GoogleMaps
// ...
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

Sustituye `YOUR_GOOGLE_MAPS_API_KEY` por tu key real.

**Búsqueda de dirección:** Geocoding API (misma key). Actívala en Google Cloud.

**Ruta por calles:** La línea entre origen y destino usa **Directions API** (mejor ruta por calles). Activa "Directions API" en el mismo proyecto de Google Cloud.
**Pines del mapa:** `assets/images/pinOrigen.png` y `pinDestino.png`. Rutas en `app_assets.dart`.

---

## Assets (logo e icono)

- **Logo:** Coloca tu archivo en `assets/images/logo.png`. La app lo usa en Splash y donde se referencie `AppAssets.logo`.
- **Icono de la app:** Coloca `app_icon.png` (recomendado 1024×1024) en `assets/icons/app_icon.png`. Para el launcher en Android/iOS hay que configurar los iconos de la plataforma (flutter_launcher_icons o manualmente).

Si cambias la ruta o el nombre del archivo, actualiza solo `lib/core/constants/app_assets.dart`.
