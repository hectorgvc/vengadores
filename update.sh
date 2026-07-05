#!/usr/bin/env bash
# =============================================================
# Vengadores Workflow — update.sh
# Sincroniza agentes y skills desde este repo hacia una instalación
# YA existente (~/.claude + vault). A diferencia de setup.sh (que nunca
# sobreescribe nada), este script SÍ actualiza el contenido de agentes
# y skills que ya tenías instalados, para que queden al día con el repo.
# Uso: ./update.sh [ruta-vault]
# =============================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="${1:-$HOME/ObsidianVault}"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_SKILLS="$CLAUDE_DIR/skills"
CLAUDE_AGENTS="$CLAUDE_DIR/agents"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}✔${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
same()    { echo -e "  — sin cambios: $1"; }
section() { echo -e "\n${GREEN}▸ $1${NC}"; }

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║      Vengadores Workflow — Update       ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Vault destino : $VAULT"
echo "  Claude config : $CLAUDE_DIR"
echo ""

if [ ! -d "$CLAUDE_AGENTS" ] || [ ! -d "$VAULT/03-Skills" ]; then
  echo "No se detectó una instalación previa en esta máquina."
  echo "Corré ./setup.sh primero (instala desde cero)."
  exit 1
fi

# ── 0. Actualizar el repo clonado ─────────────────────────
section "0 · Repo"

if [ -d "$REPO_DIR/.git" ]; then
  if git -C "$REPO_DIR" pull --ff-only; then
    info "Repo actualizado a la última versión"
  else
    warn "No se pudo hacer git pull (¿cambios locales sin commitear? ¿sin internet?)"
    warn "Corriendo update con el contenido que ya tenías clonado."
  fi
else
  warn "$REPO_DIR no es un git repo — no se puede actualizar automáticamente."
  warn "Volvé a clonar: git clone https://github.com/hectorgvc/vengadores.git"
fi

# ── 1. Migraciones conocidas (skills renombradas/descontinuadas) ──
section "1 · Migraciones"

if [ -d "$VAULT/03-Skills/team-onboarding" ]; then
  rm -rf "$VAULT/03-Skills/team-onboarding"
  info "Eliminada skill obsoleta: team-onboarding (renombrada a jarvis)"
fi
if [ -e "$CLAUDE_SKILLS/team-onboarding" ]; then
  rm -f "$CLAUDE_SKILLS/team-onboarding"
  info "Symlink obsoleto eliminado: team-onboarding"
fi

# ── 2. Agentes — sobreescribir con la versión del repo ────
section "2 · Agentes (~/.claude/agents/)"

mkdir -p "$CLAUDE_AGENTS"
for agent_file in "$REPO_DIR/agents/"*.md; do
  agent_name="$(basename "$agent_file")"
  DEST="$CLAUDE_AGENTS/$agent_name"
  if [ -f "$DEST" ] && cmp -s "$agent_file" "$DEST"; then
    same "$agent_name"
  else
    cp "$agent_file" "$DEST"
    info "Actualizado: $agent_name"
  fi
done

# ── 3. Skills — sincronizar contenido existente + agregar nuevas ──
section "3 · Skills (vault + ~/.claude/skills/)"

mkdir -p "$CLAUDE_SKILLS"
for skill_dir in "$REPO_DIR/skills/"*/; do
  skill_name="$(basename "$skill_dir")"
  DEST="$VAULT/03-Skills/$skill_name"

  if [ -d "$DEST" ]; then
    if diff -rq "$skill_dir" "$DEST" >/dev/null 2>&1; then
      same "$skill_name"
    else
      rm -rf "$DEST"
      cp -r "$skill_dir" "$DEST"
      info "Actualizada: $skill_name"
    fi
  else
    cp -r "$skill_dir" "$DEST"
    info "Nueva skill: $skill_name"
  fi

  LINK="$CLAUDE_SKILLS/$skill_name"
  [ ! -e "$LINK" ] && ln -s "$DEST" "$LINK" && info "Symlink creado: $skill_name"
done

# ── Resumen ────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║           Update completado ✔            ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Agentes   : $CLAUDE_AGENTS"
echo "  Skills    : $CLAUDE_SKILLS"
echo ""
echo "  Nota: si usabas la skill 'team-onboarding', ahora se llama"
echo "  'jarvis'. Decile a Claude Code: 'Ejecuta la skill jarvis'."
echo ""
