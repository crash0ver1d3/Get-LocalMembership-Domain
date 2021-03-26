##############################################################################
#  Script: Get-LocalMembership-Domain.ps1
#    Date: 2020.09.18
# Version: 3.5
#  Author: Blake Regan @crash0ver1d3
# Purpose: Identify accounts in local groups on domain joined windows computers.
#   Legal: Script provided "AS IS" without warranties or guarantees of any
#          kind.  USE AT YOUR OWN RISK.  Public domain, no rights reserved.
##############################################################################



#requires Active Directory Module
#If not installed, but you want to install the RSAT-AD Powershell tools, run the following command to install the built in windows feature, on WS2K12R2 and above
#PS>Install-WindowsFeature RSAT-AD-PowerShell, no reboot needed.
Import-Module ActiveDirectory
$domain=(Get-WmiObject Win32_ComputerSystem).Domain.Split('.')

<#Servers is a place holder for an OU, or OUs that you want to monitor.
You can create a block for each OU that you want to monitor
Plans to add detection for OUs that have computer objects and iterate through array
#>
#dc=contoso,dc=redmond,dc=local
$root = [ADSI]"LDAP://RootDSE"
#$DOMAIN = $root.Get("rootDomainNamingContext")
$DOMAIN = $root.defaultNamingContext

#Gather query targets into an array, using the $DOMAIN variable to gather the Domain Container Format, like dc=contoso,dc=redmond,dc=local
#You can target what every OU that you require, just fill in the Distinguished name in the search base "dc=contoso,dc=redmond,dc=local" format. $DOMAIN will
#dynamically resolve to whatever domain you run this script in.

$Servers=Get-ADComputer -Filter * -SearchBase "ou=Servers,$DOMAIN" -Properties Name, DistinguishedName | Select-Object -Property Name,DistinguishedName 

#timestamp cannot contain decimal in the format, as that will appear as a file name extension, and prevent export from being created
$timestamp=(Get-Date -UFormat "%Y%m%d_%H-%M-%S")


#Define the export paths, including $timestamp in the file name, for records keeping. Also allows you to run query multiple times in the same directory, and not have duplicate filename
$AdminExport="C:\Temp\Local Group Membership\LocalAdminMembership$timestamp.csv"
$RDP_UsersExport="C:\Temp\Local Group Membership\RemoteDesktop$timestamp.csv"

#create csv header column names, using the Add-Content cmdlet, and defining the $AdminExport file to update
Add-Content $AdminExport -Value "Server-User"

#Check that WMI port is accesible on the target host, if so, perform query. This does add a little extra time, but worth it for accuracy, and a clean report.
#You will see errors for hosts that are not reachable on port 135 (WMI), but that will not affect your results.
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

#create csv header column names, using the Add-Content cmdlet, and defining the $RDP_UsersExport file to update
Add-Content $RDP_UsersExport -Value "Server-User"

#Check that WMI port is accesible on the target host, if so, perform query. This does add a little extra time, but worth it for accuracy, and a clean report.
#You will see errors for hosts that are not reachable on port 135 (WMI), but that will not affect your results.
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
