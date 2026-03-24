# Contrato para Refresh Token (backend de autenticación)

Para que la app del pasajero mantenga la sesión sin pedir login cada 24 horas, el **servicio de autenticación** (el que expone `POST /auth/login` en `baseUrlAuth`) debe implementar lo siguiente.

## 1. Respuesta de Login

Además de `token` (access token, JWT con validez ej. 24h), la respuesta debe incluir:

- **`refresh_token`** (string): token opaco o JWT de larga duración (ej. 30 días) que solo sirve para obtener un nuevo `token`.
- **`expires_in`** (number, opcional): segundos hasta que vence el `token` (ej. `86400` para 24h).

Ejemplo de cuerpo de respuesta exitosa:

```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "rt_abc123...",
    "expires_in": 86400
  }
}
```

Si no envías `refresh_token` o `expires_in`, la app sigue funcionando como hasta ahora (solo guarda `token` y cuando caduca el usuario debe volver a iniciar sesión).

## 2. Endpoint de refresh

- **Método y ruta:** `POST /auth/refresh` (o la que configuréis; en la app está `AppConfig.refreshPath = '/auth/refresh'`).
- **Body (JSON):**

```json
{
  "refresh_token": "rt_abc123..."
}
```

- **Respuesta exitosa (200):**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "rt_nuevo...",
  "expires_in": 86400
}
```

- `refresh_token` en la respuesta puede ser el mismo (rotación opcional) o uno nuevo (rotación recomendada).
- Si el `refresh_token` es inválido o expiró, devolver **401** (la app llevará al usuario a login).

## 3. Dónde se implementa

- **Backend que gestiona login:** el mismo que hoy devuelve `data.token` en `POST /auth/login` (en vuestro caso el API en `baseUrlAuth`, ej. `http://ec2-3-151-19-233.../api/v1`).
- **No** es el servidor WebSocket (`app_texi_WebSocket`): ese solo valida el JWT que ya le pasa la app; no emite ni refresca tokens.

## 4. Resumen para pedir al equipo backend

Podéis enviar algo así:

> Necesitamos que el API de autenticación (login) soporte refresh token para que la app no cierre sesión a las 24h:
> 1. En la respuesta de **POST /auth/login**, además de `data.token`, incluir `data.refresh_token` (string) y opcionalmente `data.expires_in` (segundos).
> 2. Nuevo endpoint **POST /auth/refresh** que reciba en el body `{ "refresh_token": "..." }` y devuelva `{ "token": "...", "refresh_token": "...", "expires_in": 86400 }`. Si el refresh_token es inválido, responder 401.

La app del pasajero ya está preparada: cuando el backend exponga esto, la app refrescará el token automáticamente al abrir y cuando falte poco para que venza.
