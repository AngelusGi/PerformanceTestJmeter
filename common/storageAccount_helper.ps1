function Connect-ToAzure {
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $ClientId = $env:servicePrincipalId,
        [Parameter(Mandatory = $false)]
        [string]
        $ClientSecret = $env:servicePrincipalKey,
        [Parameter(Mandatory = $false)]
        [string]
        $TenantId = $env:tenantId
    )
    
    process {
        Install-Module "Az.Accounts" -Force -Scope CurrentUser
        Import-Module "Az.Accounts" -Force
        
        Disable-AzContextAutosave
        $SecurePassword = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
        $AzCredential = New-Object System.Management.Automation.PSCredential ($ClientId, $SecurePassword)
        Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $AzCredential
    }
}

function Get-StorageAccountTable {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [string]
        $StorageAccountName,
        [Parameter(Mandatory = $true)]
        [string]
        $StorageAccountTable
    )

    process {
        Install-Module "Az.Resources" -Force -Scope CurrentUser
        Install-Module "Az.Storage" -Force -Scope CurrentUser
        Install-Module "AzTable" -Force -Scope CurrentUser
        Import-Module "Az.Resources" -Force
        Import-Module "Az.Storage" -Force
        Import-Module "AzTable" -Force

        $azStorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        $azStorageAccountContext = $azStorageAccount.Context

        $azStorageTable = Get-AzStorageTable –Context $azStorageAccountContext -Name $AzStorageAccountTable
        return $azStorageTable.CloudTable

    }
}
