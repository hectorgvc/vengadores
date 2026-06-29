# =============================================================
# Vengadores Workflow — setup.ps1
# Instalación para Windows (PowerShell 5.1+)
# Uso: .\setup.ps1 [-Vault "C:\Users\TU\ObsidianVault"]
# =============================================================

param(
    [string]$Vault = "$env:USERPROFILE\ObsidianVault"
)

$ErrorActionPreference = "Stop"
$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = "$env:USERPROFILE\.claude"
$ClaudeMd  = "$ClaudeDir\CLAUDE.md"
$ClaudeSkills = "$ClaudeDir\skills"
$ClaudeAgents = "$ClaudeDir\agents"

function Write-OK  { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Skip { param($msg) Write-Host "  --   $msg (ya existe)" -ForegroundColor Gray }

Write-Host ""
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host "      Vengadores Workflow - Setup (Win)    " -ForegroundColor Cyan
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Vault destino : $Vault"
Write-Host "  Claude config : $ClaudeDir"
Write-Host ""

$confirm = Read-Host "  Continuar? [S/n]"
if ($confirm -ne "" -and $confirm -notmatch "^[Ss]$") {
    Write-Host "Cancelado."
    exit 0
}

# ── 1. Estructura del vault ──────────────────────────────
Write-Host "`n  > 1 Estructura del vault" -ForegroundColor Green

$dirs = @(
    "$Vault\00-Reglas-Globales",
    "$Vault\01-Proyectos",
    "$Vault\02-Plantillas",
    "$Vault\03-Skills",
    "$Vault\04-Wiki\tech",
    "$Vault\04-Wiki\patterns"
)

foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-OK "Creada: $d"
    } else {
        Write-Skip $d
    }
}

if (-not (Test-Path "$Vault\.gitignore")) {
    @".obsidian/workspace*.json`n.trash/" | Set-Content "$Vault\.gitignore"
    Write-OK "Creado .gitignore"
}

# ── 2. Plantillas ────────────────────────────────────────
Write-Host "`n  > 2 Plantillas" -ForegroundColor Green

Get-ChildItem "$RepoDir\templates\*.md" | ForEach-Object {
    $dest = "$Vault\02-Plantillas\$($_.Name)"
    if (-not (Test-Path $dest)) {
        Copy-Item $_.FullName $dest
        Write-OK "Plantilla: $($_.Name)"
    } else {
        Write-Skip $_.Name
    }
}

# ── 3. Skills en el vault ────────────────────────────────
Write-Host "`n  > 3 Skills del vault" -ForegroundColor Green

Get-ChildItem "$RepoDir\skills" -Directory | ForEach-Object {
    $dest = "$Vault\03-Skills\$($_.Name)"
    if (-not (Test-Path $dest)) {
        # robocopy: /E copia subdirectorios (incluyendo vacíos), /NJH /NJS /NP = silencioso
        robocopy $_.FullName $dest /E /NJH /NJS /NP | Out-Null
        Write-OK "Skill: $($_.Name)"
    } else {
        Write-Skip "skill $($_.Name)"
    }
}

# ── 4. Scripts ───────────────────────────────────────────
Write-Host "`n  > 4 Scripts" -ForegroundColor Green

Get-ChildItem "$RepoDir\scripts\*.sh" | ForEach-Object {
    $dest = "$Vault\$($_.Name)"
    if (-not (Test-Path $dest)) {
        Copy-Item $_.FullName $dest
        Write-OK "Script: $($_.Name)"
    } else {
        Write-Skip $_.Name
    }
}

# ── 5. Agentes (~/.claude/agents/) ──────────────────────
Write-Host "`n  > 5 Agentes Vengadores (~/.claude/agents/)" -ForegroundColor Green

if (-not (Test-Path $ClaudeAgents)) { New-Item -ItemType Directory -Path $ClaudeAgents -Force | Out-Null }

Get-ChildItem "$RepoDir\agents\*.md" | ForEach-Object {
    $dest = "$ClaudeAgents\$($_.Name)"
    if (-not (Test-Path $dest)) {
        Copy-Item $_.FullName $dest
        Write-OK "Agente: $($_.Name)"
    } else {
        Write-Skip "agente $($_.Name)"
    }
}

# ── 6. Puente global ~/.claude/CLAUDE.md ────────────────
Write-Host "`n  > 6 Puente ~/.claude/CLAUDE.md" -ForegroundColor Green

if (-not (Test-Path $ClaudeDir)) { New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null }

$bridgeLine = "@$Vault\00-Reglas-Globales\CLAUDE-global.md"
$bridgeMarker = "# Vengadores Workflow"

if (-not (Test-Path $ClaudeMd)) {
    "$bridgeMarker`n$bridgeLine" | Set-Content $ClaudeMd
    Write-OK "Creado ~/.claude/CLAUDE.md"
} elseif ((Get-Content $ClaudeMd -Raw) -notlike "*$bridgeLine*") {
    "`n$bridgeMarker`n$bridgeLine" | Add-Content $ClaudeMd
    Write-OK "Bridge añadido a ~/.claude/CLAUDE.md"
} else {
    Write-Skip "bridge en ~/.claude/CLAUDE.md"
}

# ── 7. Skills globales (copias en Windows) ──────────────
Write-Host "`n  > 7 Skills globales (~/.claude/skills/)" -ForegroundColor Green
Write-Warn "Windows: se usan copias en lugar de symlinks (sin modo desarrollador requerido)"

if (-not (Test-Path $ClaudeSkills)) { New-Item -ItemType Directory -Path $ClaudeSkills -Force | Out-Null }

Get-ChildItem "$Vault\03-Skills" -Directory | Where-Object { Test-Path "$($_.FullName)\SKILL.md" } | ForEach-Object {
    $dest = "$ClaudeSkills\$($_.Name)"
    if (-not (Test-Path $dest)) {
        robocopy $_.FullName $dest /E /NJH /NJS /NP | Out-Null
        Write-OK "Skill global: $($_.Name)"
    } else {
        Write-Skip "skill $($_.Name)"
    }
}

# ── 8. TestSprite CLI ────────────────────────────────────
Write-Host "`n  > 8 TestSprite CLI" -ForegroundColor Green

if (Get-Command testsprite -ErrorAction SilentlyContinue) {
    Write-OK "testsprite ya instalado"
} else {
    Write-Warn "TestSprite no instalado. Para instalarlo:"
    Write-Warn "  npm install -g @testsprite/cli"
    Write-Warn "  `$env:TESTSPRITE_API_KEY='<tu-clave>'"
    Write-Warn "  testsprite setup --from-env --agent claude"
}

# ── 9. Git del vault ─────────────────────────────────────
Write-Host "`n  > 9 Git del vault" -ForegroundColor Green

if (Get-Command git -ErrorAction SilentlyContinue) {
    if (-not (Test-Path "$Vault\.git")) {
        git -C $Vault init -q
        git -C $Vault add .
        git -C $Vault commit -q -m "Setup inicial — Vengadores Workflow"
        Write-OK "Repositorio git inicializado"
    } else {
        Push-Location $Vault
        git add .
        git commit -q -m "Vengadores setup — $(Get-Date -Format 'yyyy-MM-dd')" 2>$null
        Pop-Location
        Write-OK "Cambios commiteados"
    }
} else {
    Write-Warn "git no encontrado — instala git para versionar el vault"
}

# ── Resumen ──────────────────────────────────────────────
Write-Host ""
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host "         Setup completado correctamente     " -ForegroundColor Cyan
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Vault     : $Vault"
Write-Host "  Agentes   : $ClaudeAgents"
Write-Host "  Skills    : $ClaudeSkills"
Write-Host ""
Write-Host "  Siguiente paso — abre Claude Code y ejecuta:"
Write-Host "  'Ejecuta la skill team-onboarding'"
Write-Host ""
