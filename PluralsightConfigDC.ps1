Configuration PluralsightConfigDC {


    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName cChoco
    Import-DscResource -ModuleName ComputerManagementDSC
    Import-DscResource -ModuleName xDNSServer
   

    $DomainCreds = Get-AutomationPSCredential -Name "DomainAdmin"
    $DomainName = get-AutomationVariable -Name "DomainName"
    $NBDomainName, $null = $DomainName -split "\."
    $AzureFileShareCreds = Get-AutomationPSCredential -Name "AzureFileShare"
    
        
    Node "localhost" {
        
        cChocoInstaller installChoco
        {
            InstallDir = "c:\ProgramData\chocolatey"
            
        }

        cChocoPackageInstaller installEdgeChromium
        {
            Name      = "microsoft-edge"
            DependsOn = "[cChocoInstaller]installChoco"
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

        xDnsRecord SPWildcardArecord
        {
            Ensure    = 'Present'
            Name      = "*"
            Zone      = $DomainName
            Type      = 'ARecord'
            Target    = "10.0.0.7"
            DependsOn = '[WindowsFeature]DNS'
        }

        
      
        DnsServerAddress DnsServerAddress {
            Address        = '127.0.0.1'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Validate       = $true
            DependsOn      = "[WindowsFeature]DnsTools"
        }
        
        WindowsFeature ADDSInstall {
            Ensure    = "Present"
            Name      = "AD-Domain-Services"
            #DependsOn = "[cDiskNoRestart]ADDataDisk"
            DependsOn = "[DnsServerAddress]DnsServerAddress"
        }

        WindowsFeature ADTools {
            Ensure    = "Present"
            Name      = "RSAT-ADDS"
            DependsOn = "[WindowsFeature]ADDSInstall"

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
        
        

        WaitForADDomain "emersonline" {
            DomainName = "emersonline.com"
            Credential = $Creds
            DependsOn  = "[ADDomain]FirstDS"
        }

        
        

        ADUser 'SPInstall' {
            Ensure               = 'Present'
            UserName             = 'SPInstall'
            Password             = $DomainCreds
            DomainName           = $DomainName
            DisplayName          = "SP Install Account"
            PasswordNeverExpires = $true
            DependsOn            = "[WaitForADDomain]emersonline"
        }
    

        ADUser 'SPFarm' {
            Ensure               = 'Present'
            UserName             = 'SPFarm'
            Password             = $DomainCreds
            DomainName           = $DomainName
            DisplayName          = "SP Install Account"
            PasswordNeverExpires = $true
            DependsOn            = "[WaitForADDomain]emersonline"
        }

        

        ADUser 'SPCacheSuperReader' {
            Ensure               = 'Present'
            UserName             = 'SPCacheSuperReader'
            Password             = $DomainCreds
            DomainName           = $DomainName
            DisplayName          = "SP Cache Reader Account"
            PasswordNeverExpires = $true
            DependsOn            = "[WaitForADDomain]emersonline"
        }
        ADUser 'SPCacheSuperUser' {
            Ensure               = 'Present'
            UserName             = 'SPCacheSuperUser'
            Password             = $DomainCreds
            DomainName           = $DomainName
            DisplayName          = "SP Cache Reader Account"
            PasswordNeverExpires = $true
            DependsOn            = "[WaitForADDomain]emersonline"
        }
        ADUser 'SPWebAppPool' {
            Ensure               = 'Present'
            UserName             = 'SPWebAppPool'
            Password             = $DomainCreds
            DomainName           = $DomainName
            DisplayName          = "SP Web Application Pool Account"
            PasswordNeverExpires = $true
            DependsOn            = "[WaitForADDomain]emersonline"
        }
        ADUser 'SPServiceAppPool' {
            Ensure               = 'Present'
            UserName             = 'SPServiceAppPool'
            Password             = $DomainCreds
            DomainName           = $DomainName
            DisplayName          = "SP Service Application Pool Account"
            PasswordNeverExpires = $true
            DependsOn            = "[WaitForADDomain]emersonline"
        }
        ADUser 'SPProfile' {
            Ensure               = 'Present'
            UserName             = 'SPProfile'
            Password             = $DomainCreds
            DomainName           = $DomainName
            DisplayName          = "SP User Profile Service Account"
            PasswordNeverExpires = $true
            DependsOn            = "[WaitForADDomain]emersonline"
        }
        ADUser 'SPContent' {
            Ensure               = 'Present'
            UserName             = 'SPContent'
            Password             = $DomainCreds
            DomainName           = $DomainName
            DisplayName          = "SP Search Content Account"
            PasswordNeverExpires = $true
            DependsOn            = "[WaitForADDomain]emersonline"
        }
        ADUser 'SQLInstall' {
            Ensure               = 'Present'
            UserName             = 'SQLInstall'
            Password             = $DomainCreds
            DomainName           = $DomainName
            DisplayName          = "SQL Install Account"
            PasswordNeverExpires = $true
            DependsOn            = "[WaitForADDomain]emersonline"
        }
        ADUser 'SQLService' {
            Ensure               = 'Present'
            UserName             = 'SQLService'
            Password             = $DomainCreds
            DomainName           = $DomainName
            DisplayName          = "SQL Service Account"
            PasswordNeverExpires = $true
            DependsOn            = "[WaitForADDomain]emersonline"
        }
        <# Script "NetworkDiscovery" {
            TestScript = { $false }
            SetScript  = {
                Invoke-Expression -Command 'netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes'
            }
            GetScript  = { "" }
            Credential = $DomainCreds    
        }

        Firewall SMBRulesIN "FPS-SMB-In-TCP"
        {
            Ensure = "Present"
            Name = "FPS-SMB-In-TCP"
            Enabled = "True"
        }
        Firewall SMBRulesOUT "FPS-SMB-Out-TCP"
        {
            Ensure = "Present"
            Name = "FPS-SMB-Out-TCP"
            Enabled = "True"
        } #>


        File "CopySPSource" {
            SourcePath      = "\\emersnbesharedfiles.file.core.windows.net\emersnbeshared"
            DestinationPath = "c:\SharedFiles"
            Ensure          = "Present"
            Credential      = $AzureFileShareCreds
            Type            = "Directory"
            Recurse         = $true
        }

        SmbShare 'SharedFiles'
        {
            Name                  = 'SharedFiles'
            Path                  = 'C:\SharedFiles'
            ConcurrentUserLimit   = 20
            EncryptData           = $false
            FolderEnumerationMode = 'AccessBased'
            CachingMode           = 'Manual'
            ContinuouslyAvailable = $false
            FullAccess            = @("$NBdomainname\spinstall")
            ReadAccess            = @('Everyone')
            DependsOn             = '[File]CopySPSource'
        }
    }    
    
}      
        
