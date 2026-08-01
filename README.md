# texi_passenger_app

App Flutter para pasajeros Texi.

## Documentación

| Tema | Ubicación |
|------|-----------|
| **Plan de limpieza / control (fases 0–6)** | [`.cursor/functional-modules/passenger-trip-request/texi-passenger-app-cleanup-tracker.md`](../.cursor/functional-modules/passenger-trip-request/texi-passenger-app-cleanup-tracker.md) |
| Notas de ingeniería (monolitos, HTTP, realtime) | [`.cursor/functional-modules/passenger-trip-request/texi-passenger-app-engineering-notes.md`](../.cursor/functional-modules/passenger-trip-request/texi-passenger-app-engineering-notes.md) |
| Borrador de viaje (UX) | `.cursor/functional-modules/passenger-trip-request/` |
| Onboarding pasajero | `.cursor/functional-modules/passenger-onboarding/` |
| Contratos API | `.cursor/contracts-matrix.md` |

## Arranque local (pre-prod)

```bash
flutter pub get
flutter run \
  --dart-define=TEXI_BACKEND_BASE_URL=https://api.dev.taxitexi.com \
  --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
```

> **Prod:** usar key Maps **propia del pasajero** (package `com.taxitexi.texi_passenger_app` + SHA-1 upload pasajero). No reutilizar la key prod del conductor — ver [`passenger-app-credentials-matrix.md`](../.cursor/functional-modules/passenger-trip-request/passenger-app-credentials-matrix.md).

## Estructura (`lib/`)

| Área | Ruta | Rol |
|------|------|-----|
| Router | `core/router/app_router.dart` | GoRouter + redirect por sesión (F0) |
| Config | `core/config/app_config.dart` | Backend URL, Maps |
| Auth | `core/auth/auth_service.dart` | Token, refresh |
| HTTP unificado | `core/network/passenger_api_client.dart` | Auth REST + factory viajes |
| Providers HTTP | `core/network/passenger_api_providers.dart` | `passengerApiClientProvider`, perfil cache |
| Viajes REST | `core/network/trips_api.dart` | Quote, create, lugares, historial |
| Trip UI | `features/trip/trip_request_screen.dart` | Pantalla principal mapa/borrador |
| Realtime | `features/trip/passenger_realtime_controller.dart` | Socket.IO pasajero |
| Estado borrador | `features/trip/trip_request_state.dart` | `tripRequestProvider` |
| Perfil / soporte | `features/profile/passenger_profile_preview_screen.dart` | Perfil + tickets |
| Login | `features/login/` | OTP, registro perfil |

## Rutas principales

| Path | Requiere token |
|------|----------------|
| `/`, `/login`, `/auth/*` | No |
| `/home`, `/trip/*`, `/profile`, `/trip/history` | Sí (`redirect` GoRouter) |
| `/labs` | Sí + allowlist QA o `TEXI_PASSENGER_INTERNAL_TOOLS` |

## Providers y fuentes de verdad (viaje)

| Provider / servicio | Rol |
|---------------------|-----|
| `tripRequestProvider` | Borrador: origen, destino, cotización, `tripId` |
| `passengerRealtimeProvider` | Socket.IO: status, coords conductor, chat |
| `passengerInternalToolsVisibleProvider` | Gate labs (teléfono QA / dart-define) |
| `localeProvider` | Idioma UI |
| `TripsApi` | REST viajes (quote, create, historial) |
| `AuthService` | Token, refresh, logout → `onSessionExpired` |
| `TripSessionStorage` | Rehidratación viaje activo |

## Convención de errores (`errorCode` → l10n)

1. El backend devuelve `code` en JSON (p. ej. `RBAC_FORBIDDEN`, `PASS_AUTH_INVALID`).
2. La UI **no** muestra el mensaje crudo del servidor al usuario salvo fallback controlado.
3. Mapeo centralizado en `lib/core/l10n/trip_error_localization.dart`:
   - `localizedTripApiError(l10n, code, fallbackMessage: …)` — REST viajes
   - `localizedPassengerRealtimeError(l10n, code)` — realtime pasajero
4. Perfil/soporte: códigos `PASS_*` / `RBAC_*` en `passenger_profile_preview_screen` → claves `profileError*` del ARB.
5. Cambios de códigos nuevos: agregar case en `trip_error_localization.dart` + clave ARB es/en (no-breaking).

## Calidad

```bash
flutter analyze
dart run tool/verify_l10n.dart
dart run tool/find_unused_l10n_keys.dart
flutter test
```

## Getting Started (Flutter)

Ver [documentación Flutter](https://docs.flutter.dev/).
