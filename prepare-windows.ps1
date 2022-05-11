Write-Host "Install WSL2 + Ubuntu 20.04`r`n"
wsl.exe --install -d 'Ubuntu-20.04'
wsl.exe --set-default 'Ubuntu-20.04'

# Enable WinRM Windows service
# To verify the config:
# - check if https listener port 5986 is open: winrm enumerate winrm/config/Listener
# - check service if BasicAuth is active: winrm get winrm/config/Service 
Write-Host "Enabling WinRM (if you don't need it, you can disable it after applying the playbooks)`r`n"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
Invoke-Webrequest $url -OutFile C:\Temp\AnsibleWinrmConfig.ps1 -Verbose
sleep 2
C:\Temp\AnsibleWinrmConfig.ps1 -EnableCredSSP -DisableBasicAuth -Verbose
Enable-WSManCredSSP -Role Server -Force

Write-Host "Installing Chocolatey package manager`r`n"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))


Write-Host "`r`n`r`nDone! To finalize the setup, clone this repository into your WSL and continue from there.`r`nRefer to README for step by step instructions or details."