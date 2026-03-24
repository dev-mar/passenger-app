## Referencias de backend para la app de pasajero

Este documento indica **qué archivos del backend** debe usar el equipo de Flutter (pasajero) como referencia al implementar o ajustar funcionalidades.

---

### 1. Contrato HTTP (REST)

- **Fuente de verdad del contrato de la API REST**:
  - `app_texi_WebSocket/docs/API-CONTRACT.md`

Usar este archivo para:

- Ver **endpoints disponibles** (`/passengers/...`, `/drivers/...`, `/location/...`).
- Conocer el **formato estándar de respuesta**:
  - Éxito:
    ```json
    {
      "success": true,
      "status_code": 200,
      "code": "ALGUN_CODIGO",
      "message": "Texto legible",
      "data": { ... }
    }
    ```
  - Error:
    ```json
    {
      "success": false,
      "status_code": 400,
      "code": "ALGUN_ERROR",
      "message": "Descripción del error",
      "error": { "message": "detalle opcional" }
    }
    ```
- Ver **códigos (`code`) y status HTTP** esperados para:
  - Cotización de viajes.
  - Creación de viajes.
  - Cancelaciones, etc.

---

### 2. Contrato tiempo real (WebSocket) – Pasajero

- **Documento principal**:
  - `texi_passenger_app/docs/PASSENGER-REALTIME-BACKEND-CONTRACT.md`

Usar este archivo para:

- Ver la lista de **eventos Socket.IO** que recibe/emite la app de pasajero:
  - `trip:accepted`, `trip:status`, `trip:driver_location`, etc.
- Entender **qué debe hacer la app** con cada evento:
  - Estado de UI (“Buscando conductor”, “Conductor en camino”, “Viaje en curso”…).
  - Cómo mostrar la información del conductor:
    - `driverName`, `carModel`, `carPlate`, etc. (enviados en `trip:accepted`).

---

### 3. Documentos complementarios del backend útiles

Según la funcionalidad que se implemente, también son relevantes:

- `app_texi_WebSocket/docs/PRODUCTION-TEST-GUIDE.md`
  - Para entender el flujo de pruebas end‑to‑end en Postman/Swagger.
- `app_texi_WebSocket/docs/LOCATION-ZONE-VALIDATION.md`
  - Para diagnosticar problemas de cobertura (ciudades / zonas de servicio).

---

### 4. Resumen para el equipo de pasajero

Al implementar o modificar funcionalidades:

- **Para llamadas HTTP** (login, cotizar, crear viaje, cancelar, etc.):
  - Revisar siempre `app_texi_WebSocket/docs/API-CONTRACT.md`.
- **Para tiempo real (Socket.IO)**:
  - Revisar `texi_passenger_app/docs/PASSENGER-REALTIME-BACKEND-CONTRACT.md`.

Estos dos documentos son la referencia principal para mantenerse alineados con el backend.+
