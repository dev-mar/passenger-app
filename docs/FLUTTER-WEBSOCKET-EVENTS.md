# Referencia de eventos WebSocket para Flutter

Documento único para el equipo Flutter: todos los eventos Socket.IO del sistema, dirección, payload y uso. Incluye cómo mostrar al conductor en el mapa del pasajero.

---

## 1. Cómo usar esta referencia

- **Cliente → Servidor:** la app **emite** (`socket.emit(...)`).
- **Servidor → Cliente:** la app **escucha** (`socket.on(...)`).
- **Rol:** Conductor (C) o Pasajero (P). Cada app solo usa los eventos de su rol.

Para más detalle de conexión, JWT y ejemplos de código, ver **`FLUTTER-SOCKET-INTEGRATION.md`**.

---

## 2. Eventos: Conductor (app emite → servidor escucha)

La app del **conductor** debe emitir estos eventos cuando corresponda.

| Evento | Payload (objeto) | Uso en Flutter |
|--------|-------------------|----------------|
| **`location:update`** | `{ "lat": double, "lng": double, "bearing": double?, "speed": double? }` | Enviar cada 3–5 s (o al mover) para que el backend actualice la posición. Obligatorio para recibir ofertas y para que el pasajero reciba en tiempo real la posición del conductor en su mapa (`trip:driver_location`). |
| **`driver:setAvailability`** | `{ "availability": "available" \| "busy" \| "on_break" }` | Al cambiar modo (disponible / en viaje / pausa). El backend también marca `busy` al aceptar y `available` al completar/cancelar. |
| **`ping`** | `{ "t": timestamp }` opcional | Mantener conexión; el servidor responde `pong` o por ack. |
| **`trip:accept`** | `{ "tripId": "uuid" }` | El conductor acepta la oferta. Enviar al tocar "Aceptar" en la pantalla de oferta. |
| **`trip:reject`** | `{ "tripId": "uuid" }` | El conductor rechaza la oferta. |
| **`trip:arrived`** | `{ "tripId": "uuid" }` | El conductor llegó al punto de recogida. |
| **`trip:started`** | `{ "tripId": "uuid" }` | El conductor inició el viaje (pasajero a bordo). |
| **`trip:completed`** | `{ "tripId": "uuid" }` | El conductor finalizó el viaje. |

**Ejemplo Dart (emitir):**

```dart
// Ubicación (conductor)
socket.emit('location:update', {
  'lat': position.latitude,
  'lng': position.longitude,
  'bearing': position.heading ?? 0,
  'speed': speed ?? 0,
});

// Aceptar oferta
socket.emit('trip:accept', { 'tripId': tripId });

// Llegó a recogida
socket.emit('trip:arrived', { 'tripId': tripId });
```

---

## 3. Eventos: Servidor → Conductor (app escucha)

La app del **conductor** debe registrar listeners para estos eventos.

| Evento | Payload (resumen) | Uso en Flutter |
|--------|-------------------|----------------|
| **`connection:ack`** | `{ ok, serverTime, profile, status, wallet, hasActiveTrip, activeTrip }` | Al conectar. Guardar `profile.driverId`, `status.availability`, `activeTrip` si hay viaje en curso. |
| **`trip:offer`** | `{ tripId, offeredPrice?, etaMinutes? }` | Nueva oferta de viaje. Mostrar pantalla de oferta y botones Aceptar/Rechazar. |
| **`trip:accepted`** | `{ tripId, driverId, status, estimatedPrice, createdAt, updatedAt }` | Confirmación de que su aceptación se aplicó. Navegar a pantalla de “en camino a recogida”. |
| **`trip:rejected`** | `{ success, tripId }` | Confirmación de rechazo. |
| **`trip:arrived`** / **`trip:started`** / **`trip:completed`** | Objeto con `tripId`, `status`, `passengerId`, `driverId`, `estimatedPrice`, `createdAt`, `updatedAt` | Eco del cambio de estado que él envió. Actualizar UI (ej. “Viaje iniciado”, “Viaje finalizado”). |
| **`trip:error`** | `{ code, message }` | Error en accept/reject o cambio de estado. Mostrar mensaje al usuario. |
| **`trip:cancelled`** | `{ tripId, reason? }` | El viaje fue cancelado (por pasajero o por el conductor). Actualizar estado y volver a disponibilidad. |
| **`driver:availability_ack`** | `{ ok: true, availability }` | Disponibilidad actualizada correctamente. |
| **`driver:availability_error`** | `{ ok: false, code, message?, retryAfterSec? }` | Error o rate limit. Códigos: `INVALID_AVAILABILITY`, `RATE_LIMITED`. |
| **`pong`** | `{ t, clientT? }` | Respuesta a `ping`. |
| **`location:ack`** | `{ success: true, t }` | Ubicación recibida por el servidor. |
| **`gps:error`** | `{ message, code }` | Error en `location:update` (payload inválido, coordenadas fuera de rango, etc.). |

**Ejemplo Dart (escuchar):**

```dart
socket.on('connection:ack', (data) {
  if (data['ok'] == true) {
    final profile = data['profile'];
    final status = data['status'];
    // profile.driverId, status.availability, status.isOnline
  }
});

socket.on('trip:offer', (data) {
  final tripId = data['tripId'];
  final offeredPrice = data['offeredPrice'];
  final etaMinutes = data['etaMinutes'];
  // Mostrar pantalla de oferta
});

socket.on('trip:accepted', (data) {
  // Navegar a "en camino a recogida"
});

socket.on('trip:status', (data) { /* no se usa para conductor; ver trip:arrived/started/completed */ });
```

---

## 4. Eventos: Pasajero (solo escucha; no emite eventos de viaje por Socket)

El **pasajero** no emite eventos de viaje por WebSocket. Crea/cancela viajes por **REST** (`POST /passengers/trips`, `POST .../cancel`). Por Socket solo **escucha** estos eventos.

### 4.1 Contrato de eventos para pasajero

| Evento | Payload (resumen) | Uso en Flutter |
|--------|-------------------|----------------|
| **`trip:accepted`** | `{ tripId, driverId, status, fullName?, driverName?, username?, carColor?, carPlate?, carModel?, estimatedPrice?, createdAt?, updatedAt? }` | Un conductor aceptó el viaje. Mostrar tarjeta con **nombre de perfil** del conductor (`fullName`) y datos del vehículo (color, modelo, placa), más el estado “Conductor en camino”. La app hace fallback a `driverName` / `driver_name` y, como último recurso, `username`. |

| **`trip:status`** | `{ tripId, status, driverId?, updatedAt, reason? }` | Cambio de estado: `accepted`, `arrived` (llegó a recogida), `started` (viaje iniciado), `completed` (viaje terminado), `cancelled`, `expired`. La app actualiza la card de estado; cuando llega `arrived` reproduce un tono de alerta del sistema; cuando llega `completed` abre el sheet de calificación y, al terminar, resetea el mapa para permitir nuevas solicitudes. |

| **`trip:driver_location`** | `{ tripId, lat, lng, bearing, speed, updatedAt }` | Posición en tiempo real del conductor (solo cuando el viaje está en `accepted`, `arrived` o `started`). Actualiza el marcador del conductor en el mapa del pasajero. |

**Mapa de campos para la card del pasajero (`trip:accepted`):**

- **Nombre visible del conductor:** `fullName` → si no existe, usar `driverName` / `driver_name` → si no, `username`.
- **Color del vehículo:** `carColor` o `car_color`.
- **Placa:** `carPlate`, `car_plate` o `plate`.
- **Modelo:** `carModel` o `car_model`.

### 4.2 Flujo de estados (pasajero)

1. **`trip:accepted`**
   - UI: overlay “Buscando conductor” desaparece; aparece card con:
     - “Conductor en camino”.
     - Nombre del conductor (`fullName`).
     - Color, modelo y placa del vehículo.

2. **`trip:status`**
   - `status = 'accepted'`: se mantiene card de “Conductor en camino”.
   - `status = 'arrived'`:
     - Sonido: la app reproduce `SystemSound.play(SystemSoundType.alert)` (tono del sistema).
     - UI: card pasa a “El conductor llegó”.
   - `status = 'started'`: card muestra “Viaje en curso”.
   - `status = 'completed'`:
     - UI: card muestra “Viaje finalizado”.
     - Se abre sheet de calificación (5 estrellas) para evaluar al conductor.
     - Al enviar u omitir la calificación, la app:
       - Desconecta el socket (`disconnect()`).
       - Resetea el estado de solicitud (`tripRequestProvider.reset()`).
       - Limpia destino, ruta y errores locales en el mapa, dejando la pantalla lista para un **nuevo viaje**.
   - `status = 'cancelled'` / `status = 'expired'`:
     - La app puede tratarlo como viaje finalizado (ocultar overlay, volver al estado libre). Si el backend envía `reason`, se puede mostrar un mensaje más específico.

3. **`trip:driver_location`**
   - Mientras `status` ∈ `{ 'accepted', 'arrived', 'started' }`, la app:
     - Actualiza `driverLat` / `driverLng` en el estado.
     - Dibuja / mueve el marcador del conductor en el mapa.
   - Al pasar a `completed` / `cancelled` / `expired`, el backend deja de enviar este evento y la app debe ocultar el marcador del conductor.

**Ejemplo Dart (pasajero):**

```dart
socket.on('trip:accepted', (data) {
  final tripId = data['tripId']?.toString();
  if (tripId == null || tripId != activeTripId) return;

  final driverName = data['fullName']?.toString()
    ?? data['driverName']?.toString()
    ?? data['driver_name']?.toString()
    ?? data['username']?.toString();

  final carColor = data['carColor']?.toString() ?? data['car_color']?.toString();
  final carPlate = data['carPlate']?.toString()
    ?? data['plate']?.toString()
    ?? data['car_plate']?.toString();
  final carModel = data['carModel']?.toString() ?? data['car_model']?.toString();

  // Actualizar estado: status='accepted', driverName, carColor, carPlate, carModel
});

socket.on('trip:status', (data) {
  final tripId = data['tripId']?.toString();
  final status = data['status']?.toString();
  if (tripId == null || status == null || tripId != activeTripId) return;

  if (status == 'arrived') {
    SystemSound.play(SystemSoundType.alert); // tono del sistema
    // UI: “El conductor llegó”
  } else if (status == 'started') {
    // UI: “Viaje en curso”
  } else if (status == 'completed') {
    // UI: “Viaje finalizado” + abrir sheet de calificación
  }

  // Guardar status en el estado global (provider) para que TripStatusCard se actualice.
});

socket.on('trip:driver_location', (data) {
  final tripId = data['tripId']?.toString();
  if (tripId == null || tripId != activeTripId) return;
  final lat = (data['lat'] as num).toDouble();
  final lng = (data['lng'] as num).toDouble();
  final bearing = (data['bearing'] as num?)?.toDouble() ?? 0.0;

  // Actualizar marcador del conductor en el mapa: LatLng(lat, lng), rotation: bearing.
});
```

---

## 5. Ver al conductor en el mapa del pasajero

**Pregunta:** ¿Cómo puede el pasajero ver en tiempo real la posición del conductor en el mapa?

**Implementado en el backend:** 

- El conductor envía su posición con **`location:update`** (Cliente → Servidor).
- Si ese conductor tiene un viaje activo con un pasajero (estado `accepted`, `arrived` o `started`), el servidor emite a la sala del pasajero el evento **`trip:driver_location`** con la posición actual.
- La app del pasajero debe escuchar **`trip:driver_location`** y actualizar el marcador del conductor en el mapa.

**Payload del evento `trip:driver_location` (Servidor → Pasajero):**

| Campo      | Tipo   | Descripción                          |
|-----------|--------|--------------------------------------|
| `tripId`  | string | UUID del viaje                       |
| `lat`     | number | Latitud                              |
| `lng`     | number | Longitud                             |
| `bearing` | number | Rumbo/orientación (grados, 0–360)    |
| `speed`   | number | Velocidad (unidad según backend)     |
| `updatedAt` | string | ISO 8601 de la actualización       |

**Ejemplo de uso en Flutter:**

```dart
// Pasajero: actualizar posición del conductor en el mapa (solo cuando el viaje está aceptado/en curso)
socket.on('trip:driver_location', (data) {
  final tripId = data['tripId'] as String;
  final lat = (data['lat'] as num).toDouble();
  final lng = (data['lng'] as num).toDouble();
  final bearing = (data['bearing'] as num?)?.toDouble() ?? 0.0;
  // Actualizar marcador del conductor en el mapa: LatLng(lat, lng), rotation: bearing
  // Opcional: usar data['speed'] y data['updatedAt'] para UI (ETA, “actualizado hace X s”)
});
```

**Cuándo se deja de compartir:** El evento solo se envía cuando el viaje está en estado `accepted`, `arrived` o `started`. En cuanto el viaje pasa a `completed`, `cancelled` o `expired`, el backend **deja de emitir** `trip:driver_location` a ese pasajero. La app debe ocultar el marcador del conductor al recibir `trip:status` con `completed` o `cancelled`.

**Conductores cercanos (REST, no WebSocket):** Para mostrar en el mapa conductores disponibles en un radio de la posición del pasajero (antes de solicitar viaje), la app debe llamar al endpoint REST **`GET /passengers/nearby-drivers`** con query `lat`, `lng`, y opcionalmente `radiusKm`, `limit`. La respuesta es `{ "drivers": [ { "driverId", "lat", "lng", "distanceKm" }, ... ] }`. En Flutter: usar Dio (o el cliente HTTP que tengan), pasar el JWT del pasajero en `Authorization: Bearer ...`, y dibujar un marcador por cada conductor en el mapa. **Ejemplo completo de request/response y código Dart:** ver **`PASSENGER-API-INTEGRATION.md`** § 2.5 (Endpoint conductores cercanos y ejemplo de uso en Flutter).

---

## 6. Resumen rápido por rol

| Rol | Emite (emit) | Escucha (on) |
|-----|--------------|--------------|
| **Conductor** | `location:update`, `driver:setAvailability`, `ping`, `trip:accept`, `trip:reject`, `trip:arrived`, `trip:started`, `trip:completed` | `connection:ack`, `trip:offer`, `trip:accepted`, `trip:rejected`, `trip:arrived`/`started`/`completed`, `trip:error`, `trip:cancelled`, `driver:availability_ack`/`_error`, `pong`, `location:ack`, `gps:error` |
| **Pasajero** | — (viajes por REST) | `trip:accepted`, `trip:status`, `trip:driver_location` |

---

## 7. Documentos relacionados

- **`PASSENGER-REALTIME-BACKEND-CONTRACT.md`** – Contrato pasajero–backend: cómo muestra la app los estados, qué debe emitir el backend (salas, payload de trip:accepted con datos del conductor) y cómo validar.
- **`FLUTTER-SOCKET-INTEGRATION.md`** – Conexión, JWT, path, ejemplos de código y flujos.
- **`PASSENGER-API-INTEGRATION.md`** – REST para pasajero (quote, crear viaje, cancelar, GET estado, conductores cercanos con ejemplo Dart).
