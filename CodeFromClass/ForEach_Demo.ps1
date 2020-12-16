<# 
.SYNOPSIS
    ForEach Demo
.DESCRIPTION
    ForEach Demo Sample
.NOTES
    Author    : R.G.Lennon
 #>


#Demo ForEach
	

# foreach($num in 1,2,3) 
# {
#    Write-Host "Count in foreach $num"
# }

# Write-Host "`n"
# foreach($num in 1..10) 
# {
#    Write-Host $num
# }

Write-Host "`n"
$myArray = (1,2,3)
foreach($num in $myArray) 
{
   Write-Host $num
} 


