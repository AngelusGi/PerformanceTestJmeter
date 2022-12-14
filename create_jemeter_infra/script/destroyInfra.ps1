[CmdletBinding()]
param (
    # project name (ex. AZE1754)
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName,

    # Azure storage account of the project who is requesting performance test
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectAuthToken,

    # Azure DevOps admin path
    [Parameter(Mandatory = $true)]
    [string]
    $AzDevOpsPat,
    
    # Branch in which will pipeline executed
    [Parameter(Mandatory = $false)]
    [string]
    $ExecutionBranch = "refs/heads/main"

)

$path = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "devops_authenticator.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "devops_pipeline_handler.ps1" -Resolve)

$body = @{
    "stagesToSkip"       = @()
    "resources"          = @{
        "repositories" = @{
            "self" = @{
                "refName" = $ExecutionBranch
            }
        }
    }
    "templateParameters" = @{
        "project"   = $ProjectName
        "tokenAuth" = $ProjectAuthToken
    }
    "variables"          = @{}
}

$bodyJson = (ConvertTo-Json $body -Depth 99)
Write-Host "body > $($bodyJson)"
Invoke-AzDevOpsPipeline -BodyJson $bodyJson
