configuration windowsfeatures {

    # param(
    #     [Parameter(Mandatory=$true)]
    #     [string] $Pass
    # )

    Import-DscResource -ModuleName PsDesiredStateConfiguration

    node localhost {

        WindowsFeature WebServer {
            Ensure = "Present"
            Name = "Hyper-V"
            IncludeAllSubFeature = $true
        }

        Script ScriptExample
        {
            SetScript = {
                # cmd.exe /C "cmdkey /add:`"nepetersosios.file.core.windows.net`" /user:`"localhost\nepetersosios`" /pass:$Pass"
                # New-PSDrive -Name Z -PSProvider FileSystem -Root "\\nepetersosios.file.core.windows.net\windows-os-iso" -Persist
                New-Item c:\test.txt
            }
        }
    }
}