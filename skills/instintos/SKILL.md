---
name: instintos
description: >
  Aprendizaje continuo entre sesiones: hooks deterministas capturan cada
  tool call, un observer en background detecta patrones repetidos y les
  asigna un puntaje de confianza. Nunca actúa solo más allá de anotar a
  nivel proyecto — promover a global o generar skills nuevas siempre pide
  confirmación explícita. Activar cuando el usuario diga "instinct
  status", "evolucioná los instintos", "/evolve", o quiera revisar/promover
  patrones aprendidos con `instinct-cli.py`.
metadata:
  origin: adaptada de affaan-m/ECC (skills/continuous-learning-v2), MIT
---

# Instintos — aprendizaje continuo entre sesiones

Sistema de hooks que observa cómo trabajás y construye "instincts"
(comportamientos atómicos aprendidos, con puntaje de confianza) a lo
largo de muchas sesiones y proyectos. Adaptado de
`affaan-m/ECC` (MIT), endurecido para que nunca actúe de forma autónoma
más allá de anotar localmente.

## Qué NO es esta skill

No reemplaza a `headroom-learn`. Son dos trabajos distintos:

| | `headroom-learn` | `instintos` |
|---|---|---|
| Disparo | Manual, a pedido, una vez por sesión | Automático, continuo, cada tool call |
| Qué produce | Notas en español dentro del vault (KB, `CLAUDE-global.md`, notas de proyecto) | YAML de instincts con confidence score, fuera del vault |
| Para quién | Vos, leyendo Obsidian | El comportamiento de Claude entre sesiones |
| Cuándo brilla | Post-mortem deliberado de una sesión con errores | Micro-patrones repetidos, demasiado finos para invocar algo manual por cada uno |

Usá los dos. Si con el tiempo sentís que se pisan, se evalúa entonces —
no hoy, sin evidencia de uso real.

## Qué hace SOLO, sin pedirte permiso

- Los hooks (`hooks/observe.sh`) escriben una línea a
  `observations.jsonl` en cada tool call — local, redacta secretos por
  regex, sin red, timeout de 8s.
- El observer en background (prompt en `agents/observer.md`, corre en
  Haiku) analiza esas observaciones y crea/actualiza instincts, **pero
  solo a nivel proyecto**. Nunca promueve a global ni modifica skills por
  su cuenta — eso está delegado explícitamente a `instinct-cli.py` o a
  `/evolve`.
- Guarda todo en `~/.local/share/ecc-homunculus/` (o
  `$XDG_DATA_HOME/ecc-homunculus`) — **fuera del vault**, a propósito:
  mismo criterio que Graphify o el venv de headroom — herramienta/datos
  operativos no se pushean a GitHub, solo el conocimiento ya destilado.

## Reglas duras (lo que el usuario pidió: "que sea sugerencia")

El propio `instinct-cli.py` ya exige confirmación interactiva `[y/N]`
para promover un instinct de proyecto a global — pero estas reglas lo
dejan explícito y sin atajos:

1. **Nunca pasar `--force`** a `instinct-cli.py promote` (ni a `import`,
   `projects delete`, `projects merge`, `projects gc`) — sin excepción,
   igual que la regla de `headroom-learn` de nunca usar `--apply`.
2. **`/evolve` es de dos pasos.** Primero mostrar los candidatos
   (clusters de instincts que podrían volverse skill/comando/agente) sin
   `--generate`. Esperar el visto bueno explícito del usuario. Recién ahí
   correr `--generate`. Nunca saltarse el primer paso.
3. **El observer nunca se activa solo.** `config.json` instala con
   `"observer": {"enabled": false}` — el usuario lo prende cuando quiera
   empezar a generar instincts, no como parte de la instalación.
4. `instinct-cli.py import <url>` solo se corre si el usuario lo pide
   explícitamente con una URL concreta — no es parte de ningún flujo
   automático. (Ya trae sus propias protecciones: solo HTTPS, bloquea
   IPs privadas/loopback/reservadas, límite de 2MB, timeout 15s —
   auditado antes de instalar esta skill.)

## Comandos

- `python3 scripts/instinct-cli.py status` — ver instincts activos y
  candidatos a promoción (solo lectura).
- `python3 scripts/instinct-cli.py promote` — revisar candidatos
  (confianza ≥0.8, presentes en 2+ proyectos) y promoverlos, con
  confirmación `[y/N]` (nunca `--force`).
- `python3 scripts/instinct-cli.py promote <id>` — promover uno
  específico, misma confirmación.
- "evolucioná los instintos" / `/evolve` — clusteriza instincts
  relacionados en candidatos a skill/comando/agente. Mostrar candidatos
  primero, generar solo con confirmación explícita del usuario.

## Instalación de los hooks

Esta skill por sí sola no activa la captura — hace falta cablear
`hooks/observe.sh` en `~/.claude/settings.json` (`PreToolUse` y
`PostToolUse`). Corre en **toda sesión, todo proyecto**, no solo acá:
cada tool call ejecuta este script (liviano: parseo JSON vía Python,
timeout 8s, sin red). El usuario debe saber esto antes de aprobarlo —
no es exclusivo del vault.

## Relación con el resto del sistema

- `headroom-learn` — complementario, no redundante (ver tabla arriba).
- `mentor` — los instincts promovidos a global son candidatos a
  convertirse en reglas del protocolo de decisión, pero esa incorporación
  la decide el usuario, no el sistema.
