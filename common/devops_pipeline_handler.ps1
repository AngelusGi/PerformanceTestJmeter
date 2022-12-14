function Stop-AzDevOpsPipeline {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $PipelineRunId
    )
    process {
        $body = "{`"status`":4}"
        $apiUri = "$($AzDevOpsUrl)/AZU1730/_apis/build/builds/$($PipelineRunId)?api-version=6.0-preview.6"

        try {
            Invoke-RestMethod $apiUri -Method 'PATCH' -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat )) -Body $body
        }
        catch {
            Write-Warning "Error log > $($error[0].exception.message)"
            Write-Error "*** Unable to cancel pipeline 'performance-test' execution in 'AZU1730' with id '$PipelineRunId' ***"
        }
        
        Write-Error "*** Time limit exceeded, cancelling pipeline 'performance-test' execution in 'AZU1730' with id '$PipelineRunId' ***"            
    }
}

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
        Write-Host "*** Pipeline with id '$($PipelineId)' call in progress... ***"
        $response = Invoke-RestMethod -Uri $apiUri -Method 'POST' -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat )) -Body $BodyJson
        Write-Host "*** Pipeline with id '$($PipelineId)' call executed ***"

        $isEndExecution = $false

        do {
            Start-Sleep -s 30
            try {
                $pipelineRun = Invoke-RestMethod -Uri $response.url -Method 'GET' -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat ))
            }
            catch {
                Write-Warning "Error log > $($error[0].exception.message)"
                Write-Error "*** ERROR: Unable to check pipeline with id '$($PipelineId)' state ***"
            }

            Write-Host "pipeline with id '$($PipelineId)' state -> $($pipelineRun.state)"
            
            if ($pipelineRun.state -ne 'inProgress') {
                $isEndExecution = $true

                if ($pipelineRun.result -ne "succeeded") {
                    Write-Error "*** WARNING: pipeline with id '$($PipelineId)' exited with error code -> $($pipelineRun.result)"
                }
                else {
                    Write-Host "pipeline with id '$($PipelineId)' result -> $($pipelineRun.result)"
                }
            }


        } while ($false -eq $isEndExecution)
        
    }
    catch {
        Write-Warning "Error log > $($error[0].exception.message)"
        Write-Error "*** ERROR: Unable to execute with id '$($PipelineId)' ***"
    }

}

