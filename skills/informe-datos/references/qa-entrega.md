# QA antes de entregar

Adaptado de `analysis-qa-checklist` (nimrodfisher/data-analytics-skills, MIT).
Recorrer completo cada vez, no solo en informes grandes.

## 1. Pregunta
- [ ] Responde la pregunta que se hizo (no una parecida)
- [ ] Período y alcance coinciden con lo pedido
- [ ] Las definiciones (ej. "cliente activo", "venta neta") coinciden con las del usuario

## 2. Fuentes
- [ ] Datos frescos (no un snapshot viejo)
- [ ] Problemas de calidad de la Fase 2 documentados y su efecto considerado

## 3. Cálculos
- [ ] Joins del tipo correcto y con el conteo de filas esperado (sin doble conteo)
- [ ] Nulos manejados a propósito (`SUM`/`AVG` los ignoran en silencio; `a - b` da NULL)
- [ ] Zona horaria consistente
- [ ] Divisiones protegidas contra cero
- [ ] Cada porcentaje con el denominador correcto
- [ ] 3 filas verificadas a mano contra la fuente
- [ ] Segmentos suman el total

## 4. Validez
- [ ] Muestra suficiente para la afirmación
- [ ] Correlación no presentada como causa
- [ ] Outliers identificados y su efecto en la conclusión evaluado
- [ ] Segmentos clave revisados por separado (paradoja de Simpson)
- [ ] Más de una línea base cuando la elegida cambia la historia

## 5. Conclusiones
- [ ] Cada conclusión sostenida por un dato mostrado
- [ ] Hallazgos inesperados reportados, no escondidos
- [ ] Limitaciones escritas
- [ ] Cada hallazgo tiene acción (o "no requiere acción" explícito)

## 6. Presentación
- [ ] Ejes, etiquetas y títulos correctos; eje Y desde 0 en barras
- [ ] Números con formato consistente (moneda, decimales, separador de miles)
- [ ] Precisión acorde al dato
- [ ] Sin texto de plantilla ni placeholders
- [ ] Datos sensibles revisados antes de publicar

## Errores más frecuentes
1. **Doble conteo por join** uno-a-muchos → contar filas antes y después de cada join.
2. **Denominador equivocado** → escribirlo explícito antes de calcular.
3. **Nulos que desaparecen** en agregados.
4. **Zona horaria**: UTC vs. local corre ventas al día siguiente.
5. **Sesgo de supervivencia**: analizar solo clientes/productos que siguen activos.
6. **Correlación como causa**.
7. **Línea base conveniente**.
8. **Conclusión enterrada** al final.
9. **Teatro de precisión** (3.847362%).
10. **Supuestos invisibles**.
