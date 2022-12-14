[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]
    $AzDevOpsPat,
    [Parameter(Mandatory = $true)]
    [int]
    $TestTimespan,
    [Parameter(Mandatory = $false)]
    [string]
    $PipelineRunId,
    [Parameter(Mandatory = $true)]
    [int]
    $TimeSpanLimit
)

$path = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "devops_authenticator.ps1" -Resolve)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "devops_pipeline_handler.ps1" -Resolve)

Write-Host "Test timespan limit > $TimeSpanLimit"
Write-Host "Test timespan provided > $TestTimespan"
# Write-Host "Pipeline run id > $PipelineRunId"

if ( $TestTimespan -gt $TimeSpanLimit ) {
    Write-Host "*** Time limit excedeed ***" -ForegroundColor Red
    exit 1
}

# if ($TestTimespan -gt $TimeSpanLimit) {
#     Stop-AzDevOpsPipeline -PipelineRunId $PipelineRunId
# }
