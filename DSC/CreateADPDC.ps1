configuration CreateADPDC
{
  param
  (
    [Parameter(Mandatory)]
    [String]$DomainName,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$Admincreds,

    <# [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$SharePointSetupUserAccountcreds,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$SharePointFarmAccountcreds,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$SharePointServiceAccountcreds,
     #>
    [Int]$RetryCount = 20,
    [Int]$RetryIntervalSec = 30
  )

  Import-DscResource -ModuleName ActiveDirectoryDsc, NetworkingDsc, xDisk, cDisk, PSDesiredStateConfiguration, ComputerManagementDSC

  [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Where-Object InterfaceDescription -like 'Microsoft Hyper-V Network Adapter*' | Select-Object -First 1
  $InterfaceAlias = $($Interface.Name)
  Enable-NetAdapterRss -Name $InterfaceAlias

  Node localhost
  {
    LocalConfigurationManager {
      ConfigurationMode  = 'ApplyOnly'
      RebootNodeIfNeeded = $true
    }

    WindowsFeature DNS {
      Ensure = "Present"
      Name   = "DNS"
    }

    WindowsFeature DnsTools {
      Ensure    = "Present"
      Name      = "RSAT-DNS-Server"
      DependsOn = "[WindowsFeature]DNS"
    }

    DnsServerAddress DnsServerAddress
    {
      Address        = '127.0.0.1'
      InterfaceAlias = $InterfaceAlias
      AddressFamily  = 'IPv4'
      Validate       = $true
      DependsOn      = "[WindowsFeature]DnsTools"
    }
    IEEnhancedSecurityConfiguration IEAdmin {
      Enabled = $false
      Role    = "Administrators"
    }

    IEEnhancedSecurityConfiguration IEUsers {
      Enabled = $false
      Role    = "Users"
    }

    Script script1 {
      SetScript  = {
        Set-DnsServerDiagnostics -All $true
        Write-Verbose -Verbose "Enabling DNS client diagnostics"
      }
      GetScript  = { @{ } }
      TestScript = { $false }
      DependsOn  = "[DnsServerAddress]DnsServerAddress"
    }

    <# xWaitforDisk Disk2
    {
      DiskNumber = 2
      RetryIntervalSec =$RetryIntervalSec
      RetryCount = $RetryCount
      DependsOn  = "[Script]script1"
    }

    cDiskNoRestart ADDataDisk
    {
      DiskNumber  = 2
      DriveLetter = "F"
      DependsOn   ="[xWaitforDisk]Disk2"
    } #>

    WindowsFeature ADDSInstall {
      Ensure    = "Present"
      Name      = "AD-Domain-Services"
      #DependsOn = "[cDiskNoRestart]ADDataDisk"
      DependsOn = "[Script]script1"
    }

    ADDomain FirstDS {
      DomainName                    = $DomainName
      Credential                    = $DomainCreds
      SafemodeAdministratorPassword = $DomainCreds
      DatabasePath                  = "c:\NTDS"
      LogPath                       = "c:\NTDS"
      SysvolPath                    = "c:\SYSVOL"
      DependsOn                     = "[WindowsFeature]ADDSInstall"
    }
    

    <# ADUser SetupUser
    {
      DomainName = $DomainName
      Credential = $DomainCreds
      UserName   = $SharePointSetupUserAccountcreds.UserName
      Password   = $SharePointSetupUserAccountcreds
      Ensure     = "Present"
      DependsOn  = "[ADDomain]FirstDS"
    }
    ADUser FarmUser
    {
      DomainName = $DomainName
      Credential = $DomainCreds
      UserName   = $SharePointFarmAccountcreds.UserName
      Password   = $SharePointFarmAccountcreds
      Ensure     = "Present"
      DependsOn  = "[ADUser]SetupUser"
    }
    ADUser ServiceUser
    {
      DomainName = $DomainName
      Credential = $DomainCreds
      UserName   = $SharePointServiceAccountcreds.UserName
      Password   = $SharePointServiceAccountcreds
      Ensure     = "Present"
      DependsOn  = "[ADUser]FarmUser"
    } #>
  }
}