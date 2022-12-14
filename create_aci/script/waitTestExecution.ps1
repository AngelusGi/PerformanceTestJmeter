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

    # Azure resource group of the project who requested the performance test
    [Parameter(Mandatory = $true)]
    [string]
    $AzProjectRgName,

    # Name of the Jmeter controller name of the project who requested the performance test
    [Parameter(Mandatory = $true)]
    [string]
    $JmeterControllerName,

    # Name of the Jmeter file containing test definition in file share
    [Parameter(Mandatory = $true)]
    [string]
    $JmeterJmxFileName,

    # Name of the project who is requesting performance test
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName

)

$path = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "dateTime_helper.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "storageAccount_helper.ps1" -Resolve)

Connect-ToAzure
$cloudTable = Get-StorageAccountTable -ResourceGroupName $AzRgName -StorageAccountName $AzStgAccName -StorageAccountTable $AzStorageAccountTable

$projectRecords = Get-AzTableRow -Table $cloudTable -PartitionKey $ProjectName

$notDestroied = $projectRecords | Where-Object { $_.IsDestroyed -eq $false }

if ($notDestroied.Count -eq 1) {
    [bool]$isNotTimeExpired = $true
    [bool]$isTestFinished = $false

    Write-Host "Record found for project '$($notDestroied.PartitionKey)'"
    Write-Host "Planned start date > '$($notDestroied.StartDate)'"
    Write-Host "Planned end date > '$($notDestroied.EndDate)'"

    # $commands = @("/bin/sh", "-c", "cp -r /jmeter/$($JmeterJmxFileName) .; /entrypoint.sh -s -J server.rmi.ssl.disable=true")
    # Write-Host "*** Launching performance test ***"

    # foreach ($command in $commands) {
    #     Write-Host "Running command > $($command)"
    #     az container exec --resource-group $AzProjectRgName --name $JmeterControllerName --exec-command $command
    # }

    do {
        $currentTime = Convert-DatesToItalianTime -DateToConvert (Get-CurrentDate)
        Write-Host "current time > $($currentTime)"
        Write-Host "Test in progress..."
        $projectEndDate = Convert-DatesFromTable -DateToConvert $notDestroied.EndDate
        
        if ($currentTime -le $projectEndDate) {
            Start-Sleep -Seconds 60

            $testStatus = az container show --resource-group $AzProjectRgName --name $JmeterControllerName --query "containers[0].instanceView.currentState.state" -o tsv

            if ($testStatus -eq "Running") {
                Write-Host "Test in progress..."
            }
            else {
                $isTestFinished = $true
                Write-Host "Test completed"
            }

            if ($isTestFinished) {
                $isNotTimeExpired = $false
            }
        }
        else {
            Write-Host "##[warning] *** Time expired for project '$($notDestroied.PartitionKey)'. Actual date $($currentTime), project time limit $($projectEndDate). ***"
            Write-Host "Infrastructure destroy will triggered for project '$($notDestroied.PartitionKey)'"
            exit 1
        }
    } while ($isNotTimeExpired)
}
else {
    Write-Warning "*** ERROR: something went work any or multiple performance test in progress *** "
    exit 1
}
