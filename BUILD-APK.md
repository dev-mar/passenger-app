# Generar APK para instalar en el celular

Para probar en un dispositivo real **sin instalar desde el IDE** (evita problemas de metadata o registro cuando luego hagas pruebas formales), genera el archivo APK y instálalo manualmente.

---

## Opción recomendada: APK de debug (pruebas)

No requiere configuración de firma. Genera un APK que puedes copiar al celular e instalar.

```bash
cd texi_passenger_app
flutter build apk --debug
```

**Dónde queda el APK:**

- **Ruta:** `build/app/outputs/flutter-apk/app-debug.apk`
- Desde la raíz del proyecto: `texi_passenger_app/build/app/outputs/flutter-apk/app-debug.apk`

**Instalación en el celular:**

1. Copia `app-debug.apk` al teléfono (USB, correo, Drive, etc.).
2. En el celular, abre el archivo y acepta instalar desde “orígenes desconocidos” si lo pide.
3. Instala. No reemplaza una versión de Play Store; es una instalación independiente para pruebas.

---

## Opción: APK de release (más cercano a producción)

Para un APK listo para distribuir (o probar como “release”) hace falta tener configurada la firma en Android. Si ya tienes keystore:

```bash
flutter build apk --release
```

El archivo queda en: `build/app/outputs/flutter-apk/app-release.apk`

Si no has configurado firma, Flutter usará un keystore de debug para release en algunos casos; para publicar en Play Store más adelante tendrás que configurar tu propio keystore en `android/app/build.gradle`.

---

## Resumen

| Objetivo              | Comando                    | Archivo generado   |
|-----------------------|----------------------------|---------------------|
| Probar en el celular  | `flutter build apk --debug` | `app-debug.apk`    |
| Build de release      | `flutter build apk --release` | `app-release.apk` |

Siempre que quieras una nueva versión para instalar a mano, vuelve a ejecutar el comando; el APK se regenera en la misma ruta.
