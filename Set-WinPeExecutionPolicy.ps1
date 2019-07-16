Function Set-WinPEExecutionPolicy
{
<#
  .SYNOPSIS
  Sets the Powershell-Executionpolicy for Windows PE
  .DESCRIPTION
  This Cmdlet is an auxiliary Cmdlet for New-WinPEImage. It changes the Executionpolicy for a mounted Wim-File. 
  .EXAMPLE
  Set-WinPEExecutionPolicy -WinPEMountPath C:\WinPeServicing\WinMount
  
  Sets the Executionpolicy to unrestricted for the Mounted Image in C:\WinPeServicing\WinMount
  .NOTES
  Version: 1.0
  Author: Holger Voges
  Date: 16.07.2019
  .Link
  www.netz-weise-it.training
#> 
  param(
    [ValidateSet('Unrestricted','Remotesigned','Allsigned','Restricted')]
    $ExecutionPolicy = 'Unrestricted',
    
    [parameter(mandatory=$true)]
    [ValidateScript({ Test-path $_ -PathType Container })]    
    $WinPEMountPath
  )

  Try {
    reg load "HKLM\WinPE" "$WinPEMountPath\Windows\System32\config\software"
    If ( $LASTEXITCODE -ne 0 )
    {
      Write-Error "Couldn´t mount Registry"
      Break
    }
    $RegPath = "HKLM:\WinPE\Microsoft\PowerShell\1\ShellIds\Microsoft.Powershell\"
    $NIArgs = @{Path  = $RegPath 
      Name  = 'ExecutionPolicy' 
      Value = $ExecutionPolicy
      PropertyType = 'String'
    Force = $True}
    New-ItemProperty @NIArgs
    reg unload "HKLM\WinPE"
  }
  Catch 
  {
    Write-Error "Execution Policy couldn´t be set"
    $_.Exception.Message
  }
}