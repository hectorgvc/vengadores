# Vengadores Workflow

Sistema de desarrollo con agentes de IA para Claude Code, basado en un vault de Obsidian
como fuente de verdad. Un equipo de especialistas coordinados por Nick Fury (el orquestador),
con verificación en vivo via TestSprite.

## Instalación rápida

**Opción recomendada — un solo prompt, la IA hace todo:** copiá
[`prompts/prompt-instalacion-ia.md`](prompts/prompt-instalacion-ia.md) y
pegalo en Claude Code. Clona el repo, corre el setup y te hace el
onboarding sin que toques la terminal.

**Opción manual:**

```bash
git clone https://github.com/hectorgvc/vengadores.git
cd vengadores
chmod +x setup.sh
./setup.sh
```

El script crea el vault, instala los agentes, las skills y conecta Claude Code.
Luego abre Claude Code y ejecutá:

```
Ejecuta la skill jarvis
```

Eso configura tu perfil personal y genera `CLAUDE-global.md` automáticamente.

## Actualizar una instalación existente

¿Ya instalaste Vengadores antes y solo querés lo último (agentes
corregidos, skills nuevas, renombres)? Copiá
[`prompts/prompt-actualizacion-ia.md`](prompts/prompt-actualizacion-ia.md)
y pegalo en Claude Code — clona o actualiza el repo y corre `update.sh`
(o `update.ps1` en Windows) por vos.

A diferencia de `setup.sh` (que nunca sobreescribe nada existente),
`update.sh` sí sincroniza el contenido de agentes y skills ya instalados
con la última versión del repo, agrega lo nuevo y limpia migraciones
conocidas (ej. skills renombradas). No toca tus proyectos ni tu perfil.

```bash
cd vengadores
git pull
./update.sh
```

---

## El equipo — Agentes

| Agente | Modelo | Rol |
|--------|--------|-----|
| `dev-senior` | Opus | Implementa features y repara bugs complejos |
| `hawkeye` | Sonnet | Dev junior — tareas acotadas con guía explícita |
| `ui-ux-designer` | Sonnet | Interfaces HTML/CSS/JS con iconos Lucide |
| `qa-bug-hunter` | Sonnet | Caza bugs y los reporta (no repara) |
| `security-analyst` | Opus | Audita y corrige vulnerabilidades |
| `dba` | Sonnet | Migraciones SQL y cambios de esquema |
| `documentalista` | Haiku | Registra todo en el vault al cerrar cada misión |

---

## Skills disponibles

| Skill | Trigger | Para qué |
|-------|---------|----------|
| `vengadores` | `/vengadores` | Orquestador — convoca al equipo |
| `jarvis` | "ejecuta el onboarding" | Genera tu perfil y CLAUDE-global.md |
| `team-context` | automática | Fundacional — carga CLAUDE-global.md |
| `testsprite` | `/testsprite` | Verifica código contra app desplegada en vivo |
| `brainstorming` | `/brainstorming` | De idea a diseño con método socrático |
| `depuracion-sistematica` | `/depuracion-sistematica` | Causa raíz antes que parche |
| `tdd` | `/tdd` | Red-Green-Refactor |
| `fase` | `/fase` | Recomienda modelo óptimo (Sonnet/Opus) |
| `hilo` | `/hilo` | ¿Conviene un hilo nuevo? |
| `lucide` | `/lucide` | Referencia de iconos Lucide por negocio |
| `auth-setup` | "necesito auth" | Configura autenticación (Clerk / JWT) |
| `reporte-proyecto` | "reporte del proyecto X" | Genera reporte desde la bitácora |
| `headroom-learn` | "aprende de esta sesión" | Mina sesiones → aprendizajes al vault |
| `wiki-connect` | "conecta con la wiki" | Vincula conceptos técnicos entre proyectos |
| `junior-code-review` | "revisa mi código" | Review orientado a aprendizaje (para Hawkeye) |

---

## Flujo de una misión

```
Usuario: "vengadores, implementa el módulo de pagos"

Nick Fury (orquestador):
  1. Analiza la misión
  2. Presenta el plan de batalla (agentes + orden)
  3. Espera aprobación
  4. Ejecuta:
     qa-bug-hunter  → encuentra bugs existentes
     dev-senior     → implementa el módulo
     dba            → migración de esquema (si aplica)
     security-analyst → audita (si aplica)
     testsprite     → verifica en vivo contra la app desplegada
     documentalista → registra en el vault
  5. Reporta al usuario qué quedó listo y qué pendiente
```

---

## TestSprite — verificación en vivo

TestSprite cierra el loop del agente: en vez de "creer" que el código funciona,
corre tests reales contra tu app desplegada.

```bash
npm install -g @testsprite/testsprite-cli
export TESTSPRITE_API_KEY=<tu-clave>   # testsprite.com → Settings → API Keys
testsprite setup --from-env --agent claude
```

Luego en cualquier misión con la app desplegada:
```
/testsprite
```

---

## Proyecto nuevo

```bash
cd ~/ObsidianVault
./nuevo-proyecto.sh "Nombre del Proyecto" [/ruta/al/repo]
```

---

## Estructura resultante

```
~/.claude/
├── CLAUDE.md              ← importa CLAUDE-global.md del vault
├── agents/                ← definiciones del equipo Vengadores
│   ├── dev-senior.md
│   ├── hawkeye.md
│   ├── ui-ux-designer.md
│   ├── qa-bug-hunter.md
│   ├── security-analyst.md
│   ├── dba.md
│   └── documentalista.md
└── skills/                ← symlinks a ~/ObsidianVault/03-Skills/

~/ObsidianVault/
├── 00-Reglas-Globales/
│   ├── CLAUDE-global.md   ← generado por jarvis
│   └── mi-perfil.md
├── 01-Proyectos/          ← un folder por proyecto (vacío al inicio)
├── 02-Plantillas/
├── 03-Skills/             ← todas las skills instaladas
├── 04-Wiki/
├── nuevo-proyecto.sh
└── usar-skill.sh
```

---

## Requisitos

| Herramienta | Versión | Para |
|-------------|---------|------|
| Node.js | 18+ | Claude Code |
| Claude Code | última | `npm install -g @anthropic-ai/claude-code` |
| Git | cualquiera | Versionar el vault |
| bash | 3.2+ | Scripts del vault |
| TestSprite CLI | última | Verificación en vivo (opcional) |

Compatible con macOS, Linux y WSL2.
