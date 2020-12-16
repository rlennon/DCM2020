#
#System.String $items = Get-Service -DisplayName
ForEach ($item in Get-Service) 
{
    If ($item -icontains "Service" )
    {
      $count+=1
    }
}
Write-Host $count