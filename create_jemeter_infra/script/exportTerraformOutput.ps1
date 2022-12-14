Write-Host $env:jsonOutputVariablesPath

Write-Host $env

Write-Host "$(jsonOutputVariablesPath)"

$json = Get-Content $env:jsonOutputVariablesPath | Out-String | ConvertFrom-Json

foreach ($prop in $json.psobject.properties) {
    Write-Host("##vso[task.setvariable variable=$($prop.Name);]$($prop.Value.value)")
}