###########################################################################
#                                                                         #
#   Copyright (c) Microsoft Corporation. All rights reserved.             #
#                                                                         #
#   This code is licensed under the MIT License (MIT).                    #
#                                                                         #
###########################################################################

$ErrorActionPreference = 'Stop'

if (!(Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
}
Import-Module -Name PSScriptAnalyzer -Force

$codeAnalysis = Invoke-ScriptAnalyzer -Path .\Containers-Toolkit\ -Recurse -ExcludeRule PSProvideCommentHelp

$lintIssues = $codeAnalysis | Where-Object { $_.Severity -notlike 'Error' }
$lintErrors = $codeAnalysis | Where-Object { $_.Severity -like '*Error' }
Write-Warning "$($lintIssues.Count) errors and $($lintIssues.Count) warnings found"

if ($lintErrors -or $lintIssues) {
    Export-Clixml -Path 'psscriptanalysis.xml' -InputObject $codeAnalysis
}

if ($lintErrors) {
    Throw "$($lintErrors.Count) lint errors found"
}
