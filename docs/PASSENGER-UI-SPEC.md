# Passenger UI Spec (v1)

Objetivo: UX moderna, limpia, dark premium, lectura rapida, baja fatiga visual e interaccion intuitiva.

## 1) Design Tokens Base

- Espaciado: `4 / 8 / 12 / 16 / 20 / 24`
- Radios: `12 / 16 / 20`
- Targets tactiles: minimo `44x44`
- Sombras: suaves, blur medio, sin contraste agresivo
- Duraciones animacion: `200–300ms` (micro), `350–450ms` (entrada relevante)
- Curvas: `easeOutCubic` o equivalentes suaves

## 2) Jerarquia Visual

- Titulos: peso alto, contraste fuerte, max 1 idea por bloque
- Subtitulos: tono neutro, soporte contextual
- Cards: borde sutil + superficie elevada, sin ruido visual
- CTA principal: 1 por pantalla o bloque

## 3) Componentes Base Unificados

- `AppBar` consistente (titulo claro + acciones acotadas)
- `PremiumStateView` para estados `empty/error/offline`
- `PremiumSkeletonBox` para carga
- Botones con `TexiScalePress`
- Inputs con estados claros (normal/focus/error)

## 4) Contrato Visual de Foto de Perfil

- Principal: `profilePhotoUrl`
- Fallback temporal: `picture_profile`
- Debe contemplar: `profilePhotoExpiresAt` + refresh por REST
- Fallback UX: iniciales premium sin salto visual

## 5) Criterios UX de Calidad (Definition of Done)

- Consistente en flujo completo
- Legible con text scale alto
- Accesible (AA minima)
- Sin regresiones visuales ni de interaccion
- Estados de red cubiertos (loading/empty/error/offline)
