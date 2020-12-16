<# 
.SYNOPSIS
    Demo Switch
.DESCRIPTION
    If Statement Sample
.NOTES
    File Name : SwitchDemo1.ps1
    Author    : R.G.Lennon
 #>

Set-Variable -Name num1 -Value 12345

switch ($num1) {
    12345 
     { 
        Write-Host "`nOption 12345 chosen `n"   #remember `n is newline
     }
     54321 
     { 
        Write-Host "This is just another example"   
     }
    Default 
     {
         "If none of the above then this is chosen"
     }
}