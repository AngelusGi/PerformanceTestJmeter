[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountSas,
    [Parameter(Mandatory = $true)]
    [string]
    $StorageAccountUrl,
    [Parameter(Mandatory = $true)]
    [string]
    $AzDevOpsPat
)

$path = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "library_handler.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "project_selector.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "devops_authenticator.ps1" -Resolve)

# NOME LIBRARY -> <KAPP>-Secret-PerformanceTest
# TOKEN SAS -> fileStorageSAS
# URL FILE SHARE -> fileStorageUrl

$devopsProject = Search-AzDevopsProject -ProjectName $ProjectName

$devOpsLibrary = Search-AzDevopsLibrary -AzDevOpsProject $devopsProject

$secretList = @(@{"name" = "fileStorageUrl"; "secret" = $StorageAccountUrl; }, @{"name" = "fileStorageSAS"; "secret" = $StorageAccountSas; })

foreach ($secretToAdd in $secretList) {
    $azDevOpsLibrary = Get-AzDevopsLibrarySecrets -Project $devopsProject -VariableGroupName $devOpsLibrary.name

    $azDevopsLibraryBody = Add-SecretToLibrary -Project $devopsProject -VariableGroup $azDevOpsLibrary -SecretName $secretToAdd['name'] -SecretValue $secretToAdd['secret']
    Update-AzDevOpsLibrary -ProjectName $devopsProject.name -VariableGroup $azDevOpsLibrary -BodyLibrary (ConvertTo-Json $azDevopsLibraryBody -Depth 99)
}
