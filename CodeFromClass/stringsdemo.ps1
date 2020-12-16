

<# 
.SYNOPSIS
    Demo set and new variable
.DESCRIPTION
    Examples of operators and variables
.NOTES
    File Name : VarDemo3.ps1
    Author    : R.G.Lennon
 #>


Write-Host " Create Variables:`n " #back-quote at top lef of keyboard!

New-Variable –Name “CourseTerm” –value “Term9” 
Set-Variable –Name “CourseName” –value “M.Sc. DevOps”

Write-Host $CourseTerm
Write-Host $CourseName
Remove-Variable -Name CourseTerm #removes from memory

Write-Host "`n`nCheck Again: "
$CourseTerm
$CourseName

Clear-Variable -Name CourseName #empties the content of the variable
Write-Host $CourseName
Set-Variable -Name CourseName -Value "MyCourse"
Write-Host $CourseName

$string1 = "String"
$string2 = 'Also a String'
$string3 = "String with quotes ""Can be"" double quoted"
$string4 = "String with quotes `"Can be`" double quoted" #back tick
$hereString = @" 
My string has a quote " symbol in it
"@
#note that the text is on a separate line in the herestring

Write-Host $hereString 