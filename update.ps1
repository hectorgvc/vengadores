# =============================================================
# Vengadores Workflow — update.ps1
# Sincroniza agentes y skills desde este repo hacia una instalación
# YA existente (~/.claude + vault). A diferencia de setup.ps1 (que nunca
# sobreescribe nada), este script SÍ actualiza el contenido de agentes
# y skills que ya tenías instalados, para que queden al día con el repo.
# Uso: .\update.ps1 [-Vault "C:\Users\TU\ObsidianVault"]
# =============================================================

param(
    [string]$Vault = "$env:USERPROFILE\ObsidianVault"
)

$ErrorActionPreference = "Stop"
$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = "$env:USERPROFILE\.claude"
$ClaudeSkills = "$ClaudeDir\skills"
$ClaudeAgents = "$ClaudeDir\agents"

function Write-OK   { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Same { param($msg) Write-Host "  --   sin cambios: $msg" -ForegroundColor Gray }

Write-Host ""
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host "      Vengadores Workflow - Update (Win)   " -ForegroundColor Cyan
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Vault destino : $Vault"
Write-Host "  Claude config : $ClaudeDir"
Write-Host ""

if (-not (Test-Path $ClaudeAgents) -or -not (Test-Path "$Vault\03-Skills")) {
    Write-Host "No se detecto una instalacion previa en esta maquina."
    Write-Host "Corre .\setup.ps1 primero (instala desde cero)."
    exit 1
}

# ── 0. Actualizar el repo clonado ─────────────────────────
Write-Host "`n  > 0 Repo" -ForegroundColor Green

if (Test-Path "$RepoDir\.git") {
    Push-Location $RepoDir
    git pull --ff-only
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Repo actualizado a la ultima version"
    } else {
        Write-Warn "No se pudo hacer git pull (¿cambios locales sin commitear? ¿sin internet?)"
        Write-Warn "Corriendo update con el contenido que ya tenias clonado."
    }
    Pop-Location
} else {
    Write-Warn "$RepoDir no es un git repo — no se puede actualizar automaticamente."
    Write-Warn "Volve a clonar: git clone https://github.com/hectorgvc/vengadores.git"
}

# ── 1. Migraciones conocidas ──────────────────────────────
Write-Host "`n  > 1 Migraciones" -ForegroundColor Green

if (Test-Path "$Vault\03-Skills\team-onboarding") {
    Remove-Item "$Vault\03-Skills\team-onboarding" -Recurse -Force
    Write-OK "Eliminada skill obsoleta: team-onboarding (renombrada a jarvis)"
}
if (Test-Path "$ClaudeSkills\team-onboarding") {
    Remove-Item "$ClaudeSkills\team-onboarding" -Recurse -Force
    Write-OK "Eliminada copia obsoleta: team-onboarding"
}

# ── 2. Agentes — sobreescribir con la version del repo ────
Write-Host "`n  > 2 Agentes (~/.claude/agents/)" -ForegroundColor Green

if (-not (Test-Path $ClaudeAgents)) { New-Item -ItemType Directory -Path $ClaudeAgents -Force | Out-Null }

Get-ChildItem "$RepoDir\agents\*.md" | ForEach-Object {
    $dest = "$ClaudeAgents\$($_.Name)"
    if ((Test-Path $dest) -and ((Get-FileHash $_.FullName).Hash -eq (Get-FileHash $dest).Hash)) {
        Write-Same $_.Name
    } else {
        Copy-Item $_.FullName $dest -Force
        Write-OK "Actualizado: $($_.Name)"
    }
}

# ── 3. Skills — sincronizar contenido existente + agregar nuevas ──
Write-Host "`n  > 3 Skills (vault + ~/.claude/skills/)" -ForegroundColor Green

if (-not (Test-Path $ClaudeSkills)) { New-Item -ItemType Directory -Path $ClaudeSkills -Force | Out-Null }

Get-ChildItem "$RepoDir\skills" -Directory | ForEach-Object {
    $skillName = $_.Name
    $dest = "$Vault\03-Skills\$skillName"

    # /MIR refleja el origen exacto en el destino (agrega, actualiza y borra sobrantes)
    robocopy $_.FullName $dest /MIR /NJH /NJS /NP | Out-Null
    Write-OK "Sincronizada: $skillName"

    $link = "$ClaudeSkills\$skillName"
    robocopy $dest $link /MIR /NJH /NJS /NP | Out-Null
    Write-OK "Sincronizada (global): $skillName"
}

# ── Resumen ────────────────────────────────────────────────
Write-Host ""
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host "          Update completado correctamente   " -ForegroundColor Cyan
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Agentes   : $ClaudeAgents"
Write-Host "  Skills    : $ClaudeSkills"
Write-Host ""
Write-Host "  Nota: si usabas la skill 'team-onboarding', ahora se llama"
Write-Host "  'jarvis'. Decile a Claude Code: 'Ejecuta la skill jarvis'."
Write-Host ""
