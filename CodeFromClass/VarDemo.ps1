<#
.SYNOPSIS
    Explanation of the demo script in one line
.DESCRIPTION
    More detailed explanation o the demo script.
.NOTES
    File Name:  VarDemo.ps1
    Author:     R.G.Lennon
#>

$age    = 21
Write-Host $age
$student_name   = "Patricia Doherty" #Firstname and last name only
Write-Host $student_name


Write-Host $student_name.Length   #property
$student_name.GetType() #method
