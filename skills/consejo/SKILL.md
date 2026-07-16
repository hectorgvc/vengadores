---
name: consejo
description: >
  Convoca un consejo de cuatro voces para decisiones ambiguas, con
  desacuerdo estructurado antes de elegir. Activar cuando el usuario diga
  "convocá al consejo", "necesito una segunda opinión con disenso",
  "pressure-test esto", "war room esto", o "/consejo" — y también cuando
  Claude detecte que está por decidir algo con 2+ caminos igualmente
  válidos y sin evidencia que incline la balanza. NO activar para code
  review, verificación de una implementación ya hecha, o tareas de
  ejecución obvias — para eso están `mentor`, el peer-review de
  `vengadores`, o simplemente hacer la tarea.
metadata:
  origin: adaptada de affaan-m/ECC (skills/council), MIT
---

# Consejo

Cuatro voces para decisiones bajo ambigüedad genuina:
- **Arquitecto** — la voz en contexto (vos, la sesión actual o Fury)
- **Escéptico** — subagente
- **Pragmático** — subagente
- **Crítico** — subagente

Es para **decidir bajo ambigüedad**, no para code review, no para
planificar pasos de implementación, no para diseñar arquitectura desde
cero.

## Cuándo usar

- La decisión tiene múltiples caminos creíbles y ningún ganador obvio.
- Hace falta que los trade-offs queden explícitos, no implícitos.
- El usuario pide segundas opiniones, disenso o múltiples perspectivas.
- El anclaje conversacional es un riesgo real (llevás rato analizando algo
  y ya no ves con claridad las alternativas).
- Una decisión de ir/no ir se beneficia de un desafío adversarial.

Ejemplos: monorepo vs polyrepo, lanzar ya vs pulir antes, feature flag vs
rollout directo, achicar alcance vs mantener amplitud estratégica.

## Cuándo NO usar

| En vez de consejo | Usar |
| --- | --- |
| Verificar si una implementación ya hecha es correcta | Peer-review de `vengadores` (gate de `qa-bug-hunter` sobre el diff) |
| Romper una feature en pasos de implementación | El plan de batalla de `vengadores` |
| Diseñar arquitectura de sistema desde cero | `dev-senior` (Opus) |
| Revisar código por bugs o seguridad | `qa-bug-hunter`, `security-analyst`, `/code-review`, `/security-review` |
| Preguntas puramente fácticas | Responder directo |
| Tareas de ejecución obvias | Hacer la tarea |
| Una sola decisión, un solo agente, gate rápido | `mentor` (protocolo de las 5 preguntas) alcanza solo |

**Relación con `mentor`:** `consejo` es la escalada de `mentor`, no un
reemplazo. `mentor` corre siempre antes de actuar (gate de 5 preguntas,
un solo agente). Se escala a `consejo` cuando esas 5 preguntas no
resuelven la duda porque hay ambigüedad real, no falta de análisis.

## Roles

| Voz | Lente |
| --- | --- |
| Arquitecto | correctitud, mantenibilidad, implicancias de largo plazo |
| Escéptico | cuestiona la premisa, empuja simplicidad, rompe supuestos |
| Pragmático | velocidad de entrega, impacto en el usuario, realidad operativa |
| Crítico | edge cases, riesgo de downside, modos de falla |

Las tres voces externas se lanzan como subagentes frescos con **solo la
pregunta y el contexto relevante**, nunca la conversación completa —
ese es el mecanismo anti-anclaje.

## Flujo

### 1. Extraé la pregunta real

Reducí la decisión a un prompt explícito: ¿qué estamos decidiendo?, ¿qué
restricciones importan?, ¿qué cuenta como éxito? Si la pregunta es vaga,
hacé una pregunta aclaratoria antes de convocar al consejo.

### 2. Juntá solo el contexto necesario

Si la decisión es específica del código: recolectá los archivos,
snippets o métricas relevantes, compacto, solo lo que hace falta para
decidir. Si es estratégica/general: saltate los snippets del repo salvo
que cambien materialmente la respuesta.

### 3. Formá primero la posición del Arquitecto

Antes de leer las otras voces, escribí: tu posición inicial, las tres
razones más fuertes a favor, el riesgo principal de tu camino preferido.
Hacé esto primero para que la síntesis no termine siendo un espejo de
las voces externas.

### 4. Lanzá las tres voces independientes en paralelo

Usá la herramienta **Agent** con `subagent_type: general-purpose`, una
llamada por voz, las tres en el mismo mensaje (paralelo real, no
secuencial). Cada una recibe:

```text
Sos el/la [ROL] en un consejo de decisión de cuatro voces.

Pregunta:
[pregunta de decisión]

Contexto:
[solo los snippets o restricciones relevantes]

Respondé con:
1. Posición — 1-2 oraciones
2. Razonamiento — 3 bullets concisos
3. Riesgo — el riesgo más grande de tu recomendación
4. Sorpresa — algo que las otras voces podrían pasar por alto

Sé directo. Sin rodeos. Menos de 300 palabras.
```

Énfasis por rol:
- **Escéptico**: cuestioná el encuadre, cuestioná los supuestos, proponé
  la alternativa creíble más simple.
- **Pragmático**: optimizá por velocidad, simplicidad y ejecución real.
- **Crítico**: sacá a la luz riesgo de downside, edge cases, y razones por
  las que el plan podría fallar.

### 5. Sintetizá con resguardos contra el sesgo

Sos participante y sintetizador a la vez, así que:
- no descartes una voz externa sin explicar por qué.
- si una voz externa te cambió la recomendación, decilo explícito.
- incluí siempre la disidencia más fuerte, aunque la rechaces.
- si dos voces coinciden en contra de tu posición inicial, tratalo como
  señal real.
- mantené las posiciones crudas visibles antes del veredicto.

### 6. Presentá un veredicto compacto

```markdown
## Consejo: [título corto de la decisión]

**Arquitecto:** [posición en 1-2 oraciones]
[1 línea de por qué]

**Escéptico:** [posición en 1-2 oraciones]
[1 línea de por qué]

**Pragmático:** [posición en 1-2 oraciones]
[1 línea de por qué]

**Crítico:** [posición en 1-2 oraciones]
[1 línea de por qué]

### Veredicto
- **Consenso:** [dónde coinciden]
- **Disidencia más fuerte:** [el desacuerdo más importante]
- **Chequeo de premisa:** [¿el Escéptico cuestionó la pregunta misma?]
- **Recomendación:** [el camino sintetizado]
```

Que se lea de un vistazo.

## Regla de persistencia

No escribas notas sueltas en rutas fuera del vault. Si el consejo cambia
materialmente una recomendación:
- usá `documentalista` para guardar la decisión en
  `01-Proyectos/<proyecto>/Decisiones/` (el lugar donde ya vive esto), o
- si el resultado pertenece a la sesión actual nomás, alcanza con el
  reporte al usuario — no toda decisión necesita persistirse.

Persistí solo cuando la decisión cambia algo real.

## Seguimiento multi-ronda

El default es una ronda. Si el usuario quiere otra ronda: mantené la
pregunta nueva enfocada, incluí el veredicto anterior solo si hace falta,
y mantené al Escéptico lo más limpio posible para no perder el valor
anti-anclaje.

## Anti-patrones

- Usar consejo para code review.
- Usar consejo cuando la tarea es puro trabajo de ejecución.
- Darles a los subagentes toda la conversación completa.
- Esconder el desacuerdo en el veredicto final.
- Persistir cada decisión como nota sin importar su relevancia.

## Skills relacionadas

- `mentor` — el gate que corre antes; consejo es su escalada.
- Peer-review de `vengadores` — verificación de implementación, no
  decisión.
- `documentalista` — persistir la decisión si cambió algo real.

## Ejemplo

Pregunta:
```text
¿Lanzamos esta feature en alpha ya, o esperamos a que el flujo de QA
esté más completo?
```

Forma probable del consejo:
- Arquitecto empuja por integridad estructural y evitar una superficie
  confusa.
- Escéptico cuestiona si el QA es realmente el factor bloqueante.
- Pragmático pregunta qué se puede lanzar ya sin dañar la confianza.
- Crítico se enfoca en carga de soporte, deuda de expectativas y
  confusión del rollout.

El valor no es la unanimidad. El valor es hacer legible el desacuerdo
antes de elegir.
