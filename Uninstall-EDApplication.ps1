<#
.Synopsis
   Uninstalls one or many Win32 applications
.DESCRIPTION
   Uses the registry (both x86 and x64) to find the uninstall string of the applications. The command should work for most if not att .msi applications and most .exe uninstallers if they have the uninstall string registerd in the registry.
.EXAMPLE
   Uninstall-EDApplication -Name "Java"
.EXAMPLE
   Uninstall-EDApplication -Name "Java","vlc","firefox"
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
    }
    PROCESS {
        Foreach ($App in $Application){
            Write-Verbose "Gathering Uninsall strings for $App"

            $InstalledApp = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,
                HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall  |        
                Get-ItemProperty |
                Where-Object {$_.DisplayName -match $App}
            
            Foreach ($installedappVersion in $InstalledApp){
                If ($installedappVersion.UninstallString -like "*.exe`"") {
                    #For the uninstall string to work we need to remove any " "
                
                    Write-Verbose "Trying to uninstall .EXE Application `"$($installedappVersion.DisplayName)`""
                
                    $UninstallString = $installedappVersion.UninstallString
                    $UninstallString = $UninstallString -replace "`"", ""
                    Start-Process $UninstallString "/S" -Wait -NoNewWindow
                
                    Write-Verbose ("Uninstalled " + $installedappVersion.DisplayName)
                
                    $ApplicationStatus= @{SearchTerm = $App
                          Application = $installedappVersion.displayname
                          Publisher = $installedappVersion.Publisher                        
                          InstallLocation = $installedappVersion.installLocation
                          Version = $installedappVersion.Version
                          ComputerName = $env:COMPUTERNAME
                          UserName = $env:USERNAME
                          UninstallString = $UninstallString
                          UninstallStatus = "Successful"
                          UninstallDate = Get-Date -Format yyyyMMdd}
                }
            
                elseif ($installedappVersion.UninstallString -like "*MsiExec.exe /X*") {
                    Write-Verbose "Trying to uninstall .MSI Application `"$($installedappVersion.DisplayName)`""
                
                    $UninstallString = $installedappVersion.UninstallString
                    $MSIExec = $UninstallString -split " "
                    Start-Process $MSIExec[0] "$($MSIExec[1]) /qn /norestart" -Wait -NoNewWindow
                    Write-Verbose ("Uninstalled " + $installedappVersion.DisplayName)
                
                    $ApplicationStatus= @{SearchTerm = $App
                          Application = $installedappVersion.displayname
                          Publisher = $installedappVersion.Publisher                        
                          InstallLocation = $installedappVersion.installLocation
                          Version = $installedappVersion.Version
                          ComputerName = $env:COMPUTERNAME
                          UserName = $env:USERNAME
                          UninstallString = $UninstallString
                          UninstallStatus = "Successful"
                          UninstallDate = Get-Date -Format yyyyMMdd}
                }
            
                Else {
                
                    if ($installedappVersion) {
                        Write-Verbose "The Application Was Found but there was no uninstall String"
                        $ApplicationStatus= @{SearchTerm = $App
                              Application = $installedappVersion.displayname
                              Publisher = $installedappVersion.Publisher                        
                              InstallLocation = $installedappVersion.installLocation
                              Version = $installedappVersion.Version
                              ComputerName = $env:COMPUTERNAME
                              UserName = $env:USERNAME
                              UninstallString = $UninstallString
                              UninstallStatus = "Unsuccessful"
                              UninstallDate = Get-Date -Format yyyyMMdd}
                          
                    }
                
                    if (!$installedappVersion) {
                        Write-Verbose "The Application doesn't seem to exist"

                        $ApplicationStatus= @{SearchTerm = $App
                              Application = $installedappVersion.displayname
                              Publisher = $null                       
                              InstallLocation = $null
                              Version = $null
                              ComputerName = $env:COMPUTERNAME
                              UserName = $env:USERNAME
                              UninstallString = $null
                              UninstallStatus = "NotFound"
                              UninstallDate = Get-Date -Format yyyyMMdd}
                    }
                }
            $Done = New-Object -TypeName psobject -Property $ApplicationStatus
            Write-Output $Done
            }
        }
    }
}

#Uninstall-EDApplication -Name "Java"
