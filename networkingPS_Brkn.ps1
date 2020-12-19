<#
.SYNOPSIS
	Networking Assignment (PowerShell) : Scripting the Deployment Pipeline 
	
.DESCRIPTION
	This script will run several network tests commands and display an exception if the server is not configured to receive Inbound calls or added as a TrustedHost. 
	The following needs to be configured on each server
       1. Run Enable-PSRemoting
       2. Windows Remote Management (HTTP-In) needs to be enables. use New-NetFirewallRule to set the firewall rules.
       3. Configure WinRM and allow your client PC as a TrustedHost
       4. Run Test-WsMan ComputerName to test if WinRM is correctly setup

.NOTE: Please update the IPAddresses.txt file with your own IP addresses or Computer Names, and also ensure that you have the Settings.ini file.

.CONCLUSION
	The goal of the script was to execute a list of commands from a central Windows server connecting 
	to multiple remote servers on the same network. The list of commands is testing networks connections, 
	get the current user logged onto the server, check if any security warnings and errors on the server’s 
	event logs, display the server’s detailed network information and check if any given ports are open or 
	closed on the server. 

	The strategy selected was to connect to multiple Windows operating machines only connected on the same 
	domain sharing the same gateway. It is important to note that this script will not work if all windows 
	machines are not on the same trusted network domain. 

	The user requires administrator rights on the domain to be able to connect to all windows servers. 
	It is recommended to run the Enable-PSRemoting command and to enable the Window Remote Manager services 
	on all windows servers to establish connectivity between these servers. The Settings.ini file contains 
	the location of the IPAddresses.txt file which has a list of either computer names or IP addresses. 
	It also includes the path where the script will write logs and messages to an output.log file. The settings 
	file also contains a list of ports to validate for all servers. This script ran successfully on a newly 
	created domain environment configured using VMWare, using a Windows 2019 server running Active Directory 
	connecting to a Window 10 personal computer. 
   
	The main Function, called Test-Network, accepts the list of servers from the IPAddresses.txt file and calls 
	other Functions to execute each task individually. This method ensures each Function executes independently 
	and consist of its internal exception handling. The script will continue to run, even If one remote server 
	incorrectly configured or an exception thrown for one or more commands executed. 
      
.EXAMPLE
	Another example of how to use this cmdlet when using multiple servers
	  . .\NetworkTests.ps1

.NOTES
	Filename:     NetworkTests.ps1
	Setting File: Settings.ini 
#>


Get-Content ".\Settings.ini" | foreach-object -begin {$settings=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $settings.Add($k[0], $k[1]) } }
$computerNames = Get-Content $settings.Get_Item("IPAddressesFile")
#Calling the Main Function to carry out network tests
Test-Network $computerNames

#Region Test-Network
<# 
.SYNOPSIS
	Main Function doing network tests. 

.DESCRIPTION
	This Function will call all the other Functions to carry out network tests.

.PARAMETERS
	$ServerNames: Pass a list of server names as String Array
#>
Function Test-Network
{
    Param(
		[Parameter()]
        [string[]]
        $ServerNames)

    Begin
    {
		$computerNames = $ServerNames
		# Creating objects to be used
		$serverArray = @()
		$errorOutputArray = @()
		$networkInformationArray = @()
		$checkOpenPortsArray = @()
		# Ports to check
		$portList = $settings.PortsToValidate.Split(",") # Split the sitring into a an array
		# Start to write to the Log File. All output will be written in the Log File
		Start-Transcript -Path $settings.Get_Item("LogFile")
    }    
	Process
    {    
		# BSC DCM 2020, I need to send the list of $computerNames to the next part of the process (Foreach). 
		# Which command should I use?
		Write-Output $computerNames  
		# Write-Host $computerNames
		# Uncomment the correct one of the above choices!

	# Start Process
    Foreach ($computerName in $computerNames)
    {
        # Test the connection to the ComputerName or Ip Address Given
        if (Test-Connection -ComputerName $computerName -Count 1 -Quiet)
        { 
            # Get User Logged onto the server
            $serverArray += Get-UserDetail $computerName
            # Check if any security errors or warning was log to the eventlog
            $errorOutputArray += Check-WarningsErrors $computerName
            # Get Network Information
            $networkInformationArray += Get-NetworkInfo $computerName
            # Check for open ports as per list given
            $checkOpenPortsArray += Check-OpenPorts $computerName $portList
        } 
		else 
		{
			$server = [ordered]@{
			ComputerName = $computerName
			UserName = "Remote Server Not Available"   
								}
			$serverArray += New-Object -TypeName PSObject -Property $server
        }
    } # bottom of Foreach loop
    }
    End
    {
		# Printing all the objects
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

#Region Get-UserDetail
<#
.SYNOPSIS
     Get User Detail
   
.DESCRIPTION
    This Function will get the current user logged onto the server.

.PARAMETERS
    $ComputerName: A Valid Computer Name or IP Address
#>
Function Get-UserDetail
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([array])]
    Param(
        [Parameter()]
        [string]
        $ComputerName)
		$serverArray = @()
    try
    {
        # Get the UserName logged onto the server
        $userName = (Get-WmiObject -Class win32_computersystem -ComputerName $ComputerName).UserName
        # Add the server found to the server Array
        $server = [ordered]@{
        ComputerName = $ComputerName
        UserName = $UserName
							}
        $serverArray = New-Object -TypeName PSObject -Property $server
    }
    catch 
    { 
        $server = [ordered]@{
        ComputerName = $computerName
        UserName = "(Get-UserDetail) Server Error: " + $_.Exception.Message + " : "  + $_.FullyQualifiedErrorId
							}
        $serverArray = New-Object -TypeName PSObject -Property $server
    }
    return $serverArray   
    
}
#endRegion

#Region Check-WarningsErrors
<#
.SYNOPSIS
    Check for warnings or errors 
	
.DESCRIPTION
    This Function will check if any warnings or errors is on the server EventLog

.PARAMETERS
    $ComputerName: A Valid Computer Name or IP Address
#>
Function Get-WarningsErrors
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
        $EventLogTest = Get-EventLog -ComputerName $ComputerName -LogName Security -Before $DateBefore -After $DateAfter | Where-Object {$_.EntryType -like 'Error' -or $_.EntryType -like 'Warning'}
        #$EventLogTest = Get-EventLog -LogName System -Newest 5   @TEST
        if ($null -ne $EventLogTest)
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
                Message = $eventLog.Message}
                $errorOutputArray = New-Object -TypeName PSObject -Property $errorOutput
            }
        }
		else
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

#Region Get-NetworkInfo
<#
.SYNOPSIS
    Get Network Info
   
.DESCRIPTION
    This Function will get detailed network information

.PARAMETERS
    $ComputerName: A Valid Computer Name or IP Address
#>
Function Get-NetworkInfo
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([array])]
   	Param(
        [Parameter()]
        [string]
        $ComputerName)
        #Parameter Computer name added
		$networkInformationArray = @()
    try
    {
        $networkInfo = Test-NetConnection -InformationLevel Detailed -ComputerName $computerName 
        $networkInfoOutput = [ordered]@{
        ComputerName = $networkInfo.ComputerName
        RemoteAddress = $networkInfo.RemoteAddress
        NameResolutionResults = $networkInfo.NameResolutionResults
        InterfaceAlias = $networkInfo.InterfaceAlias
        SourceAddress = $networkInfo.SourceAddress
        NetRoute = $networkInfo.NetRoute
        PingSucceeded = $networkInfo.PingSucceeded
        PingReplyDetails = $networkInfo.PingReplyDetails
										}
        $networkInformationArray = New-Object -TypeName PSObject -Property $networkInfoOutput
    }
    catch 
    { 
        $networkInfo = Test-NetConnection -InformationLevel Detailed -ComputerName $computerName 
        $networkInfoOutput = [ordered]@{
        ComputerName = $networkInfo.ComputerName
        RemoteAddress = "(Get-NetworkInfo) Server Error: " + $_.Exception.Message + " : "  + $_.FullyQualifiedErrorId
        NameResolutionResults = ""
        InterfaceAlias = ""
        SourceAddress = ""
        NetRoute = ""
        PingSucceeded = ""
        PingReplyDetails = "" 
										}
        $networkInformationArray = New-Object -TypeName PSObject -Property $networkInfoOutput
    }

    return $networkInformationArray   
}
#endregion

#Region Check-OpenPorts
<#
.SYNOPSIS
    Get Open Ports 

.DESCRIPTION
	This Function will check for OpenPors within ComputerName and PortList
	
.PARAMETERS  
	$ComputerName: A Valid Computer Name or IP Address
	$PortList: A Valid Port List
#>

# BSc DCM - fix this
# fill in appropriate comments for the method as per the section above. this comment refers to the 
# check-openports Function shown below.
Function Get-OpenPorts
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([array])]
    Param(
        [Parameter()]
        [string]
        $ComputerName,
        [Parameter()]
        [string[]]
        $PortList)
		$checkOpenPortsArray = @()
    try
    {
        # below an iterator here to go through all $ports in $PortList
        Foreach ($ports in $PortList)
		{
			$portConnected = Test-NetConnection -InformationLevel Detailed -ComputerName $computerName -port $port -Warning SilentlyContinue
			#check by port $port, and the computer name $ComputerName, added an action of SilentlyContinue if a warning occurs
			$ports = [ordered]@{
			ComputerName = $ComputerName
			Port = $port
			Open = $portConnected.TcpTestSucceeded
                           }
			$checkOpenPortsArray += New-Object -TypeName PSObject -Property $ports
        }
    }
    catch 
    { 
        $ports = [ordered]@{
        ComputerName = $ComputerName
        Port = $port
        Open = "(Check-OpenPorts) Server Error: " + $_.Exception.Message + " : "  + $_.FullyQualifiedErrorId
                           }
        $checkOpenPortsArray = New-Object -TypeName PSObject -Property $ports
    }
    return $checkOpenPortsArray   
}
#endregion

