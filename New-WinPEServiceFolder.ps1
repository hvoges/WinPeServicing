Function New-WinPEServiceFolder
{
   <#
      .SYNOPSIS
      Creates a WinPEServicing-Folder, which is needed for creating a custom WinPE-Image
      .DESCRIPTION
      This Cmdlet creates the Default-Folder Structure for creating a new Windows PE Image. 
        C:\WINPESERVICEFOLDER
        |   StartNetTemplate.cmd
        |   Winpeshl_template.ini
        |
        +---PEApplications
        +---PEDriver
        +---PEMount
        +---PowershellModules
        \---Scripts
                ShellLauncherConfig.ps1
                start.ps1
      The StartnetTemplate.cmd is the Batch-File which Windows PE automatically runs during startup. You can cutomize it by changing the
      template. It will be copied to the image as Startnet.cmd during Image-Creation. Same for the Winpeshl_template.ini. In this file you 
      can add alternate shells Windows PE runs at startup. 
      All Folders in PEApplications will be copied to the WinPE Program Files Folder
      Alle Drives will be added to the Image. The have to be in .ini any .sys-Format, no setups!
      PEMount is the folder where the Image will be mounted. Don´t modify it. 
      All PowershellModules copied to this folder will be automatically available when you start Powershell in Windows PE
      The Scripts-Folder is for Script-Files. Two Scripts will be automatically created: Start.ps1 runs a simple graphical Program-Launcher. 
      You can customize the Launcher by modifying the ShellLauncherConfig.ps1
      .EXAMPLE
      Creating a new Service-Folder

      New-WinPEServiceFolder
      
      Creates a new Service-Folder in its default-location <SystemDrive>:\WinPEServicing
      .EXAMPLE
      To customize the Location for the Service-Folder, use the -ServiceRootFolder-Parameter. The Name of the Folder must be given, it is not 
      automatically created!

      New-WinPEServiceFolder -ServiceRootFolder D:\WinPE
      
      Creates a new Service-Folder on D:\WinPE. The name of the ServiceFolder is now WinPE, not WinPeServicing!
      .NOTES
      Version: 1.0
      Author: Holger Voges
      Date: 16.07.2019
      .Link
      www.netz-weise-it.training
  #>    
  param( 
    [parameter(position=0)]
    $ServiceFolderRoot = ( join-Path -Path $env:SystemDrive -childpath "WinPEServiceFolder" )
  )
  
  If (-not ( Test-Path $ServiceFolderRoot ))
  {
    $Null = mkdir $ServiceFolderRoot
  }
  
  If (-not ( Test-Path ( Join-Path -Path $ServiceFolderRoot -ChildPath PEDriver )))
  {
    $Null = mkdir $ServiceFolderRoot\PEDriver
  }
  
  If (-not ( Test-Path ( Join-Path -Path $ServiceFolderRoot -ChildPath Scripts )))
  {
    $Null = mkdir $ServiceFolderRoot\Scripts
  }

  If (-not ( Test-Path ( Join-Path -Path $ServiceFolderRoot -ChildPath "PEApplications" )))
  {
    $Null = mkdir $ServiceFolderRoot\PEApplications
  }
  
  If (-not ( Test-Path ( Join-Path -Path $ServiceFolderRoot -ChildPath "PowershellModules" )))
  {
    $Null = mkdir $ServiceFolderRoot\PowershellModules
  }
  
  if (-not ( Test-Path -path ( Join-Path -Path $ServiceFolderRoot -ChildPath PEMount )))
  {
    $Null = mkdir $ServiceFolderRoot\PEMount
  }
  
  if (-not ( Test-Path -path ( Join-Path -Path $ServiceFolderRoot -ChildPath "StartNet.cmd" )))
  {
    $StartnetCode = @"
; This in a Template for Startnet.cmd
; Startnet.cmd is executed during startup. Use it to start your command automatically. 
wpeinit
"@
    $StartnetCode | Set-Content -Path ( Join-Path -Path $ServiceFolderRoot -ChildPath "StartNetTemplate.cmd" )
  }
  
  if (-not ( Test-Path -path ( Join-Path -Path $ServiceFolderRoot -ChildPath "StartNet.cmd" )))
  {
    $WinPeShliniCode = @"
; This in a Template for WinPeshl.ini
; WinPeShl.ini is used to start an alternative Shell. 
[LaunchApp]
AppPath = %SYSTEMDRIVE%\windows\system32\WindowsPowerShell\v1.0\Powershell.exe
[LaunchApps]
Net Use S: \\192.168.100.251\DeploymentShare$ /user:mdtadmin Passw0rd
s:\WinPeInit\Starterscript.ps1
"@
    $WinPeShliniCode | Set-Content -Path ( Join-Path -Path $ServiceFolderRoot -ChildPath "Winpeshl_template.ini" )
  }

  if (-not ( Test-Path -path ( Join-Path -Path $ServiceFolderRoot\Scripts -ChildPath "Start.ps1" )))
  {
    $WinPeShliniCode = @'
function Start-AppLauncher
{
param(
    # [Switch]$Logoff, 

    [ValidateScript({ If ( -not ( Test-Path -Path $_ ) )
                      { 
                        Throw `"Die angegebene Konfigurationsdatei exisitiert nicht. Bitte prüfen Sie den Pfad!`" 
                      } 
                      $true 
                    })]
    $FormConfigFile
)
    $FormData = & $FormConfigFile
    $ButtonHeigth = 64
    $ButtonWidth = 400
    $ButtonSpacer = 15
    $TextSize = 12
    $TextColor = '#000000'
    $FormsColor = "#ffffff"
    $ButtonColor = "#4a90e2"

    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $Elements = ( ($FormData).GetEnumerator() | Measure-Object ).Count

    $AppLauncher                     = New-Object system.Windows.Forms.Form
    $AppLauncher.ClientSize          = "$( $ButtonWidth + 30 ),$(( $ButtonHeigth + 20 ) * $Elements)"  # ( '{0},{1}' -f ( $ButtonWidth + 100 ),( $ButtonHeigth + 30 ) * $Elements )
    $AppLauncher.text                = "AppLauncher"
    $AppLauncher.BackColor           = $FormsColor
    $AppLauncher.TopMost             = $false
    # $Applauncher.FormBorderStyle = FormBorderStyle.FixedDialog;
    # $AppLauncher.MaximizeBox = $false;
    $AppLauncher.AutoSize = $false

    $YPosition = 15
    # $FormData.GetEnumerator() | Sort-Object -Property @{expression={$_.Value.Index}} | ForEach-Object { $_.Value.Index }

    [array]$Buttons = ForEach ( $ProgramData in (($FormData).GetEnumerator() | Sort-Object -Property @{expression={$_.Value.Index}}) )
    {
        $Button                      = New-Object system.Windows.Forms.Button
        $Button.BackColor            = If ( $ProgramData.value.Color ) { $ProgramData.Value.Color } Else { $ButtonColor }
        $Button.ForeColor            = $TextColor
        $Button.text                 = $ProgramData.Value.Name
        $Button.width                = $ButtonWidth
        $Button.height               = $ButtonHeigth
        $Button.location             = New-Object System.Drawing.Point(15,$YPosition)
        $Button.Font                 = "Microsoft Sans Serif,$TextSize"
        If ( $programData.Value.Parameter )
        { 
            $Button.Add_Click({ Start-Process -FilePath $ProgramData.Value.Path -ArgumentList $ProgramData.Value.Parameter -WorkingDirectory ( Split-Path $ProgramData.Value.path -Parent ) }.GetNewClosure()) 
        }
        Else 
        {
            $Button.Add_Click({ Start-Process -FilePath $ProgramData.Value.Path -WorkingDirectory ( Split-Path $ProgramData.Value.path -Parent )}.GetNewClosure()) 
        }      
        $Button
        $YPosition = $YPosition + $ButtonHeigth + $ButtonSpacer
    }

    $AppLauncher.controls.AddRange($Buttons)

    $null = $AppLauncher.ShowDialog()
#     logoff.exe

}

$mypath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Start-AppLauncher -FormConfigFile $mypath\ShellLauncherConfig.ps1
'@
    $WinPeShliniCode | Set-Content -Path ( Join-Path -Path $ServiceFolderRoot\Scripts -ChildPath 'start.ps1' )
  }

  if (-not ( Test-Path -path ( Join-Path -Path $ServiceFolderRoot\Scripts -ChildPath 'ShellLauncherConfig.ps1' )))
  {
    $WinPeShliniCode = @'
<#
Fügen Sie für jedes Programm zwischen den geschweifen Klammern ein neues Hashtable (=KOnfigurationswert) ein, und zwar nach dem Schema:

Programmname = @{
    Path = "Der Pfad zum Programm in Anführungszeichen"
    Index = Die Position im Menü, beginnende bei der kleinsten Zahl
    Color = '#00FF00' # Die Buttonfarbe, stellt 3 Hexadezimalwerte für die drei Grundfarben dar. 000000 = Schwarz, FFFFFF=WEiß. Color ist Optional 
    Eine Auflistung von Farbcodes gibt es hier: https://www.99colors.net/dot-net-colors
}  

Achten Sie darauf, dass Programmname keine Leerzeichen enthalten darf! Sollte das Menü nichts darstellen, ist die Konfiguration vermutlich fehlerhaft. 
Am Besten kopieren und editieren Sie die Datei in der Powershell ISE oder einem anderen Powershell-Editor. 
#>
@{
  Logoff = @{
    Name = "Copy VHD to Disk"
    Path = "Powershell.exe"
    Parameter = "-ExecutionPolicy unrestricted -f ${env:windir}\InitializeOs.ps1"
    Color = "#FFD700"
  Index = 1
    }
  Shutdown = @{
    Name = "NotePad"
    Path = "${env:windir}\system32\Notepad.exe"
    Color = "#ffD700"
    Index = 2
  }
}
'@
    $WinPeShliniCode | Set-Content -Path ( Join-Path -Path $ServiceFolderRoot\Scripts -ChildPath 'ShellLauncherConfig.ps1' )
  }  
}