Set-Variable -Name "AzDevOpsUrl" -Value "https://dev.azure.com/snam-devops" -Option constant -Scope script

function Set-AccessToken {
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $Usr = '',
        [Parameter(Mandatory = $true)]
        [string]
        $Psswd = ''
    )
    
    process {
        return ( [System.Convert]::ToBase64String( [System.Text.Encoding]::ASCII.GetBytes("$($Usr):$($Psswd)") ) )
    }
}

function Set-ConnectionHeaders {
    param (
        [Parameter( Mandatory = $true )]
        [string]
        $AccessToken,
        [Parameter( Mandatory = $false )]
        [string]
        $ContentType = "application/json",
        [Parameter( Mandatory = $false )]
        [string]
        $AuthenticationType = "Basic"
    )

    process {
        $_headers = New-Object "System.Collections.Generic.Dictionary[[string],[string]]"
        $_headers.Add("Authorization", "$($AuthenticationType) $($AccessToken)")
        $_headers.Add("Content-Type", $($ContentType))

        return $_headers
    }
}
