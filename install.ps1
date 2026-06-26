<# 
.SYNOPSIS
    Installs the switchpilot GitHub Copilot model switcher.

.DESCRIPTION
    Copies the Set-CopilotModel.ps1 script to ~/.local/bin, copies the example
    model registry to ~/.copilot/model_registry.json, and adds aliases to both
    Windows PowerShell and PowerShell 7+ profiles.
#>

$ErrorActionPreference = 'Stop'

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$binDir      = "$env:USERPROFILE\.local\bin"
$registryDir = "$env:USERPROFILE\.copilot"
$registryFile = "$registryDir\model_registry.json"
$exampleFile  = Join-Path $scriptDir 'model_registry.json.example'

$profilePaths = @(
    "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
)

$aliasLine   = 'Set-Alias -Name switchpilot -Value "$env:USERPROFILE\.local\bin\Set-CopilotModel.ps1"'
$commentLine = '# GitHub Copilot Model Switcher'

Write-Host "=== switchpilot installer ===" -ForegroundColor Cyan

# Create directories
foreach ($dir in @($binDir, $registryDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created: $dir"
    }
}

# Copy main script
$scriptSrc  = Join-Path $scriptDir 'Set-CopilotModel.ps1'
$scriptDest = Join-Path $binDir 'Set-CopilotModel.ps1'
Copy-Item -Path $scriptSrc -Destination $scriptDest -Force
Write-Host "Installed: $scriptDest"

# Copy example registry (only if not already present)
if (-not (Test-Path $registryFile)) {
    Copy-Item -Path $exampleFile -Destination $registryFile
    Write-Host "Installed: $registryFile"
    Write-Host "  Edit this file to add models matching your local LLM setup."
} else {
    Write-Host "Registry already exists, skipped: $registryFile"
}

# Add alias to profiles
foreach ($profile in $profilePaths) {
    $profileDir = Split-Path -Parent $profile
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $profile)) {
        New-Item -ItemType File -Path $profile -Force | Out-Null
    }

    $content = Get-Content $profile -Raw -ErrorAction SilentlyContinue
    if ($content -notmatch [regex]::Escape($aliasLine)) {
        Add-Content -Path $profile -Value "`n$commentLine`n$aliasLine"
        Write-Host "Added alias to: $profile"
    } else {
        Write-Host "Alias already present in: $profile"
    }
}

Write-Host ""
Write-Host "Done. Open a new PowerShell window or run:" -ForegroundColor Green
Write-Host "  . `$PROFILE"
Write-Host ""
Write-Host "Then configure your models:" -ForegroundColor Yellow
Write-Host "  notepad `$env:USERPROFILE\.copilot\model_registry.json"
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  switchpilot -List"
Write-Host "  switchpilot qwen-coder-3b"
