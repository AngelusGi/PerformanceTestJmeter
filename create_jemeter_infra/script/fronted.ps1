function Invoke-AzDevOpsPipeline {
    param (
        [Parameter(Mandatory = $true)]
        $BodyJson,
        [Parameter(Mandatory = $false)]
        [string]
        # Id of the project within the pipeline to invoke
        $PipelineId = "864",
        [Parameter(Mandatory = $false)]
        [string]
        # Name of the project within the pipeline to invoke
        $PipelineProjectName = "AZU1730"
    )

    $apiUri = "$($AzDevOpsUrl)/$($PipelineProjectName)/_apis/pipelines/$($PipelineId)/runs?api-version=6.0-preview.1"
    Write-Host $apiUri
    try {
        $response = Invoke-RestMethod -Uri $apiUri -Method 'POST' -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat )) -Body $BodyJson
        Write-Host "*** Pipeline in progess ***"

        $isEndExecution = $false
        Get-AzDevOpsPipelineLog -PipelineRunId $response.id -PipelineProjectName $PipelineProjectName

        do {
            # Start-Sleep -s 30
            try {
                $pipelineRun = Invoke-RestMethod -Uri $response.url -Method 'GET' -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat ))
            }
            catch {
                Write-Error "*** ERROR: $($error[0].exception.message) ***"
            }

            Write-Host "pipeline state -> $($pipelineRun.state)"
            
            if ($pipelineRun.state -ne 'inProgress') {
                $isEndExecution = $true

                if ($pipelineRun.result -ne "succeeded") {
                    Write-Warning "*** WARNING: pipeline with id '$($PipelineId)' exited with error code -> $($pipelineRun.result)"
                    Get-AzDevOpsPipelineLog -PipelineRunId $response.id -PipelineProjectName $PipelineProjectName
                }
                else {
                    Get-AzDevOpsPipelineLog -PipelineRunId $response.id -PipelineProjectName $PipelineProjectName
                }
            }


        } while ($false -eq $isEndExecution)
        
    }
    catch {
        Write-Warning "Error log > $($error[0].exception.message)"
        Write-Error "*** ERROR: Unable to execute with id '$($PipelineId)' ***"
    }

}

function Get-AzDevOpsPipelineLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # Id of the project within the pipeline to invoke
        $PipelineRunId,
        [Parameter(Mandatory = $false)]
        [string]
        # Name of the project within the pipeline to invoke
        $PipelineProjectName = "AZU1730"
    )

    process {
        $apiUri = "$($AzDevOpsUrl)/$($PipelineProjectName)/_apis/build/builds/$($PipelineRunId)/logs?api-version=5.1"

        try {
            Start-Sleep 20
            $pipelineDefinition = Invoke-RestMethod -Uri $apiUri -Method 'GET' -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat ))

            foreach ($pipeline in $pipelineDefinition.value) {
                
                $apiUri = "$($AzDevOpsUrl)/$($PipelineProjectName)/_apis/build/builds/$($PipelineRunId)/logs/$($pipeline.id)?api-version=5.1"
                

                $pipelineLog = Invoke-RestMethod -Uri $pipeline.url -Method 'GET' -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat ))
                $pipelineLog
                
                # Write-Host "type > $($pipelineLog.gettype())"
                # if ($pipelineLog.contains("*** ERROR:")) {
                #     $logs = $pipelineLog.Split([System.Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries)

                #     foreach ($el in $logs) {
                #         if ($el.Contains("*** ERROR:")) {
                #             Write-Warning "*********** ************** ************** **********"
                #             Write-Output $el
                #         }
                #     }
                # }
                # ($pipelineLog | ConvertTo-Json -Depth 99)

            }
        }
        catch {
            { 1:<#Do this if a terminating exception happens#> }
        }
    }
}

$AzDevOpsPat = 'w34zfi7kuu52eogdhhtq7wndncq6xirtp4kmvnix6odahgvaw5ea'
$path = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
Import-Module (Join-Path -Path $path -ChildPath "common" -AdditionalChildPath "devops_authenticator.ps1" -Resolve)

$body = @{
    "stagesToSkip"       = @()
    "resources"          = @{
        "repositories" = @{
            "self" = @{
                # "refName" = $ExecutionBranch
            }
        }
    }
    "templateParameters" = @{
        # "project"      = $env:project
        # "tokenAuth"    = $env:tokenAuth
        # "testTimespan" = $env:testTimespan
    }
    "variables"          = @{}
}

# $AzDevOpsPat = $env:TriggerPAT
# Invoke-AzDevOpsPipeline -PipelineId $env:JmeterPipelineIdCreateInfra -BodyJson ($body | ConvertTo-Json -Depth 99)

Invoke-AzDevOpsPipeline -PipelineId 203 -BodyJson ($body | ConvertTo-Json -Depth 99)

