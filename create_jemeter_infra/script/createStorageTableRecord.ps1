[CmdletBinding()]
param (
    # project name (ex. AZE1754)
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName,

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

    # Project test timespan
    [Parameter(Mandatory = $true)]
    [int]
    $TestTimeSpan,

    # Azure resource group of the project who is requesting performance test
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectRgName,

    # Azure storage account of the project who is requesting performance test
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectStgAccName,

    # Test timespan grace period
    [Parameter(Mandatory = $false)]
    [string]
    $TestGracePeriod = 30

)


$path = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "dateTime_helper.ps1" -Resolve) -ErrorAction Stop
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "project_selector.ps1" -Resolve) -ErrorAction Stop
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "storageAccount_helper.ps1" -Resolve) -ErrorAction Stop

Connect-ToAzure

$cloudTable = Get-StorageAccountTable -ResourceGroupName $AzRgName -StorageAccountName $AzStgAccName -StorageAccountTable $AzStorageAccountTable

$timeDefinitions = Get-StartAndEndDate -TimeSpanInMinutes $TestTimeSpan -GracePeriodInMinutes $TestGracePeriod

Add-AzTableRow -Table $cloudTable -PartitionKey $ProjectName -RowKey $timeDefinitions['partitionPrimaryKey'] -property @{"Kapp" = (Get-ProjectKapp -ProjectName $ProjectName); "IsDestroyed" = $false; "AzRgName" = $ProjectRgName; "AzStgName" = $ProjectStgAccName; "TestTimeSpan" = $TestTimeSpan; "StartDate" = (Convert-DatesToItalianTime -DateToConvert ($timeDefinitions['startDate'])); "EndDate" = Convert-DatesToItalianTime -DateToConvert ($timeDefinitions['endDate']) } -Verbose
