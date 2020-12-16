<# 
.SYNOPSIS
    Demo IF
.DESCRIPTION
    If Statement Sample
.NOTES
    File Name : SelectionDemo1.ps1
    Author    : R.G.Lennon
 #>

 Clear-Host

 #Set-Variable -Name num1 -Value 12345
 #Set-Variable -Name num1 -Value 54321
 Set-Variable -Name num1 -Value abc
 
 if ($num1 -eq 12345)
 {
    Write-Host "Found User"
 }
 elseif ($num1 -lt 5000)
 {
     Write-Host "Value less than 5000"
 }
 else
 {
    Write-Host "Not a match"
 } 
