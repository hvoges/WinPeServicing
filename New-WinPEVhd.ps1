Function New-WinPEVhd
{
   <#
      .SYNOPSIS
      Creates a customized Windows PE Wim-File
      .DESCRIPTION
      New-WinPEVHD creates a VHD-File from a Windows PE wim. The Windows ADK must be installed prior to using this cmdlet. You also first 
      have to create a Servicing-Folder with New-WinPEServicingFolder. The VHD-File can be copied to an exisiting bootable drive and 
      added to the Boot-Manager with bcdedit or the Add-BCDEntry-Cmdlet from the bcdstore-Module. Afterwards, you can directly boot into 
      a service-PE-Image. 
      .EXAMPLE
      After you customied the Servicing-Folder, you can start creating a new image.

      New-WinPEVhd -VhdPath D:\WinPE.vhdx  -WinPEWim C:\WinPEServicing\WinPE.wim
      
      Creates a New vhdx-File from WinPE.wim. The Default-Size for the vhdx is 10GB. If you boot from a vhdx-file, the vhdx-File is 
      enlarged to its full size, even it is created dynamically. 
      .EXAMPLE
      New-WinPEVhd -VhdPath D:\WinPE.vhdx  -WinPEWim C:\WinPEServicing\WinPE.wim -Size 5GB
      
      Creates a New vhdx-File from WinPE.wim. The Size for the vhdx is cutomized to 5GB. If you boot from a vhdx-file, the vhdx-File is 
      enlarged to its full size, even it is created dynamically, so the size of the vhdx matters. Normally, 2GB should be sufficient even 
      for fully blown wim-Image with all features activated. 
      .NOTES
      Version: 1.0
      Author: Holger Voges
      Date: 16.07.2019
      .Link
      www.netz-weise-it.training
  #>    
  param(
    $VhdPath = "$env:Userprofile\WinPE.vhdx",

    [INT64]$disksize = 10GB, 
    
    [Parameter(Mandatory=$true)]
    [ValidateScript({ If ( -not (Get-WindowsImage -ImagePath $_ -Index 1 | where-object -FilterScript { $_.EditionID -eq "WindowsPE" }) )
                      { Throw "Das angegebene Image ist kein valides WIM-Image" }
                      $true 
                    })]
    $WinPeWim
  )
  
  $vhd = new-vhd -Path $VhdPath -SizeBytes $DiskSize -Dynamic
  $vhd = $vhd | Mount-VHD -PassThru
  Try 
  {
    Initialize-Disk -PartitionStyle GPT -Number $vhd.Number
    $partition = $vhd | New-Partition -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'System' -Confirm:$false
    Set-Partition -DiskNumber $vhd.Number -PartitionNumber ( $partition | Get-Partition ).PartitionNumber -NewDriveLetter ( Get-Freedrive )
    $partition = Get-Volume -UniqueId $Partition.UniqueId
    Expand-WindowsImage -ImagePath $WinPeWim -Index 1 -ApplyPath ( $partition.DriveLetter + ":\")
  }
  Finally
  {
    $vhd | Dismount-VHD
  }
}