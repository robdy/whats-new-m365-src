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

# ================
#endregion Variables
# ================

# ================
#region Processing
# ================

# Install newest module
Install-Module MicrosoftTeams -Scope CurrentUser -AllowPrerelease

Get-Module MicrosoftTeams -ListAvailable

# Connect

# ================
#region Process cmdlets
# ================

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