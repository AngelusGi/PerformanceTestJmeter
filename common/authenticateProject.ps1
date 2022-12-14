[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName,
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectAuthToken,
    [Parameter(Mandatory = $true)]
    [string]
    $EncryptionKey,
    [Parameter(Mandatory = $false)]
    [string]
    $PipelineRunId,
    [Parameter(Mandatory = $false)]
    [string]
    $AzDevOpsPat
)

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "pipeline_project_authenticator.ps1" -Resolve)
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "devops_pipeline_handler.ps1" -Resolve)

Test-ProjectAuthentication -EncryptedText $ProjectAuthToken -EncryptionKey $EncryptionKey -ProjectName $ProjectName

# $unencryptedText = Test-ProjectAuthentication -EncryptedText $ProjectAuthToken -EncryptionKey $EncryptionKey
# Write-Host "Unencrypted text > $($unencryptedText)"

# if ($unencryptedText -notmatch "$($ProjectName)") {
#     Stop-AzDevOpsPipeline -PipelineRunId $PipelineRunId
#     Write-Error "*** ERROR: project authentication failed ***"
# }
