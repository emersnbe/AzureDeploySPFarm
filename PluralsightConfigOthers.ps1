Configuration PluralsightConfigOthers {


    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName cChoco
    Import-DscResource -ModuleName ComputerManagementDSC
    Import-DscResource -ModuleName xDSCDomainjoin

    $Creds = Get-AutomationPSCredential -Name "DomainJoinCreds"
    $DomainFriendlyCreds = Get-AutomationPSCredential -Name "DomainFriendlyCreds"
    $DomainName = get-AutomationVariable -Name "DomainName"
    
    $env   
    

    node localhost {

        cChocoInstaller installChoco
        {
            InstallDir = "c:\ProgramData\chocolatey"
        }

        cChocoPackageInstaller installEdgeChromium
        {
            Name      = "microsoft-edge"
            DependsOn = "[cChocoInstaller]installChoco"
        }

        cChocoPackageInstaller installSQLServerManStudio
        {
            Name      = "sql-server-management-studio"
            DependsOn = "[cChocoInstaller]installChoco"
        }
        cChocoPackageInstaller vsCode
        {
            Name      = "vsCode"
            DependsOn = "[cChocoInstaller]installChoco"
        }
        cChocoPackageInstaller vsCode-Powershell
        {
            Name      = "vsCode-Powershell"
            DependsOn = "[cChocoInstaller]installChoco"
        }

        DnsServerAddress UseDomainDNS
        {
            Address        = '10.0.0.4'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Validate       = $false
            
        }

        WaitForADDomain emersonline {
            DomainName = 'emersonline.com'
            Credential = $Creds
            RestartCount  = 1
            WaitTimeout   = 600
            DependsOn = '[DNSServerAddress]UseDomainDNS'
            
        }
        
        
        
        xDSCDomainJoin JoinDomain {
            
            Domain     = $DomainName
            Credential = $Creds # Credential to join to domain
            DependsOn  = "[WaitForADDomain]emersonline"
        }

        Group AddSPInstallAccountToLocalAdminGroup {
            GroupName='Administrators'
            Ensure= 'Present'
            MembersToInclude= "Emersonline\SPInstall"
            Credential = $DomainFriendlyCreds
            PsDscRunAsCredential = $DomainFriendlyCreds
            DependsOn = "[xDSCDomainJoin]JoinDomain"
            
        }
        Firewall NB-Datagram-In 
        {
            Ensure = "Present"
            Name = "NB-Datagram-In"
            Enabled = "True"
        }
        Firewall NB-Name-In      
        {
            Ensure = "Present"
            Name = "NB-Name-In"
            Enabled = "True"
        }
        Firewall NB-Session-In         
        {
            Ensure = "Present"
            Name = "NB-Session-In"
            Enabled = "True"
        }
        Firewall SQLPort {
            Ensure = "Present"
            Name = "SQLPort"
            Direction = 'Inbound'
            Protocol = "TCP"
            LocalPort = '1433'
            Enabled = 'True'
        }
        
    }
}