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

# Policies
$dataPoliciesFolder = Join-Path $dataFolder 'policies'

# Common
$changelogPath = Join-Path $dataFolder 'changelog.json'
$timeFormatString = '%Y-%m-%d %H:%M:%S'
$m365PassString = ConvertTo-SecureString $env:M365_PASSWORD -AsPlainText -Force
$m365Creds = New-Object System.Management.Automation.PSCredential ($env:M365_USERNAME, $m365PassString)

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

if (Test-Path $changelogPath) {
  $changelogContent = Get-Content -Path $changelogPath | ConvertFrom-Json
}

# Get all cmdlets
$currentCmdlets = Get-Command -Module 'MicrosoftTeams'

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

  # Do not process newly-added cmdlets
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

  # Do not add changelog entry for newly-added cmdlet
  if ($cmdlet.Name -notin $addedCmdlets.Name) {
    foreach ($addedParam in $addedParams) {
      $changelogContent = @([pscustomobject]@{
        Category = "Param"
        Cmdlet = $cmdlet.Name
        Param = $addedParam
        Event = "Add"
        Timestamp = Get-Date -UFormat $timeFormatString
      }) + $changelogContent
    }
  }

  # Do not add changelog entry for removed cmdlets
  if ($cmdlet.Name -notin $removedCmdlets.Name) {
    foreach ($removedParam in $removedParams) {
      $changelogContent = @([pscustomobject]@{
        Category = "Param"
        Cmdlet = $cmdlet.Name
        Param = $removedParam
        Event = "Remove"
        Timestamp = Get-Date -UFormat $timeFormatString
      }) + $changelogContent
    }  
  }

  # Export params to the file
  # Also applies to newly-added cmdlets
  # So that next run has something to compare with
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

try {
  $allPoliciesCmdlets = $currentCmdlets | Where-Object {
  $_.Name -match "Get-Cs\w*(Policy|Configuration|Settings)$" -and 
  $_.Name -notin @(
    "Get-CsOnlineVoicemailUserSettings", # User cmdlet
    "Get-CsUserPstnSettings", # User cmdlet
    # Not available for dev tenant
    "Get-CsOnlineDialInConferencingTenantSettings",
    "Get-CsNetworkConfiguration",
    "Get-CsTenantNetworkConfiguration",
    "Get-CsTeamsAudioConferencingPolicy",
    # Not working currently
    "Get-CsTeamsWorkLoadPolicy"
    )
  }

  if (-not (Test-Path $dataPoliciesFolder)) {
    # No directory, create it
    New-Item -ItemType Directory $dataPoliciesFolder | Out-Null
  }

  # Connect to Microsoft Teams
  try {
    Connect-MicrosoftTeams -Credential $m365Creds | Out-Null
  } catch {
    $e = $_
    Write-Host "Error connecting to Microsoft Teams"
    throw $e
  }

  foreach ($policyCmdlet in $allPoliciesCmdlets) {
    <#
    $policyCmdlet = $allPoliciesCmdlets[0]
    #>
    $cmdletName = $policyCmdlet.Name
    $policyFilePath = Join-Path $dataPoliciesFolder "$cmdletName.json"

    # Getting cached policy params
    $cachedPolicyParams = $null
    $cmdletParamsFilePath = Join-Path $dataParamsFolder "$($cmdlet.Name).json"

    if (Test-Path $policyFilePath) {
      # Cached file exists, import it
      $cachedPolicyParams = Get-Content -Path $policyFilePath | ConvertFrom-Json
    }

    # Getting current parameter list
    $allParamList = @()
    $invocationText = "$cmdletName"
    if ($cmdletName -like "*policy") {
      $invocationText += " -Identity Global"
    }
    $scriptBlock = [scriptblock]::Create($invocationText)
    $allParamList = (& $scriptBlock).PSObject.Properties | Select-Object -Expand Name
    
    $addedPolicyParams = @($allParamList | Where-Object -FilterScript {$_ -notin $cachedPolicyParams})
    $removedPolicyParams = @($cachedPolicyParams | Where-Object -FilterScript {$_ -notin $allParamList})

    foreach ($addedPolicyParam in $addedPolicyParams) {
      $changelogContent = @([pscustomobject]@{
        Category = "Policy"
        Cmdlet = $cmdletName
        Param = $addedPolicyParam
        Event = "Add"
        Timestamp = Get-Date -UFormat $timeFormatString
      }) + $changelogContent
    }
    foreach ($removedPolicyParam in $removedPolicyParams) {
      $changelogContent = @([pscustomobject]@{
        Category = "Policy"
        Cmdlet = $cmdletName
        Param = $removedPolicyParam
        Event = "Remove"
        Timestamp = Get-Date -UFormat $timeFormatString
      }) + $changelogContent
    }

    $allParamList | ConvertTo-Json -Depth 10 | Out-File $policyFilePath -Force
  } # end of foreach

} catch {
  $err = $_
  Write-Host "Error processing MicrosofTeams policies"
  Write-Error $err
}

# ================
#endregion Process policies
# ================

# Disconnect Teams
Disconnect-MicrosoftTeams

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
