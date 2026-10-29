---
description: >
  Usar para auditar código de UI (HTML/CSS/JS, vistas PHP/Blade, componentes)
  contra ~90 reglas de interfaz de Vercel (accesibilidad, foco visible,
  formularios, tipografía, imágenes sin alt, rendimiento, touch, dark mode,
  i18n, copy) MÁS las reglas duras del vault (Lucide, SweetAlert2, Tom Select,
  Flatpickr, Tippy, CSP self-hosted). Devuelve hallazgos `archivo:línea`.
  Activar con "/auditoria-ui", "revisá la UI", "chequeá accesibilidad",
  "auditá el diseño", "¿cumple buenas prácticas?", y antes de entregar UI
  nueva. Sirve igual para páginas públicas y pantallas internas (ERP).
  NO usar para criterio estético / "se ve genérico" (`direccion-arte`),
  animaciones (`animaciones`) ni bugs de lógica (`qa-bug-hunter`).
depends_on:
  - team-context
---

# auditoria-ui — reglas de interfaz, con `archivo:línea`

Revisión mecánica y rápida: no opina de gusto, verifica reglas.

## Pasos

1. **Reglas vigentes**: WebFetch de
   `https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md`.
   Si falla (sin red), usar la copia local
   `references/vercel-web-interface-guidelines.md` (snapshot 2026-10-29,
   MIT) y decirlo en el reporte.
2. **Archivos**: los que indique el usuario; si no, los tocados en el diff
   actual (`git diff --name-only`). Leer por rangos, no completos.
3. **Aplicar** las reglas de Vercel + las del equipo (abajo).
4. **Reportar** en el formato de abajo. Sin preámbulo.

## Reglas del equipo (se suman a las de Vercel)

- Iconos solo Lucide (nunca emojis, FontAwesome, heroicons).
- `alert()`/`confirm()`/`prompt()` nativos → SweetAlert2 (o helpers del
  proyecto, ej. `erpAlert`/`erpConfirm`); toasts con el mixin de SweetAlert2.
- `<select>` con búsqueda o muchas opciones → Tom Select.
- Fechas con rango/formato/locale → Flatpickr, no `type="date"` pelado.
- `title="..."` con contenido formateado → Tippy.js.
- Tablas con orden/búsqueda/paginado → Simple-DataTables.
- CSP `script-src 'self'`: ningún `<script>`/CSS/fuente por CDN, ningún
  handler inline (`onclick=`), ningún `<script>` inline sin nonce.
- Salida dinámica escapada (XSS) y token CSRF en todo `<form>` POST.
- Si existe `Arquitectura/design-system.md` en el vault del proyecto:
  colores, tipografías y radios fuera de sus tokens = hallazgo.

## Formato del reporte

```
## ruta/al/archivo.php
ruta/al/archivo.php:42 - botón solo-ícono sin aria-label
ruta/al/archivo.php:88 - confirm() nativo → SweetAlert2 (regla vault)

## ruta/limpio.css
✓ pass
```

Al final: total por severidad (bloquea / mejora) y "reglas: online" u
"offline (snapshot 2026-10-29)".

## Atribución

Reglas de [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines)
(MIT, `references/LICENSE-vercel`), commit 434b7f9.
