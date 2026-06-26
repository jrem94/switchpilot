<# 
.SYNOPSIS
    Sets GitHub Copilot environment variables from a model registry.

.DESCRIPTION
    Reads a model registry JSON file and maps model properties to COPILOT_* environment variables.
    Supports listing available models, switching models, and removing all COPILOT_* variables.

.PARAMETER ModelName
    The model key from the registry (e.g., "qwen3.5-4b").

.PARAMETER List
    Lists all available models from the registry.

.PARAMETER Remove
    Removes all COPILOT_* environment variables from the specified scope.

.PARAMETER Scope
    Environment variable scope: Process, User, or Machine. Default: User.

.EXAMPLE
    Set-CopilotModel.ps1 qwen3.5-4b

.EXAMPLE
    Set-CopilotModel.ps1 -List

.EXAMPLE
    Set-CopilotModel.ps1 -Remove

.EXAMPLE
    Set-CopilotModel.ps1 qwen3.5-4b -Scope Process
#>

[CmdletBinding(DefaultParameterSetName = 'SetModel')]
param(
    [Parameter(ParameterSetName = 'SetModel', Position = 0, Mandatory = $true)]
    [string]$ModelName,

    [Parameter(ParameterSetName = 'List', Mandatory = $true)]
    [switch]$List,

    [Parameter(ParameterSetName = 'Remove', Mandatory = $true)]
    [switch]$Remove,

    [Parameter(ParameterSetName = 'SetModel')]
    [Parameter(ParameterSetName = 'Remove')]
    [ValidateSet('Process', 'User', 'Machine')]
    [string]$Scope = 'User'
)

$registryPath = Join-Path $env:USERPROFILE '.copilot\model_registry.json'

function Get-Registry {
    if (-not (Test-Path $registryPath)) {
        Write-Error "Model registry not found at: $registryPath"
        exit 1
    }
    try {
        return Get-Content $registryPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to parse registry JSON: $_"
        exit 1
    }
}

function Set-EnvVar {
    param([string]$Name, [string]$Value, [string]$Scope)
    [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
    Set-Item -Path "env:$Name" -Value $Value -Force
}

function Remove-EnvVar {
    param([string]$Name, [string]$Scope)
    [Environment]::SetEnvironmentVariable($Name, $null, $Scope)
    if (Test-Path "env:$Name") { Remove-Item -Path "env:$Name" -Force }
}

if ($List -or $ModelName -eq 'list') {
    $registry = Get-Registry
    $models = $registry.PSObject.Properties | ForEach-Object {
        $m = $_.Value
        [pscustomobject]@{
            Name        = $_.Name
            Model       = $m.model
            Provider    = $m.providerType
            ProviderUrl = $m.providerUrl
            Context     = $m.context
            Output      = $m.output
            Offline     = $m.offline
        }
    }
    $models | Format-Table -AutoSize
    exit 0
}

if ($Remove -or $ModelName -eq 'remove') {
    $copilotVars = [Environment]::GetEnvironmentVariables($Scope).Keys | Where-Object { $_ -like 'COPILOT_*' }
    if ($copilotVars.Count -eq 0) {
        Write-Host "No COPILOT_* variables found in $Scope scope."
        exit 0
    }
    foreach ($var in $copilotVars) {
        Remove-EnvVar -Name $var -Scope $Scope
        Write-Host "Removed: $var"
    }
    Write-Host "Cleared all COPILOT_* variables from $Scope scope."
    exit 0
}

$registry = Get-Registry
$model = $registry.$ModelName

if (-not $model) {
    Write-Error "Model '$ModelName' not found in registry."
    Write-Host "Available models: $($registry.PSObject.Properties.Name -join ', ')"
    exit 1
}

$mappings = @{
    'COPILOT_MODEL'                           = $model.model
    'COPILOT_OFFLINE'                         = $model.offline.ToString().ToLower()
    'COPILOT_PROVIDER_BASE_URL'               = $model.providerUrl
    'COPILOT_PROVIDER_MAX_OUTPUT_TOKENS'      = $model.output.ToString()
    'COPILOT_PROVIDER_MAX_PROMPT_TOKENS'      = $model.context.ToString()
    'COPILOT_PROVIDER_TYPE'                   = $model.providerType
    'COPILOT_PROVIDER_API_KEY'                = $model.api_key
}

# Support both 'compaction' and 'compactionThreshold' field names for backward compatibility
$compactionValue = if ($model.compactionThreshold) { $model.compactionThreshold } elseif ($model.compaction) { $model.compaction } else { $null }
if ($compactionValue -ne $null) {
    $mappings['COPILOT_BACKGROUND_COMPACTION_THRESHOLD'] = $compactionValue
}

foreach ($kvp in $mappings.GetEnumerator()) {
    Set-EnvVar -Name $kvp.Key -Value $kvp.Value -Scope $Scope
}

Write-Host "Applied model: $ModelName" -ForegroundColor Green
$mappings.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key) = $($_.Value)"
}