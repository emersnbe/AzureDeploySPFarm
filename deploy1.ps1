
param (
    
    
    [string]$rgbase = "Pluralsight"
    
)

$preferredlocations = "northeurope", "westeurope", "eastUS"
$deploymentName = "ParallelDeploy"
$parametersfile = "C:\code\AzureDeploySPFarm\azuredeploy.parameters.json"
$templatefile = "C:\code\AzureDeploySPFarm\azuredeploy-noExtensions.json"
$suffix = $null
$location = "northeurope"


$rg = Get-AzResourceGroup $rgbase -erroraction silentlycontinue

$newrgname = $rgbase


if ($rg) {
    Write-Host "Resource Group $rgbase already exists."

    while ($rg) {
        $suffix++
        $newrgname = $rgbase + $suffix
        Write-Host "Finding unused Resource Group, trying - $newrgname."
        $rg = Get-AzResourceGroup $newrgname -erroraction silentlycontinue


    }

    
}

Write-Host "$newrgname is unused. Will attempt to create deployment using this group"
Write-Host "Deleting resource groups previously tagged OK to delete: "
$deletedrgs = Get-AzResourceGroup -Tag @{"OKToDelete" = "Yes" } | Select-Object ResourceGroupName, Location
Write-Host ($deletedrgs.ResourceGroupName -join "`n" )
$deletedrgs | Remove-AzResourceGroup -Verbose -force -asjob | Out-Null
Write-Host "...Done"

Write-Host "Creating Resource group in preferred location:  $location " -NoNewline
New-AzResourceGroup $newrgname -Location $location -Tag @{OKToDelete = "Yes";Created = Get-Date } | Out-Null
$DeployedOK = $false

while ($DeployedOK -eq $false) {
    Write-Host "Loop Count (Debug): $i"
    
    Write-Host "Trying Deployment in $newrgname in $location..." -NoNewline
    New-AzResourceGroupDeployment -Name $deploymentName `
        -ResourceGroupName $newrgname `
        -TemplateFile $templatefile `
        -TemplateParameterFile $parametersfile `
        -ErrorVariable DeploymentError `
        -ErrorAction SilentlyContinue `
        -Verbose



    if (!([string]$deploymenterror -like "*quotaexceeded*")) {
        Write-Host "Success"
        $DeployedOK = $true
    }
    else {
        Write-Host "Failed. Waiting for Deleted RG to empty out."
        start-sleep 10
        
        
        

    }
        
}
Write-Host "Getting Public IP Address to manually add DNSLabels"

$PublicIPAddresses = Get-AzPublicIpAddress -ResourceGroupName $newrgname
foreach ($pip in $PublicIPAddresses) {
        
    $DNSLabel = $pip.Name.ToLower() -replace "IP", "emersnbe"
    $pip.dnsSettings = @{"DomainNameLabel" = $DNSLabel }
    
    Set-AzPublicIpAddress -PublicIpAddress $pip | Out-Null
    Write-Host "Created DomainNameLabel $DNSLabel"      
} 

Write-Host 
Write-Host "------------------------------------------------------------------------------------------------------"
Write-Host "Sucessfully launched deployment to Resouce Group $newrgname in $location."
Write-Host "------------------------------------------------------------------------------------------------------"
Write-Host "Deleted the following Resource Groups to cleanup:" 




foreach ($rg in $deletedrgs) {
    Write-Host "$($rg.ResourceGroupName) ($($rg.Location))"
}

Write-Host "------------------------------------------------------------------------------------------------------"
Write-Host

