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
    $ProjectName,

    [Parameter(Mandatory = $true)]
    [string]
    $JmeterControllerIp,

    [Parameter(Mandatory = $true)]
    [string]
    $JmeterWorkersIp,

    [Parameter(Mandatory = $true)]
    [string]
    $ShaSubnet,

    [Parameter(Mandatory = $false)]
    [string]
    $Protocol = 'Ah',

    [Parameter(Mandatory = $false)]
    [string]
    $Access = 'Allow',

    [Parameter(Mandatory = $false)]
    [int]
    $PortRangeStart = 0,

    [Parameter(Mandatory = $false)]
    [int]
    $PortRangeEnd = 65535

)

$azNsg = az network nsg show --name $AzNsgName --resource-group $AzRgName | ConvertFrom-Json -Depth 99
$existingRules = az network nsg rule list --resource-group $azNsg.resourceGroup --nsg-name $azNsg.name | ConvertFrom-Json -Depth 99
$projectRule = $existingRules | Where-Object { $_.name -match $ProjectName }

if ($null -eq $projectRule) {
    Write-Host "*** Rules creation in progress for project '$($ProjectName)' ***"
    
    # nodi worker accettano richieste solo da nodo controller
    # nodo controller accetta richieste solo da subnet sha richieste solo da nodo controller
    # nessuno accetta richieste da service tag internet

    # # storage account accetta connessioni solo da:
    #     - SUBNET SHA
    #     - IP NODI WORKER
    #     - IP NODO CONTROLLER
    
    $rulesList = @("Jmeter-Controller", "Jmeter-Worker", "Jmeter-SHA")
    $any = '*'
    # Write-Host "Controller Ip > $($JmeterControllerIp)"
    # Write-Host "Worker Ips > $($JmeterWorkersIp)"
    # Write-Host "SHA Subnet > $($ShaSubnet)"

    foreach ($ruleType in $rulesList) {

        if ($ruleType -match "Controller") {
            $description = "$($ProjectName) - Performance Test - Jmeter controller ACIs accepts only from Jmeter worker nodes"
            $sourceIp = $JmeterWorkersIp
            $destinationIp = $JmeterControllerIp
        }
        elseif ($ruleType -match "Worker") {
            $description = "$($ProjectName) - Performance Test - Jmeter Workers ACIs accepts only from Jmeter controller node"
            $sourceIp = $JmeterControllerIp
            $destinationIp = $JmeterWorkersIp
        }
        else {
            #SHA
            $description = "$($ProjectName) - Performance Test - Jmeter controller ACIs accepts only from SHA"
            # $sourceIp = $ShaSubnet
            $sourceIp = $any
            $destinationIp = $JmeterControllerIp
        }

        $ruleName = "$($ProjectName)-$($ruleType)"
        Write-Host "*** Creating rule '$($ruleName)' ***"

        try {
            foreach ($source in ($sourceIp.split(','))) {
                foreach ($destination in ($destinationIp.split(','))) {
                    $azNsg = az network nsg show --name $AzNsgName --resource-group $AzRgName | ConvertFrom-Json -Depth 99
                    $existingRules = $null
                    $existingRules = az network nsg rule list --resource-group $azNsg.resourceGroup --nsg-name $azNsg.name | ConvertFrom-Json -Depth 99

                    [int]$priority = ($existingRules.priority | Measure-Object -Maximum).Maximum

                    if ($priority -lt 100) {
                        $priority = 99
                    }

                    if ($priority -gt 4090) {
                        Write-Error "*** Error: creating rules for project '$($ProjectName)', any slot available to create rule. Actual rule count '$($priority)' ***"
                        exit 1
                    }
            
                    $azNsgRule = az network nsg rule create --resource-group "$($azNsg.resourceGroup)" --nsg-name "$($azNsg.name)" --name "$($ruleName)-$(Get-Random -Minimum 110 -Maximum 999)" --priority "$($priority + 1)" --source-address-prefixes "$($source)" --source-port-ranges 0-65535 --destination-address-prefixes "$($destination)" --destination-port-ranges 0-65535 --access "$($Access)" --protocol "$($Protocol)" --description "$($description)" | ConvertFrom-Json -Depth 99
            
                    Start-Sleep -Seconds 30
                    Write-Host "Rule '$($azNsgRule.name)' created with priority '$($azNsgRule.priority)' and provisioning state '$($azNsgRule.provisioningState)' ***"
                }
            }
        }
        catch {
            Write-Error "*** Error: creating rules for project '$($ProjectName)'. ***"
            exit 1
        }
        
    }

}
else {
    Write-Error "*** Error: rules for project '$($ProjectName)' already exist. ***"
    exit 1
}
