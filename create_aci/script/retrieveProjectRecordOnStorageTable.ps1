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

    # Project name
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName
)

$path = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "project_selector.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "storageAccount_helper.ps1" -Resolve)

Connect-ToAzure
$cloudTable = Get-StorageAccountTable -ResourceGroupName $AzRgName -StorageAccountName $AzStgAccName -StorageAccountTable $AzStorageAccountTable

$projectRecords = Get-AzTableRow -Table $cloudTable -PartitionKey $ProjectName

$notDestroied = $projectRecords | Where-Object { $_.IsDestroyed -eq $false }

if ($notDestroied.Count -eq 1) {
    $variablesToExport = "AzRgName", "AzStgName"
    Write-Host "Record found for project '$($notDestroied.PartitionKey)'"

    foreach ($exportVariable in $variablesToExport) {
        Write-Host "Exporting $($exportVariable) to Azure DevOps Pipeline in progress..."
        Write-Host("##vso[task.setvariable variable=$($exportVariable);issecret=false]$($notDestroied.$exportVariable)")
    }
}
elseif (( [string]::IsNullOrEmpty($notDestroied) -or [string]::IsNullOrWhiteSpace($notDestroied) )) {
    Write-Host "##[warning] *** ERROR: any test in progress for project $($ProjectName) *** "
}
else {
    Write-Warning "*** ERROR: something went work any or multiple performance test in progress for project $($ProjectName) *** "
    exit 1
}
