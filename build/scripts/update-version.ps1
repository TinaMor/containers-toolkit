[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [String]$ManifestPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('major', 'minor', 'patch')]
    [String]$ReleaseType
)

$Script:ManifestPath = $ManifestPath
$Script:ReleaseType = $ReleaseType

function Get-NewVersion {
    [version]$currentVersion = (Get-Module -ListAvailable -Name $Script:ManifestPath).Version

    $Major = $currentVersion.Major
    $Minor = $currentVersion.Minor
    $Build = $currentVersion.Build

    switch ($Script:ReleaseType) {
        # MAJOR version is increased for incompatible API changes.
        'major' { 
            $Major++
            $Minor = 0
            $Build = 0
        }
        # MINOR version is increased for backward-compatible feature additions.
        'minor' { 
            $Minor++
            $Build = 0
        }
        # PATCH version is increased for backward-compatible bug fixes.
        'patch' { 
            $Build++
        }
        Default {
            Write-Error "Invalid release type specified: '$Script:ReleaseType'"
            exit 1
        }
    }

    return (New-Object Version -ArgumentList $major, $minor, $build).ToString()
}

$NewSemVer = Get-NewVersion 
Write-Output "Updating module version to $NewSemVer"
$Params = @{
    Path          = $manifestPath
    ModuleVersion = $NewSemVer
}
Update-ModuleManifest @Params


# Test the manifest script is valid
Test-ModuleManifest -Path $manifestPath
