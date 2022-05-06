# Go to https://docs.microsoft.com/en-us/windows/wsl/install-manual for names of the distros
# (hover over the link and enter the name after https://aka.ms/)

# Write-Host "Enabling Hyper-V (required for WSL2)"
# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Write-Host "Enabling Virtual Machine platform (required for WSL2)"
# Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

# Write-Host "Enabling WSL2"
# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

Write-Host "Install WSL2 + Ubuntu 20.04"
wsl.exe --install Ubuntu-20.04 --set-default Ubuntu-20.04 --no-launch

Write-Host "Enabling WinRM (if you don't need it, you can disable it after applying the playbooks)"
winrm quickconfig -transport:http -force

Write-Host "Installing Chocolatey package manager"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

Write-Host "Done!"

Write-Host "To finalize the setup, clone this repository into your WSL and continue from there. Refer to README step by step instructions for details."