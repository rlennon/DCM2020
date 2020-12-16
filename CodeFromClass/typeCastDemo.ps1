

[int] $num1=5
[string] $course_name="PowerShell Scripting"

[string] $num2 = 10
$num2.GetType()

$num2 -is [int]::MaxValue    #false

$num2 -is [string]           #true


$num3 = [int]"20"
$num3.GetType()

Write-Host $course_name -ForegroundColor DarkCyan -BackgroundColor DarkMagenta 
Write-Output "I have something to say" 


