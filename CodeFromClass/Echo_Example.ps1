<# 
.SYNOPSIS
    CmdLet Demo
.DESCRIPTION
    CmdLet Demo Sample
.NOTES
    Author    : R.G.Lennon
 #>

 #F5 then run in command prompt as: Echo_Ex Ruth
 function  Echo_Ex 
 {
     param (
         [Parameter (Mandatory=$True, ValueFromPipeline=$True)] 
         [psobject] $SourceObject         
     )

     process
     {
         If ($SourceObject -is [String] )
         {   
             Write-Host "Hello " $SourceObject
         }
         else {
             Write-Host "Not what I wanted!"
         }
     }
 }