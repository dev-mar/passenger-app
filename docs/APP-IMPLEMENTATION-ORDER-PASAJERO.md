## Plan de implementación – App Pasajero

Este documento sirve para ordenar el trabajo pendiente de Flutter (pasajero) según lo que ya está implementado y lo que falta.

---

### 0) Referencias que NO deben duplicarse

- Contrato HTTP (REST): `app_texi_WebSocket/docs/API-CONTRACT.md`
- Contrato WebSocket (pasajero): `texi_passenger_app/docs/PASSENGER-REALTIME-BACKEND-CONTRACT.md`

---

### 1) Ya tenemos (alineado con backend)

#### 1.1 REST

- Cotización: `POST /passengers/trips/quote`
- Crear viaje + disparar ofertas: `POST /passengers/trips`
- Listar conductores cercanos: `GET /passengers/nearby-drivers`
- Sync de estado por tripId: `GET /passengers/trips/:tripId` (respuesta puede incluir **`driverLocation`** opcional; ver `PASSENGER-REALTIME-BACKEND-CONTRACT.md` § 0.1)
- Cancelar viaje: `POST /passengers/trips/:tripId/cancel`

#### 1.2 WebSocket (pasajero)

- Conexión Socket a la sala `passenger:${passengerId}`
- Eventos:
  - `trip:accepted` (con campos del conductor/vehículo enriquecidos)
  - `trip:status` (incluye nuevos campos aditivos `isFinal` y `endedReason`)
  - `trip:driver_location`

#### 1.3 UI / flujo (importante)

- Al recibir `status=completed`, se muestra sheet de calificación.
- Si el usuario omite o cierra el sheet, el flujo se resetea para poder pedir otro viaje.
- Si el viaje llega a `cancelled/expired`, el flujo se resetea automáticamente.

---

### 2) Falta / tareas por implementar (orden sugerido)

> Nota: las tareas de “falta” se enfocan en evitar que el pasajero se quede bloqueado o “pegado” si se desconecta y vuelve.

#### 2.1 Rehidratación tras reconectar (IMPORTANTE)

- Problema actual:
  - El backend **no reenvía automáticamente** el último `trip:status`/`trip:accepted` al reconectar WebSocket.
- Tarea:
  - Al abrir la app con un `tripId` guardado, hacer sync con:
    - `GET /passengers/trips/:tripId`
  - Luego actualizar el estado local (provider) usando la respuesta REST.

#### 2.2 Manejo de reconexión cuando faltó `trip:accepted`

- Problema:
  - Si reconectas después de la etapa `accepted`, podrías no recibir `trip:accepted`.
- Tarea:
  - Alineación UI:
    - Garantizar que la tarjeta de “Conductor en camino” se pueda construir con REST o por eventos posteriores.
- Backend (ya parcialmente cubierto):
  - `GET /passengers/trips/:tripId` puede devolver **`driverLocation`** (opcional) para reforzar el mapa tras reconexión/polling; ver § 0.1 del contrato pasajero.
- Recomendación (backend opcional, futuro):
  - Si hace falta **más** que posición (p. ej. nombre/placa/vehículo en el mismo GET), evaluar ampliar `data` o un endpoint dedicado — hoy parte de eso llega por **`trip:accepted`** en socket.

#### 2.3 Estado final (isFinal / endedReason)

- Tarea:
  - Aunque hoy el reset se puede hacer por `status`, implementar en la app el uso de:
    - `trip:status.isFinal`
    - `trip:status.endedReason`

Esto vuelve el comportamiento más robusto para `cancelled/expired` y para futuros estados.

#### 2.4 Bloqueo de nuevas solicitudes mientras el viaje no está cerrado

- Confirmar regla:
  - Si `tripState.tripId != null` y `rtState.status` no es `completed/cancelled/expired`, no permitir `createTrip`.
- Si `createTrip` llega igual desde UI:
  - Validar antes de llamar `POST /passengers/trips`.

---

### 3) Rating (calificación) – punto a coordinar

- Hoy:
  - El backend **no implementa** (según la evidencia encontrada) un modelo persistente de “pending/submitted/skipped” de rating.
  - El sheet resetea UI, pero no cambia un estado persistente del lado servidor.
- Tarea futura:
  - Si el negocio necesita recordar “rating pendiente” tras cerrar/reabrir:
    - Implementar persistencia y un endpoint para:
      - `POST /passengers/trips/:tripId/rating` o similar
      - y `GET` del estado de rating.

---

### 4) Pruebas mínimas recomendadas para el pasajero

1. Aceptar viaje y luego desconectar/reconectar app.
2. Viaje en curso: reconectar sin perder eventos.
3. Viaje `completed`: cerrar sheet con gesto (swipe/tap fuera) y confirmar que se resetea.
4. Viaje `cancelled/expired`: confirmar que se desbloquea UI para pedir otro viaje.

