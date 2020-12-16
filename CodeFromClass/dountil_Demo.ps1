<# 
.SYNOPSIS
    do until Demo
.DESCRIPTION
    do until Demo Sample
.NOTES
    Author    : R.G.Lennon
 #>

 #do..until

$num=1
do
{
   $num++
   Write-Host $num
} until($num -eq 8)

