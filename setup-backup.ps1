# setup-backup.ps1 — configura el backup automático del vault hacia GitHub (Windows)
# Repo destino: https://github.com/hectorgvc/vault-backup.git

$Vault     = "$env:USERPROFILE\ObsidianVault"
$ClaudeDir = "$env:USERPROFILE\.claude"
$Settings  = "$ClaudeDir\settings.json"
$Remote    = "https://github.com/hectorgvc/vault-backup.git"
$RepoDir   = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "  [!]  $m" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  ======================================" -ForegroundColor Cyan
Write-Host "      Vault Backup - Setup (Windows)  " -ForegroundColor Cyan
Write-Host "  ======================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Copiar script de backup al vault ──────────────────
$ScriptSrc  = "$RepoDir\vault-backup.ps1"
$ScriptDest = "$Vault\vault-backup.ps1"

if (Test-Path $ScriptSrc) {
    Copy-Item $ScriptSrc $ScriptDest -Force
    Write-OK "Script instalado en $ScriptDest"
} else {
    Write-Warn "vault-backup.ps1 no encontrado. Corré esto desde la carpeta de vengadores."
    exit 1
}

# ── 2. Configurar git remote en el vault ─────────────────
if (-not (Test-Path "$Vault\.git")) {
    git -C $Vault init -q
    Write-OK "Repositorio git inicializado"
}

$existingRemote = git -C $Vault remote get-url origin 2>$null
if ($existingRemote) {
    Write-Warn "Remote 'origin' ya existe: $existingRemote"
    Write-Warn "Para apuntarlo al backup: git -C '$Vault' remote set-url origin $Remote"
} else {
    git -C $Vault remote add origin $Remote
    Write-OK "Remote configurado: $Remote"
}

# ── 3. Push inicial ───────────────────────────────────────
Write-Host ""
Write-Host "  Haciendo push inicial..."
git -C $Vault add -A
$d = Get-Date -Format "yyyy-MM-dd"
git -C $Vault commit -q -m "setup inicial vault-backup — $d" 2>$null
$push = git -C $Vault push -u origin main --quiet 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-OK "Push inicial exitoso → $Remote"
} else {
    Write-Warn "Push inicial falló. Causas posibles:"
    Write-Warn "  - Repo vault-backup no existe → crealo en github.com/new (privado)"
    Write-Warn "  - Sin autenticación → gh auth login o token HTTPS"
    Write-Warn "  Luego: git -C '$Vault' push -u origin main"
}

# ── 4. Task Scheduler (Windows no tiene hook Stop nativo confiable) ──────────
Write-Host ""
Write-Host "  Configurando Task Scheduler para backup al cerrar sesión..." -ForegroundColor Green

$taskName   = "VaultBackup"
$scriptPath = $ScriptDest
$action     = New-ScheduledTaskAction -Execute "powershell.exe" `
                -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger    = New-ScheduledTaskTrigger -AtLogOff
$settings   = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 2)

try {
    Register-ScheduledTask -TaskName $taskName -Action $action `
        -Trigger $trigger -Settings $settings -Force | Out-Null
    Write-OK "Task Scheduler configurado: backup al cerrar sesión de Windows"
} catch {
    Write-Warn "No se pudo crear la tarea programada (requiere permisos de admin)."
    Write-Warn "Creala manualmente:"
    Write-Warn "  schtasks /create /tn VaultBackup /tr `"powershell -File '$scriptPath'`" /sc onlogoff /f"
}

# ── Resumen ───────────────────────────────────────────────
Write-Host ""
Write-Host "  ======================================" -ForegroundColor Cyan
Write-Host "        Setup completado              " -ForegroundColor Cyan
Write-Host "  ======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Vault  : $Vault"
Write-Host "  Repo   : $Remote"
Write-Host "  Log    : $ClaudeDir\vault-backup.log"
Write-Host ""
Write-Host "  Probar manualmente: powershell -File '$ScriptDest'"
Write-Host ""
