##############################################################################
#  Script: Get-LocalMembership-Domain.ps1
#    Date: 2020.09.18
# Version: 3.5
#  Author: Blake Regan @blake_r38
# Purpose: Identify accounts in local groups on domain joined windows workstations
#   Legal: Script provided "AS IS" without warranties or guarantees of any
#          kind.  USE AT YOUR OWN RISK.  Public domain, no rights reserved.
##############################################################################




Import-Module ActiveDirectory
$domain=(Get-WmiObject Win32_ComputerSystem).Domain.Split('.')

<#Servers is a place holder for an OU, or OUs that you want to monitor.
You can create a block for each OU that you want to monitor
Plans to add detection for OUs that have computer objects and iterate through array
#>
if ($domain.Count -eq 1)
{
   $Servers=Get-ADComputer -Filter * -SearchBase "ou=Servers,dc=$($domain[0])" -Properties Name, DistinguishedName | Select-Object -Property Name,DistinguishedName 
}

if ($domain.Count -eq 2)
{
   $Servers=Get-ADComputer -Filter * -SearchBase "ou=Servers,dc=$($domain[0]),dc=$($domain[1])" -Properties Name, DistinguishedName | Select-Object -Property Name,DistinguishedName 
}

if ($domain.Count -eq 3)
{
   $Servers=Get-ADComputer -Filter * -SearchBase "ou=Servers,dc=$($domain[0]),dc=$($domain[1]),dc=$($domain[2])" -Properties Name, DistinguishedName | Select-Object -Property Name,DistinguishedName 
}


$Servers=Get-ADComputer -Filter * -SearchBase "ou=Servers,dc=$($domain[0]),dc=$($domain[1])" -Properties Name, DistinguishedName | Select-Object -Property Name,DistinguishedName
$AdminExport="C:\Temp\Local Group Membership\LocalAdminMembership.csv"
$RDP_UsersExport="C:\Temp\Local Group Membership\RemoteDesktop.csv"


Add-Content $AdminExport -Value "Server-User"

foreach ($Server in $Servers)
{
    if (Test-NetConnection -Port 135  -ComputerName $Server.Name)
    {
        <#
        write-host
        write-host $Server.Name
        $Content=Invoke-Command -ComputerName $Server.Name -ScriptBlock {Get-LocalGroupMember -group "Administrators"  | select-object -Property PSComputerName,Name,ObjectClass}
        Add-Content $AdminExport -Value $($Content)
        $Content=$null
        #>
        #WMI Version, useful for environments with legacy Powershell Versions
        $LocalAdmins = Get-WmiObject -query "Select * From Win32_Group Where Name='Administrators' and LocalAccount='True'" -computer $Server.Name
        $Content=$LocalAdmins.GetRelationships("Win32_GroupUser") | select PartComponent
        Add-Content $AdminExport -Value $($Content)
        $Content=$null
        
    }
}


Add-Content $RDP_UsersExport -Value "Server-User"

foreach ($Server in $Servers)
{
    if (Test-NetConnection -Port 135 -ComputerName $Server.Name)
    {
        <#
        write-host
        write-host $Server.Name
        $Content=Invoke-Command -ComputerName $Server.Name -ScriptBlock {Get-LocalGroupMember -group 'Remote Desktop Users'  | select-object -Property PSComputerName,Name,ObjectClass}
        Add-Content $RDP_UsersExport -Value $($Content)
        $Content=$null
        #>

        #WMI Version, useful for environments with legacy Powershell Versions
        $LocalAdmins = Get-WmiObject -query "Select * From Win32_Group Where Name='Remote Desktop Users' and LocalAccount='True'" -computer $Server.Name
        $Content=$LocalAdmins.GetRelationships("Win32_GroupUser") | select PartComponent
        Add-Content $RDP_UsersExport -Value $($Content)
        $Content=$null
        
        
    }
}
