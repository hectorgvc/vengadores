---
description: >
  Criterio y reglas de animación de UI para que las interfaces no queden
  estáticas ni genéricas. Activar SIEMPRE que se cree o edite UI con
  movimiento (o que debería tenerlo), o cuando el usuario diga: "se ve
  estático", "todos los estilos se parecen", "mejorá las animaciones",
  "revisá las animaciones", o "/animaciones". Tres modos: consulta
  (framework de decisión), review (gate estricto) y auditoría de codebase
  (planes autocontenidos que ejecuta hawkeye). Adaptada de
  emilkowalski/skills (MIT).
depends_on:
  - team-context
---

# Animaciones — criterio antes que movimiento

El problema típico no es no saber animar: es animar **sin criterio** —
las mismas 3 transiciones para todo, y todas las UIs terminan iguales.
Esta skill pone el framework de decisión ANTES de escribir CSS/JS.
El material completo (Emil Kowalski, MIT) vive en `references/`.

## Framework de decisión (obligatorio antes de animar)

1. **¿Debe animarse siquiera?** Frecuencia alta = menos animación (un
   dropdown que se abre 50 veces al día no tolera 400ms). Animá lo que
   comunica causa-efecto; lo decorativo se gana su lugar o no va.
2. **¿Cuál es el propósito?** Orientar (de dónde viene / a dónde va),
   feedback (pasó algo) o continuidad (esto es lo mismo que aquello).
   Si no podés nombrar el propósito, no animes.
3. **Easing según el caso**: entrada `ease-out` (NUNCA `ease-in` para
   entrar), salida `ease-in`, movimiento dentro de pantalla
   `ease-in-out`. Curvas custom > keywords cuando el detalle importa.
4. **Duración**: micro 150–300ms; complejas ≤ 400ms; la salida ~60–70%
   de la entrada. En la duda, más rápido.

## Reglas duras de componente

- Botones: feedback al instante (`:active` con scale/color) — el feel
  responsivo es prioridad 1.
- **Nunca `scale(0)` → 1**: partí de ~0.95 + opacity.
- Popovers/menús: `transform-origin` del lado del trigger (origin-aware).
- Tooltips: delay solo en el primer hover; los siguientes abren directo.
- CSS transitions > keyframes para UI interrumpible.
- Springs para lo que sigue al mouse/gesto (config y cuándo:
  `references/design-eng.md` § Spring Animations).
- Solo `transform`/`opacity`; `prefers-reduced-motion` SIEMPRE.

## Modos

| Modo | Cuándo | Qué leer |
|---|---|---|
| **Consulta** | Antes de construir UI con movimiento | `references/design-eng.md` |
| **Review** | Gate antes de commitear UI animada | `references/review.md` + `references/review-standards.md` |
| **Auditoría** | "Mejorá las animaciones de este proyecto" | `references/improve.md` — audita TODO el codebase → tabla priorizada → planes autocontenidos en `plans/` (`references/improve-plan-template.md`) |

**Triage de ejecución (regla del equipo):** los planes de la auditoría
son autocontenidos a propósito — los ejecuta `hawkeye` (Sonnet), uno por
plan. El que audita (Opus / sesión principal) no los implementa: el
caro audita, el barato ejecuta.

## Vocabulario

Para PEDIR una animación con precisión (a un agente o a cualquier IA):
`references/vocabulary.md`. Filosofía de diseño Apple/WWDC traducida a
web: `references/apple-design.md`.

## Atribución

Adaptada de [emilkowalski/skills](https://github.com/emilkowalski/skills)
(MIT) — Emil Kowalski (Vercel; Sonner, Vaul, animations.dev). Los
originales están verbatim en `references/`; solo se quitó el bloque
promocional "Initial Response" de design-eng.md.
