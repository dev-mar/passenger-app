/// Flag de **cambio vistas** (Operador / Seguridad).
///
/// - `true` (default): Operador solo 3 acciones; Conductores verificados en Seguridad.
/// - `false`: layout previo (Operador incluye la lista de verificación).
///
/// Revertir: poner `false` y hot-restart / rebuild de la app.
const bool kPassengerAccountViewsV2 = true;
