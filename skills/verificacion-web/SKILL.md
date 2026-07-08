---
description: >
  Verificación LOCAL en navegador real usando Playwright CLI (@playwright/cli).
  Activar después de un cambio con superficie web (vistas, JS, formularios)
  ANTES de commitear, cuando la app corre en localhost/Docker local, o cuando
  el usuario diga "probalo en el navegador", "verifica la UI local",
  "/verificacion-web". NO usar para verificar el ambiente desplegado — eso es
  la skill testsprite. Complementarias: esta capa prueba lo que todavía no
  salió de tu máquina; TestSprite da el veredicto sobre lo publicado.
  (Usa el binario `playwright-cli` por debajo; la skill se llama distinto a
  propósito, para no colisionar con la skill que instala ese binario.)
depends_on:
  - team-context
---

# verificacion-web — verificador local en navegador (Playwright CLI)

Cerrás el loop de desarrollo ANTES del commit: manejás un navegador real
contra la app local, verificás el cambio de punta a punta y solo entonces
declarás el trabajo listo para commit/deploy.

**Ciclo:** código → playwright-cli contra localhost → pasa → commit/deploy →
testsprite contra el ambiente real → documentalista.

---

## Las dos capas de verificación (no confundir)

| | `playwright-cli` (esta skill) | `testsprite` |
|---|---|---|
| Corre contra | localhost / Docker local | URL pública desplegada |
| Cuándo | antes del commit | después del deploy |
| Quién ejecuta | Claude, en tu máquina | agente de TestSprite en la nube |
| Costo | gratis | créditos |
| Localhost | ✅ | ❌ (lo rechaza) |

## Regla dura: CLI, no MCP

Siempre el binario `playwright-cli` por Bash — **nunca el Playwright MCP**
en agentes con shell. El MCP mete el snapshot de accesibilidad completo en
el contexto en cada paso (4–10x más tokens); el CLI escribe los snapshots
a disco y se leen solo cuando hacen falta.

## Setup (una sola vez por máquina)

```bash
npm install -g @playwright/cli        # o: npm install -g --prefix ~/.local
playwright-cli install-browser chromium
```

Config por proyecto en `.playwright/cli.config.json`. Ni la config ni los
snapshots que el CLI escribe a disco se commitean — agregar a
`.git/info/exclude` del repo:

```
.playwright/
.playwright-cli/
```

```json
{
  "browser": {
    "browserName": "chromium",
    "launchOptions": { "headless": true, "chromiumSandbox": false }
  }
}
```

> `chromiumSandbox: false` solo hace falta si el navegador falla con
> "Chromium sandboxing failed!" (AppArmor en Ubuntu 24.04+). Si abre sin
> eso, dejá el sandbox activo.

## Flujo típico

```bash
playwright-cli open http://localhost:8080/login
playwright-cli snapshot            # devuelve refs (e5, e15...) de cada elemento
playwright-cli fill e5 "usuario@test.com"
playwright-cli fill e7 "clave123" --submit
playwright-cli snapshot            # verificar el estado resultante
playwright-cli console error       # ¿errores JS en consola?
playwright-cli requests            # ¿requests 4xx/5xx?
playwright-cli screenshot          # solo si hace falta evidencia visual
playwright-cli close               # SIEMPRE cerrar al terminar
```

- Interactuá por **refs del snapshot** (`e15`), nunca por selectores CSS
  adivinados. Snapshot primero, acción después.
- Para verificar layout/CSS: `screenshot` y mirala — la presencia de un
  elemento en el snapshot NO garantiza que se vea bien.
- `state-save` / `state-load` para no re-loguearte en cada sesión de prueba.

## Reporte

Igual que testsprite: veredicto literal. Qué se probó, qué se vio
(consola, requests, snapshot), qué falló con el output real. Si no
pudiste levantar la app local, decilo — "sin verificar porque <X>" —
no lo des por hecho.

## En el flujo Vengadores

`dev-senior`/`hawkeye` terminan → **playwright-cli** verifica local →
commit/deploy → skill `testsprite` verifica lo desplegado →
`documentalista` registra. Si la app no corre local, se salta esta capa
y se documenta el porqué.

## Referencia completa de comandos

Cookies, storage, tabs, red (mock de requests con `route`), diálogos,
teclado/mouse, PDF: leer `references/comandos.md` (referencia oficial
del paquete).
