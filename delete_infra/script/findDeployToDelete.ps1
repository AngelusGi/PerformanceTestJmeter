[CmdletBinding()]
param (
    # Azure resource group of the administrative project
    [Parameter(Mandatory = $true)]
    [string]
    $AzRgName,

    # Azure storage account of the administrative project
    [Parameter(Mandatory = $true)]
    [string]
    $AzStgAccName,

    # Azure storage table of the administrative project
    [Parameter(Mandatory = $true)]
    [string]
    $AzStorageAccountTable,

    # Branch in which will pipeline executed
    [Parameter(Mandatory = $false)]
    [string]
    $ExecutionBranch = "refs/heads/main",

    [Parameter(Mandatory = $true)]
    [string]
    $AzDevOpsPat

)

$path = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "dateTime_helper.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "project_selector.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "storageAccount_helper.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "devops_authenticator.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "devops_pipeline_handler.ps1" -Resolve)

Connect-ToAzure
$cloudTable = Get-StorageAccountTable -ResourceGroupName $AzRgName -StorageAccountName $AzStgAccName -StorageAccountTable $AzStorageAccountTable

$projectRecords = Get-AzTableRow -Table $cloudTable

$notDestroied = $projectRecords | Where-Object { $_.IsDestroyed -eq $false }

$currentTime = Convert-DatesToItalianTime -DateToConvert (Get-CurrentDate)

foreach ($project in $notDestroied) {
    $projectEndDate = Convert-DatesFromTable -DateToConvert $project.EndDate
    
    if ($currentTime -le $projectEndDate) {
        Write-Host "Any performance test to destroy in project '$($project.PartitionKey)'"
    }
    else {
        Write-Host "##[warning] *** Time expired for project '$($project.PartitionKey)'. Actual date $($currentTime), project time limit $($projectEndDate). ***"
        Write-Host "Trigger infrastructure destroy for project '$($project.PartitionKey)'"

        $body = @{
            "stagesToSkip"       = @(
                "AuthenticateProject"
            )
            "resources"          = @{
                "repositories" = @{
                    "self" = @{
                        "refName" = $ExecutionBranch
                    }
                }
            }
            "templateParameters" = @{
                "project"   = $($project.PartitionKey)
                "tokenAuth" = "Admin"
            }
            "variables"          = @{}
        }
        
        $bodyJson = (ConvertTo-Json $body -Depth 99)
        Write-Host "body > $($bodyJson)"
        Invoke-AzDevOpsPipeline -BodyJson $bodyJson
    }
}
