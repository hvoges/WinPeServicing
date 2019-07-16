# WinPEServicing

A Powershell-Module for creating custom Windows PE Boot-Media, including USB-Drives and VHD-Files to boot from

## Getting Started

To use the Module, you have to have the Windows ADK installed first. Since Windows 10 1809, you can simply download the Windows PE-Package from https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install. As the Windows PE has no dependencies on the Operating System you want to service, simply use the latest Version of the Package. 

### Prerequisites

Windows ADK from https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install is mandatory, as the Windows-PE Wim-File is located here. 

### Installing

To Use the Module, simply import it with Import-Module:
Import-Module c:\WinPeServicing\WinPeServicing.psd1

Or you simply copy the module to one of the Powershell-Module-Folders. It will be imported automatically then. The default-Folder is located here:
$programfiles\WindowsPowershell\Modules

## Authors

* **Holger Voges** 

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
