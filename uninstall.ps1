<#
.SYNOPSIS
    Uninstalls the switchpilot GitHub Copilot model switcher.

.DESCRIPTION
    Removes the Set-CopilotModel.ps1 script, optionally removes the model
    registry, and strips the alias from both PowerShell profiles.
#>

$ErrorActionPreference = 'Stop'

$binDir       = "$env:USERPROFILE\.local\bin"
$registryFile = "$env:USERPROFILE\.copilot\model_registry.json"

$profilePaths = @(
    "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
)

$aliasLine   = 'Set-Alias -Name switchpilot -Value "$env:USERPROFILE\.local\bin\Set-CopilotModel.ps1"'
$commentLine = '# GitHub Copilot Model Switcher'

Write-Host "=== switchpilot uninstaller ===" -ForegroundColor Cyan

# Remove main script
$scriptDest = Join-Path $binDir 'Set-CopilotModel.ps1'
if (Test-Path $scriptDest) {
    Remove-Item -Path $scriptDest -Force
    Write-Host "Removed: $scriptDest"
} else {
    Write-Host "Not found: $scriptDest"
}

# Prompt to remove registry
if (Test-Path $registryFile) {
    $response = Read-Host "Remove model registry at $registryFile? (y/n)"
    if ($response -eq 'y') {
        Remove-Item -Path $registryFile -Force
        Write-Host "Removed: $registryFile"
    } else {
        Write-Host "Kept: $registryFile"
    }
}

# Remove alias from profiles
foreach ($profile in $profilePaths) {
    if (-not (Test-Path $profile)) { continue }

    $lines = Get-Content $profile
    $lines = $lines | Where-Object {
        $_ -ne $aliasLine -and $_ -ne $commentLine
    }

    if ($lines.Count -eq 0) {
        Remove-Item -Path $profile -Force
        Write-Host "Removed empty profile: $profile"
    } else {
        $lines | Set-Content $profile -Force
        Write-Host "Cleaned alias from: $profile"
    }
}

Write-Host ""
Write-Host "Uninstall complete. Open a new PowerShell window for changes to take effect." -ForegroundColor Green
