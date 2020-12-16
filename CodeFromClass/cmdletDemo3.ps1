function find_files_written_after
{
    #Remember: F5 first, then type at the terminal to run the new commandlet
    #   find_files_written_after
   
   Get-ChildItem -Path C:\deleteMe -Recurse | Where-Object {$_.LastWriteTime -gt "05/10/2020"}
} 

