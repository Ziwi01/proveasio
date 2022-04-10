function runAsAdmin {
    Start-Process -FilePath "pwsh" -Verb RunAs
}

Write-Host @"
_,.-'~'-.,__,.-'~'-.,__,.-'~'-.,__
    __         ____             
   / /_  ___  / / /  ____  ____ 
  / __ \/ _ \/ / /  / __ \/ __ \
 / / / /  __/ / /_ / / / / /_/ /
/_/ /_/\___/_/_/(_)_/ /_/\____/ 

_,.-'~'-.,__,.-'~'-.,__,.-'~'-.,__
"@

Set-Alias -Name adminRun -Value runAsAdmin 