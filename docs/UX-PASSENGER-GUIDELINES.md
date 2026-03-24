# Guía UX — app pasajero (Texi)

Objetivo: **misma línea visual y de interacción** en toda la app; las pantallas nuevas deben reutilizar estos bloques.

## Tokens de movimiento (`lib/core/ui/texi_motion.dart`)

| Token        | Uso |
|-------------|-----|
| `TexiMotion.fast` | Botones, chips |
| `TexiMotion.medium` | Paneles / sheets |
| `TexiMotion.emphasized` | Entradas destacadas (SnackBars) |
| `TexiMotion.pulseLoop` | Iconos de estado |

## Micro-interacción en botones (`TexiScalePress`)

- Envuelve **CTAs principales** (`FilledButton`, `FloatingActionButton`, `FilledButton.icon`) para una ligera escala al presionar (~97%).
- Import: `import '../../core/ui/texi_scale_press.dart';` (ajusta la ruta según el feature).

```dart
TexiScalePress(
  child: FilledButton(
    onPressed: ...,
    child: Text(...),
  ),
)
```

## Feedback háptico y audio (`TexiUiFeedback`)

- **`TexiUiFeedback.lightTap()`** — selección / tap en botón secundario.
- **`TexiUiFeedback.softImpact()`** — confirmación suave.
- **`TexiUiFeedback.instance.playSoftChime()`** — sonido discreto vía `SystemSound` (sin plugins nativos extra; evita fallos de build Kotlin en Windows con proyecto y pub cache en distintas unidades).

Reservar el **chime** para momentos informativos importantes (p. ej. recuperación de viaje), no en cada tap.

## SnackBar de recuperación de viaje

- Implementación: `lib/features/trip/trip_recovery_feedback.dart` (entrada animada + pulso en icono + sonido + botón con `TexiScalePress`).
- El aspecto base de **todos** los SnackBars viene de `AppTheme.dark` → `snackBarTheme` (`lib/core/theme/app_theme.dart`).

## Tema global (`AppTheme.dark`)

- **ColorScheme** con `ColorScheme.fromSeed` + overrides de marca (amarillo Texi, superficies oscuras).
- **SnackBar**: flotante, bordes 18, `surfaceContainerHighest`, tipografía legible.
- **Diálogos / bottom sheets**: radios 24 / 28, manilla en sheets, sombra suave.
- **Cards**: radio 16, elevación 3.
- **Botones**: `Filled` / `Outlined` / `Text` alineados (radio 14, padding consistente).
- **Ripple**: `InkSparkle.splashFactory` (Material 3).
- **Progreso**: track oscuro + acento primario.
- **Transiciones de página**: zoom (Android), Cupertino (iOS/macOS).

Nuevas pantallas deben **preferir el tema** (`Theme.of(context)`) antes de hardcodear colores.

## Próximas mejoras coherentes

- Reutilizar `TexiMotion` en animaciones custom.
- Evitar duplicar duraciones mágicas (`Duration(milliseconds: …)`) sueltas en widgets; preferir tokens.
