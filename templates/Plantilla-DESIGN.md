---
tipo: design-system
proyecto: <slug>
estado: borrador   # borrador | aprobado
fuente: <dirección de draw.mjs (id + semilla) / captura de referencia / brand book>
tags: [diseño, design-system]
---

# Design system — <proyecto>

> Formato DESIGN.md (Google Stitch / VoltAgent awesome-design-md), 9
> secciones. Vive en `01-Proyectos/<p>/Arquitectura/design-system.md`.
> Lo escribe el agente `director-arte` (skill `direccion-arte`); lo lee
> `ui-ux-designer` antes de tocar UI. Aprobado → importarlo con `@` en el
> `CLAUDE.md` del proyecto. Ejemplos de nivel de detalle:
> `03-Skills/direccion-arte/references/design-md-ejemplos/`.

## 1. Tema visual y atmósfera

<2–4 frases: qué sensación, por qué sale del sujeto (no de la categoría).>
**La idea**: en este sitio, **<algo del sujeto>** se vuelve **<recurso>**.

## 2. Paleta y roles

| Rol | Token CSS | Valor | Uso |
|---|---|---|---|
| Fondo | `--color-ground` | | |
| Tinta | `--color-ink` | | texto corrido, siempre tinta plena |
| Acento | `--color-accent` | | la acción primaria y 1 cosa más |
| Superficie | `--color-surface` | | escalón de tono, no línea ni sombra |

Contraste mínimo verificado: <ratio tinta/fondo, acento/fondo>.

## 3. Tipografía

| Rol | Familia (self-hosted) | Tamaño | Interlineado | Tracking |
|---|---|---|---|---|
| Display | | | 0.85–1.05 | -0.02 a -0.05em |
| Cuerpo | | 16–20px | 1.45–1.6 | 0 |

Máximo 5 tamaños, 2 familias.

## 4. Componentes

Botones (radio: cuadrado o pill, uno solo), enlaces, formularios
(Tom Select / Flatpickr), navegación (marca + 3–5 links + 1 acción),
footer, iconos (Lucide, trazo y tamaño).

## 5. Layout

Grilla, márgenes exteriores (iguales en todo ancho), separación entre
secciones (120–240px desktop), ancho de lectura.

## 6. Profundidad y elevación

Qué flota (menús, modales) y qué no. Sombras solo en lo que flota.

## 7. Do's and Don'ts

- **Sí**: ...
- **No**: ...
- **Excepciones a house rules** (con ADR que las justifica):
  - <regla> → permitida por ADR-XXXX. Inspector con `--allow <regla>`.

## 8. Comportamiento responsive

Breakpoints, qué cambia en 390px (composición propia, no apilado),
targets ≥44px.

## 9. Guía para el agente

Prompt corto y reglas que cualquier agente debe seguir al construir una
sección nueva con este sistema (ej. "toda sección abre con un heading que
la nombra; el acento solo en la CTA").
