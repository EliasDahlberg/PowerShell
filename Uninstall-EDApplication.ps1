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
    Process {
        Foreach ($App in $Application){
            Write-Verbose "Gathering Uninsall strings for $App"

            $InstalledApp = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,
                HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall  |        
                Get-ItemProperty |
                Where-Object {$_.DisplayName -match $App}
            
            If ($InstalledApp.UninstallString -like "*.exe`"") {
                #For the uninstall string to work we need to remove any " "
                
                Write-Verbose "Trying to uninstall .EXE Application `"$($InstalledApp.DisplayName)`""
                
                $UninstallString = $InstalledApp.UninstallString
                $UninstallString = $UninstallString -replace "`"", ""
                & cmd.exe /C $UninstallString /S
                Write-Verbose ("Uninstalled " + $InstalledApp.DisplayName)
                
                $ApplicationStatus= @{Application = $InstalledApp.displayname
                      Publisher = $InstalledApp.Publisher                        
                      InstallLocation = $InstalledApp.installLocation
                      Version = $InstalledApp.Version
                      ComputerName = $env:COMPUTERNAME
                      UserName = $env:USERNAME
                      UninstallString = $UninstallString
                      UninstallStatus = "Successful"
                      UninstallDate = Get-Date -Format yyyyMMdd}
            }
            
            elseif ($InstalledApp.UninstallString -like "*MsiExec.exe /X*") {
                Write-Verbose "Trying to uninstall .MSI Application `"$($InstalledApp.DisplayName)`""
                
                $UninstallString = $InstalledApp.UninstallString
                & cmd.exe /c "$UninstallString  /qn /norestart"
                
                Write-Verbose ("Uninstalled " + $InstalledApp.DisplayName)
                
                $ApplicationStatus= @{Application = $InstalledApp.displayname
                      Publisher = $InstalledApp.Publisher                        
                      InstallLocation = $InstalledApp.installLocation
                      Version = $InstalledApp.Version
                      ComputerName = $env:COMPUTERNAME
                      UserName = $env:USERNAME
                      UninstallString = $UninstallString
                      UninstallStatus = "Successful"
                      UninstallDate = Get-Date -Format yyyyMMdd}
            }
            
            Else {
                Write-Verbose "The Application Was Found but there was no uninstall String"

                if ($InstalledApp) {
                    $ApplicationStatus= @{SearchTerm = $App
                          Application = $InstalledApp.displayname
                          Publisher = $InstalledApp.Publisher                        
                          InstallLocation = $InstalledApp.installLocation
                          Version = $InstalledApp.Version
                          ComputerName = $env:COMPUTERNAME
                          UserName = $env:USERNAME
                          UninstallString = $UninstallString
                          UninstallStatus = "Unsuccessful"
                          UninstallDate = $null}

                }
                
                if (!$InstalledApp) {
                    Write-Verbose "The Application doesn't seem to exist"

                    $ApplicationStatus= @{SearchTerm = $App
                          Application = $InstalledApp.displayname
                          Publisher = $null                       
                          InstallLocation = $null
                          Version = $null
                          ComputerName = $env:COMPUTERNAME
                          UserName = $env:USERNAME
                          UninstallString = $null
                          UninstallStatus = "NotFound"
                          UninstallDate = $null}
                }
            }
        $Done = New-Object -TypeName psobject -Property $ApplicationStatus
        Write-Output $Done
        }
    }
}

#Uninstall-EDApplication -Name "Java"
