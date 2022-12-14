[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName,
    [Parameter(Mandatory = $true)]
    [string]
    $AzDevOpsPat
)

$path = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "library_handler.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "project_selector.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "devops_authenticator.ps1" -Resolve)

$devopsProject = Search-AzDevopsProject -ProjectName $ProjectName

$devOpsLibrary = Search-AzDevopsLibrary -AzDevOpsProject $devopsProject

$secretList = @("fileStorageUrl", "fileStorageSAS")

foreach ($secretToRemove in $secretList) {
    $azDevOpsLibrary = $null
    $azDevopsLibraryBody = $null
    
    $azDevOpsLibrary = Get-AzDevopsLibrarySecrets -Project $devopsProject -VariableGroupName $devOpsLibrary.name

    $azDevopsLibraryBody = Remove-SecretToLibrary -Project $devopsProject -VariableGroup $azDevOpsLibrary -SecretName $secretToRemove
    $jsonBody = ConvertTo-Json $azDevopsLibraryBody -Depth 99

    # Write-Host "body > $jsonBody"
    # Write-Host "body > $(ConvertTo-Json $azDevOpsLibrary -Depth 99)"
    Update-AzDevOpsLibrary -ProjectName $devopsProject.name -VariableGroup $azDevOpsLibrary -BodyLibrary $jsonBody
}
