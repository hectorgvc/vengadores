#!/usr/bin/env bash
# vault-backup.sh — backup automático del vault de Obsidian hacia GitHub
# Repo: https://github.com/hectorgvc/vault-backup.git
# Configurar el remote una sola vez:
#   git remote add origin https://github.com/hectorgvc/vault-backup.git
#   git push -u origin main

set -euo pipefail

VAULT="${HOME}/ObsidianVault"
LOG="${HOME}/.claude/vault-backup.log"
REMOTE="https://github.com/hectorgvc/vault-backup.git"
MAX_LINES=500

log() {
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $1" >> "$LOG"
}

rotate_log() {
  if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt "$MAX_LINES" ]; then
    tail -n "$MAX_LINES" "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
  fi
}

# ── Validaciones ──────────────────────────────────────────────────────────────

if [ ! -d "$VAULT" ]; then
  log "ERROR: vault no encontrado en $VAULT"
  exit 0
fi

if [ ! -d "$VAULT/.git" ]; then
  log "ERROR: $VAULT no es un repositorio git. Ejecutá: git -C $VAULT init"
  exit 0
fi

cd "$VAULT"

# Configurar remote si no existe
if ! git remote get-url origin &>/dev/null; then
  git remote add origin "$REMOTE"
  log "Remote configurado: $REMOTE"
fi

# ── Verificar si hay cambios ──────────────────────────────────────────────────

if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  log "Sin cambios — backup omitido"
  rotate_log
  exit 0
fi

# ── Commit y push ─────────────────────────────────────────────────────────────

TIMESTAMP="$(date '+%Y-%m-%d %H:%M')"
git add -A

if git commit -m "backup auto — ${TIMESTAMP}" --quiet; then
  log "Commit creado: backup auto — ${TIMESTAMP}"
else
  log "ERROR: commit falló"
  rotate_log
  exit 0
fi

if git push origin main --quiet 2>> "$LOG"; then
  log "Push exitoso → vault-backup"
else
  log "WARN: push falló (¿sin internet?). El commit quedó local, se reintentará en el próximo backup."
  # No bloquear — salir limpio para no interrumpir cierre de sesión
fi

rotate_log
