# PowerShell-7-LTS-Deployment

Microsoft is retiring the MSI installer for PowerShell 7 in lieu of the lesser MSIX.
This complicates things for automation purposes and more specifically, for me, setting PowerShell 7 as the default shell for OpenSSH.

- Deploys the LTS version of PowerShell 7 (7.6.10) via winget.
- Deploys OpenSSH Server, latest version retrieved from https://github.com/PowerShell/Win32-OpenSSH/releases/latest.
- Sets OpenSSH default shell to PowerShell 7 (pwsh) via registry key.
