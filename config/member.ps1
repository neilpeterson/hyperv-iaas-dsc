Configuration member {

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    node localhost {
        
        WindowsFeature IIS {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }
    }
}