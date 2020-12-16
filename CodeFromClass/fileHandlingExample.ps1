<# 
.SYNOPSIS
    ForEach to copy files
.DESCRIPTION
    ForEach practical example with file copy Demo Sample
.NOTES
    Author    : R.G.Lennon
 #>

#Sample: to copy files

Clear-Host
string $sourcepath = "C:\deleteme\Fldr_1";
string $destpath = "C:\deleteme\Fldr_2";


ForEach ($file in Get-ChildItem $sourcepath  )
{
    #Write-Host $file.name
    
    $file.CopyTo($destpath)
    Write-Host "$file written"
} 
Write-Host "finisihed"