Get-AzAutomationAccount|Import-AzAutomationDscConfiguration -SourcePath C:\code\AzureDeploySPFarm\PluralsightConfigOthers.ps1 -published -force|Start-AzAutomationDscCompilationJob
Get-AzAutomationAccount|Import-AzAutomationDscConfiguration -SourcePath C:\code\AzureDeploySPFarm\PluralsightConfigDC.ps1 -published -force|Start-AzAutomationDscCompilationJob