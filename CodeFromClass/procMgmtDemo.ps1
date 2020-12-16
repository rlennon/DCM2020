<# 
.SYNOPSIS
    CmdLet procMgmt Demo
.DESCRIPTION
    CmdLet process managemnt Demo Sample
.NOTES
    Author    : R.G.Lennon
 #>

#Remember: F5 first, then type at the terminal to run the new commandlet
#   procMgmt
function procMgmt
{   #uncomment each example one at a time.
    #each should be a spearate function but for space saving all are included as one
    #here
    
    #Get-Counter -Counter "\Processor(*)\% Processor Time"  -SampleInterval 2 -MaxSamples 3
    #Get-Process | measure VirtualMemorySize -Sum
    Get-Process -Name F*
    #Get-Process -Id 728

} 

