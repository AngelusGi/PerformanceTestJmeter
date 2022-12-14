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

    # Name of the project to search in the table storage
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName

)

$path = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "dateTime_helper.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "project_selector.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "storageAccount_helper.ps1" -Resolve)

Connect-ToAzure
$cloudTable = Get-StorageAccountTable -ResourceGroupName $AzRgName -StorageAccountName $AzStgAccName -StorageAccountTable $AzStorageAccountTable

$projectRecords = Get-AzTableRow -PartitionKey $ProjectName -Table $cloudTable

$projectToDestroy = $projectRecords | Where-Object { $_.IsDestroyed -eq $false }

if ($null -eq $projectToDestroy) {
    Write-Host "##[warning] *** ERROR: any performance test to destroy for project '$($ProjectName)' ***"
    exit 1
}

if (($projectToDestroy.GetType()).FullName -eq "System.Object[]") {
    Write-Host "##[error] *** ERROR: multiple performance test for project '$($ProjectName)' in progress ***"
    exit 1
}
else {
    try {
        $projectToDestroy.IsDestroyed = $true
        Write-Host "*** Project record update in progess ***"
        $projectToDestroy | Update-AzTableRow -Table $cloudTable
        Write-Host (ConvertTo-Json $projectToDestroy -Depth 99)
    }
    catch {
        Write-Host "##[error] *** ERROR: unable to update record for project '$($ProjectName)' ***" -ForegroundColor Red
        exit 1
    }
}
