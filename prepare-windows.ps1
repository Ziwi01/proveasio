###############
# Install WSL2 distro
###############

Write-Host "Install WSL2 + Ubuntu 20.04`r`n"
wsl.exe --install -d 'Ubuntu-20.04'
wsl.exe --set-default 'Ubuntu-20.04'

###############
# Enable WinRM Windows service with CredSSP authentication, disable Basic Auth
###############
Write-Host "Enabling WinRM (if you don't need it, you can disable it after applying the playbooks)`r`n"

winrm quickconfig

#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
Invoke-Webrequest $url -OutFile ${env:USERPROFILE}\AnsibleWinrmConfig.ps1 -Verbose
sleep 2
Set-ExecutionPolicy Bypass -Scope Process -Force; ${env:USERPROFILE}\AnsibleWinrmConfig.ps1 -EnableCredSSP -DisableBasicAuth -Verbose
Enable-WSManCredSSP -Role Server -Force

Write-Host "`r`n`r`n"
Write-Host "To verify if WINRM got configured properly:`r`n" 
Write-Host "  - check if https listener port 5986 is open: winrm enumerate winrm/config/Listener`r`n"
Write-Host "  - check service if CredSSP is active: winrm get winrm/config/Service`r`n"

###############
# Install Chocolatey
###############

Write-Host "Installing Chocolatey package manager`r`n"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

###############
# Finish
###############
Write-Host "`r`n`r`nDone! To finalize the setup, clone this repository into your WSL and continue from there.`r`nRefer to README for step by step instructions or details."
