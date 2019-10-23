function New-WinPEImage
{
   <#
      .SYNOPSIS
      Creates a customized Windows PE Wim-File
      .DESCRIPTION
      New-WinPEImage creates a customized Windows PE Boot Wim-File from the Windows ADK PE-Template. After customizing the Image, 
      the Wim-file can be used to create a VHDX-File or a bootable USB-Media with New-WinPEVhd and New-WinPEBootMedia. The Windows ADK
      must be installed prior to using this cmdlet. You also first have to create a Servicing-Folder with New-WinPEServicingFolder.
      .EXAMPLE
      After you customied the Servicing-Folder, you can start creating a new image.

      New-WinPEImage -Language en-us -ServiceFolder D:\WinPEServiceFolder
      
      Creates a New Wim-File with en-us Keyboard-Settings. Elsewise, German keyboard-Settings will be user. The Service-Folder must
      be created prior to calling this command. If the Servide-Folder is in it´s default location (Systemdrive:\WinPEServiceFolder), you 
      can omit the Parameter -ServiceFolder
      .EXAMPLE
      New-WinPEImage -Language en-us -ServiceFolder D:\WinPEServiceFolder -Architecture x86
      
      The Cmdlets uses the x64-Wim-Template by Default. If you want to create a 32-Bit-Image, use the -Architecture-Parameter. 
      .NOTES
      Version: 1.0
      Author: Holger Voges
      Date: 16.07.2019
      .Link
      www.netz-weise-it.training
  #>  
  param(
    [parameter(position=0)]
    [string]$ServiceFolder = ( join-Path -Path $env:SystemDrive -childpath "WinPEServiceFolder" ),

    [parameter(position=1)]
    [ValidateSet('amd64','x86')]
    [string]$Architecture = 'amd64',
  
    # $StartNet = 'startnet.cmd',
  
    [parameter(position=3)]
    [ValidateSet('ar-sa','bg-bg','cs-cz','da-dk','de-de','el-gr','en-gb','en-us','es-es','es-mx','et-ee','fi-fi','fr-ca','fr-fr','he-il','hr-hr','hu-hu','it-it','ja-jp','ko-kr','lt-lt','lv-lv','nb-no','nl-nl','pl-pl','pt-br','pt-pt','ro-ro','ru-ru','sk-sk','sl-si','sr-latn-rs','sv-se','th-th','tr-tr','uk-ua','zh-cn','zh-tw')]
    [string]$Language = 'de-de'
  )

  $InstallerKey = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders'
  $PeInstallPathAmd64 = "*\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\"
  $PeInstallPathx86 = "*\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\"
  
  if ( -not ( Get-Itemproperty -Path $InstallerKey -name $PeInstallPathAmd64 ) -and $Architecture -eq 'amd64')
  { 
    Write-Error -Message "Windows PE for 64 Bit cannot be found on this system"
  }
  Elseif ( -not ( Get-Itemproperty -Path $InstallerKey -name $PeInstallPathx86 ) -and $Architecture -eq 'x86')
  { 
    Write-Error -Message "Windows PE for 32 Bit cannot be found on this system"
  }

  $DriverFolder = Join-Path -Path $ServiceFolder -ChildPath "PEDriver"
  $ScriptFolder = Join-Path -Path $ServiceFolder -ChildPath "Scripts"
  $MountFolder = Join-Path -Path $ServiceFolder -ChildPath "PEMount"
  #toDo: Pfad aus Registry korrekt ermitteln
  $ADKRootPath = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'Windows Kits\10\Assessment and Deployment Kit\' 
  $AdkPath = Join-Path -Path $ADKRootPath -ChildPath 'Windows Preinstallation Environment' 
  If ( -not ( Test-Path $AdkPath ))
  { Return 'Please test if the ADK is installed' }
  $WinPeOCsPath = $AdkPath + "\$Architecture\WinPE_OCs"
  $DismPath = $ADKRootPath + '\Deployment Tools' + "\$Architecture\DISM"
  If ( test-path -Path $DismPath\dism.exe )
  {
    $dism = get-command -Name $DismPath\dism.exe 
  }
  Else 
  {
    $dism = get-command -Name dism.exe 
  }

  if (-not ( Test-Path -path $MountFolder)) 
  {
    New-WinPEServiceFolder -ServiceFolderRoot $ServiceFolder
  }
 
  $WimFile = Copy-Item  -Path "$AdkPath\$Architecture\en-us\winpe.wim" -Destination $ServiceFolder -PassThru
  Try 
  { 
    Mount-WindowsImage -ImagePath $WimFile.Fullname -Path $MountFolder -Index 1 
    
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\WinPE-WMI.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\$Language\WinPE-WMI_$Language.cab" -Path "$MountFolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\WinPE-NetFx.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\$Language\WinPE-NetFx_$Language.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\WinPE-Scripting.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\$Language\WinPE-Scripting_$Language.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\WinPE-PowerShell.cab" -Path "$MountFolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\$Language\WinPE-PowerShell_$Language.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\WinPE-DismCmdlets.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\$Language\WinPE-DismCmdlets_$Language.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\WinPE-EnhancedStorage.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\$Language\WinPE-EnhancedStorage_$Language.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\WinPE-StorageWMI.cab" -Path "$Mountfolder" -IgnoreCheck
    Add-WindowsPackage -PackagePath "$WinPeOcsPath\$Language\WinPE-StorageWMI_$Language.cab" -Path "$Mountfolder" -IgnoreCheck
    Set-WinPeExecutionPolicy -ExecutionPolicy Unrestricted -WinPEMountPath $MountFolder
    foreach ( $folder in (get-childitem $ServiceFolder\PowershellModules\ -Directory ))
    {
      Copy-Item -Path $folder.fullname -Destination "$MountFolder\Program Files\WindowsPowerShell\Modules" -Recurse -Force
    }
    foreach ( $folder in (get-childitem $ServiceFolder\PEApplications\ -Directory ))
    {
      Copy-Item -Path $folder.FullName -Destination "$MountFolder\Program Files" -Recurse
    }   
    # Copy Powershell-Scripts
    mkdir -Path "$MountFolder\Scripts\"
    Copy-Item -Path $ScriptFolder\* -Destination "$MountFolder\Scripts\" -Recurse
    If ( test-path -Path ( Join-Path -path $ServiceFolder -Childpath "startnetTemplate.cmd" ))
    {
      Copy-Item -Path "$ServiceFolder\StartNetTemplate.cmd" -Destination ( Join-Path -Path $MountFolder -childpath "\Windows\System32\Startnet.cmd" ) -Force
    }
    If ( test-path -Path ( Join-Path -path $ServiceFolder -Childpath "Winpeshl_template.ini" ))
    {
      Copy-Item -Path "$ServiceFolder\Winpeshl_template.ini" -Destination ( Join-Path -Path $Mountfolder -childpath "\Windows\System32\Winpeshl.ini" ) -Force
    }
    
    & $dism /image:$MountFolder /Set-InputLocale:$Language 
    & $dism /image:$Mountfolder /Set-ScratchSpace:256
    
    if ( Get-ChildItem -path $DriverFolder\*.inf -Recurse)
    {
      Add-WindowsDriver -Path $DriverFolder -Recurse -ForceUnsigned -WindowsDirectory $MountFolder
    }
  }
  Catch 
  {
    Write-Error $_.Exception.Message
  }
  Finally
  {
    Dismount-WindowsImage -Path $MountFolder -Save
  }
}