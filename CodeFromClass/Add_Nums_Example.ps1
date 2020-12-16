<# 
.SYNOPSIS
    CmdLet Demo
.DESCRIPTION
    CmdLet Demo Sample
.NOTES
    Author    : R.G.Lennon
 #>

 #F5 then run in command prompt as: Add_nums_Ex 10 22
 function  Add_Nums_Ex 
 {
     param (
         $num1, $num2
     )

     process
     {
        Write-Host ($num1+$num2)
     }
 }