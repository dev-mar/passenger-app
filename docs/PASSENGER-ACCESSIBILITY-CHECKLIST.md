# Passenger Accessibility Checklist (Pre-Merge)

## Contraste y legibilidad

- [ ] Texto principal cumple contraste AA sobre fondo
- [ ] Texto secundario mantiene legibilidad en dark mode
- [ ] Estados de error usan color + mensaje (no solo color)

## Interaccion

- [ ] Todos los controles tactiles son >= 44x44
- [ ] Existe feedback visual en tap/press
- [ ] Acciones criticas tienen confirmacion clara

## Tipografia y escalado

- [ ] No hay overflow en textScaleFactor alto (1.2 / 1.4 / 1.6)
- [ ] Titulos y botones mantienen jerarquia clara

## Estados UX

- [ ] Loading visible y no bloqueante
- [ ] Empty state con accion sugerida
- [ ] Error state con reintento
- [ ] Offline state con mensaje accionable

## Navegacion y foco

- [ ] Flujo de formularios con `textInputAction` correcto
- [ ] Siguiente campo recibe foco esperado
- [ ] Teclado no tapa CTA principal

## QA visual

- [ ] Pantallas pequenas (height reducido)
- [ ] Pantallas grandes/tablet
- [ ] Modo oscuro
- [ ] Conectividad lenta/intermitente
