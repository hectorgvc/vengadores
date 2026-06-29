---
description: >
  Verificación de código contra la app desplegada usando TestSprite CLI.
  Activar cuando el usuario diga: "corre los tests", "verifica con testsprite",
  "chequea en vivo", "/testsprite", o después de que dev-senior/hawkeye terminen
  un cambio y la app esté desplegada. NO usar contra localhost — requiere URL
  pública. En el flujo Vengadores, va ENTRE el agente dev y el documentalista.
depends_on:
  - team-context
---

# testsprite — verificador en vivo

Cerrás el loop del agente: corré tests reales contra la app desplegada,
leé los fallos y devolvé el resultado para que el dev corrija o el
documentalista cierre la misión.

**Ciclo:** código → tests en vivo → fallo → fix → tests → pasa → documentalista

---

## Paso 0 — Verificar prerequisitos

```bash
# ¿Está instalada la CLI?
testsprite --version 2>/dev/null || echo "FALTA: npm install -g @testsprite/cli"

# ¿Hay API key?
[ -n "$TESTSPRITE_API_KEY" ] || echo "FALTA: export TESTSPRITE_API_KEY=<tu-clave>"

# ¿Hay PROJECT_ID?
[ -n "$TESTSPRITE_PROJECT_ID" ] || echo "FALTA: export TESTSPRITE_PROJECT_ID=<id>"
```

Si falta la CLI, instalarla:
```bash
npm install -g @testsprite/cli
testsprite setup --from-env --agent claude
```

Si la URL objetivo es localhost → **DETENER**. TestSprite requiere URL pública.
Informar al usuario que primero debe hacer deploy.

---

## Paso 1 — Correr los tests

**Backend (todos):**
```bash
testsprite test run --all \
  --project "$TESTSPRITE_PROJECT_ID" \
  --wait \
  --output json
```

**Frontend (test específico):**
```bash
testsprite test run "$TEST_ID" --wait --output json
```

**Con URL override (si la app cambió de host):**
```bash
testsprite test run --all \
  --project "$TESTSPRITE_PROJECT_ID" \
  --target-url "https://tu-app.com" \
  --wait --output json
```

Guardar el exit code. Si es `0` → todos pasaron, ir al Paso 4.
Si es `1` → hay fallos, ir al Paso 2.

---

## Paso 2 — Diagnosticar fallos

Para cada test fallido:

```bash
# Resumen de fallo (una pantalla)
testsprite test failure summary "$TEST_ID"

# Bundle completo (DOM snapshots, hipótesis, código)
testsprite test failure get "$TEST_ID" --out ./testsprite-fallos
```

El `failure summary` devuelve:
- Pasos que fallaron
- Hipótesis de causa raíz (generadas por IA)
- Código del test para referencia

Presentar al orquestador (Vengadores):
```
TESTSPRITE — FALLOS ENCONTRADOS
Test: <nombre> | ID: <test-id> | Severidad: <p0-p3>
Fallo: <descripción del paso fallido>
Causa probable: <hipótesis>
Archivos relacionados: <archivo:línea si se puede inferir>
→ Handoff a dev-senior para fix
```

---

## Paso 3 — Loop fix → verify

El orquestador pasa los fallos al agente dev (`dev-senior` o `hawkeye`).
Una vez que el dev aplique el fix, **rerrunear sin gastar créditos** (FE)
o rerrunear con closure (BE):

```bash
# Rerun (FE — sin créditos extra)
testsprite test rerun "$TEST_ID" --wait --output json

# Rerun BE con no-auto-heal (para ver si el fix fue suficiente)
testsprite test rerun "$TEST_ID" --wait --no-auto-heal --output json
```

Si pasa → actualizar LOOP.md y continuar al Paso 4.
Si sigue fallando → volver al Paso 2. Máximo 3 ciclos antes de escalar
al orquestador con el resumen completo.

---

## Paso 4 — Actualizar LOOP.md

Al final de cada iteración, agregar una línea a `LOOP.md` en la raíz del repo:

```
YYYY-MM-DD HH:MM | <agente> | <qué se hizo> | <tests: N pasaron, M fallaron> | <estado>
```

Ejemplo:
```
2026-06-30 14:22 | dev-senior | fix: validación de email en /register | 12 pasaron, 0 fallaron | ✅ PASS
2026-06-30 14:05 | hawkeye | feat: endpoint POST /users | 10 pasaron, 2 fallaron | ❌ FAIL → retry
```

Si no existe `LOOP.md`, crearlo con encabezado:
```markdown
# Loop de verificación — TestSprite

| Fecha/Hora | Agente | Cambio | Tests | Estado |
|---|---|---|---|---|
```

---

## Paso 5 — Handoff al documentalista

Si todos los tests pasan, devolver al orquestador:
```
TESTSPRITE — VERIFICACIÓN COMPLETA
Tests pasados: N/N
LOOP.md actualizado
→ Listo para handoff a documentalista
```

Si tras 3 ciclos siguen habiendo fallos:
```
TESTSPRITE — CICLOS AGOTADOS (3/3)
Tests fallando: M
Fallos persistentes: <lista>
→ Escalar al orquestador para decisión
```

---

## Variables de entorno recomendadas

Agregar a `.env.example` del proyecto:
```bash
TESTSPRITE_API_KEY=        # Obtener en testsprite.com → Settings → API Keys
TESTSPRITE_PROJECT_ID=     # ID del proyecto en TestSprite
```

---

## Comandos útiles adicionales

```bash
# Ver historial de runs
testsprite test result "$TEST_ID" --history --since 24h

# Listar tests fallidos del proyecto
testsprite test list --project "$TESTSPRITE_PROJECT_ID" --status failed

# Ver saldo de créditos
testsprite usage

# Simular sin gastar créditos (aprendizaje)
testsprite --dry-run test run --all --project "$TESTSPRITE_PROJECT_ID" --wait
```
