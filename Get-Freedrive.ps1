function Get-Freedrive
{
  <#
      .SYNOPSIS
      Get-Freedrives lists the first free driveletter in the alphabet.
      .DESCRIPTION
      Get-Freedrive can be used to test for the first available free driveletter. The Parameter $inverse searches backwards through the alphabet.
      .EXAMPLE
      get-freedrive -inverse -startLetter Z
      Starts the search with letter z searching backwards. Returns a character.
      .NOTES
      Place additional notes here.
      www.netz-weise-it.training/weisheiten/
  #>
  [cmdletbinding()]
  param(
   
    # The letter to start the search from - default is C or Z, if -inverse is chosen
    [char]$startLetter = 'C',
   
    # Inverse forces a backwards search through the alphabet
    [switch]$inverse
  )
  
  # Setting Start-Letter to Z when using inverse Search
  If ( -not ( $PSBoundParameters.ContainsKey('Startletter') ) -and ( $inverse ) )
    { $startLetter = 'Z' }

  [int]$Counter = ([Convert]::ToByte( $startLetter ))
  if ( $inverse )
    { $Chararray = $Counter..67 }
  Else { $Chararray = $Counter..90 }
  $drives = Get-PSDrive -PSProvider FileSystem
  foreach ( $letter in $CharArray )
  {
    if ( [Char]$letter -notin $drives.Name )
    {
      [char]$letter
      break
    }
  }
}