# Use this powershell script to perform a remote cluster reset
# Format :  .\Cluster_StartServices_Reset [cluster name] [node 1] [node 2]
# Example:  .\Cluster_StartServices_Reset CAMAKRSQLCLS1 CAMAKRSQLN1 CAMAKRSQLN2
#
#
$logdate = (get-date).tostring('yyyy-MM-dd_HH-mm-ss')
$log = "C:\scripts\Cluster_Patching\Logs\Cluster_StartServices_Reset_" + $logdate + ".log"            

$emailrecipients = "ITDatabaseOperations@homesite.com"
$erroremailrecipients = "ITDatabaseOperations@homesite.com"

$emailfrom = "Lower_Cluster_StartServices_Reset@homesite.com"
$emailserver = "hsboscas.camelot.local"

# Make sure the cluster module is loaded            
#            
try            
{            
$CurrentMods = Get-Module -ErrorAction Stop            
}            
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "ERROR- Unable To Start Cluster Services" `
-Body "The automated 'Cluster_StartServices_Reset' script encountered an error. See attached log." `
-attachment $log -priority high            
                
write-host "Starting Cluster Services encountered an error"            
exit            
}            

$ClusterModLoaded = $FALSE            
foreach ($Mod in $CurrentMods)
{            
	if ($Mod.Name -eq "FailoverClusters")            
    	{            
    		$ClusterModLoaded = $TRUE            
    		$now = (get-date).tostring('HH:mm:ss -')            
    		out-file -filepath $log -inputobject "$now PS cluster module loaded successfully" -Append           
    	}            
}            

if ($ClusterModLoaded -eq $FALSE)            
{            
	try            
	{            
	Import-Module FailoverClusters -ErrorAction Stop            
    	$now = (get-date).tostring('HH:mm:ss -')            
    	out-file -filepath $log -inputobject "$now PS cluster module loaded successfully" -Append  
    	}            
	catch            
    	{            
	$ErrorMessage = $_.Exception.Message	
	$now = (get-date).tostring('HH:mm:ss -')            
	out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "ERROR- Unable To Start Cluster Services" `
	-Body "The automated 'Cluster_StartServices_Reset' script encountered an error. See attached log." `
	-attachment $log -priority high            
                
	write-host "Starting Cluster Services encountered an error"            
	exit            
	}            
}            

out-file -filepath $log -inputobject "=======================================================================================================================" -Append

# Check that all arguments were supplied
#
if ($args.length -ne 3)
{
	$now = (get-date).tostring('HH:mm:ss -')            
    	out-file -filepath $log -inputobject "$now Invalid script format." -Append
    	out-file -filepath $log -inputobject "$now Format :  .\Cluster_StartServices_Reset [cluster name] [node 1] [node 2]" -Append
    	out-file -filepath $log -inputobject "$now Example:  .\Cluster_StartServices_Reset CAMAKRSQLCLS1 CAMAKRSQLN1 CAMAKRSQLN2" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "ERROR- Unable To Start Cluster Services" `
	-Body "The automated 'Cluster_StartServices_Reset' script encountered an error. See attached log." `
	-attachment $log -priority high            
                
	write-host "Starting Cluster Services encountered an error"            
	exit
}

#Assign arguments
#
$ClusterName = $args[0]
$Node1 = $args[1]
$Node2 = $args[2]

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Input parameters are: $ClusterName and $Node1 and $Node2" -Append

$DomainName = (Get-WmiObject Win32_ComputerSystem).Domain

#Get all Clusters in Domain
#
try            
{            
$ClusterList = Get-Cluster -domain $DomainName -ErrorAction Stop
}            
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "ERROR- Unable To Start Cluster Services" `
-Body "The automated 'Cluster_StartServices_Reset' script encountered an error. See attached log." `
-attachment $log -priority high            
                
write-host "Starting Cluster Services encountered an error"            
exit            
}            

#Build array of clusters
#
$ClusterArray = New-Object System.Collections.ArrayList
ForEach($item in $ClusterList)
{
	[void] $ClusterArray.Add($item.Name)
}

#Validate cluster name
#
$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Validating first parameter $ClusterName (cluster name)" -Append

if ($ClusterArray -notcontains $ClusterName)
{
	out-file -filepath $log -inputobject "$now $ClusterName is not a valid cluster name." -Append
	out-file -filepath $log -inputobject "$now First parameter should be one of the following: $ClusterArray" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "ERROR- Unable To Start Cluster Services" `
	-Body "The automated 'Cluster_StartServices_Reset' script encountered an error. See attached log." `
	-attachment $log -priority high            
                
	write-host "Starting Cluster Services encountered an error"            
	exit
}

out-file -filepath $log -inputobject "$now $ClusterName is valid" -Append

#Get all nodes in cluster
#
try            
{            
$ClusterNodes = Get-ClusterNode -Cluster $ClusterName |sort-object name -ErrorAction Stop
}            
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "ERROR- Unable To Start Cluster Services" `
-Body "The automated 'Cluster_StartServices_Reset' script encountered an error. See attached log." `
-attachment $log -priority high            
                
write-host "Starting Cluster Services encountered an error"            
exit            
}            

#Build list of nodes
#
$NodeArray = New-Object System.Collections.ArrayList
ForEach($item in $ClusterNodes)
{
	[void] $NodeArray.Add($item.Name)
}

#Validate node name 1
#
$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Validating first parameter $Node1 (node 1)" -Append

if ($NodeArray -notcontains $Node1)
{
	out-file -filepath $log -inputobject "$now $Node1 is not a valid node name." -Append
	out-file -filepath $log -inputobject "$now First parameter should be one of the following: $NodeArray" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "ERROR- Unable To Start Cluster Services" `
	-Body "The automated 'Cluster_StartServices_Reset' script encountered an error. See attached log." `
	-attachment $log -priority high            
                
	write-host "Starting Cluster Services encountered an error"            
	exit
}

out-file -filepath $log -inputobject "$now $Node1 is valid" -Append

#Validate node name 2
#
$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Validating second parameter $Node2 (node 2)" -Append

if ($NodeArray -notcontains $Node2)
{
	out-file -filepath $log -inputobject "$now $Node2 is not a valid node name." -Append
	out-file -filepath $log -inputobject "$now Second parameter should be one of the following: $NodeArray" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "ERROR- Unable To Start Cluster Services" `
	-Body "The automated 'Cluster_StartServices_Reset' script encountered an error. See attached log." `
	-attachment $log -priority high            
                
	write-host "Starting Cluster Services encountered an error"            
	exit
}

out-file -filepath $log -inputobject "$now $Node2 is valid" -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

# Open new log file
#
$log = "C:\scripts\Cluster_Patching\Logs\Cluster_StartServices_Reset_" + $ClusterName + "_" + $logdate + ".log"

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Starting reset job"

# Parameters were validated above. Repeating for new log only.
#
out-file -filepath $log -inputobject "$now Cluster to reset   : $ClusterName" -Append
out-file -filepath $log -inputobject "$now Node 1 : $Node1" -Append
out-file -filepath $log -inputobject "$now Node 2 : $Node2" -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Getting resource groups from ""$Node1"" and ""$Node2"" in cluster ""$ClusterName"" -- BEFORE Starting Services" -Append

try            
{            
$BeforeReset = Get-ClusterNode -Cluster $ClusterName -Name $Node1,$Node2 | Get-ClusterGroup |sort-object name -ErrorAction Stop
}
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "ERROR- ""$ClusterName"" - Unable To Start Cluster Services" `
-Body "The automated script to start and reset services between ""$Node1"" and ""$Node2"" on Cluster ""$ClusterName"" encountered an error. See attached job log." `
-attachment $log -priority high            
                
write-host "Starting Cluster Services encountered an error"            
exit            
}            

out-file -filepath $log -inputobject $BeforeReset -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append


#Flip
#
$itemno = 0
ForEach($item in $BeforeReset)
{
	$now = (get-date).tostring('HH:mm:ss -')
	$itemName = $item.Name
	$itemNode = $item.OwnerNode
	$targetNode = ""


	if ($itemName -eq "Available Storage")
	{
		$targetNode = $Node1
	}
	
	if ($itemName -eq "Cluster Group")
	{
		$targetNode = $Node1
	}

	$IsDTC = $item.Name.ToUpper().Contains("DTC")
	if ($IsDTC -eq "True")
	{
		$targetNode = $Node1
	}

	$IsSQLServer = $item.Name.StartsWith("SQL Server (")
	if ($IsSQLServer -eq "True")
	{
		$itemno = $itemno + 1
		if ($itemno%2 -eq 0)
		{
			$targetNode = $Node2
		}
		else
		{
			$targetNode = $Node1
		}
	}

	if ([string]$itemNode -ne $targetNode)
	{
		$now = (get-date).tostring('HH:mm:ss -')
		out-file -filepath $log -inputobject "$now Moving and Starting resource group ""$itemName"" to ""$targetNode"" in cluster ""$ClusterName""" -Append
		try            
		{            
		$MoveClusterGroup = Move-ClusterGroup -Cluster $ClusterName -Name $itemName -Node $targetNode -ErrorAction Stop
		
		$StartClusterGroup = Start-ClusterGroup -Cluster $ClusterName -Name $itemName -ErrorAction Stop
		}
		catch            
		{
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
		$now = (get-date).tostring('HH:mm:ss -')            
		out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
		out-file -filepath $log -inputobject "$now Terminating script." -Append
               
		Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
		-Subject "ERROR- ""$ClusterName"" - Unable To Start Cluster Services" `
		-Body "The automated script to start and reset services between ""$Node1"" and ""$Node2"" on Cluster ""$ClusterName"" encountered an error. See attached job log." `
		-attachment $log -priority high            
                
		write-host "Starting Cluster Services encountered an error"            
		exit            
		}            
	}
	else
	{
		$now = (get-date).tostring('HH:mm:ss -')
		out-file -filepath $log -inputobject "$now Starting resource group ""$itemName"" to ""$targetNode"" in cluster ""$ClusterName""" -Append
		try            
		{            
		$StartClusterGroup = Start-ClusterGroup -Cluster $ClusterName -Name $itemName -ErrorAction Stop
		}
		catch            
		{
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
		$now = (get-date).tostring('HH:mm:ss -')            
		out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
		out-file -filepath $log -inputobject "$now Terminating script." -Append
               
		Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
		-Subject "ERROR- ""$ClusterName"" - Unable To Start Cluster Services" `
		-Body "The automated script to start and reset services between ""$Node1"" and ""$Node2"" on Cluster ""$ClusterName"" encountered an error. See attached job log." `
		-attachment $log -priority high            
                
		write-host "Starting Cluster Services encountered an error"            
		exit            
		}            
	}
}

out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Getting resource groups from ""$Node1"" and ""$Node2"" in cluster ""$ClusterName"" -- AFTER Starting Services" -Append

try            
{            
$AfterReset = Get-ClusterNode -Cluster $ClusterName -Name $Node1,$Node2 | Get-ClusterGroup |sort-object name -ErrorAction Stop
}
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "ERROR- ""$ClusterName"" - Unable To Start Cluster Services" `
-Body "The automated script to start and reset services between ""$Node1"" and ""$Node2"" on Cluster ""$ClusterName"" encountered an error. See attached job log." `
-attachment $log -priority high            
                
write-host "Starting Cluster Services encountered an error"            
exit            
}            

out-file -filepath $log -inputobject $AfterReset -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now Job complete. Sending email." -Append

Send-MailMessage -to $emailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject """$ClusterName"" - Started Cluster Services" `
-Body "The automated script to start and reset services between ""$Node1"" and ""$Node2"" on Cluster ""$ClusterName"" completed successfully. See attached log." `
-attachment $log
 
write-host "Started and reset services between ""$Node1"" and ""$Node2"" on ""$ClusterName"""          


























