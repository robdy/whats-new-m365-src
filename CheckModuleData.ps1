<#
  .SYNOPSIS
  Analyses existing cmdlets in Teams modules
  
  .DESCRIPTION
  Version: 0.1
  Analyses existing cmdlets in Teams modules
  and detects any new additions

  .NOTES
  Author: Robert Dyjas https://dyjas.cc

  Workflow:
  - 

  Standards:
  - 

  Features planned:
  - Documentation

  Known issues:
  -

  .EXAMPLE
  CheckModuleData.ps1
#>

# ================
#region Variables
# ================
$dataFolder = 'data'

# Cmdlets
$dataCmdletsFolder = Join-Path $dataFolder 'cmdlets'
$cmdletsFilePath = Join-Path $dataCmdletsFolder 'cmdlets.json'

# Params
$dataParamsFolder = Join-Path $dataFolder 'params'

# Common
$changelogPath = Join-Path $dataFolder 'changelog.json'
$timeFormatString = '%Y-%m-%d %H:%M:%S'

# ================
#endregion Variables
# ================

# ================
#region Processing
# ================

Write-Host "Started processing MicrosoftTeams module"

if ($env:GITHUB_ACTIONS) {
  Set-Location $env:GITHUB_WORKSPACE
}

# Install newest module
try {
  Set-PSRepository PSGallery -InstallationPolicy Trusted
  Install-Module MicrosoftTeams -Scope CurrentUser -AllowPrerelease -ErrorAction Stop -RequiredVersion '2.1.0-preview'
  Write-Host "MicrosoftTeams module installed"
} catch {
  $err = $_
  Write-Host "Error installing MicrosofTeams module"
  Write-Error $err
}

if (Test-Path $changelogPath) {
  $changelogContent = Get-Content -Path $changelogPath | ConvertFrom-Json
}

# ================
#region Process cmdlets
# ================
try {
  if (-not (Test-Path $dataCmdletsFolder)) {
    # No directory, create it
    New-Item -ItemType Directory $dataCmdletsFolder | Out-Null
  }

  if (Test-Path $cmdletsFilePath) {
    # Cached file exists, import it
    $cachedCmdlets = Get-Content -Path $cmdletsFilePath | ConvertFrom-Json
  }

  $currentCmdlets = Get-Command -Module 'MicrosoftTeams'
  $addedCmdlets = @($currentCmdlets | Where-Object -FilterScript {$_.Name -notin $cachedCmdlets.Name})
  $removedCmdlets = @($cachedCmdlets | Where-Object -FilterScript {$_.Name -notin $currentCmdlets.Name})
  Write-Host "Added cmdlets:   $($addedCmdlets.Count)"
  Write-Host "Removed cmdlets: $($removedCmdlets.Count)"

  foreach ($addedCmdlet in $addedCmdlets) {
    $changelogContent = @([pscustomobject]@{
      Category = "Cmdlet"
      Cmdlet = $addedCmdlet.Name
      Event = "Add"
      Timestamp = Get-Date -UFormat $timeFormatString
    }) + $changelogContent
  }
  foreach ($removedCmdlet in $removedCmdlets) {
    $changelogContent = @([pscustomobject]@{
      Category = "Cmdlet"
      Cmdlet = $removedCmdlet.Name
      Event = "Remove"
      Timestamp = Get-Date -UFormat $timeFormatString
    }) + $changelogContent
  }

  $currentCmdlets | Select-Object Name, CommandType | ConvertTo-Csv | ConvertFrom-Csv | ConvertTo-Json -Depth 10 | Out-File $cmdletsFilePath -Force
} catch {
  $err = $_
  Write-Host "Error processing MicrosofTeams cmdlets"
  Write-Error $err
}

# ================
#endregion Process cmdlets
# ================

# ================
#region Process cmdlet params
# ================

try {
  if (-not (Test-Path $dataParamsFolder)) {
  # No directory, create it
  New-Item -ItemType Directory $dataParamsFolder | Out-Null
}

foreach ($cmdlet in $currentCmdlets) {
  <#
  $cmdlet = $currentCmdlets[0]
  #>
  $cachedParams = $null
  $cmdletParamsFilePath = Join-Path $dataParamsFolder "$($cmdlet.Name).json"

  if (Test-Path $cmdletParamsFilePath) {
    # Cached file exists, import it
    $cachedParams = Get-Content -Path $cmdletParamsFilePath | ConvertFrom-Json
  }

  # Getting current parameter list
  $currentParams = $cmdlet.Parameters.GetEnumerator() | Select-Object -ExpandProperty Key
  $addedParams = @($currentParams | Where-Object -FilterScript {$_ -notin $cachedParams})
  $removedParams = @($cachedParams | Where-Object -FilterScript {$_ -notin $currentParams})

  foreach ($addedParam in $addedParams) {
    $changelogContent = @([pscustomobject]@{
      Category = "Param"
      Cmdlet = $cmdlet.Name
      Param = $addedParam
      Event = "Add"
      Timestamp = Get-Date -UFormat $timeFormatString
    }) + $changelogContent
  }
  foreach ($removedParam in $removedParams) {
    $changelogContent = @([pscustomobject]@{
      Category = "Param"
      Cmdlet = $cmdlet.Name
      Param = $removedParam
      Event = "Remove"
      Timestamp = Get-Date -UFormat $timeFormatString
    }) + $changelogContent
  }
  $currentParams | ConvertTo-Json -Depth 10 | Out-File $cmdletParamsFilePath -Force
} # end of foreach

} catch {
  $err = $_
  Write-Host "Error processing MicrosofTeams cmdlet params"
  Write-Error $err
}

# ================
#endregion Process cmdlet params
# ================

# ================
#region Process policies
# ================

# ================
#endregion Process policies
# ================

# Disconnect Teams

# Export changelog
$changelogContent | ConvertTo-Json -Depth 3 | Out-File $changelogPath -Force

# ================
#endregion Processing
# ================

# ================
#region Cleanup
# ================

# ================
#endregion Cleanup
# ================