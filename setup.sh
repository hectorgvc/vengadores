#!/usr/bin/env bash
# =============================================================
# Vengadores Workflow — setup.sh
# Instala el sistema completo: vault, skills, agentes, testsprite.
# Uso: ./setup.sh [ruta-vault]
# =============================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="${1:-$HOME/ObsidianVault}"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
CLAUDE_SKILLS="$CLAUDE_DIR/skills"
CLAUDE_AGENTS="$CLAUDE_DIR/agents"
MODE="fresh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}✔${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
skip()    { echo -e "  — skipped: $1 (ya existe)"; }
section() { echo -e "\n${GREEN}▸ $1${NC}"; }

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║      Vengadores Workflow — Setup        ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Vault destino : $VAULT"
echo "  Claude config : $CLAUDE_DIR"
echo ""

[ -d "$VAULT" ] && MODE="integration" && \
  warn "Vault ya existe — modo integración (no se sobreescribe nada)." || \
  info "Instalación nueva en $VAULT"

read -rp "  ¿Continuar? [S/n] " CONFIRM
CONFIRM="${CONFIRM:-S}"
[[ "$CONFIRM" =~ ^[Ss]$ ]] || { echo "Cancelado."; exit 0; }

# ── 1. Estructura del vault ────────────────────────────────
section "1 · Estructura del vault"

dirs=(
  "$VAULT/00-Reglas-Globales"
  "$VAULT/01-Proyectos"
  "$VAULT/02-Plantillas"
  "$VAULT/03-Skills"
  "$VAULT/04-Wiki/tech"
  "$VAULT/04-Wiki/patterns"
)
for d in "${dirs[@]}"; do
  [ ! -d "$d" ] && mkdir -p "$d" && info "Creada: $d" || skip "$d"
done

[ ! -f "$VAULT/.gitignore" ] && cat > "$VAULT/.gitignore" <<'EOF'
.obsidian/workspace*.json
.trash/
EOF
info "Creado .gitignore"

# ── 2. Plantillas ──────────────────────────────────────────
section "2 · Plantillas"

for tpl in "$REPO_DIR/templates/"*.md; do
  DEST="$VAULT/02-Plantillas/$(basename "$tpl")"
  [ ! -f "$DEST" ] && cp "$tpl" "$DEST" && info "Plantilla: $(basename "$tpl")" || skip "$(basename "$tpl")"
done

# Plantilla-Wiki
WIKI_TPL="$VAULT/02-Plantillas/Plantilla-Wiki.md"
if [ ! -f "$WIKI_TPL" ]; then
  cat > "$WIKI_TPL" <<'EOF'
---
tags: []
relacionado: []
proyectos: []
---
# {{Concepto}}

## Qué es

## Cómo lo usamos

## Notas relacionadas
- [[concepto-relacionado]]

## Proyectos que lo usan
- [[proyecto]]

## Referencias
EOF
  info "Plantilla: Plantilla-Wiki.md"
fi

# ── 3. Skills en el vault ──────────────────────────────────
section "3 · Skills del vault"

for skill_dir in "$REPO_DIR/skills/"*/; do
  skill_name="$(basename "$skill_dir")"
  DEST="$VAULT/03-Skills/$skill_name"
  [ ! -d "$DEST" ] && cp -r "$skill_dir" "$DEST" && info "Skill: $skill_name" || skip "skill $skill_name"
done

# README de skills
SKILLS_README="$VAULT/03-Skills/README.md"
if [ ! -f "$SKILLS_README" ]; then
  cat > "$SKILLS_README" <<'EOF'
# Librería Vengadores — Skills

| Skill | Descripción | Depende de | Estado |
|-------|-------------|------------|--------|
| vengadores | Orquestador del equipo | — | ✅ |
| jarvis | Entrevista de perfil — genera mi-perfil.md y CLAUDE-global.md | — | ✅ |
| team-context | Fundacional — todas las demás la leen | — | ✅ |
| reporte-proyecto | Genera reporte final desde la bitácora | team-context | ✅ |
| junior-code-review | Revisión orientada a aprendizaje | team-context | ✅ |
| testsprite | Verificación en vivo contra app desplegada | team-context | ✅ |
| brainstorming | De idea a diseño con método socrático | — | ✅ |
| depuracion-sistematica | Causa raíz antes que parche | — | ✅ |
| tdd | Red-Green-Refactor | — | ✅ |
| fase | Recomienda modelo óptimo (Sonnet/Opus) | — | ✅ |
| hilo | ¿Conviene un hilo nuevo? | — | ✅ |
| lucide | Referencia de iconos Lucide | — | ✅ |
| auth-setup | Configura autenticación | team-context | ✅ |
| headroom-learn | Mina sesiones → vault | team-context | ✅ |
| wiki-connect | Conecta proyectos con la wiki | team-context | ✅ |

## Instalar una skill
```bash
./usar-skill.sh nombre --global
./usar-skill.sh nombre --proyecto /ruta/repo
./usar-skill.sh nombre --proyecto /ruta --copia
```
EOF
  info "Creado 03-Skills/README.md"
fi

# ── 4. Wiki inicial ────────────────────────────────────────
section "4 · Wiki — 04-Wiki/"

WIKI_README="$VAULT/04-Wiki/README.md"
if [ ! -f "$WIKI_README" ]; then
  cat > "$WIKI_README" <<'EOF'
---
tags: [wiki, index]
---
# Wiki — Base de conocimiento

Conceptos técnicos y patrones reutilizables entre proyectos.

## Estructura
- **tech/** — conceptos técnicos (JWT, Docker, frameworks, APIs)
- **patterns/** — patrones reutilizables entre proyectos
EOF
  info "Creado 04-Wiki/README.md"
fi

# ── 5. Scripts ─────────────────────────────────────────────
section "5 · Scripts"

for script in "$REPO_DIR/scripts/"*.sh; do
  DEST="$VAULT/$(basename "$script")"
  [ ! -f "$DEST" ] && cp "$script" "$DEST" && chmod +x "$DEST" && \
    info "Script: $(basename "$script")" || skip "$(basename "$script")"
done

# ── 6. Agentes (~/.claude/agents/) ────────────────────────
section "6 · Agentes Vengadores (~/.claude/agents/)"

mkdir -p "$CLAUDE_AGENTS"
for agent_file in "$REPO_DIR/agents/"*.md; do
  agent_name="$(basename "$agent_file")"
  DEST="$CLAUDE_AGENTS/$agent_name"
  [ ! -f "$DEST" ] && cp "$agent_file" "$DEST" && \
    info "Agente: $agent_name" || skip "agente $agent_name"
done

# ── 7. Puente global ~/.claude/CLAUDE.md ──────────────────
section "7 · Puente ~/.claude/CLAUDE.md"

mkdir -p "$CLAUDE_DIR"
BRIDGE_LINE="@$VAULT/00-Reglas-Globales/CLAUDE-global.md"
BRIDGE_MARKER="# Vengadores Workflow"

if [ ! -f "$CLAUDE_MD" ]; then
  printf "%s\n%s\n" "$BRIDGE_MARKER" "$BRIDGE_LINE" > "$CLAUDE_MD"
  info "Creado ~/.claude/CLAUDE.md"
elif grep -qF "$BRIDGE_LINE" "$CLAUDE_MD"; then
  skip "bridge en ~/.claude/CLAUDE.md"
else
  printf "\n%s\n%s\n" "$BRIDGE_MARKER" "$BRIDGE_LINE" >> "$CLAUDE_MD"
  info "Bridge añadido a ~/.claude/CLAUDE.md"
fi

# ── 8. Skills globales (symlinks) ──────────────────────────
section "8 · Skills globales (~/.claude/skills/)"

mkdir -p "$CLAUDE_SKILLS"
for skill_dir in "$VAULT/03-Skills/"*/; do
  [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name="$(basename "$skill_dir")"
  DEST="$CLAUDE_SKILLS/$skill_name"
  [ ! -e "$DEST" ] && ln -s "$skill_dir" "$DEST" && \
    info "Symlink global: $skill_name" || skip "symlink $skill_name"
done

# ── 9. Skills GeneXus (opcional) ──────────────────────────
section "9 · Skills GeneXus (opcional)"

GX_DIR="$REPO_DIR/skills-extra/genexus-skills"
echo "  Skills GeneXus incluye: nexa, gx-erp-connector, ui-creator,"
echo "  chameleon-controls-library, design-system-builder, mercury-design-system"
echo ""
read -rp "  ¿Instalar skills de GeneXus? [s/N] " GX_CONFIRM
GX_CONFIRM="${GX_CONFIRM:-N}"

if [[ "$GX_CONFIRM" =~ ^[Ss]$ ]]; then
  # Inicializar submodule si no está descargado
  if [ ! -f "$GX_DIR/README.md" ]; then
    info "Descargando genexus-skills (submodule)..."
    git -C "$REPO_DIR" submodule update --init skills-extra/genexus-skills
  fi

  # Symlinks para skills planas (nexa, gx-erp-connector)
  for skill_dir in "$GX_DIR"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || continue
    skill_name="$(basename "$skill_dir")"
    DEST="$CLAUDE_SKILLS/$skill_name"
    [ ! -e "$DEST" ] && ln -s "$skill_dir" "$DEST" && \
      info "Symlink GeneXus: $skill_name" || skip "symlink $skill_name"
  done

  # Symlinks para skills dentro de frontend/
  for skill_dir in "$GX_DIR/frontend/"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || continue
    skill_name="$(basename "$skill_dir")"
    DEST="$CLAUDE_SKILLS/$skill_name"
    [ ! -e "$DEST" ] && ln -s "$skill_dir" "$DEST" && \
      info "Symlink GeneXus: $skill_name" || skip "symlink $skill_name"
  done
  info "Skills GeneXus instaladas. Se activan manualmente: /nexa, /ui-creator, etc."
else
  info "Skills GeneXus omitidas. Para instalarlas luego:"
  info "  git submodule update --init skills-extra/genexus-skills"
  info "  Luego volver a ejecutar: ./setup.sh"
fi

# ── 10. Git guardrails (opcional) ─────────────────────────
section "10 · Git Guardrails (hook de seguridad)"

echo "  Bloquea comandos git destructivos antes de que Claude los ejecute:"
echo "  git push, reset --hard, clean -f, branch -D, checkout ."
echo ""
read -rp "  ¿Instalar git guardrails? [s/N] " GG_CONFIRM
GG_CONFIRM="${GG_CONFIRM:-N}"

if [[ "$GG_CONFIRM" =~ ^[Ss]$ ]]; then
  HOOKS_DIR="$CLAUDE_DIR/hooks"
  mkdir -p "$HOOKS_DIR"
  cp "$REPO_DIR/hooks/block-dangerous-git.sh" "$HOOKS_DIR/block-dangerous-git.sh"
  chmod +x "$HOOKS_DIR/block-dangerous-git.sh"

  SETTINGS_FILE="$CLAUDE_DIR/settings.json"
  python3 - <<PYEOF
import json, os
path = "$SETTINGS_FILE"
settings = {}
if os.path.exists(path):
    with open(path) as f:
        settings = json.load(f)

hook_entry = {
    "matcher": "Bash",
    "hooks": [{"type": "command", "command": "~/.claude/hooks/block-dangerous-git.sh"}]
}
hooks = settings.setdefault("hooks", {})
pre = hooks.setdefault("PreToolUse", [])
if not any("block-dangerous-git" in str(h) for h in pre):
    pre.append(hook_entry)
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
    print("Hook registrado en settings.json")
else:
    print("Hook ya estaba registrado")
PYEOF
  info "Git guardrails instalados"
else
  info "Git guardrails omitidos. Para instalarlos luego: ejecutá ./setup.sh de nuevo."
fi

# ── 11. TestSprite CLI (opcional) ─────────────────────────
section "11 · TestSprite CLI (verificación en vivo)"

if command -v testsprite &>/dev/null; then
  info "testsprite ya instalado: $(testsprite --version 2>/dev/null || echo 'ok')"
else
  warn "TestSprite no instalado. Para instalarlo:"
  warn "  npm install -g @testsprite/testsprite-cli"
  warn "  export TESTSPRITE_API_KEY=<tu-clave>   # testsprite.com → Settings → API Keys"
  warn "  testsprite setup --from-env --agent claude"
  warn "La skill 'testsprite' quedará disponible pero inactiva hasta instalar la CLI."
fi

# ── 12. Git del vault ──────────────────────────────────────
section "12 · Git del vault"

if [ ! -d "$VAULT/.git" ]; then
  git -C "$VAULT" init -q
  git -C "$VAULT" add .
  git -C "$VAULT" commit -q -m "Setup inicial — Vengadores Workflow"
  info "Repositorio git inicializado"
else
  (cd "$VAULT" && git add . && \
   git commit -q -m "Vengadores setup — $(date +%Y-%m-%d)" 2>/dev/null) || true
  info "Cambios commiteados"
fi

# ── Resumen ────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║           Setup completado ✔            ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Vault     : $VAULT"
echo "  Agentes   : $CLAUDE_AGENTS"
echo "  Skills    : $CLAUDE_SKILLS"
echo ""
echo "  Siguiente paso — abre Claude Code y ejecuta:"
echo "  'Ejecuta la skill jarvis'"
echo ""
echo "  Esto configura tu perfil personal (CLAUDE-global.md)."
echo ""
echo "  Para verificación en vivo con TestSprite:"
echo "  npm install -g @testsprite/testsprite-cli"
echo "  export TESTSPRITE_API_KEY=<tu-clave>"
echo "  testsprite setup --from-env --agent claude"
echo ""
