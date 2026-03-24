# Regla de trabajo — UI (app pasajero Texi)

Documento para **quien integre código de interfaz**: estructura, convenciones y dónde colocar cada pieza. Objetivo: **misma línea visual**, **menos duplicidad** y **revisiones más rápidas**.

---

## 1) Principios

1. **Pantallas delgadas, widgets con nombre**: la pantalla orquesta estado y navegación; el detalle visual vive en widgets reutilizables.
2. **Tokens antes que números mágicos**: radios, espaciados, tamaños de icono y tipografía compartida van en `lib/core/theme/app_ui_tokens.dart` (junto con `AppColors` y `AppTheme`).
3. **Texto visible siempre localizable**: claves en `lib/l10n/app_es.arb` y `app_en.arb`; no dejar strings de usuario en español/inglés hardcodeados en widgets.
4. **Tema primero**: colores y estilos base preferir `Theme.of(context)` y `AppTheme.dark`; `AppColors` solo donde el tema no cubre un caso concreto de marca.

---

## 2) Estructura de carpetas (UI)

| Ubicación | Uso |
|-----------|-----|
| `lib/core/theme/` | `app_colors.dart`, `app_theme.dart`, **`app_ui_tokens.dart`** (radios, `AppSpacing`, `AppSizes`, sombras, etc.) |
| `lib/core/widgets/` | Componentes **transversales** a varios features: `PremiumStateView`, `PremiumSkeletonBox`, logos, etc. |
| `lib/core/ui/` | Comportamiento compartido: `TexiScalePress`, `TexiMotion`, barrel `texi_ui.dart` si aplica |
| `lib/core/feedback/` | Háptico / audio: `TexiUiFeedback` |
| `lib/features/<feature>/` | Pantallas y **estado** del feature |
| `lib/features/<feature>/widgets/` | Widgets **específicos** del feature, extraídos para no inflar la pantalla (ej. `trip/widgets/`) |
| `lib/gen_l10n/` | Archivos generados a partir de los `.arb` **no editar a mano** |

**Regla**: si un bloque UI se usa en **más de un feature**, valorar subirlo a `lib/core/widgets/`. Si solo aplica a viaje, perfil, etc., dejarlo en `features/<feature>/widgets/`.

---

## 3) Tokens de diseño (`app_ui_tokens.dart`)

Antes de escribir `BorderRadius.circular(14)` o `SizedBox(height: 12)`, buscar en:

- **`AppRadii`** — esquinas (tarjetas, sheets, chips pill, etc.)
- **`AppSpacing`** — padding y gaps entre elementos
- **`AppSizes`** — alturas de botón, asas de arrastre, avatares, áreas de animación, etc.
- **`AppIconSizes`** — tamaños de iconos coherentes
- **`AppTypography`** — tamaños de texto cuando no basta `TextTheme`
- **`AppBorders`** — grosores de borde
- **`AppElevation`** — elevaciones puntuales (ej. botón orb de cerrar)
- **`AppDurations`** — duraciones reutilizables (animaciones)
- **`AppShadows`** — sombras `const` alineadas con la estética actual

Si el diseño **necesita un valor nuevo** que va a repetirse, **añádelo una vez** aquí con un nombre claro y úsalo en todos los sitios.

El tema global (`AppTheme`) ya consume estos tokens donde se ha alineado; las pantallas nuevas deben **seguir el mismo criterio**.

---

## 4) Componentes y patrones obligatorios

| Necesidad | Qué usar |
|-----------|-----------|
| Estado vacío / error / offline en flujo premium | `PremiumStateView` (`lib/core/widgets/premium_state_view.dart`) |
| Carga tipo skeleton | `PremiumSkeletonBox` |
| CTA con micro-interacción | `TexiScalePress` alrededor del botón |
| Animaciones / duraciones | `TexiMotion` (`lib/core/ui/texi_motion.dart`) |
| Feedback al usuario | `TexiUiFeedback` (háptico; chime solo en hitos, no en cada tap) |

Referencia de producto y jerarquía visual: **`docs/PASSENGER-UI-SPEC.md`**.

Referencia de movimiento, tema y SnackBars: **`docs/UX-PASSENGER-GUIDELINES.md`**.

---

## 5) Internacionalización (i18n)

1. Añadir clave y texto en **`lib/l10n/app_es.arb`** y **`lib/l10n/app_en.arb`**.
2. Ejecutar generación de l10n según el proyecto (`flutter gen-l10n` o el comando que use el repo).
3. En código: `AppLocalizations.of(context)!` o variable `l10n` local; **no** `Text('Hola')` para copy de producto.
4. Placeholders: documentar en `.arb` con `"@clave": { "placeholders": { ... } }` como ya se hace en el proyecto.

---

## 6) Accesibilidad y calidad

Antes de dar por cerrada una pantalla, revisar **`docs/PASSENGER-ACCESSIBILITY-CHECKLIST.md`** (contraste, escalado de texto, targets, semántica donde aplique).

---

## 7) Checklist rápido antes de abrir PR (UI)

- [ ] Sin strings de usuario hardcodeados (salvo debug temporal, luego quitar).
- [ ] Radios / espaciados / iconos preferentemente desde **`app_ui_tokens.dart`**.
- [ ] Estados de carga / error / vacío cubiertos donde el flujo lo requiera.
- [ ] No duplicar bloques grandes de UI: extraer a `widgets/` del feature o a `core/widgets/`.
- [ ] `dart analyze` sin errores en archivos tocados.

---

## 8) Ejemplo de flujo para un feature nuevo

1. Crear pantalla en `lib/features/mi_feature/mi_feature_screen.dart` (principalmente `build` + lógica).
2. Si el `build` supera ~150–200 líneas de UI, extraer secciones a `lib/features/mi_feature/widgets/`.
3. Usar tokens + tema + componentes premium ya existentes.
4. Añadir strings a `.arb` y regenerar l10n.
5. Actualizar rutas en `app_router.dart` si hay navegación nueva.

---

## 9) Documentos relacionados

| Documento | Contenido |
|-----------|-----------|
| `PASSENGER-UI-SPEC.md` | Tonos, jerarquía, componentes base, DoD UX |
| `UX-PASSENGER-GUIDELINES.md` | Tema, motion, TexiScalePress, feedback, SnackBars |
| `PASSENGER-ACCESSIBILITY-CHECKLIST.md` | Revisión accesibilidad |
| `APP-IMPLEMENTATION-ORDER-PASAJERO.md` | Orden sugerido de implementación |

---

*Última alineación con la estructura actual: tokens centralizados en `app_ui_tokens.dart`, widgets de viaje en `lib/features/trip/widgets/`, y tema en `AppTheme.dark`.*
