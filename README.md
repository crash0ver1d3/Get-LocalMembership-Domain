# Get-LocalMembership-Domain
This script is designed for use on a windows domain environment. You will notice that there is only one OU cited, and it is hard coded. You will need to modify this value to the specific OU that you would like to query/monitor. If you would like to query/monitor multiple OUs, you can approach this two ways:
1.Create a block for each OU. You will also need to define a new variable to store output to for each OU that your are querying/monitoring.
2.Create detection to identify OUs that have computer objects, create an output file for each one, and iterate through those OUs.

Future plans to add option number 2
