# Calidad de datos — checklist y umbrales

Adaptado de `programmatic-eda` y `data-quality-audit`
(nimrodfisher/data-analytics-skills, MIT).

## Umbrales por defecto (los usa `scripts/perfil.py`)

| Chequeo | WARN | FAIL |
|---|---|---|
| Nulos por columna | > 5% | > 30% |
| Duplicados de fila completa | > 0% | > 1% |
| Duplicados por clave | > 0% (justificar versionado) | — |
| Outliers (IQR) | fuera de Q1 − 1.5·IQR / Q3 + 1.5·IQR | — (se revisan, no se borran) |

Excepciones: campos opcionales (teléfono 2, segundo apellido) toleran
hasta 50% de nulos; documentarlo.

Cada outlier se clasifica: **señal real** (venta grande legítima),
**error de datos** (unidad equivocada, dato de prueba) o **centinela**
(`-1`, `0`, `9999` = "desconocido").

## Checklist

### Estructura
- [ ] Carga sin errores (encoding, separador — en RD/LatAm suele ser `;`)
- [ ] Cantidad de filas plausible para la población esperada
- [ ] **Grano** identificado: qué representa una fila (factura, línea de factura, cliente-mes)
- [ ] Clave única identificada y verificada
- [ ] Tipos correctos (fechas como fecha, RNC/cédula como texto, no número)
- [ ] Joins entre archivos no inflaron filas

### Completitud y unicidad
- [ ] Nulos revisados por columna contra umbral
- [ ] Ceros vs. nulos: ¿el 0 significa algo o es "faltante"?
- [ ] Duplicados de fila completa y por clave

### Validez
- [ ] Montos ≥ 0 salvo notas de crédito/devoluciones (documentar el signo)
- [ ] Categorías dentro del set esperado (sin variantes "Santo Domingo" / "Sto. Dgo.")
- [ ] Fechas dentro de rango (sin futuras, sin anteriores al arranque del sistema)
- [ ] Integridad referencial: FKs sin huérfanos (o tasa documentada)
- [ ] Moneda única o conversión explícita (DOP/USD)

### Frescura y series de tiempo
- [ ] Registro más reciente dentro del rezago esperado
- [ ] Volumen por período sin caídas abruptas (corte de carga) ni picos (backfill)
- [ ] Huecos en fechas documentados

### Lógica de negocio
- [ ] Columnas derivadas recalculadas a partir de las de origen (ej. total = subtotal + ITBIS)
- [ ] **Total de control**: la suma cuadra con un número conocido (reporte nativo, cierre contable)
- [ ] Segmentos suman el total

## SQL de perfilado (MySQL)

```sql
SELECT COUNT(*)                          AS filas,
       COUNT(DISTINCT id)                AS claves_distintas,
       SUM(total IS NULL)                AS total_nulos,
       MIN(fecha), MAX(fecha),
       SUM(total < 0)                    AS montos_negativos
FROM facturas
WHERE fecha >= '2026-09-01' AND fecha < '2026-10-01';
```

Rangos de fecha siempre como `>= inicio AND < fin`, nunca `BETWEEN` ni
`DATE(col) = ...` (rompe el índice y pierde el último día con hora).
