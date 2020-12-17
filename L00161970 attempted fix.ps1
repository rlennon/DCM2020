<#
Daniel Sheridan L00161870 OOPR CA2
#>

Get-Content ".\Settings.ini" | foreach-object -begin
    {$settings=@{}}
        -process { $k = [regex]::split($_,'=');
            if(($k[0].CompareTo("") -ne 0) -and
                ($k[0].StartsWith("[") -ne $True))
                    { $settings.Add($k[0], $k[1]) } }

$computerNames = Get-Content $settings.Get_Item("IPAddresses.txt")

#Calling the Main function to carry out network tests

NetworkTest $computerNames

#Region NetworkTest 

<# 
Changed Network-Tests to NetworkTest as suggested in Visual Code
#>

function NetworkTest
{
    Param(
     [Parameter()]
        [string[]]
            $ServerNames)

    Begin
        {
        $computerNames = $ServerNames
            #Creating objects to be used
                $serverArray = @()
                    $errorOutputArray = @()
                        $networkInformationArray = @()
                            $checkOpenPortsArray = @()
    $portList = $settings.PortsToValidate.Split(",")

    
    Start-Transcript -Path $settings.Get_Item("LogFile")
    #Which command should I use?

        Write-Output $computerNames  

 <#
 Write-Output uncommented DSheridan as this is the correct choice
 Test-Connection changed to Test-NetConnection below to match rest of script
 #>    
    
    # Start Process
    Foreach ($computerName in $computerNames)
    {
       
        if (Test-NetConnection -ComputerName $computerName -Count 1 -Quiet)
        { 
                $serverArray += Get-UserDetail $computerName

                $errorOutputArray += Check-WarningsErrors $computerName

                $networkInformationArray += Get-NetworkInfo $computerName

                $checkOpenPortsArray += Check-OpenPorts $computerName $portList
      
        }
        else
        {
        $server = [ordered]@{
        ComputerName=$computerName
        UserName="Remote Server Not Available"}
            $serverArray += New-Object -TypeName PSObject -Property $server
        }
    }
    

    }
    End
    {

#Region
    "*" * 50
    Write-Output "*   Servers Information"
    "*" * 50
    $serverArray | Format-Table -AutoSize

    "*" * 50
    Write-Output "*   EventLog - Errors and Warnings"
    "*" * 50
    $errorOutputArray | Format-Table -AutoSize
    "*" * 50
    Write-Output "*   Network Information"
    "*" * 50
    $networkInformationArray | Format-Table -AutoSize
    "*" * 50
    Write-Output "*   Open Ports"
    "*" * 50
    $checkOpenPortsArray | Format-Table -AutoSize

    Stop-Transcript
    }
}
#endregion

#Region
Get-UserDetail

    [CmdletBinding()]
    [Alias()]
    [OutputType ([array])]
    Param(
         [Parameter()]
         ([string]))
         $ComputerName
         
    $serverArray = @()
    try
    {
        
        $userName = (Get-WmiObject -Class win32_computersystem -ComputerName $ComputerName).UserName

        $server = [ordered]@{
            ComputerName=$ComputerName
            UserName=$UserName
        }
        $serverArray = New-Object -TypeName PSObject -Property $server
    }
    Catch
    
    { 
        $server = [ordered]@{
            ComputerName=$computerName
            UserName="(Get-UserDetail) Server Error: " + $_.Exception.Message + " : "  + $_.FullyQualifiedErrorId
        }
        $serverArray = New-Object -TypeName PSObject -Property $server
    }
    return $serverArray   

#endRegion

#Region CheckWarningsErrors  (Changed as deatedcted)
<#
.Synopsis
   Check for warnings or errors 
.DESCRIPTION
   This function will check if any warnings or errors is on the server EventLog
.PARAMETERS
    $ComputerName: A Valid Computer Name or IP Address
#>
function CheckWarningsErrors
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([array])]
    Param(
        [Parameter()]
        [string]
        $ComputerName
        )

    # Date before and after to check 24 hours worth of data
    $DateBefore = (Get-Date)
    $DateAfter = (Get-Date).AddDays(-1)

    $errorOutputArray = @()
    try
    {
        # Check if any security errors or warning was log to the eventlog
        $EventLogTest = Get-EventLog -ComputerName $ComputerName -LogName Security -Before $DateBefore -After $DateAfter | 
        Where-Object {$_.EntryType -like 'Error' -or $_.EntryType -like 'Warning'}

        #$EventLogTest = Get-EventLog -LogName System -Newest 5   @TEST
        If ($null -ne $EventLogTest )
        {
            # If Warnings or Errors found, then write it out to the log file
            Foreach ($eventLog in $EventLogTest)
            {
                $errorOutput = [ordered]@{
                    ComputerName=$ComputerName
                    EntryType = $eventLog.EntryType
                    Index = $eventLog.Index 
                    Source = $eventLog.Source
                    InstanceID = $eventLog.InstanceID
                    Message = $eventLog.Message }
                    $errorOutputArray = New-Object -TypeName PSObject -Property $errorOutput
            }
        }else
        {
            # If no errors where found
                $errorOutput = [ordered]@{
                ComputerName=$ComputerName
                EntryType = ""
                Index = "" 
                Source = ""
                InstanceID = ""
                Message = "No Warning or Errors found on this server" }
                $errorOutputArray = New-Object -TypeName PSObject -Property $errorOutput
        }
    }
    catch 
    { 
        $errorOutput = [ordered]@{
                ComputerName=$ComputerName
                EntryType = "" ;  Index = "" ; Source = ""
                InstanceID = ""
                Message = "(Check-WarningsErrors) Server Error: " + $_.Exception.Message + " : "  + $_.FullyQualifiedErrorId }
                $errorOutputArray = New-Object -TypeName PSObject -Property $errorOutput

    }
    return $errorOutputArray   
    
}
#endregion

#Region
Get-NetworkInfo
<#
.Synopsis
   Get Network Info
.DESCRIPTION
   This function will get detailed network information
.PARAMETERS
    $ComputerName: A Valid Computer Name or IP Address
#>

Get-NetworkInfo 

    [CmdletBinding()]
    [Alias()]
    [OutputType()] 
    ([string]$ComputerName = $env:computername)
        #BSC DCM students 2020 - fix this
        #a parameter should be added here for the string variable named ComputerName
        
        

    $networkInformationArray = @()

    try
    {
        $networkInfo = Test-NetConnection -InformationLevel Detailed -ComputerName $computerName 
                $networkInfoOutput = [ordered]@{
                    ComputerName=$networkInfo.ComputerName
                    RemoteAddress=$networkInfo.RemoteAddress
                    NameResolutionResults=$networkInfo.NameResolutionResults
                    InterfaceAlias=$networkInfo.InterfaceAlias
                    SourceAddress=$networkInfo.SourceAddress
                    NetRoute=$networkInfo.NetRoute
                    PingSucceeded=$networkInfo.PingSucceeded
                    PingReplyDetails=$networkInfo.PingReplyDetails }
                    $networkInformationArray = New-Object -TypeName PSObject -Property $networkInfoOutput
    }
    catch 
    { 
        $networkInfo = Test-NetConnection -InformationLevel Detailed -ComputerName $computerName 
                $networkInfoOutput = [ordered]@{
                    ComputerName=$networkInfo.ComputerName
                    RemoteAddress="(Get-NetworkInfo) Server Error: " + $_.Exception.Message + " : "  + $_.FullyQualifiedErrorId
                    NameResolutionResults=""
                    InterfaceAlias=""
                    SourceAddress=""
                    NetRoute=""
                    PingSucceeded=""
                    PingReplyDetails="" }
                    $networkInformationArray = New-Object -TypeName PSObject -Property $networkInfoOutput
    }

    return $networkInformationArray   

#endregion

#Region Check-OpenPorts
<#
.Synopsis
Check what ports are open
   
.DESCRIPTION
Checks the ports that are open
   
.PARAMETERS

#>

# BSc DCM - fix this
# fill in appropriate comments for the method as per the section above. this comment refers to the 
# check-openports function shown below.
function Check-OpenPorts 

    [CmdletBinding()]
    [Alias()]
    [OutputType([array])]
    Param(
        [Parameter()]
        [string])
        $ComputerName,
        [Parameter()]
        [string[]]
        $PortList
        
    $checkOpenPortsArray = @()
    

        
        # BSc DCM 2020 - fix this
        # We need an iterator here to go through all $ports in $PortList
        # Write in the single line of code to iterate through the port list

	foreach ($port in 1..1024) {If (($a=Test-NetConnection srvfs01 -Port))}
	$port -WarningAction
	SilentlyContinue.tcpTestSucceeded -eq $true
        {
            
            #BSc DCM 2020 - Fix this
            # $portConnected =
            # finish the above line of code using the Test-NetConnection command and then uncomment.
            #check by port $port, and the computer name $ComputerName.
            # add an action of SilentlyContinue if a warning occurs
            # this is one line of code only!
            $ports = [ordered]@{
                ComputerName=$ComputerName
                Port=$port
                Open=$portConnected.TcpTestSucceeded
            }
            $checkOpenPortsArray += New-Object -TypeName PSObject -Property $ports
        }
    
    catch 
    { 
        $ports = [ordered]@{
                ComputerName=$ComputerName
                Port=$port
                Open="(Check-OpenPorts) Server Error: " + $_.Exception.Message + " : "  + $_.FullyQualifiedErrorId
            }
            $checkOpenPortsArray = New-Object -TypeName PSObject -Property $ports
    }
    return $checkOpenPortsArray   

