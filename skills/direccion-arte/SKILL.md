---
description: >
  Usar cuando una página pública (landing, sitio institucional, portafolio,
  producto) va a verse "genérica", "hecha por IA", "de plantilla", "todas
  iguales", o ANTES de diseñar un sitio nuevo o un rediseño: elige una
  dirección de arte, escribe el DESIGN.md del proyecto, construye desde una
  captura de referencia (image-to-code) y critica el resultado con capturas a
  1440/768/390 hasta 3 rondas. También pantallas de app (dashboards, ERP) con
  sus propias reglas. Activar con "/direccion-arte", "dale dirección de arte",
  "que no parezca plantilla", "hacelo como esta captura". La usa el agente
  `director-arte`. NO usar para animaciones finas (`animaciones`), auditoría
  de accesibilidad/reglas (`auditoria-ui`) ni SEO (`seo`). Adaptada de
  Leonxlnx/taste-skill (MIT).
depends_on:
  - team-context
---

# direccion-arte — decidir el look antes de construir

Una página hecha por un modelo se parece al promedio de todas: titular
centrado, etiqueta chica arriba, fila de tarjetas con ícono, degradado
suave. Nada está mal y nada fue **decidido**. Esta skill pone las
decisiones primero y las verifica en un navegador real.

El método completo y sus scripts están **sin modificar** en `upstream/`
(taste-skill v2.1, MIT). Este archivo dice cómo lo usa el equipo y qué
reglas del vault ganan. Leé `upstream/SKILL.md` entero la primera vez que
la uses en un proyecto.

`<skill>` = `~/.claude/skills/direccion-arte/upstream`. Requiere Node 22+
y Chrome/Chromium (sirve el de `playwright-cli`). Los scripts no instalan
nada; escriben en `.taste-skill/` del proyecto → agregalo a
`.git/info/exclude`.

## Jerarquía de reglas (ante un choque, gana la de arriba)

1. **ADRs y `design-system.md` del proyecto** (decisiones del cliente).
2. **Reglas globales del vault**: Lucide, SweetAlert2, Tom Select,
   Flatpickr, Tippy, CSP self-hosted, nada de emojis.
3. **House rules de `upstream/SKILL.md`** (sin eyebrows, sin degradados,
   sin tarjetas con ícono, sin glass, ≤2 tipografías…).

Si un ADR pide algo que una house rule prohíbe (ej. grilla de servicios
con íconos Lucide), se respeta el ADR, se corre el inspector con
`--allow <regla>` solo para esa regla y se anota en la sección "Do's and
Don'ts" del `design-system.md`.

## Adaptaciones del equipo sobre el upstream

- **Fuentes**: el upstream propone Google Fonts. Con CSP `'self'`, se
  descargan y se sirven desde los assets del proyecto.
- **Imágenes**: orden = fotos reales del cliente → ilustración propia
  (skill `anatomy-asset` para isométricas, si está activa) → colecciones
  abiertas con `assets.mjs` y crédito en el footer. **Nunca** presentar una
  foto de archivo como el equipo, la flota o las instalaciones del cliente.
- **Prueba social**: jamás inventada (cifras, clientes, testimonios). Igual
  que el upstream.
- **Copy en español**: la regla de "titular en 2 líneas" (~32 caracteres)
  convive con la keyword del H1 de la skill `seo`: la keyword entra en el
  titular y se recorta el resto, no al revés.
- **Movimiento** (paso 9 del upstream): se aplica junto con la skill
  `animaciones`; si chocan, gana `animaciones` en duraciones/easing y el
  upstream en el mínimo de elementos que se mueven.
- **Capturas y navegador**: si `inspect.mjs` no corre, tomar capturas con
  `navegador-qa` (sección "Revisión visual a 3 anchos") y criticarlas igual.

## Modos

| Modo | Cuándo | Pasos |
|---|---|---|
| **Dirección** | Sitio nuevo o rediseño | Upstream pasos 1–5 (inventario del sujeto, argumento, `draw.mjs`, idea, copy) → volcar el resultado en `design-system.md` (plantilla `02-Plantillas/Plantilla-DESIGN.md`) |
| **Desde imagen** | "Hacelo como esta captura" | Ver abajo |
| **Crítica** | Antes de entregar o "revisá el diseño" | `lint.mjs` + `inspect.mjs` → leer TODAS las capturas → `upstream/references/critique.md` → 3 problemas principales, máx. 3 rondas |
| **App** | Dashboard, ERP, panel admin | `upstream/references/app-screens.md` entero, `draw.mjs --app`, `inspect.mjs --app` |

### Modo "Desde imagen" (image-to-code)

1. Leé la captura con Read. Describí en notas: grilla, márgenes, escala
   tipográfica (relación titular/cuerpo), paleta por roles (fondo, tinta,
   acento), radios, densidad.
2. **Tomá el acabado, no el objeto**: tokens y composición sí; logo,
   textos, fotos y marca ajena nunca.
3. Volcalo en `design-system.md` antes de escribir HTML.
4. Construí y capturá al **mismo ancho** que la referencia; compará lado a
   lado con Read y listá diferencias por prioridad. Máx. 3 rondas.

## Dónde vive el DESIGN.md

En el vault, no en el repo (regla de vault): 
`01-Proyectos/<p>/Arquitectura/design-system.md`, con formato de 9
secciones (Google Stitch / awesome-design-md). Cuando esté aprobado, se
importa con `@` en el `CLAUDE.md` del proyecto para que todo agente lo
lea. Ejemplos reales en `references/design-md-ejemplos/` (Linear, Stripe,
Vercel; MIT): son referencia de **formato y nivel de detalle**, no
identidades para copiar.

## Reporte

Dirección elegida (id + semilla) y redraws con motivo; la frase de la
idea; puntajes de la última crítica y qué sigue flojo; imágenes de
terceros con licencia; contenido de muestra a reemplazar. No declares un
chequeo que no corriste.

## Atribución

Adaptada de [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)
(MIT) — original verbatim en `upstream/`. Formato DESIGN.md de
[VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md)
(MIT). Origen y commit en `ORIGEN.md`.
