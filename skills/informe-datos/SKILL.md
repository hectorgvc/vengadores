---
description: >
  Construye informes profesionales de datos (análisis + hallazgos +
  recomendaciones) a partir de cualquier fuente: CSV/Excel, una base SQL
  (MySQL de mavelerp u otra), o un MCP conectado (Alegra, Supermetrics).
  Flujo de 5 fases con compuertas: planificar → validar datos → analizar →
  sintetizar → QA antes de entregar. Activar cuando el usuario diga
  "armame un informe de <datos>", "analizá este CSV/Excel", "reporte de
  ventas/clientes/inventario", "qué dicen estos datos", "/informe-datos".
  NO usar para el status de un proyecto del vault (eso es
  `reporte-proyecto`), ni para diseñar un dashboard dentro de una app (eso
  es `dashboard-analyst`), ni para estados financieros formales (eso es
  el agente `contador`).
depends_on:
  - team-context
---

# informe-datos — informes profesionales de cualquier dato

Un informe no es una tabla con colores: es la **respuesta a una pregunta
de negocio**, con evidencia verificada y una recomendación. Si el informe
no cambia ninguna decisión, sobra.

Regla de oro: **ningún número sale sin haber sido verificado contra la
fuente.** Nunca inventar, estimar sin rotular, ni rellenar huecos.
"Sin datos" es una respuesta válida.

---

## Fase 1 — Planificar (antes de tocar los datos)

Respondé estas cinco cosas. Si falta alguna y no se puede inferir, una
sola pregunta al usuario con todas juntas:

1. **Pregunta de negocio** — una oración. "¿Por qué bajaron las ventas en
   septiembre?" es una pregunta; "ventas de septiembre" no.
2. **Audiencia** — ejecutivo (¿vamos bien?), operativo (¿qué hago hoy?) o
   analítico (¿por qué pasó?). Define largo y profundidad.
3. **Decisión que habilita** — qué va a hacer distinto quien lo lea.
4. **Fuente(s) y período** — tabla/archivo/MCP, rango de fechas, zona
   horaria (mavelerp: `America/Santo_Domingo`).
5. **Formato de salida** — ver tabla abajo. Default: **Claude Doc**.

Descomponé la pregunta en 2–5 sub-preguntas, cada una respondible con una
sola consulta o cálculo. Ese es el esqueleto del informe.

| Destino | Formato | Cómo |
|---|---|---|
| Leer/compartir/comentar (default) | Claude Doc | skill `anthropic-skills:docs` |
| Interactivo, con filtros | Artifact HTML | skill `artifact-design` + `dataviz` |
| Imprimir / adjuntar formal | PDF | skill `anthropic-skills:pdf` |
| Que el lector siga calculando | Excel | skill `anthropic-skills:xlsx` |
| Presentar en reunión | Deck | Artifact tipo Slides (quickstart `slides`) |

## Fase 2 — Validar los datos (compuerta dura)

**Si los datos no pasan, el informe no sale**: se entrega el diagnóstico
de calidad y se frena.

- **Archivos (CSV)**: correr el perfilador (stdlib, sin dependencias):
  ```bash
  python3 -I ~/.claude/skills/informe-datos/scripts/perfil.py datos.csv [--clave id] [--json]
  ```
  Da filas, columnas, tipo inferido, % nulos, duplicados (fila completa y
  por clave), min/max/media/mediana, outliers por IQR y rango de fechas,
  con veredicto OK/WARN/FAIL por columna. Para Excel: exportar la hoja a
  CSV primero (skill `xlsx`).
- **SQL**: queries de perfilado (`COUNT(*)`, `COUNT(col)`, `COUNT(DISTINCT
  clave)`, `MIN/MAX` de fechas) **antes** de la query analítica. Las
  queries de informe son **solo lectura** — nunca INSERT/UPDATE/DELETE/DDL.
  Para queries no triviales, pedí al agente `dba` que las revise con su
  checklist de "Queries analíticas".
- **MCP (Alegra, Supermetrics…)**: confirmar período, moneda, y que el
  total del MCP coincida con el reporte nativo de la plataforma cuando
  exista (ej. `reports_get_general_sales_totals` vs. suma de facturas).

Checklist completo y umbrales: `references/calidad-datos.md`. Lo mínimo:
grano (qué representa una fila), clave única, nulos, duplicados, rangos
plausibles, frescura, y **un total de control** que cuadre con algo
conocido.

## Fase 3 — Analizar

Elegí la técnica según la pregunta (detalle en
`references/tecnicas-analisis.md`; leé solo la sección que aplique):

| Pregunta | Técnica |
|---|---|
| ¿Cómo evoluciona? | Serie temporal: tendencia, estacionalidad, anomalías |
| ¿Por qué cambió X? | Causa raíz: validar el cambio → descomponer → drill-down |
| ¿Volvemos a venderles? | Cohortes / retención |
| ¿Dónde se pierden? | Embudo |
| ¿Qué grupos hay? | Segmentación por reglas |
| ¿Cómo estamos? | Métricas de negocio vs. período anterior / meta |
| ¿Por qué dos fuentes no coinciden? | Reconciliación de métricas |

Reglas: comparar siempre contra una **línea base explícita** (período
anterior, mismo período año anterior, meta); revisar los segmentos
principales por separado (paradoja de Simpson); guardar cada query/cálculo
que produce un número del informe — van al anexo de metodología.

## Fase 4 — Sintetizar y redactar

Estructura fija (pirámide: la conclusión primero). Detalle y plantilla en
`references/sintesis-y-redaccion.md`:

1. **Resumen ejecutivo** — 3–5 líneas: la respuesta, el número que la
   sostiene y la recomendación. Si solo leen esto, alcanza.
2. **Hallazgos** — 3–5 máximo, ordenados por impacto × confianza ×
   accionabilidad. Cada uno: hecho → por qué importa → qué hacer, con su
   número y nivel de confianza.
3. **Detalle / evidencia** — gráficos y tablas que sostienen cada hallazgo.
4. **Recomendaciones** — acción concreta, responsable sugerido, plazo.
5. **Metodología y supuestos** — fuentes, período, filtros, queries,
   limitaciones, calidad de datos de la Fase 2.

**Gráficos**: leer la skill `dataviz` antes de escribir el primero. Para
elegir qué mostrar y con qué tipo de gráfico en informes con varias
vistas, consultar a `dashboard-analyst` (regla global: no hay librería de
gráficos fija). Un gráfico por mensaje; el título del gráfico **es** la
conclusión ("Ventas cayeron 18% por el canal mayorista"), no la
descripción ("Ventas por canal").

**Estilo**: español, sin jerga técnica para audiencias de negocio,
precisión acorde al dato (~4%, no 3.847%), moneda y decimales
consistentes. Íconos: Lucide. Nunca emojis.

## Fase 5 — QA antes de entregar (compuerta dura)

Recorrer `references/qa-entrega.md` completo. Lo no negociable:

- Cada número del resumen ejecutivo re-verificado contra la fuente.
- Totales de segmentos suman el total general.
- Denominadores de cada porcentaje revisados.
- Ninguna afirmación causal sin evidencia (correlación ≠ causa).
- Supuestos y limitaciones escritos, no implícitos.
- Datos sensibles (PII, montos de clientes con nombre) revisados antes de
  publicar: un Artifact/Doc es compartible; preguntar si el informe lleva
  datos que no deberían salir.

Al entregar, decir en una línea qué se verificó y qué quedó como
limitación conocida.

---

## Integración con el sistema

- **`dba`**: revisa queries analíticas (fan-out de joins, NULLs, zona
  horaria, rendimiento) y reconciliación entre fuentes.
- **`contador`**: estados financieros, DGII (606/607), conciliaciones. Si
  el informe es contable formal, delegar.
- **`dashboard-analyst`**: qué KPIs y qué gráficos; también si el informe
  va a convertirse en un dashboard recurrente.
- **Vault**: si el informe es de un proyecto, guardar un resumen (no los
  datos) en `01-Proyectos/<proyecto>/` y registrar en la bitácora.

## Origen

Proceso adaptado y traducido de `nimrodfisher/data-analytics-skills`
(MIT). Ver `ORIGEN.md`.
