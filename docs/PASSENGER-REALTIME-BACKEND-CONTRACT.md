# Contrato pasajero–backend: estados en tiempo real

Documento para alinear **cómo muestra la app** los estados del viaje, **qué debe hacer el backend** (salas, eventos, payloads) y **qué debe ocurrir** para validar que todo está bien.

**Alcance:** Este documento aplica **solo a la app del pasajero** (`texi_passenger_app`). Todo lo que aquí se indica revisar o implementar es en la app de pasajero y en el backend que emite a esa app. La app del conductor tiene su propio flujo y eventos; ver §5 y `FLUTTER-WEBSOCKET-EVENTS.md`.

---

## 0. URLs: REST vs auth vs Socket.IO (`app_texi_WebSocket`)

| Uso | Base URL (ejemplo pre-prod) | Paths |
|-----|-----------------------------|--------|
| **Login / auth** | `http://<host>/api/v1` (servicio aparte) | `/auth/login`, `/auth/verify-code`, etc. |
| **REST pasajero (viajes)** | `https://<websocket-host>` **sin** `/api/v1` | `GET /passengers/nearby-drivers`, `POST /passengers/trips/quote`, `POST /passengers/trips`, `GET /passengers/trips/:tripId` |
| **Socket.IO** | Mismo host que REST de viajes (típico) | Path: `/socket.io/` |

- **JWT REST:** header `Authorization: Bearer <JWT>` (requerido en rutas `/passengers/...`).
- **Socket.IO:** token vía `Authorization: Bearer <JWT>` (u otras formas que exponga el middleware); el **rol se deduce del JWT** — no hace falta `x-role` en el cliente.

**Error típico si la app usa mal el prefijo:** llamar `.../api/v1/passengers/trips/quote` cuando el backend monta `app.use('/passengers', ...)` en raíz → **404** “Ruta no encontrada”. La app debe usar `AppConfig.baseUrlTripsRest` **sin** `/api/v1` salvo que Infra confirme un proxy que lo anteponga.

### 0.1 `GET /passengers/trips/:tripId` — cómo se usaba y cómo se usa ahora

**No es un cambio de ruta ni de método:** sigue siendo el mismo `GET` con el mismo `Authorization`. Lo que cambió es el **cuerpo de `data`**: se añadió un campo **opcional** y **aditivo** para no romper clientes antiguos.

#### Antes (contrato mínimo histórico)

La app solo podía confiar en que `data` incluía algo como:

| Campo | Uso en la app pasajero |
|-------|-------------------------|
| `tripId` | Identificar el viaje |
| `status` | Sincronizar estado del viaje (`searching`, `accepted`, `completed`, …) |
| `estimatedPrice` | Opcional; cotización |
| `driverId` | Saber si ya hay conductor asignado |
| `createdAt` / `updatedAt` | Metadatos |

**Uso en Flutter (antes):** `TripsApi.getPassengerTripStatus` → modelo `TripStatusResponse` con **solo** `tripId` + `status`.  
`PassengerRealtimeController.syncTripStatusFromApi` actualizaba **únicamente** `status` / `activeTripId` en el provider.  
**La posición del conductor en el mapa** venía **exclusivamente** del evento Socket **`trip:driver_location`**, no del GET.

#### Ahora (mismo GET, respuesta enriquecida opcional)

Si el backend desplegado incluye el cambio, cuando el viaje tiene **`driver_id`** y el **`status`** es de seguimiento (`accepted`, `arrived`, `started`, `in_trip`), `data` puede incluir además:

| Campo | Tipo | Uso en la app |
|-------|------|---------------|
| `driverLocation` | objeto opcional | Última posición conocida del conductor (Redis → DB) |
| `driverLocation.lat` / `lng` | number | **Fallback** para el marcador del mapa si el socket va atrasado o hubo cortes |
| `driverLocation.bearing`, `speed`, `updatedAt`, `source` | opcionales | Informativos; la app puede ignorarlos |

**Uso en Flutter (ahora):**  
- Mismo método: `TripsApi.getPassengerTripStatus` → `TripStatusResponse` con **`driverLat` / `driverLng`** parseados desde `data.driverLocation` **si existen**.  
- `syncTripStatusFromApi` fusiona: `driverLat: res.driverLat ?? state.driverLat` (no borra la última posición si el backend aún no envía el bloque).  
- Sigue siendo válido **solo socket** en backends viejos: si `driverLocation` no viene, el comportamiento es igual que “antes” para el mapa; solo el socket mueve el pin.

#### Compatibilidad

| Cliente | Comportamiento |
|---------|----------------|
| App antigua (sin parsear `driverLocation`) | Ignora el campo JSON nuevo; sin cambios. |
| Backend antiguo (sin `driverLocation`) | La app nueva deja `driverLat`/`driverLng` en null en esa respuesta y mantiene lo que ya tenía el provider o lo que llegue por socket. |
| App nueva + backend nuevo | GET refuerza posición en polling / reconexión además de `trip:driver_location`. |

#### Referencia de código (pasajero)

| Pieza | Archivo |
|-------|---------|
| Cliente HTTP + modelo | `lib/core/network/trips_api.dart` (`TripStatusResponse`, `getPassengerTripStatus`) |
| Merge en estado realtime | `lib/features/trip/passenger_realtime_controller.dart` → `syncTripStatusFromApi` |
| Polling más frecuente en seguimiento | `lib/features/trip/trip_request_screen.dart` → `_startTripStatusPeriodicSync` / `_syncTripStatusOnceThrottled` |
| Implementación servidor | `app_texi_WebSocket/src/routes/passengers.trips.routes.js` (`GET /trips/:tripId`) |

---

## 1. Cómo lo muestra la app (pasajero)

### 1.1 Flujo de pantalla

1. **Sin viaje activo**  
   El usuario ve el mapa con origen/destino y la card inferior para ver precios y pedir viaje.

2. **Al pedir viaje (búsqueda)**  
   - Se muestra el overlay **“Buscando conductor”** (efecto radar + botón Cancelar).  
   - La app **debe** abrir Socket.IO en el mismo momento en que se crea el viaje (justo después de `POST /passengers/trips`), unirse a la sala del pasajero y quedar escuchando eventos. Si no se conecta aquí, el pasajero no recibirá `trip:accepted` ni `trip:status`.

3. **Cuando un conductor acepta**  
   - La app recibe `trip:accepted`.  
   - Desaparece “Buscando conductor” y aparece la **card de estado del viaje** (`_TripStatusCard`).  
   - En esa card se muestra: **estado** (“Conductor en camino”, “El conductor llegó”, etc.) y, si vienen en el payload, **nombre del conductor**, **color**, **modelo** y **placa** del auto.

4. **Cambios de estado (llegó, en curso, finalizado)**  
   - La app recibe `trip:status` con `status`: `arrived` | `started` | `completed` (y opcionalmente `cancelled` | `expired`).  
   - La card actualiza el texto y el icono según el estado.

5. **Posición del conductor en el mapa**  
   - Si el backend envía `trip:driver_location`, la app actualiza el marcador del conductor en el mapa (lat/lng, opcional bearing).

### 1.2 Dónde se conecta el socket (código)

- **Momento:** El viaje se crea al pulsar “Solicitar viaje”, ya sea desde el **bottom sheet de cotización** en el mapa o desde la **pantalla de confirmación**. Tras `createTrip()` exitoso, la app llama a `PassengerRealtimeController.connect(tripId, quote)` y luego navega (o permanece) en la pantalla del mapa (`trip_request`). Es **crítico** que `connect()` se invoque en ese mismo flujo; si no, el pasajero nunca recibe eventos.
- **Archivos:**
  - `lib/features/trip/trip_request_screen.dart`: en `_QuoteBottomSheet._requestTrip()` después de `setTripId(result.tripId)` se llama `connect(tripId, quote)` y luego `widget.onSuccess()` (cierra el sheet y deja al usuario en el mapa).
  - `lib/features/trip/trip_confirm_screen.dart`: en `_requestTrip()` después de `setTripId(result.tripId)` se llama `connect(tripId, quote)` y luego `context.goNamed('trip_request')`.

### 1.3 Dónde se usa el estado (código)

| Fuente de verdad | Uso en la UI |
|------------------|--------------|
| `passengerRealtimeProvider` (Riverpod) | `PassengerRealtimeController` recibe los eventos Socket y actualiza el estado. |
| `state.status` | `'searching'` → overlay “Buscando conductor”; `'accepted'` \| `'arrived'` \| `'started'` \| `'completed'` → se muestra `_TripStatusCard` con el label correspondiente. |
| `state.driverName`, `carColor`, `carPlate`, `carModel` | Se muestran en la card solo si están presentes (la app acepta camelCase o snake_case). |

### 1.3.1 Matching / rondas / tiempos (fuente de verdad: backend)

- **Reglas de negocio** del reparto (cuántos conductores por ronda, TTL de ofertas, reintentos, cuándo pasa el viaje a `expired`, etc.) las define **solo el backend** y sus workers.
- La app pasajero **no** debe inventar countdowns ni “re-buscar” por su cuenta duplicando `POST /passengers/trips`.
- La UI se limita a reflejar **`trip:status`** y el estado devuelto por **`GET /passengers/trips/:tripId`** (p. ej. `searching`, `accepted`, `expired`).

### 1.3.2 Evitar viajes duplicados (misma sesión / reabrir app)

Si el pasajero **cierra o pone en segundo plano** la app mientras el viaje sigue en **`searching`** (u otro estado no final), al volver debe seguir viendo **el mismo** `tripId` (almacenamiento local + hidratación en splash + `TripRequestScreen`).

Antes de crear otro viaje (`POST /passengers/trips`), la app llama a **`reconcileActiveTripBeforeCreateTrip`** (`lib/features/trip/passenger_active_trip_guard.dart`):

- Si `GET /passengers/trips/:id` indica **`cancelled`** o **`expired`**, limpia almacenamiento y permite un viaje nuevo.
- Si el viaje **sigue activo** (p. ej. `searching`, `accepted`, …), **reconecta** Socket.IO y **no** envía un segundo `POST` (evita dos ofertas / dos notificaciones al conductor por el mismo pasajero).

**UX:** al reconciliar, la app muestra un **SnackBar** flotante (Material 3) con título y texto explicativo (`trip_recovery_feedback.dart`), **una vez por `tripId`** por sesión, para que el pasajero entienda que **no** se duplicó el pedido. El indicador “Recuperando tu viaje…” usa `tripRecoveringStateTitle` (l10n).

### 1.4 Labels por estado (app)

| `status`   | Texto en la card        |
|-----------|--------------------------|
| `accepted`| Conductor en camino      |
| `arrived` | El conductor llegó       |
| `started` | Viaje en curso           |
| `completed` | Viaje finalizado      |
| otro      | En camino (fallback)     |

---

## 2. Qué debe hacer el backend

### 2.1 Sala del pasajero

- **Nombre de la sala:** `passenger:${key}`  
- **`key`:** debe ser el **mismo** valor con el que el pasajero se une al conectar por Socket.

**Conexión del pasajero (backend):**  
En el middleware de auth se toma del JWT: `userId ?? id ?? sub ?? uuid` y se guarda en `socket.data.passengerId`. Al conectar, el socket hace `socket.join('passenger:' + socket.data.passengerId)`.

**Emisión al pasajero:**  
El backend obtiene el `passenger_id` (numérico, de `operations.trips`) y llama a `getPassengerSocketKey(passengerId)`, que devuelve el **uuid** del usuario si existe en `public.users`, o **String(id)** si no hay uuid. Se emite a `passenger:${key}`.

**Requisito crítico:**  
El **JWT del pasajero** debe incluir el mismo identificador que usa `getPassengerSocketKey` para ese usuario. Es decir: si en BD el usuario tiene `uuid`, el token debe enviar ese `uuid`; si no tiene uuid, debe enviar el `id` numérico. Así la sala a la que se une el cliente coincide con la sala a la que el backend emite.

### 2.2 Eventos que el backend debe emitir al pasajero

Emitir **siempre** a la sala `passenger:${key}` (con `key = getPassengerSocketKey(passengerId)`).

| Evento | Cuándo | Payload mínimo (y recomendado) |
|--------|--------|----------------------------------|
| **`trip:accepted`** | Cuando un conductor acepta el viaje (WebSocket `trip:accept` o REST `POST /drivers/me/trips/:tripId/accept`). | Ver tabla siguiente. |
| **`trip:status`** | En cada cambio de estado: `arrived`, `started`, `completed`, y en cancelación. | `{ tripId, status, driverId?, updatedAt }` |
| **`trip:driver_location`** | Cuando el conductor envía `location:update` y tiene un viaje activo con ese pasajero (estado `accepted`, `arrived` o `started`). | `{ tripId, lat, lng, bearing?, speed?, updatedAt? }` |

### 2.3 Payload de `trip:accepted` (qué debe incluir el backend)

La app usa estos campos para la card del conductor (nombre, auto, placa, color). Acepta **camelCase** o **snake_case**.

| Campo (camelCase) | Alternativa (snake_case) | Tipo   | Uso en la app |
|-------------------|---------------------------|--------|----------------|
| `tripId`          | —                         | string | Filtrar por viaje activo. |
| `driverId`        | —                         | any    | Referencia. |
| `status`          | —                         | string | Debe ser `'accepted'`. |
| `driverName`      | `driver_name`             | string | Nombre del conductor en la card. |
| `carColor`        | `car_color`               | string | Ej. “Blanco”. |
| `carPlate`        | `car_plate` o `plate`     | string | Placa del vehículo. |
| `carModel`        | `car_model`               | string | Ej. “Toyota Corolla”. |
| `estimatedPrice`  | —                         | number | Opcional. |
| `createdAt` / `updatedAt` | —                  | string | Opcional. |

**Importante:**  
Hoy el backend en `trips.handler.js` y en `drivers.me.routes.js` emite `trip:accepted` **sin** `driverName`, `carColor`, `carPlate`, `carModel`. Para que la card muestre los datos del conductor, el backend debe **enriquecer** el payload de `trip:accepted` con datos del conductor y del vehículo (por ejemplo desde `public.users` + tabla de vehículos) y enviar estos cuatro campos.

### 2.4 Payload de `trip:status`

| Campo     | Tipo   | Descripción |
|----------|--------|-------------|
| `tripId` | string | UUID del viaje. |
| `status` | string | `'accepted'` \| `'arrived'` \| `'started'` \| `'completed'` \| `'cancelled'` \| `'expired'`. |
| `driverId` | any  | Opcional. |
| `updatedAt` | string | Opcional. |

La app solo actualiza el estado en el provider; no exige más campos.

### 2.5 Payload de `trip:driver_location`

| Campo      | Tipo   | Descripción |
|-----------|--------|-------------|
| `tripId`  | string | UUID del viaje. |
| `lat`     | number | Latitud. |
| `lng`     | number | Longitud. |
| `bearing` | number | Opcional; rumbo en grados. |
| `speed`   | number | Opcional. |
| `updatedAt` | string | Opcional. |

---

## 3. Qué debe ocurrir para saber que todo está bien

### 3.1 Secuencia esperada (flujo feliz)

1. Pasajero pide viaje → ve “Buscando conductor”.
2. Conductor acepta (por app WebSocket o por REST) → backend emite `trip:accepted` (y opcionalmente `trip:status` con `accepted`) a `passenger:${key}`.
3. Pasajero recibe `trip:accepted` → desaparece “Buscando conductor”, aparece la card con “Conductor en camino” y, si el backend los envía, nombre/auto/placa/color.
4. Conductor llega y envía `trip:arrived` → backend emite `trip:status` con `status: 'arrived'` al pasajero → la card muestra “El conductor llegó”.
5. Conductor inicia viaje (`trip:started`) → backend emite `trip:status` con `status: 'started'` → card “Viaje en curso”.
6. Conductor finaliza (`trip:completed`) → backend emite `trip:status` con `status: 'completed'` → card “Viaje finalizado”.
7. Mientras el viaje está en `accepted` / `arrived` / `started`, si el conductor envía `location:update`, el backend emite `trip:driver_location` al pasajero → el marcador del conductor se actualiza en el mapa.

### 3.2 Comprobaciones prácticas

- **JWT y sala:**  
  - Que el JWT del pasajero incluya `userId`, `id`, `sub` o `uuid` según lo que use el backend en `getPassengerSocketKey`.  
  - Log en backend al conectar el pasajero: “Pasajero conectado por WebSocket” con `passengerId`.  
  - Al aceptar un viaje, log “trip:accepted y trip:status(accepted) emitidos al pasajero” (o equivalente en la ruta REST).  
  Si el pasajero no recibe nada, revisar que ese `passengerId` (o el key devuelto por `getPassengerSocketKey`) sea el mismo con el que el socket hizo `join('passenger:...')`.

- **App (debug):**  
  En `passenger_realtime_controller.dart` hay `debugPrint` al conectar (`[PASSENGER_RT] Conectando Socket.IO para tripId=...`, `[PASSENGER_RT] conectado a ...`) y en cada evento (`trip:accepted`, `trip:status`, `trip:driver_location`). Con `kDebugMode` podrás ver en consola si la conexión se abre y si los eventos llegan.
  - **Si el pasajero no recibe eventos:** comprueba que tras pulsar "Solicitar viaje" en el sheet aparezca en consola `[PASSENGER_RT] Conectando Socket.IO para tripId=...` y luego `[PASSENGER_RT] conectado a ...`. Si no aparece "Conectando", el socket no se está abriendo en este flujo (revisar que `connect()` se llame después de `createTrip()` en `_QuoteBottomSheet`).

- **Datos del conductor en la card:**  
  Si la card sigue mostrando solo el estado pero sin nombre/auto/placa/color, el backend no está enviando `driverName`, `carColor`, `carPlate`, `carModel` en `trip:accepted`. Hay que enriquecer el payload en el handler y en la ruta REST de accept.

### 3.3 Resumen de validación

| Comprobación | Dónde |
|--------------|--------|
| App abre Socket tras crear viaje | App: en consola debe aparecer `[PASSENGER_RT] Conectando Socket.IO para tripId=...` y luego `[PASSENGER_RT] conectado a ...` justo después de solicitar el viaje desde el sheet de precios. Si no aparece, el flujo no está llamando a `connect()` (ver §1.2). |
| Pasajero se une a la sala correcta | Backend: log al conectar con `passengerId`. JWT debe tener el mismo id/uuid que devuelve `getPassengerSocketKey`. |
| Pasajero recibe `trip:accepted` | App: debugPrint en `socket.on('trip:accepted', ...)`. |
| Pasajero recibe `trip:status` | App: debugPrint en `socket.on('trip:status', ...)`. |
| Card muestra datos del conductor | Backend: incluir `driverName`, `carColor`, `carPlate`, `carModel` en `trip:accepted`. |
| Marcador del conductor en el mapa | Backend: emitir `trip:driver_location` cuando el conductor envía ubicación y tiene viaje activo con ese pasajero. App: listener ya actualiza `driverLat`/`driverLng`. |

---

## 4. Documentos relacionados

- **`FLUTTER-WEBSOCKET-EVENTS.md`** – Listado de eventos Socket.IO (pasajero y conductor).
- **`REFRESH-TOKEN-BACKEND.md`** – Refresh token y autenticación.
- Backend: **`app_texi_WebSocket/src/handlers/trips.handler.js`**, **`routes/drivers.me.routes.js`**, **`handlers/gps.handler.js`**, **`services/passenger.service.js`** (getPassengerSocketKey y sala).

---

## 5. ¿Solo se modifica la app del pasajero?

| Dónde | Qué aplica |
|-------|-------------|
| **App del pasajero** | Todo lo descrito en este documento: conectar Socket tras crear viaje (§1.2), escuchar `trip:accepted` / `trip:status` / `trip:driver_location`, mostrar overlay “Buscando conductor”, card de estado y marcador del conductor. Las correcciones recientes (llamar a `connect()` en el sheet de cotización) fueron **solo en la app del pasajero**. |
| **App del conductor** | Este documento **no** define el contrato del conductor. En la app del conductor se debe: conectar Socket con token de conductor, enviar `location:update`, escuchar `trip:offer`, emitir `trip:accept` / `trip:reject`, y manejar `trip:accepted`, `trip:arrived`, `trip:started`, `trip:completed`, etc. Ver lista de eventos en `FLUTTER-WEBSOCKET-EVENTS.md` y la implementación en `texi_driver_app`. |
| **Backend** | Emitir a la sala del pasajero (`passenger:${key}`) los eventos de §2; opcionalmente enriquecer `trip:accepted` con datos del conductor (nombre, placa, color, modelo). |

### 5.1 Resumen: qué revisar en cada app

**En la app del pasajero (según este documento):**

1. Tras “Solicitar viaje” (en el sheet de precios o en la pantalla de confirmación), se llama `PassengerRealtimeController.connect(tripId, quote)` y se navega o permanece en la pantalla del mapa.
2. En consola (debug) aparecen `[PASSENGER_RT] Conectando Socket.IO para tripId=...` y `[PASSENGER_RT] conectado a ...`.
3. La pantalla del mapa muestra el overlay “Buscando conductor” mientras `status == 'searching'` o mientras `connecting == true`.
4. Al recibir `trip:accepted`, desaparece el overlay y aparece la card de estado (“Conductor en camino”); si el backend envía `driverName`, `carColor`, `carPlate`, `carModel`, se muestran en la card.
5. Al recibir `trip:status` con `arrived` / `started` / `completed`, la card actualiza el texto y el icono. Cuando `trip:status.isFinal == true` (completed/cancelled/expired), la app debe considerar que el viaje terminó y volver a estado “sin viaje activo” (permitir un nuevo pedido).
6. Al recibir `trip:driver_location`, el marcador del conductor en el mapa se actualiza con `lat`/`lng`.
7. Al cancelar la búsqueda (botón en el overlay o “Cancelar” en error de conexión), la app llama **`POST /passengers/trips/:tripId/cancel`** para marcar el viaje y las ofertas como cancelados en servidor; luego `disconnect()`, limpieza de almacenamiento y `reset()`. Si el POST falla (red), se muestra error y **no** se limpia el estado local para poder reintentar.

**Dónde está implementado en la app del pasajero:**

| Punto | Archivo / lugar |
|-------|------------------|
| `connect(tripId, quote)` tras crear viaje | `trip_request_screen.dart` → `_QuoteBottomSheet._requestTrip()`; `trip_confirm_screen.dart` → `_requestTrip()` |
| Logs “Conectando” / “conectado” | `passenger_realtime_controller.dart` → `connect()` y `socket.onConnect` |
| Overlay “Buscando conductor” y card de estado | `trip_request_screen.dart` → `isSearchingDriver`, `isTripActive`, `_SearchingDriverOverlay`, `_TripStatusCard` |
| Marcador del conductor | `trip_request_screen.dart` → `markers` con `driverLat`/`driverLng` de `passengerRealtimeProvider` |
| Cancelar búsqueda / abandonar sin socket | `trip_request_screen.dart` → `_cancelSearchingTrip()` (`TripsApi.cancelPassengerTrip`) desde `_SearchingDriverOverlay` y `_ConnectionErrorOverlay` |

**En la app del conductor (fuera de este contrato):**

- Conectar Socket con JWT de conductor y enviar `location:update` cuando está “en línea”.
- Escuchar `trip:offer` y mostrar UI para aceptar/rechazar; emitir `trip:accept` / `trip:reject`.
- Escuchar `trip:accepted` (con origen/destino si el backend los envía) y mostrar ruta en mapa.
- Emitir `trip:arrived`, `trip:started`, `trip:completed` según el flujo del viaje.
- Manejar `trip:rejected`, `trip:error`, `trip:cancelled`, etc.

Si se quiere un documento equivalente para la app del conductor (contrato conductor–backend), se puede crear uno aparte siguiendo la misma estructura: flujo de pantalla, eventos que recibe/emite, payloads y comprobaciones.
