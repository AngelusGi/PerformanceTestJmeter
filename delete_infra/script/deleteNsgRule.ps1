[CmdletBinding()]
param (
    # Azure resource group of the administrative project
    [Parameter(Mandatory = $true)]
    [string]
    $AzRgName,

    # Azure storage account of the administrative project
    [Parameter(Mandatory = $true)]
    [string]
    $AzNsgName,

    # Project name
    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName

)

$azNsg = az network nsg show --name $AzNsgName --resource-group $AzRgName | ConvertFrom-Json -Depth 99
$existingRules = az network nsg rule list --resource-group $azNsg.resourceGroup --nsg-name $azNsg.name | ConvertFrom-Json -Depth 99

$projectRule = $existingRules | Where-Object { $_.name -match $ProjectName }

if ($null -ne $projectRule) {
    Write-Host "*** Rules deletion in progress for project '$($ProjectName)' ***"

    foreach ($rule in $projectRule) {
        Write-Host "*** Deleting rule '$($rule.name)' ***"
        az network nsg rule delete --resource-group $azNsg.resourceGroup --nsg-name $azNsg.name --name $rule.name
    }

}else {
    Write-Host "##[warning] *** Error: any rule found for project '$($ProjectName)'. ***"
}
