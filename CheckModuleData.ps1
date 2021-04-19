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
$dataCmdletsFolder = Join-Path $dataFolder 'cmdlets'
$cmdletsFilePath = Join-Path $dataCmdletsFolder 'cmdlets.json'

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
  Install-Module MicrosoftTeams -Scope CurrentUser -AllowPrerelease -ErrorAction Stop
  Write-Host "MicrosoftTeams module installed"
} catch {
  $err = $_
  Write-Host "Error installing MicrosofTeams module"
  Write-Error $err
}

Get-Module MicrosoftTeams -ListAvailable

# Connect

# ================
#region Process cmdlets
# ================
if (-not (Test-Path $dataCmdletsFolder)) {
  New-Item -ItemType Directory $dataCmdletsFolder
}
$currentCmdlets = Get-Command -Module 'MicrosoftTeams'
$currentCmdlets.Name
$currentCmdlets | Select-Object Name, CommandType | ConvertTo-Csv | ConvertFrom-Csv | ConvertTo-Json -Depth 10 | Out-File $cmdletsFilePath -Force

# ================
#endregion Process cmdlets
# ================

# ================
#region Process cmdlet params
# ================

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

# ================
#endregion Processing
# ================

# ================
#region Cleanup
# ================

# ================
#endregion Cleanup
# ================