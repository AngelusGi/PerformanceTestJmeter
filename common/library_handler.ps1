Set-Variable -Name "TechnologyType" -Value "PerformanceTest" -Option constant -Scope script
Set-Variable -Name "SecretLabel" -Value "JmeterPerfTest" -Option constant -Scope script

function Set-AzDevOpsLibraryBodyFirstDeploy {
    param (
        [Parameter(Mandatory = $true)]
        $AzDevOpsTargetProject,

        [Parameter(Mandatory = $true)]
        [string]
        $PipelineAuth,

        [Parameter(Mandatory = $true)]
        [string]
        $AzDevOpsTriggerPat,
        
        [Parameter(Mandatory = $true)]
        [string]
        $AzDevOpsServicePipelineId,

        [Parameter(Mandatory = $false)]
        [string]
        $AzDevOpsServiceProjectName = "AZU1730"
    )

    process {
        $variableGroupName = "$($AzDevOpsTargetProject.name)-Secret-$($TechnologyType)"
        $variableGroupDescription = "$($variableGroupName)-Description"

        $body = @{
            "description"                    = $variableGroupDescription
            "name"                           = $variableGroupName
            "providerData"                   = $null
            "type"                           = "Vsts"
            "variables"                      = @{
                "Service_$($SecretLabel)_PipelineAuth"                = @{
                    "isSecret" = $true
                    "value"    = $PipelineAuth
                }
                "Service_$($SecretLabel)_CreateInfra_PipelineId"      = @{
                    "isSecret" = $true
                    "value"    = "758"
                }
                "Service_$($SecretLabel)_CreateContainers_PipelineId" = @{
                    "isSecret" = $true
                    "value"    = "872"
                }
                "Service_$($SecretLabel)_DestroyInfra_PipelineId"     = @{
                    "isSecret" = $true
                    "value"    = "864"
                }
                "Service_$($SecretLabel)_Project"                     = @{
                    "isSecret" = $true
                    "value"    = $AzDevOpsServiceProjectName
                }
                "Service_$($SecretLabel)_Trigger_PAT"                 = @{
                    "isSecret" = $true
                    "value"    = $AzDevOpsTriggerPat
                }
            }
            "variableGroupProjectReferences" = @(
                @{
                    "description"      = $variableGroupDescription
                    "name"             = $variableGroupName
                    "projectReference" = @{
                        "id"   = $AzDevOpsTargetProject.id
                        "name" = $AzDevOpsTargetProject.name
                    }
                }
            )
        }
        return  $body | ConvertTo-Json -Depth 99
    }
}

function Set-AzDevOpsLibraryBodyUpdate {
    param (
        [Parameter(Mandatory = $true)]
        $AzDevOpsTargetProject,

        [Parameter(Mandatory = $true)]
        [string]
        $PipelineAuth,

        [Parameter(Mandatory = $true)]
        [string]
        $AzDevOpsTriggerPat,
        
        [Parameter(Mandatory = $true)]
        [string]
        $AzDevOpsServicePipelineId,

        [Parameter(Mandatory = $false)]
        [string]
        $AzDevOpsServiceProjectName = "AZU1730"
    )

    process {
        
    }
}


function New-AzDevOpsLibrary {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ProjectName,
        [Parameter(Mandatory = $true)]
        $BodyLibrary
    )

    process {
        $api = "$($AzDevOpsUrl)/_apis/distributedtask/variablegroups?api-version=6.1-preview.2"

        try {
            Write-Host "*** Library creation in $($ProjectName) project in progress ***"
            Invoke-RestMethod -Uri $api -Method 'POST' -Body $BodyLibrary -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat ))
        }
        catch {
            Write-Warning "Error log > $($error[0].exception.message)"
            Write-Error "*** ERROR: Unable to create library in $($ProjectName) project ***"
        }

    }

}

function Update-AzDevOpsLibrary {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ProjectName,
        [Parameter(Mandatory = $true)]
        $VariableGroup,
        [Parameter(Mandatory = $true)]
        $BodyLibrary
    )

    process {
        $api = "$($AzDevOpsUrl)/_apis/distributedtask/variablegroups/$($VariableGroup.id)?api-version=6.0-preview.2"

        try {
            Write-Host "*** Library update in $($ProjectName) project in progress ***"
            Invoke-RestMethod -Uri $api -Method 'PUT' -Body $BodyLibrary -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat ))
        }
        catch {
            Write-Warning "Error log > $($error[0].exception.message)"
            Write-Error "*** ERROR: Unable to update library in $($ProjectName) project ***"
        }

    }

}

function Search-AzDevopsLibrary {
    param (
        [Parameter(Mandatory = $true)]
        $AzDevOpsProject,
        [Parameter(Mandatory = $false)]
        [string]
        $AzDevOpsLibraryName
    )
    
    process {
        $devopsLibrary = Get-AzDevopsLibrary -AzDevOpsProject $AzDevOpsProject

        if ([string]::IsNullOrWhiteSpace($AzDevOpsLibraryName) -or [string]::IsNullOrEmpty($AzDevOpsLibraryName)) {
            $AzDevOpsLibraryName = "$($AzDevOpsProject.name)-Secret-$($TechnologyType)"
        }

        if ($devopsLibrary.count -ge 1) {
            $currentLibrary = ($devopsLibrary.value | Select-Object id, name, description | Where-Object name -EQ $AzDevOpsLibraryName)
            Write-Host "*** Searching '$($AzDevOpsLibraryName)' library ***"
            return $currentLibrary        
        }
        else {
            Write-Error "*** ERROR: Any project found in Azure DevOps for $($ProjectName). ***"
            return $null
        }
    }
}

function Get-AzDevopsLibrary {
    param (
        [Parameter(Mandatory = $true)]
        $AzDevOpsProject
    )
    
    process {
        $api = "$($AzDevOpsUrl)/$($AzDevOpsProject.name)/_apis/distributedtask/variablegroups?api-version=6.0-preview.2"
        
        try {
            $variableGroupList = Invoke-RestMethod $api -Method 'GET' -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat ))
            Write-Host "*** Projects libraries obtained ***"
        }
        catch {
            Write-Warning "Error log > $($error[0].exception.message)"
            Write-Error "*** ERROR: Unable to get libraries for $($ProjectName) ***"
        }

        return $variableGroupList
    }
}

function Get-AzDevopsLibrarySecrets {
    param (
        [Parameter(Mandatory = $true)]
        $Project,
        [Parameter(Mandatory = $true)]
        [string]
        $VariableGroupName
    )

    process {
        $api = "$($AzDevOpsUrl)/$($Project.name)/_apis/distributedtask/variablegroups?groupName=$($VariableGroupName)&api-version=6.0-preview.2"

        try {
            Write-Host "*** Retriving secrets in library '$($VariableGroupName)' in '$($Project.name)' project ***"
            $library = Invoke-RestMethod -Uri $api -Method 'GET' -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat ))
        }
        catch {
            Write-Warning "Error log > $($error[0].exception.message)"
            Write-Error "*** ERROR: Unable to retrieve secrets in library '$($VariableGroupName)' in '$($Project.name)' project ***"
        }

        if ($library.count -gt 0) {
            $library = (ConvertFrom-Json (ConvertTo-Json ($library.value[0]) -Depth 99) -AsHashtable -Depth 99)

            $library.Remove('variableGroupProjectReferences')
            
            $projectReferences = @(
                @{
                    "description"      = $library.description
                    "name"             = $library.name
                    "projectReference" = @{
                        "id"   = $Project.id
                        "name" = $Project.id
                    }
                }
            )
            $library.add('variableGroupProjectReferences', $projectReferences)

            return $library
        }
        else {
            Write-Error "*** ERROR: Unable to retrieve secrets in library '$($VariableGroupName)' in '$($ProjectName)' project ***"
        }
    }
}

function Add-SecretToLibrary {
    param (
        [Parameter(Mandatory = $true)]
        $Project,
        [Parameter(Mandatory = $true)]
        $VariableGroup,
        [Parameter(Mandatory = $true)]
        [string]
        $SecretName,
        [Parameter(Mandatory = $true)]
        [string]
        $SecretValue,
        [Parameter(Mandatory = $false)]
        [bool]
        $IsSecret = $true
    )

    process {
        # $library = ConvertFrom-Json -InputObject $VariableGroupJson -AsHashtable -Depth 99
        
        $values = @{
            "isSecret"    = $IsSecret
            "isReadOnly"  = $false
            "value"       = $SecretValue
            "enabled"     = $true
            "contentType" = ""
            "expires"     = $null
        }

        $VariableGroup.variables.add($SecretName, $values)
        Write-Host "*** Adding '$($SecretName)' ***"
        return $VariableGroup

        # $library.variables.add($SecretName, $values)
        # return $library
        # return (ConvertTo-Json $library -Depth 99)

    }
}

function Remove-SecretToLibrary {
    param (
        [Parameter(Mandatory = $true)]
        $Project,
        [Parameter(Mandatory = $true)]
        $VariableGroup,
        [Parameter(Mandatory = $true)]
        [string]
        $SecretName
    )

    process {
        # $tmp = $VariableGroup.variables
        # Write-Host "****************************************"
        # Write-Host ($VariableGroup | Out-String)
        # Write-Host "****************************************"
        # $tmp = $VariableGroup.variables.remove($SecretName)
        # Write-Host ($tmp | Out-String)
        $VariableGroup.variables.remove($SecretName)
        Write-Host " *** Removing '$($SecretName)' ***"
        return $VariableGroup
    }
}
