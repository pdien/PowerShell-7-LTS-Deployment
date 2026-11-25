# Ensure script is running as Admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Check if PowerShell 7 is installed.
# If not, install PowerShell 7.6.10 LTS .MSI version via winget
if (!(Get-Command "pwsh" -ErrorAction SilentlyContinue)) {
    Write-Output "PowerShell 7 not installed. Installing now."
    winget install --id Microsoft.PowerShell --exact --version 7.6.10 --scope machine --installer-type wix --source winget
    # Check if PowerShell installed successfully
    if ($LASTEXITCODE -eq 0) {
        Write-Output "PowerShell 7 successfully installed via winget."
        Write-Output "Reloading PATH variable."
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } else {
        Write-Error "PowerShell 7 install failed."
        exit 1
    }
} else {
    Write-Output "PowerShell 7 detected."
}

# Check if OpenSSH server is installed
# If not, pull from GitHub and install
Write-Output "Installing OpenSSH Server"
if (![bool](Get-Service -Name "sshd" -ErrorAction SilentlyContinue)) {
    $msiPath = "C:\temp\openssh.msi"
    $tag = Invoke-RestMethod -Uri "https://github.com/PowerShell/Win32-OpenSSH/releases/latest" -Method Get
    $tag = ($tag | Select-String -Pattern "tag_name=(\d+.*Preview)").Matches.Groups[1].Value
    $latestVersion = ($tag -replace '[^0-9.]') -replace '.$'
    $downloadUrl = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/$tag/OpenSSH-Win64-v$latestVersion.msi"

    if (-not (Test-Path "C:\Temp")) {
        New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
        Write-Output "Temporary directory created."
    }

    Write-Output "Downloading OpenSSH from $downloadUrl"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $msiPath
    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" ADDLOCAL=Server /qn /norestart" -Wait

    if ($LASTEXITCODE -eq 0) {
        Write-Output "OpenSSH Server successfully installed."
    } else {
        Write-Output "OpenSSH Server install failed."
        exit 1
    }
} else {
    Write-Output "OpenSSH Server detected."
}

if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
    # Set DefaultShell
    Write-Output "Setting DefaultShell to PowerShell 7 (MSI version)"
    $path = (Get-Command pwsh.exe).Source
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -Value $path -PropertyType String -Force -ErrorAction SilentlyContinue

    # Switch updates to LTS because Microsoft sucks dick and removed the MSI installer
    Write-Output "Changing PowerShell 7 update catalog to LTS"
    [Environment]::SetEnvironmentVariable('POWERSHELL_UPDATECHECK', 'LTS', 'Machine')
} else {
    Write-Error "PowerShell 7 not installed."
    exit 1
}