function LogViewer
{
    PROCESS
    {
        Get-WinEvent -ListLog *
        #Get-WinEvent -LogName 'Microsoft-Windows-PrintService/Admin' -MaxEvents 5
        #Get-EventLog -Log System #Explore the options!
        #Get-EventLog -Log Application Firefox
        
        #logs can sometimes be found from websites as well as files
        $w_page = (new-object net.webclient).DownloadString("https://www.lyit.ie")
        $w_page.Split("LYIT")
        
        $out_file = "C:/DeleteMe/lyit.txt"
        $w_file = (new-object net.webclient).DownloadFile("https://www.lyit.ie",$out_file) 
    }
} 
#as before F5 first, then LogViewer at the command prompt to run.
#incomment each example/line separately as they are different examples.