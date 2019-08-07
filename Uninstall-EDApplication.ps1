<#
.Synopsis
   Uninstalls one or many Win32 applications
.DESCRIPTION
   Uses the registry (both x86 and x64) to find the uninstall string of the applications. The command should work for most if not att .msi applications and most .exe uninstallers if they have the uninstall string registerd in the registry.
.EXAMPLE
   Uninstall-EDApplication -Name "Java"
.EXAMPLE
   Uninstall-EDApplication -Name "Java","vlc","firefox"
.EXAMPLE
   "Java","vlc","firefox" | Uninstall-EDApplication
.INPUTS
   System.String
.OUTPUTS
   System.Management.Automation.PSCustomObject
.RELATED LINKS
    https://github.com/EliasDahlberg
.REMARKS
    https://github.com/EliasDahlberg
.FUNCTIONALITY
   MultiApplication uninstaller
#>

Function Uninstall-EDApplication {
    [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [Alias("Name","Displayname")]
            [string[]]$Application
        )
        BEGIN {
            $Paths = @(
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall')
        }
        PROCESS {
            Foreach ($App in $Application){
                Write-Verbose "Gathering Uninsall strings for $App"

                $InstalledApp = Get-ChildItem -Path $Paths |
                    Get-ItemProperty |
                    Where-Object {$_.DisplayName -match $App}
                
                Foreach ($installedappVersion in $InstalledApp){
                    If ($installedappVersion.UninstallString -like "*.exe`""){
                        #For the uninstall string to work we need to remove any " "
                    
                        Write-Verbose "Trying to uninstall .EXE Application `"$($installedappVersion.DisplayName)`""
                    
                        $UninstallString = $installedappVersion.UninstallString -Replace("`"", "")
                        $ExitCode = Start-Process -FilePath $UninstallString -ArgumentList "/S" -Wait -NoNewWindow -PassThru
                    
                        Write-Verbose ("Uninstalled " + $installedappVersion.DisplayName)
                    
                        $ApplicationStatus = @{
                            SearchTerm = $App
                            Application = $installedappVersion.DisplayName
                            Publisher = $installedappVersion.Publisher
                            InstallLocation = $installedappVersion.InstallLocation
                            Version = $installedappVersion.Version
                            ComputerName = $env:COMPUTERNAME
                            UserName = $env:USERNAME
                            UninstallString = $UninstallString
                            UninstallStatus = $ExitCode.ExitCode
                            UninstallDate = Get-Date -Format yyyyMMdd}
                    }

                    ElseIf ($installedappVersion.UninstallString -like "*MsiExec.exe /X*"){
                        Write-Verbose "Trying to uninstall .MSI Application `"$($installedappVersion.DisplayName)`""
                    
                        $UninstallString = $installedappVersion.UninstallString
                        $MSIExec = $UninstallString -split " "
                        $ExitCode = Start-Process -FilePath $MSIExec[0] -ArgumentList "$($MSIExec[1]) /qn /norestart" -Wait -NoNewWindow -passthru
                        Write-Verbose ("Uninstalled " + $installedappVersion.DisplayName)
                    
                        $ApplicationStatus = @{
                            SearchTerm = $App
                            Application = $installedappVersion.DisplayName
                            Publisher = $installedappVersion.Publisher
                            InstallLocation = $installedappVersion.InstallLocation
                            Version = $installedappVersion.Version
                            ComputerName = $env:COMPUTERNAME
                            UserName = $env:USERNAME
                            UninstallString = $UninstallString
                            UninstallStatus = $ExitCode.ExitCode
                            UninstallDate = Get-Date -Format yyyyMMdd}
                    }
                
                    Else {
                        Write-Verbose "The Application Was Found but there was no uninstall String"
                        
                        $ApplicationStatus = @{
                            SearchTerm = $App
                            Application = $installedappVersion.DisplayName
                            Publisher = $installedappVersion.Publisher
                            InstallLocation = $installedappVersion.InstallLocation
                            Version = $installedappVersion.Version
                            ComputerName = $env:COMPUTERNAME
                            UserName = $env:USERNAME
                            UninstallString = $UninstallString
                            UninstallStatus = $ExitCode.ExitCode
                            UninstallDate = Get-Date -Format yyyyMMdd}
                    }

                $OutputStatus = New-Object -TypeName psobject -Property $ApplicationStatus
                Write-Output $OutputStatus
                
                }
            If (!$InstalledApp){
                Write-Verbose "The Application doesn't seem to exist"
                
                $ApplicationStatus = @{
                    SearchTerm = $App
                    Application = $installedappVersion.DisplayName
                    Publisher = $null
                    InstallLocation = $null
                    Version = $null
                    ComputerName = $env:COMPUTERNAME
                    UserName = $env:USERNAME
                    UninstallString = $null
                    UninstallStatus = "NotFound"
                    UninstallDate = $null}

                $OutputStatus = New-Object -TypeName PSObject -Property $ApplicationStatus
                Write-Output $OutputStatus
            }
        }
    }
    END {
    #Put this here if I or anyone else finds a use for it.
    }
}

#Uninstall-EDApplication -Name "Java"
