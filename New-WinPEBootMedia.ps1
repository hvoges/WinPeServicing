Function New-WinPeBootMedia
{
    <#
      .SYNOPSIS
      Creates a bootable USB-Media from a WIM-File
      .DESCRIPTION
      New-WinPEBootmedia creates a Windows PE Boot Media from a WinPe WIM-File. The Wim-File is part of the Windows ADK
      but can be customized using the Cmdlets New-WinPEServiceFolder and New-WinPEImage. After customizing the Image, 
      this Cmdlet creates a bootable USB-Stick and expands the WIM-file to a NTFS-Partition. In contrast the bootable
      Media the ADK creates, Windows PE does not start from a Ramdisk but directly from Media and can later be customized
      directly on the Media instead of changing the WIM-File again. 
      .EXAMPLE
      Create a New Boot-Media from Disk Number 2.

      New-WinPEBootmedia -DiskNumber 2 -WinPEMedia C:\WinPEServicing\WinPE.wim
      
      The Disk-Number is a unique number. You can find the number using the Cmdlet Get-Disk or you can use the Parameter -ShowGui 
      .EXAMPLE
      New-WinPEBootmedia -ShowGui -WinPEMedia C:\WinPEServicing\WinPE.wim -Force
      
      With -Showgui, the Cmdlets shows you all available USB-Devices from which you can chose on. If there Media is not empty, 
      -force will clean it. Without this Parameter, the USB-Media must be clean. 
      .NOTES
      Version: 1.0
      Author: Holger Voges
      Date: 16.07.2019
      .Link
      www.netz-weise-it.training
  #>
[cmdletbinding(DefaultParameterSetName='Console')]  
param(
      [ValidateScript({ If ( -not ( Get-Disk -Number $_ | Where-Object { $_.BusType -eq "Usb" }))
                        { Throw "The Device is not a USB-Drive or does not exist" }
                        $true 
                      })]
      [Parameter(Mandatory=$true,
                 ParameterSetName='byNumber')]
      [int]$DiskNumber,
  
      [Parameter(Mandatory=$false,
                 ParameterSetName='byGui')]
      [Switch]$ShowDrives,

      [ValidateScript({ If ( -not (Get-WindowsImage -ImagePath $_ -Index 1 | where-object -FilterScript { $_.EditionID -eq "WindowsPE" }) )
                        { Throw "The given File is not a Windows PE Image" }
                        $true 
                      })]
      [Parameter(Mandatory=$true)]
      [string]$WinPeWim,

      [Switch]$Force
    )
  
  # $Progs = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders"
  # $AdkPath = ( Get-Item $progs ).getvaluenames() | Where-Object { $_ -like '*Assessment and Deployment Kit\Windows Preinstallation Environment\' }
  If ( $PSBoundParameters.ContainsKey('ShowDrives'))
  {
    $Disks = Get-Disk | Where-Object { $_.BusType -eq "Usb" } | Select-Object -Property FriendlyName,Size,NumberOfPartitions,PartitionStyle,Number 
    If ( $Disks) 
    {
      $Disknumber = ( $Disks | Out-GridView -OutputMode Single -Title "Choose a medium" ).Number
    }
    Else 
    {
      'No USB-Device or usable Disk could be found'
    }
  }

  If (-not ( Test-WinPEDiskEmpty -DiskNumber $DiskNumber ) -and (-not $Force ))
  {
    "The Storage-Device {0} is not empty. Please Erase it or use Parameter -Force" -f (Get-Disk -Number $DiskNumber).FriendlyName
    break 
  }

  $BootPartition = Get-Freedrive
  Write-Verbose -Message "$bootpartition will be assigned to Bootpartition"
  $DataPartition = Get-Freedrive -startLetter ([Char]([byte][Char]$BootPartition+1))
  Write-Verbose -Message "$DataPartition will be assigned to Operating-System drive"

  $DiskpartCommand = @"
Select Disk $DiskNumber
Clean
Create Part Primary Size=100
Active
Format FS=Fat32 Label="Boot" Quick
Assign Letter=$BootPartition
Create Part Primary 
Format FS=NTFS Label="WinPe" Quick
Assign Letter=$DataPartition
"@

  $ReturnValue = $DiskpartCommand | diskpart.exe
  Expand-WindowsImage -ImagePath $WinPeWim -Index 1 -ApplyPath ( $DataPartition + ":\" )
  Copy-Item -Path $PSScriptRoot\PeBootMgr\* -Destination ( $BootPartition + ":\" ) -Recurse 
  $PeGuid = '{7619dcc9-fafe-11d9-b411-000476eba25f}' 
  $BcdStorePath = $BootPartition + ':\Boot\BCD'
  $OsPartition = [string]$DataPartition + ":"
  $ReturnValue = bcdedit.exe /store $BcdStorePath /set $PeGuid OsDevice partition=$OsPartition
  $ReturnValue +=bcdedit.exe /store $BcdStorePath /set $PeGuid Device partition=$OsPartition
  $ReturnValue += $null = bcdedit.exe /store $BcdStorePath /set $PeGuid Description "Windows PE"
  Write-Verbose -message $ReturnValue
}

