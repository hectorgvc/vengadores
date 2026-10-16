# Síntesis y redacción

Adaptado de `insight-synthesis` y `executive-summary-generator`
(nimrodfisher/data-analytics-skills, MIT).

## De hallazgo a insight

Un **hallazgo** dice qué pasó. Un **insight** dice por qué importa y qué hacer.

| Hallazgo | Insight |
|---|---|
| "Las ventas cayeron 12% en septiembre" | "Las ventas cayeron 12% en septiembre; el 80% de la caída viene de 3 clientes mayoristas que no repitieron pedido. Contactarlos esta semana podría recuperar ~RD$1.2M." |

Para cada hallazgo, responder: **¿Y qué?** (impacto) → **¿Por qué?** (causa más
probable) → **¿Ahora qué?** (acción). Si no hay "¿y qué?", no va al informe.
Preguntar "¿y qué?" tres veces suele llegar a la implicación real.

Un insight sin número es una observación: cuantificar siempre (aunque sea orden
de magnitud, rotulado como estimación).

## Priorizar

Puntaje 1–3 en **impacto × confianza × accionabilidad**. Arriba los altos en los
tres. Lo de alto impacto pero baja confianza va como "a validar", no como
conclusión. Más de 5 hallazgos = todavía no se priorizó.

Si hay contradicciones entre hallazgos, mostrarlas y decir qué dato las resolvería.

## Pirámide (la conclusión primero)

Cada sección y cada párrafo: conclusión → evidencia → detalle. Nunca enterrar el
hallazgo al final. Las recomendaciones nombran **qué hacer, quién, resultado
esperado y para cuándo** — "mejorar las ventas" no es una recomendación.

## Plantilla de informe

```markdown
# <Título que es la conclusión, no el tema>
<fecha> · <autor> · Período: <inicio–fin> · Fuente: <origen>

## Resumen ejecutivo
<Respuesta a la pregunta en 1 oración.> <Número clave.> <Recomendación principal.>

## Hallazgos
### 1. <Hallazgo como afirmación>
- **Qué pasó:** <dato con comparación vs. línea base>
- **Por qué importa:** <impacto cuantificado>
- **Causa probable:** <evidencia> · Confianza: alta/media/baja
- **Acción:** <qué, quién, cuándo>
<gráfico cuyo título es la conclusión>

### 2. …

## Recomendaciones
| Acción | Responsable | Plazo | Resultado esperado |

## Metodología y supuestos
- Fuentes y período; zona horaria
- Filtros y definiciones de métricas
- Calidad de datos (resultado de la Fase 2) y limitaciones
- Anexo: queries/cálculos que producen cada número
```

## Formatos según audiencia

| Audiencia | Largo | Énfasis |
|---|---|---|
| Ejecutiva | 1 página | resumen + decisión pedida |
| Operativa | 1–2 páginas | acciones y listas accionables (top clientes, ítems vencidos) |
| Analítica | sin límite | metodología completa, hipótesis rechazadas |
