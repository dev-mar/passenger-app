# Assets – Organización y PNG vs SVG

## Dónde está cada cosa

| Carpeta | Uso |
|---------|-----|
| `assets/images/` | Logos, ilustraciones, imágenes de pantallas. |
| `assets/icons/` | Icono de la app (launcher), iconos pequeños de UI si los tienes. |

Las rutas exactas se definen en **`lib/core/constants/app_assets.dart`**. Si mueves o renombras un archivo, cambia solo ahí.

---

## PNG vs SVG – Cuándo usar cada uno

| Formato | Conviene para | Ventaja |
|---------|----------------|---------|
| **SVG** | Logo, iconos, iconografía de marca | Escala bien en cualquier tamaño, un solo archivo, nítido en todas las pantallas. |
| **PNG** | App icon (launcher), fotos, gráficos muy detallados | Compatible en todas partes; las tiendas suelen pedir PNG para el icono (ej. 1024×1024). |

**Recomendación para Texi:**

- **Logo dentro de la app (Splash, AppBar):** usar **SVG** si lo tienes. Ya está soportado con `flutter_svg`; en el código se usa `logoSvg` y, si no existe, se usa el PNG `logo` (TEXI_ama@2x.png).
- **Icono de la app (Android/iOS launcher):** dejar en **PNG** (ej. `app_icon.png` 1024×1024).
- El resto de variantes (TEXI_ama_negro, TEXI_positivo, etc.) pueden quedarse en PNG para usarlas donde haga falta (por ejemplo en fondos claros u otros diseños).

---

## Cómo organizar (opcional)

Si quieres ordenar más:

1. **Renombrar el SVG:** `Mesa de trabajo 1.svg` → **`logo.svg`** (evita espacios y nombres largos). Así en código se usa `AppAssets.logoSvg`.
2. **Dejar los PNG como están** en `assets/images/`. Los nombres con `@2x` están bien; en Flutter se referencian tal cual.
3. **Opcional:** crear subcarpetas, por ejemplo `assets/images/logo/` y meter ahí todas las variantes del logo. En ese caso actualiza las rutas en `app_assets.dart`.

No es obligatorio reorganizar; con la estructura actual la app ya puede usar todos los assets.

---

## Qué imagen se usa dónde (por defecto)

| Lugar | Asset por defecto | Motivo |
|-------|-------------------|--------|
| **Splash** | Primero intenta `logo.svg`; si no existe, `TEXI_ama@2x.png` | Fondo negro; logo amarillo o blanco se ve bien. |
| **AppBar / resto de app** | Mismo logo que en Splash (o la variante que prefieras) | Coherencia de marca. |
| **App icon (launcher)** | `assets/icons/app_icon.png` | Lo pide la configuración de Android/iOS. |

Si en alguna pantalla necesitas otra variante (por ejemplo fondo blanco), usa en ese widget la constante que corresponda: `AppAssets.logoPositivo`, `AppAssets.logoDark`, etc.

---

## Si falta un archivo

- Si **no tienes** `logo.svg`, no hace falta crearlo: la app usa el PNG `TEXI_ama@2x.png` en Splash.
- Si **añades** `logo.svg` (renombrando el SVG que tienes), la Splash lo usará en cuanto esté en `assets/images/logo.svg` y la ruta en `app_assets.dart` sea `logoSvg`.
