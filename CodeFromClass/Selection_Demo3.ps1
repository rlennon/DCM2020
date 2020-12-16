<# 
.SYNOPSIS
    Switch demo 2
.DESCRIPTION
    If Statement Sample
.NOTES
    File Name : SwitchDemo1.ps1
    Author    : R.G.Lennon
 #>

Clear-Host
#$SrvName = "WalletService" #Xbox live networking service
$SrvName = "FortiClient Service Scheduler" #Forticlient Service scheduler
#$SrvName = "Application Information" #Use the display name not the name!
$Service1 = Get-Service -display $SrvName -ErrorAction SilentlyContinue

switch ($Service1.Status) {
    "Running" 
    {  
        Write-Host "Service Running"
    }
    "Stopped" 
    {
        Write-Host "Stopped again!"
    }
}