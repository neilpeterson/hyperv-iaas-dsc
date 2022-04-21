Configuration base-fit {

    param ( )

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName SChannelDsc

    node $AllNodes.NodeName {

        $Role = $Node.AzSecPackRole
        $Account = $Node.AzSecPackAcct
        $NameSpace = $Node.AzSecPackNS
        $CertThumb = $Node.AzSecPackCert

        $AzSecPackCMD = "
        set MONITORING_DATA_DIRECTORY=C:\Monitoring\Data
        set MONITORING_TENANT=%USERNAME%
        set MONITORING_ROLE=$Role
        set MONITORING_ROLE_INSTANCE=%COMPUTERNAME%
        set MONITORING_GCS_ENVIRONMENT=DiagnosticsProd
        set MONITORING_GCS_ACCOUNT=$Account
        set MONITORING_GCS_NAMESPACE=$NameSpace
        set MONITORING_GCS_REGION=centralus
        set MONITORING_GCS_THUMBPRINT=$CertThumb
        set MONITORING_GCS_CERTSTORE=LOCAL_MACHINE\MY
        set MONITORING_CONFIG_VERSION=1.0
        %MonAgentClientLocation%\MonAgentClient.exe -useenv"

        Protocol DisableTLS10 {
            Protocol = "TLS 1.0"
            State    = "Disabled"
        }

        Protocol DisableTLS11 {
            Protocol = "TLS 1.1"
            State    = "Disabled"
        }

        Protocol DisableSSL20 {
            Protocol = "SSL 2.0"
            State    = "Disabled"
        }

        Protocol DisableSSL30 {
            Protocol = "SSL 3.0"
            State    = "Disabled"
        }

        Protocol EnableTLS12 {
            Protocol = "TLS 1.2"
            State    = "Enabled"
        }

        CipherSuites ConfigureCipherSuites {
            IsSingleInstance  = 'Yes'
            CipherSuitesOrder = @('TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256')
            Ensure            = "Present"
        }

        File AzSecPackDir {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = 'c:\Monitoring'
        }

        File AzSecPackCMD {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = 'c:\Monitoring\runagentClient.cmd'
            Contents        = $AzSecPackCMD
            DependsOn       = '[File]AzSecPackDir'
        }

        ScheduledTask AzSecPack {
            TaskName            = 'Geneva'
            ScheduleType        = 'AtStartup'
            ActionExecutable    = 'C:\Monitoring\runagentClient.cmd'
            BuiltInAccount      = 'System'
        }
    }
}