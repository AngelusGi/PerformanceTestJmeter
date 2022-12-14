function Search-AzDevopsProject {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ProjectName
    )

    process {
        $api = "$($AzDevOpsUrl)/_apis/projects?api-version=6.0-preview.3"

        try {
            $projects = Invoke-RestMethod -Uri $api -Method 'GET' -Headers (Set-ConnectionHeaders -AccessToken ( Set-AccessToken -Psswd $AzDevOpsPat ))
            Write-Host "*** Projects list obtained ***"
        }
        catch {
            Write-Warning "Error log > $($error[0].exception.message)"
            Write-Error "*** ERROR: Unable to get projects for $($ProjectName) ***"
        }

        if ($projects.count -ge 1) {
            $currentProject = $projects.value | Where-Object { $_.name -eq $ProjectName }
            Write-Host "*** Project '$($currentProject.name)' obtained ***"
            return $currentProject        
        }
        else {
            Write-Error "*** ERROR: Any project found in Azure DevOps for $($ProjectName). ***"
        }
    }

}

function Get-ProjectKapp {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ProjectName
    )

    process {
        return ($ProjectName) -replace '\D+(\d+)', '$1'
    }
}
