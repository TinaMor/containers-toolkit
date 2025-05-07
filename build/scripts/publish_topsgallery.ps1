###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

<#
.SYNOPSIS
Publishes the Containers-Toolkit module to the PowerShell Gallery.

.PARAMETER ModulePath
The path to the directory containing the module to publish. "containers-toolkit/"

.PARAMETER ApiKey
The PSGallery API key to use to publish the module.

.PARAMETER ReleaseNotesPath
Path to the release notes. Defaults to empty string.

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [String]$ModulePath = "./containers-toolkit",

    [Parameter(Mandatory = $true)]
    [String]$ApiKey,

    [Parameter(Mandatory = $false)]
    [String]$ReleaseNotesPath
)

$ErrorActionPreference = "Stop"

$ModulePath = Resolve-Path $ModulePath
Write-Output "Publishing module to the PowerShell Gallery. Source: '$ModulePath'..."

# Get license information from the module manifest
$ModuleManifestPath = Join-Path -Path $ModulePath -ChildPath "containers-toolkit.psd1"
$ModuleManifest = Get-Content -Path $ModuleManifestPath -Raw | ConvertFrom-StringData
$LicenseUri = $ModuleManifest.LicenseUri
Write-Output "License URI: $LicenseUri"

$ReleaseNotes = if ($ReleaseNotesPath) { Get-Content -Path $ReleaseNotesPath -Raw } else { '' }
$params = @{
    Path         = "$ModulePath"
    NuGetApiKey  = "$ApiKey"
    LicenseUri   = "$LicenseUri"
    ReleaseNotes = $ReleaseNotes
}

Publish-Module @params
