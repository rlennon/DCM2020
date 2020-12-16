<#
.Synopsis
Networking Assignment (PowerShell) : Scripting the Deployment Pipeline 
.DESCRIPTION
  This script will run several network tests commands and display an exception if the server is not configured to receive Inbound calls or added as a TrustedHost. 
      The following needs to be configured on each server
         1. Run Enable-PSRemoting
       2. Windows Remote Management (HTTP-In) needs to be enables. use New-NetFirewallRule to set the firewall rules.
         3. Configure WinRM and allow your client PC as a TrustedHost
         4. Run Test-WsMan ComputerName to test if WinRM is correctly setup
  NOTE: Please update the IPAddresses.txt file with your own IP addresses or Computer Names, and also ensure that you have the Settings.ini file.
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
   
   The main function, called Network-Tests, accepts the list of servers from the IPAddresses.txt file and calls 
   other functions to execute each task individually. This method ensures each function executes independently 
   and consist of its internal exception handling. The script will continue to run, even If one remote server 
   incorrectly configured or an exception thrown for one or more commands executed. 



PHILIPS NOTES
I tidied up the code to make it look more palatable and removed the unexpected token -process from the original code.
#>


Get-Content ".\Settings.ini" | foreach-object -Begin {
     $settings 
}
    { $k = [regex]::split($_,'='); 
        if(($k[0].CompareTo("") -ne 0) -and (
        $k[0].StartsWith("[") -ne $True)) 
            { 
            $settings.Add($k[0], $k[1]) 
            } 
    }
$computerNames = Get-Content $settings.Get_Item("IPAddressesFile")

NetworkTest $computerNames

<#
PHILIPS NOTES
I changed the name of the functions from Network-Tests to NetworkTest as it was giving me an
unapproved verb error which I read online that using the plural of test is the cause of 
this, so the Network-Tests function is changed to NetworkTest throughout the code.
See Microsoft(2018) in Conclusion document for reference.
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
            $serverArray = @()
            $errorOutputArray = @()
            $networkInformationArray = @()
            $checkOpenPortsArray = @()
            $portList = $settings.PortsToValidate.Split(",") 

<#
PHILIPS NOTES
Start-Transcript sends a text log file so write-Output is the correct cmdlet in this case
#>

    Start-Transcript -Path $settings.Get_Item("LogFile")
    }    Process
    {   
     Write-Output $computerNames  
   
    Foreach ($computerName in $computerNames)
    {
<#
PHILIPS NOTES
Changed Test-connection to Test-NetConnection
#>
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
        UserName="Remote Server Not Available"   }
            $serverArray += New-Object -TypeName PSObject -Property $server
        }
    }
}
End
{
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

function  Get-UserDetail
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([array])]
    Param(
        [Parameter()]
        [string]
        $ComputerName
        )
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
<#
PHILIPS NOTES
Inserted the missing catch statement here
#>
    catch 
    { 
        $server = [ordered]@{
            ComputerName=$computerName
            UserName="(Get-UserDetail) Server Error: " + $_.Exception.Message + " : "  + $_.FullyQualifiedErrorId
        }
        $serverArray = New-Object -TypeName PSObject -Property $server
    }
    return $serverArray   
    
}

<#
PHILIPS NOTES
Changed the function name from Check-WarningsErrors into CheckWarningsErrors due to unapproved verb warning
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

    $DateBefore = (Get-Date)
    $DateAfter = (Get-Date).AddDays(-1)

    $errorOutputArray = @()
    try
    {
        
        $EventLogTest = Get-EventLog -ComputerName $ComputerName -LogName Security -Before $DateBefore -After $DateAfter | 
        Where-Object {$_.EntryType -like 'Error' -or $_.EntryType -like 'Warning'}
<#
PHILIPS NOTES
Moved null to the otherside of the -ne (not equal to) comparision operator of the EventLog if statement.
#>       
        If ($null -ne $EventLogTest)
        {
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

function Get-NetworkInfo
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([array])]
    Param ([string]$ComputerName = $env:computername)
<#
PHILIPS NOTES
Added the paramater ComputerName as a string 
#>      
    $networkInformationArray = @()

    try
    {
        #Dispalys all details of the Computer included Name, Alias, Addresses, Route, as well as Ping details
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
        # If the information cannnot be found, displays an Execption message which an Error ID
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
}
#Region CheckOpenPorts
<# PHILIPS NOTES
.Synopsis
Check waht port are currently open
.DESCRIPTION
This check what port are currectly open and listening on the server
.PARAMETERS    $ComputerName: A Valid Computer Name or IP Address
$PortList: List of listening ports 
#> 
function CheckOpenPorts
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
        $PortList
        )
    $checkOpenPortsArray = @()
    try
    {

<#
PHILIPS NOTES
Iterator for loop to run through all the ports on PortList
#>         
        For ($ports=""; $ports -le $PortList; $ports++) {
            "$PortList * $ports = " + ($PortList * $ports)
            }
        {      
<#
PHILIPS NOTES
Completed the Test-Connection added Computer Name and port as well as adding the WarningAction SilentyContinue
#> 
            $portConnected = Test-NetConnection -ComputerName $ComputerName -Port $port -WarningAction SilentlyContinue
            $ports = [ordered]@{
                ComputerName=$ComputerName
                Port=$port
                Open=$portConnected.TcpTestSucceeded
            }
            $checkOpenPortsArray += New-Object -TypeName PSObject -Property $ports
        }
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
}