configuration windowsfeatures {

    param(
        [Parameter(Mandatory=$true)]
        [string] $Pass
    )

    Import-DscResource -ModuleName PsDesiredStateConfiguration

    node localhost {

        WindowsFeature WebServer {
            Ensure = "Present"
            Name = "Hyper-V"
            IncludeAllSubFeature = $true
        }

        xVMSwitch LabSwitch {

            DependsOn = '[WindowsFeature]Hyper-V'
            Name = 'LabSwitch'
                 Ensure = 'Present'
            Type = 'Internal'
        }

    #     Script ScriptExample
    #     {
    #         GetScript = { 
    #             $results = Get-Item "c:\test.txt"
    #         }
    #         TestScript= { 
    #             Test-Path "c:\test.txt" 
    #         }
    #         SetScript = {
    #             # cmd.exe /C "cmdkey /add:`"nepetersosios.file.core.windows.net`" /user:`"localhost\nepetersosios`" /pass:`"uCw54u3owm0Yq0RGxoG0LEx/hB2WjoipIfcmgzxm5iey1NdhXGSvchXP3SQ9XbJioaE3xpiWeqFmY3KhEp80lA==`""
    #             # New-PSDrive -Name Z -PSProvider FileSystem -Root "\\nepetersosios.file.core.windows.net\windows-os-iso" -Persist
    #             # New-Item c:\test.txt

    #             $secpasswd = ConvertTo-SecureString "Monkeyskip76" -AsPlainText -Force
    #             $mycreds = New-Object System.Management.Automation.PSCredential ("Administrator", $secpasswd)
    #             $output = Invoke-Command -ScriptBlock { 
    #                 cmd.exe /C "cmdkey /add:`"nepetersosios.file.core.windows.net`" /user:`"localhost\nepetersosios`" /pass:`"uCw54u3owm0Yq0RGxoG0LEx/hB2WjoipIfcmgzxm5iey1NdhXGSvchXP3SQ9XbJioaE3xpiWeqFmY3KhEp80lA==`""
    #                 New-PSDrive -Name Z -PSProvider FileSystem -Root "\\nepetersosios.file.core.windows.net\windows-os-iso" -Persist
    #                 New-Item c:\test.txt
    #              } -ComputerName localhost -Credential $mycreds -Verbose
    #         }
    #     }
    # }
}