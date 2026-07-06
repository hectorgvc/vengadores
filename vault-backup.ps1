# vault-backup.ps1 — backup automático del vault de Obsidian hacia GitHub
# Repo: https://github.com/hectorgvc/vault-backup.git
# Configurar el remote una sola vez:
#   git remote add origin https://github.com/hectorgvc/vault-backup.git
#   git push -u origin main

$Vault  = "$env:USERPROFILE\ObsidianVault"
$Log    = "$env:USERPROFILE\.claude\vault-backup.log"
$Remote = "https://github.com/hectorgvc/vault-backup.git"
$MaxLines = 500

function Write-Log {
    param([string]$Msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$ts] $Msg" | Add-Content -Path $Log -Encoding UTF8
}

function Rotate-Log {
    if (Test-Path $Log) {
        $lines = Get-Content $Log
        if ($lines.Count -gt $MaxLines) {
            $lines | Select-Object -Last $MaxLines | Set-Content $Log -Encoding UTF8
        }
    }
}

# ── Validaciones ──────────────────────────────────────────────────────────────

if (-not (Test-Path $Vault)) {
    Write-Log "ERROR: vault no encontrado en $Vault"
    exit 0
}

if (-not (Test-Path "$Vault\.git")) {
    Write-Log "ERROR: $Vault no es un repositorio git. Ejecutá: git -C '$Vault' init"
    exit 0
}

Set-Location $Vault

# Configurar remote si no existe
$remoteCheck = git remote get-url origin 2>$null
if (-not $remoteCheck) {
    git remote add origin $Remote
    Write-Log "Remote configurado: $Remote"
}

# ── Verificar si hay cambios ──────────────────────────────────────────────────

$status = git status --porcelain
if (-not $status) {
    Write-Log "Sin cambios — backup omitido"
    Rotate-Log
    exit 0
}

# ── Commit y push ─────────────────────────────────────────────────────────────

$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git add -A

$commitResult = git commit -m "backup auto — $Timestamp" --quiet 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Commit creado: backup auto — $Timestamp"
} else {
    Write-Log "ERROR: commit falló — $commitResult"
    Rotate-Log
    exit 0
}

$pushResult = git push origin main --quiet 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Push exitoso -> vault-backup"
} else {
    Write-Log "WARN: push falló (sin internet?). Commit local guardado, se reintentará en próximo backup."
    Write-Log "Detalle: $pushResult"
}

Rotate-Log
