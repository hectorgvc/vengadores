# Referencias extendidas — ui-ux-designer

Detalle completo de las prioridades de diseño y los checklists, movidos desde
`04-Agentes/ui-ux-designer.md` para mantener el agente liviano.

## Prioridades de diseño (ejecutar en orden 1 → 10)

### 1 · Accesibilidad — CRÍTICO

- Contraste mínimo 4.5:1 texto normal, 3:1 texto grande (WCAG 2.2 AA)
- Focus rings visibles en todos los elementos interactivos (2–4px)
- Alt text descriptivo en imágenes significativas
- `aria-label` en botones solo-icono; `accessibilityLabel` en native
- Navegación completa por teclado — Tab order = orden visual
- `<label for="">` visible en cada input (nunca solo placeholder)
- No transmitir información únicamente por color — agregar icono o texto
- Respetar `prefers-reduced-motion`; escalar con Dynamic Type sin truncar
- Skip-links para usuarios de teclado
- Jerarquía de headings secuencial h1→h6 sin saltos

### 2 · Touch & Interacción — CRÍTICO

- Tamaño mínimo de tap: 44×44pt (iOS) / 48×48dp (Android) — expandir hit area si el ícono es menor
- Espaciado mínimo entre targets: 8px/8dp
- Feedback visual en tap (ripple/opacity/elevation) dentro de 80–150ms
- Nunca depender de hover como única acción primaria
- Deshabilitar botón durante async + spinner; re-habilitar en éxito/error
- Error messages claros y cerca del problema, con ruta de recuperación
- Umbral de movimiento antes de iniciar drag (evitar drags accidentales)
- No bloquear gestos del sistema (swipe-back iOS, predictive back Android)

### 3 · Performance — ALTO

- Imágenes: WebP/AVIF, `srcset/sizes`, lazy load fuera del fold
- Declarar `width`/`height` o `aspect-ratio` en imágenes (CLS < 0.1)
- `font-display: swap` para evitar FOIT; preload solo fuentes críticas
- Virtualizar listas de 50+ items
- Code splitting por ruta (React Suspense / Next.js dynamic)
- Debounce/throttle en scroll, resize, input
- Skeleton screens para esperas > 300ms (no spinners bloqueantes)
- Cargar scripts de terceros async/defer

### 4 · Estilo — ALTO

- SVG icons (Lucide) — consistentes en stroke y tamaño; nunca emojis
- El mismo estilo en todas las páginas del proyecto
- Efectos (sombras, blur, radius) coherentes con el estilo elegido — elegir UNO y comprometerse
- Un solo color de acento principal; más de uno diluye el foco
- Una sola CTA primaria por pantalla
- Diseñar light/dark juntos — no inferir dark desde light
- Blur: solo para indicar fondo descartable (modal/sheet), no decorativo
- Preferir controles nativos/system; personalizar solo cuando el branding lo requiera

### 5 · Layout & Responsive — ALTO

- Mobile-first: diseñar para 375px y escalar hacia arriba
- Breakpoints sistemáticos: 375 / 768 / 1024 / 1440
- `<meta name="viewport" content="width=device-width, initial-scale=1">` — nunca deshabilitar zoom
- Sin scroll horizontal en mobile
- max-width consistente en desktop (max-w-6xl / 7xl)
- `min-h-dvh` en vez de `100vh` en mobile
- Respetar safe areas (notch, Dynamic Island, gesture bar)
- z-index en escala definida (0 / 10 / 20 / 40 / 100 / 1000)
- Elementos fixed deben reservar padding para contenido subyacente

### 6 · Tipografía & Color — MEDIO

- Base mínima 16px body (evita auto-zoom iOS)
- Line-height 1.5–1.75 para cuerpo
- Longitud de línea: 60–75 chars desktop, 35–60 mobile
- Tokens semánticos de color — nunca hex hardcodeado en componentes
- Dark mode: variantes desaturadas/más claras; no colores invertidos
- Fuente de datos numéricos: `font-variant-numeric: tabular-nums`
- Jerarquía por tamaño + peso + tracking — no solo color
- Bold headings (600–700), Regular body (400), Medium labels (500)

### 7 · Animación — MEDIO

- Micro-interacciones: 150–300ms; transiciones complejas ≤ 400ms
- Solo `transform` y `opacity` — nunca animar `width`/`height`/`top`/`left`
- Easing: `ease-out` al entrar, `ease-in` al salir
- Salida más rápida que entrada (~60–70% de la duración de entrada)
- Entrada de lista/grid: stagger de 30–50ms por item
- Cada animación comunica causa-efecto — no decorativa
- Respetar `prefers-reduced-motion` en toda animación
- Las animaciones deben ser interrumpibles por gesto del usuario

### 8 · Formularios & Feedback — MEDIO

- Label visible por cada input — nunca solo placeholder
- Error debajo del campo relacionado, con causa + cómo corregirlo
- Validar `onBlur`, no `onKeystroke`; mostrar error solo después de que el usuario termine
- Toast auto-dismiss: 3–5 segundos; `aria-live="polite"` para screen readers
- Confirmar antes de acciones destructivas (rojo semántico + separado visualmente)
- Multi-step: indicador de progreso, back navigation habilitado
- `autocomplete` / `textContentType` para autofill del sistema
- Auto-save en formularios largos para prevenir pérdida de datos

### 9 · Navegación — ALTO

- Bottom nav: máximo 5 items, icono + texto; badges solo cuando hay urgencia real
- Back navigation: predecible, estado preservado (scroll, filtros, inputs)
- Deep linking: toda pantalla clave alcanzable por URL / deep link
- Highlight visual del destino activo en nav (color + peso)
- Modals: affordance de cierre visible; swipe-down para dismiss en mobile
- Sidebar/drawer para navegación secundaria, no primaria
- Breadcrumbs en web para jerarquías de 3+ niveles
- No resetear silenciosamente el navigation stack

### 10 · Charts & Datos — BAJO

- Tipo según dato: tendencia → línea, comparación → barras, proporción → donut (≤5 categorías)
- Leyenda siempre visible y cerca del chart; interactiva si hay múltiples series
- Tooltip en hover/tap con valores exactos y unidades
- Estado vacío útil: mensaje + acción siguiente
- No depender solo de color para distinguir series (agregar formas/patrones)
- Accesible: `data-table` como alternativa; `aria-label` describiendo el insight clave

---

## Component Checkpoint

Antes de escribir código de UI, declarar:

```
Quién: [persona concreta — no "el usuario". ¿Dónde está? ¿Qué tiene en mente?]
Verbo: [qué deben completar. No "usar el dashboard" — el verbo exacto]
Sensación: [en palabras concretas. No "limpio y moderno". ¿Cálido como un notebook? ¿Frío como terminal?]
Paleta: [colores y POR QUÉ encajan con este producto específico]
Profundidad: [bordes / sombras sutiles / superficie — elegir UNO y POR QUÉ]
Tipografía: [fuente — y POR QUÉ encaja con la intención]
Espaciado: [unidad base (4px u 8px) y escala]
```

Si no podés explicar el POR QUÉ de cada uno, es un default. Parar y pensar.

**Prueba del swap:** ¿Si cambiás tu elección por la más común, el diseño se sentiría diferente? Si no — defaulteaste.

---

## Pre-Delivery Checklist

### Visual
- [ ] Sin emojis como iconos — solo Lucide/SVG
- [ ] Todos los iconos del mismo set, stroke consistente
- [ ] Estados hover/pressed/disabled/focus visualmente distintos
- [ ] Tokens semánticos de color (sin hex hardcodeado en componentes)
- [ ] Una sola CTA primaria por pantalla

### Interacción
- [ ] Todos los tappables con feedback visual en <150ms
- [ ] Touch targets ≥ 44×44pt / 48×48dp
- [ ] Micro-interacciones en 150–300ms con easing natural
- [ ] Disabled states visualmente claros y no interactivos
- [ ] Focus order = orden visual; labels descriptivos para screen readers

### Light/Dark
- [ ] Texto primario ≥ 4.5:1 en ambos modos (verificado, no inferido)
- [ ] Texto secundario ≥ 3:1 en ambos modos
- [ ] Bordes y divisores visibles en ambos modos
- [ ] Scrim de modal 40–60% para aislar contenido de fondo

### Layout
- [ ] Safe areas respetadas (header, tab bar, bottom CTA)
- [ ] Scroll content no oculto detrás de elementos fixed
- [ ] Verificado en 375px portrait y landscape
- [ ] Ritmo 4/8px mantenido en spacing

### Accesibilidad
- [ ] Alt text en todas las imágenes significativas
- [ ] Labels, hints y errores en formularios
- [ ] Color no es el único indicador en ningún elemento
- [ ] `prefers-reduced-motion` respetado
