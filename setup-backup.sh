#!/usr/bin/env bash
# setup-backup.sh — configura el backup automático del vault hacia GitHub
# Repo destino: https://github.com/hectorgvc/vault-backup.git
# Uso: ./setup-backup.sh

set -euo pipefail

VAULT="${HOME}/ObsidianVault"
CLAUDE_DIR="${HOME}/.claude"
SETTINGS="${CLAUDE_DIR}/settings.json"
REMOTE="https://github.com/hectorgvc/vault-backup.git"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✔${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║    Vault Backup — Setup             ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ── 1. Copiar script de backup al vault ──────────────────
SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/vault-backup.sh"
SCRIPT_DEST="${VAULT}/vault-backup.sh"

if [ -f "$SCRIPT_SRC" ]; then
  cp "$SCRIPT_SRC" "$SCRIPT_DEST"
  chmod +x "$SCRIPT_DEST"
  ok "Script instalado en ${SCRIPT_DEST}"
else
  warn "vault-backup.sh no encontrado en el repo. Asegurate de correr esto desde la carpeta de vengadores."
  exit 1
fi

# ── 2. Configurar git remote en el vault ─────────────────
if [ ! -d "${VAULT}/.git" ]; then
  git -C "$VAULT" init -q
  ok "Repositorio git inicializado en vault"
fi

if git -C "$VAULT" remote get-url origin &>/dev/null; then
  warn "Remote 'origin' ya existe: $(git -C "$VAULT" remote get-url origin)"
  warn "Si querés apuntarlo al repo de backup, ejecutá:"
  warn "  git -C $VAULT remote set-url origin $REMOTE"
else
  git -C "$VAULT" remote add origin "$REMOTE"
  ok "Remote configurado: $REMOTE"
fi

# ── 3. Push inicial ───────────────────────────────────────
echo ""
echo "  Haciendo push inicial al repo de backup..."
git -C "$VAULT" add -A
git -C "$VAULT" commit -q -m "setup inicial vault-backup — $(date '+%Y-%m-%d')" 2>/dev/null || true
if git -C "$VAULT" push -u origin main --quiet 2>/dev/null; then
  ok "Push inicial exitoso → ${REMOTE}"
else
  warn "Push inicial falló. Posibles causas:"
  warn "  - El repo vault-backup aún no existe en GitHub → crealo en github.com/new (privado)"
  warn "  - Sin autenticación → configurá gh auth login o un token HTTPS"
  warn "  Una vez resuelto, corrés: git -C $VAULT push -u origin main"
fi

# ── 4. Hook Stop en settings.json ────────────────────────
echo ""
mkdir -p "$CLAUDE_DIR"
python3 - <<PYEOF
import json, os

path = "$SETTINGS"
settings = {}
if os.path.exists(path):
    with open(path) as f:
        settings = json.load(f)

hook_entry = {
    "matcher": "",
    "hooks": [{
        "type": "command",
        "command": "$SCRIPT_DEST"
    }]
}

hooks = settings.setdefault("hooks", {})
stop_hooks = hooks.setdefault("Stop", [])

if not any("vault-backup" in str(h) for h in stop_hooks):
    stop_hooks.append(hook_entry)
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
    print("  Hook Stop registrado en settings.json")
else:
    print("  Hook Stop ya estaba registrado")
PYEOF

ok "Backup configurado para correr al cerrar cada sesión de Claude Code"

# ── Resumen ───────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║      Setup completado ✔             ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
echo "  Vault     : ${VAULT}"
echo "  Repo      : ${REMOTE}"
echo "  Log       : ${CLAUDE_DIR}/vault-backup.log"
echo ""
echo "  Podés probar el backup manualmente:"
echo "  ${SCRIPT_DEST}"
echo ""
