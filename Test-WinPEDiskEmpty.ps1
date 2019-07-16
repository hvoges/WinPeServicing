Function Test-WinPeDiskEmpty
{
<#
  .SYNOPSIS
  Tests if a Disk is empty
  .DESCRIPTION
  This Cmdlet is an auxiliary Cmdlet for New-WinPEBootMedia. It checks for exisiting Volumes on a disk and
  returns True if the Disk is empty and False if there are exisiting volumes on the disk. 
  .EXAMPLE
  Test-WinPEDiskEmpty -Disknumber 2
  
  Test the Disk with Number 2.
  .NOTES
  Version: 1.0
  Author: Holger Voges
  Date: 16.07.2019
  .Link
  www.netz-weise-it.training
#>   
param(
  [ValidateScript({ If ( -not ( Get-Disk -Number $_ ))
                    { Throw "Die angegene Disk-Nummer existiert nicht" }
                    $true 
                  })]        
  [int]$DiskNumber
)
 
  [Regex]$RegEx = 'Volume\s*(\d*)\s*(.)\s*(\w*)\s*(\w*)\s*(\w*)\s*(\d*\s*\wB)\s*(\w*)\s*(\w*)'
  $DiskpartCommand = @"
Select Disk $Disknumber
Det Disk
"@

  $ReturnValue = $DiskpartCommand | diskpart.exe
  foreach ( $line in $ReturnValue )
  {
      if ( $line -match $RegEx )
      {
        Return $false
      }
  }
  $true
}