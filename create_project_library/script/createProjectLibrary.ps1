[CmdletBinding()]
param (
    # project name (ex. AZE1754)
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName,

    # Azure DevOps PAT
    [Parameter(Mandatory = $true)]
    [string]
    $AzDevOpsPat,

    # Azure DevOps PAT used by the project to trigger pipeline in DevOps service project
    [Parameter(Mandatory = $true)]
    [string]
    $TriggerPat,

    # string used to encrypt strings
    [Parameter(Mandatory = $true)]
    [string]
    $EncryptionKey
)

Set-Variable -Name "Token" -Value $AzDevOpsPat -Option constant -Scope script
Set-Variable -Name "AzDevOpsServicePipelineId" -Value "758" -Option constant -Scope script

$basePath = (($PSScriptRoot | Split-Path -Parent) | Split-Path -Parent)
Import-Module (Join-Path -Path $basePath -ChildPath "common" -AdditionalChildPath "devops_authenticator.ps1" -Resolve)
Import-Module (Join-Path -Path $basePath -ChildPath "common" -AdditionalChildPath "project_selector.ps1" -Resolve)
Import-Module (Join-Path -Path $basePath -ChildPath "common" -AdditionalChildPath "library_handler.ps1" -Resolve)
Import-Module (Join-Path -Path $basePath -ChildPath "common" -AdditionalChildPath "pipeline_project_authenticator.ps1" -Resolve)

$azDevOpsProject = Search-AzDevopsProject -ProjectName $ProjectName

$azDevOpsLibrary = Search-AzDevopsLibrary -AzDevOpsProject $azDevOpsProject

$bodyAzDevOpsLibrary = Set-AzDevOpsLibraryBodyFirstDeploy -AzDevOpsTargetProject $azDevOpsProject -PipelineAuth (Set-ProjectAuthentication -ProjectNameToEncrypt $ProjectName -EncryptionKey $EncryptionKey) -AzDevOpsTriggerPat $TriggerPat -AzDevOpsServicePipelineId $AzDevOpsServicePipelineId

if ( [string]::IsNullOrEmpty($azDevOpsLibrary) -or [string]::IsNullOrWhiteSpace($azDevOpsLibrary)) {
    #create library
    Write-Host "*** Variable group not found, creation in progess ***"
    New-AzDevOpsLibrary -BodyLibrary $bodyAzDevOpsLibrary -ProjectName $AzDevOpsProject.name
}
else {
    #update library
    Write-Host "*** Variable group found, secret update in progess ***"
    Update-AzDevOpsLibrary -BodyLibrary $bodyAzDevOpsLibrary -ProjectName $AzDevOpsProject.name -VariableGroup $azDevOpsLibrary
}
