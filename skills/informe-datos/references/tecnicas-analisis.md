# Técnicas de análisis

Leé solo la sección que aplica. Adaptado de la categoría
`03-data-analysis-investigation` de nimrodfisher/data-analytics-skills (MIT).

## Serie temporal — ¿cómo evoluciona?
1. Granularidad natural (día/semana/mes); rellenar huecos explícitamente.
2. Tendencia: comparar contra media móvil y contra el mismo período del año anterior.
3. Estacionalidad: si el patrón se repite (fin de mes, diciembre, quincena), comparar
   período contra período equivalente, no contra el inmediato anterior.
4. Anomalías: puntos a más de 3 desviaciones de la mediana móvil; cruzar los top 5
   contra eventos conocidos (campañas, feriados, caídas del sistema).
5. Pronóstico solo si hay ≥ 2 ciclos completos de historia, y siempre con rango, no
   con un número único.

## Causa raíz — ¿por qué cambió X?
1. **Validar el cambio**: si está dentro de ±1.5 desviaciones del promedio móvil, es
   ruido — decirlo y cerrar.
2. **Línea de tiempo**: escalón (evento puntual) vs. deriva gradual (cambio estructural).
3. **Descomponer la métrica**: ventas = transacciones × ticket promedio × mix.
   Identificar qué componente se movió antes de abrir dimensiones.
4. **Drill-down**: antes vs. después por cada dimensión (sucursal, canal, producto,
   vendedor, cliente). Ordenar por contribución absoluta al cambio.
5. **Hipótesis explícitas**: volumen, precio, mix, problema de datos. Aceptar o
   rechazar cada una con evidencia; las rechazadas también van al informe.

## Cohortes / retención — ¿vuelven a comprar?
1. Definir cohorte (mes de primera compra) y evento de retención (compra posterior).
2. Matriz cohorte × período con % de la cohorte activa.
3. Visualizar como heatmap; leer en diagonal (estacionalidad) y en columna (mejora
   entre cohortes).

## Embudo — ¿dónde se pierden?
1. Pasos ordenados y ventana de tiempo acordada (ej. cotización → factura en 30 días).
2. Conversión paso a paso y total; pérdidas absolutas por paso.
3. Tiempo entre pasos (mediana, P75): demoras largas indican fricción.
4. Segmentar el embudo; priorizar por clientes perdidos × valor.

## Segmentación — ¿qué grupos hay?
- Preferir **reglas de negocio** (RFM: recencia, frecuencia, monto) antes que clustering.
- 3–7 segmentos, cada uno con nombre, 2–3 rasgos que lo definen y una acción
  (retener, activar, recuperar, monetizar, dejar ir).
- Test: ¿trataríamos distinto a cada segmento? Si no, sobran segmentos.

## Métricas de negocio — ¿cómo estamos?
- Definir cada métrica una vez (numerador, denominador, filtros) y no cambiarla.
- Comercio/ERP: ventas netas, ticket promedio, margen bruto %, rotación de
  inventario, días de cobro (DSO), cuentas por cobrar vencidas por tramo.
- Siempre con comparación: vs. período anterior, vs. año anterior, vs. meta.

## Reconciliación — ¿por qué dos fuentes no coinciden?
1. Confirmar ambos valores en la fuente, no en caché.
2. Comparar grano, período/zona horaria, filtros (lado a lado), tipos de join.
3. Muestra de 20 registros presentes en A y no en B, y viceversa.
4. Tolerancias: totales financieros reportados **0%**; operativos < 0.1%;
   marketing < 1%.
5. Documentar causa, fuente canónica y si hay que recalcular algo.
