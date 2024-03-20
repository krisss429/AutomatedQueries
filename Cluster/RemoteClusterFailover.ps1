# Use this powershell script to perform a remote cluster failover
# Format :  .\RemoteClusterFailover [cluster name] [node to failover from] [node to failover to] [node to failover to must be inactive? Yes/No (default = Yes)]
# Example:  .\RemoteClusterFailover camakrsqlcls1 camakrsqln1 camakrsqln2 No
#
#
$logdate = (get-date).tostring('yyyy-MM-dd_HH-mm-ss')
$log = "C:\RemoteClusterFailover_" + $logdate + ".log"            

$emailrecipients = "rakesh.ramineni@homesite.com"
$erroremailrecipients = "rakesh.ramineni@homesite.com"

$emailfrom = "ITDatabaseOperations@homesite.com"
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
-Subject "Cluster failover error" `
-Body "The automated failover script encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Failover encountered an error"            
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
	-Subject "Cluster failover error" `
	-Body "The automated failover script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit            
	}            
}            

out-file -filepath $log -inputobject "=======================================================================================================================" -Append

# Check that all arguments were supplied
#
if ($args.length -ne 3 -and $args.length -ne 4)
{
	$now = (get-date).tostring('HH:mm:ss -')            
    	out-file -filepath $log -inputobject "$now Invalid script format." -Append
    	out-file -filepath $log -inputobject "$now Format :  .\RemoteClusterFailover [cluster name] [node to failover from] [node to failover to] [node to failover to must be inactive? Yes/No (default = Yes)]" -Append
    	out-file -filepath $log -inputobject "$now Example:  .\RemoteClusterFailover camakrsqlcls1 camakrsqln1 camakrsqln2 No" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "Cluster failover error" `
	-Body "The automated failover script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit
}

$ClusterName = $args[0]
$FromNode = $args[1]
$ToNode = $args[2]
if ($args.length -eq 4)
{
	$InactiveNodeVerification = $args[3]
}
else
{
	$InactiveNodeVerification = ""
}

$now = (get-date).tostring('HH:mm:ss -')
if ($InactiveNodeVerification -eq "")
{
	out-file -filepath $log -inputobject "$now Input parameters are: $ClusterName and $FromNode and $ToNode" -Append
}
else
{
	out-file -filepath $log -inputobject "$now Input parameters are: $ClusterName and $FromNode and $ToNode and $InactiveNodeVerification" -Append
}

$DomainName = (Get-WmiObject Win32_ComputerSystem).Domain

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
-Subject "Cluster failover error" `
-Body "The automated failover script encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Failover encountered an error"            
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
	-Subject "Cluster failover error" `
	-Body "The automated failover script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit
}

out-file -filepath $log -inputobject "$now $ClusterName is valid" -Append


try            
{            
$ClusterNodes = Get-ClusterNode -Cluster $ClusterName -ErrorAction Stop
}            
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "Cluster failover error" `
-Body "The automated failover script encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Failover encountered an error"            
exit            
}            

#Build list of nodes
#
$NodeArray = New-Object System.Collections.ArrayList
ForEach($item in $ClusterNodes)
{
	[void] $NodeArray.Add($item.Name)
}

#Build list of active (from) nodes
#
$ActiveNodeArray = New-Object System.Collections.ArrayList
ForEach($item in $ClusterNodes)
{
	$itemName = $item.Name

	try            
	{            
	$ClusterNode = Get-ClusterNode -Cluster $ClusterName -Name $itemName | Get-ClusterGroup -ErrorAction Stop
	}            
	catch            
	{            
	$ErrorMessage = $_.Exception.Message	
	$now = (get-date).tostring('HH:mm:ss -')            
	out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "Cluster failover error" `
	-Body "The automated failover script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit            
	}            

	if (($ClusterNode))
	{
		[void] $ActiveNodeArray.Add($item.Name)
	}
}

#Build list of (to) nodes
#
$InactiveNodeArray = New-Object System.Collections.ArrayList
ForEach($item in $ClusterNodes)
{
	if ($item.Name -ne $FromNode)
	{
		if ($ActiveNodeArray -notcontains $item.Name -or $InactiveNodeVerification -eq "No")
		{
			[void] $InactiveNodeArray.Add($item.Name)
		}
	}
}

#Validate from node name
#
$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Validating second parameter $FromNode (node to failover from)" -Append

if ($NodeArray -notcontains $FromNode)
{
	out-file -filepath $log -inputobject "$now $FromNode is not a valid node name." -Append
	out-file -filepath $log -inputobject "$now Second parameter should be one of the following: $ActiveNodeArray" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "Cluster failover error" `
	-Body "The automated failover script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit
}

if ($ActiveNodeArray -notcontains $FromNode)
{
	out-file -filepath $log -inputobject "$now $FromNode is not an active node" -Append
	out-file -filepath $log -inputobject "$now Second parameter should be one of the following: $ActiveNodeArray" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "Cluster failover error" `
	-Body "The automated failover script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit
}

out-file -filepath $log -inputobject "$now $FromNode is valid" -Append

#Validate to node name
#
$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Validating third parameter $ToNode (node to failover to)" -Append

if ($NodeArray -notcontains $ToNode)
{
	out-file -filepath $log -inputobject "$now $ToNode is not a valid node name." -Append
	out-file -filepath $log -inputobject "$now Third parameter should be one of the following: $InactiveNodeArray" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "Cluster failover error" `
	-Body "The automated failover script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit
}

if ($InactiveNodeArray -notcontains $ToNode)
{
	if ($InactiveNodeVerification -eq "No")
	{
		out-file -filepath $log -inputobject "$now $ToNode cannot be entered twice." -Append
	}
	else
	{
		out-file -filepath $log -inputobject "$now $ToNode is not an inactive node." -Append
	}
	out-file -filepath $log -inputobject "$now Third parameter should be one of the following: $InactiveNodeArray" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "Cluster failover error" `
	-Body "The automated failover script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit
}

out-file -filepath $log -inputobject "$now $ToNode is valid" -Append

#Validate inactive node check
#
if ($InactiveNodeVerification -ne "")
{
	$now = (get-date).tostring('HH:mm:ss -')
	out-file -filepath $log -inputobject "$now Validating fourth parameter $InactiveNodeVerification (node to failover to must be inactive?)" -Append

	if ($InactiveNodeVerification -ne "Yes" -and $InactiveNodeVerification -ne "No")
	{
		out-file -filepath $log -inputobject "$now $InactiveNodeVerification is not a valid entry." -Append
		out-file -filepath $log -inputobject "$now Fourth parameter should be one of the following: Yes No" -Append
	    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
		Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
		-Subject "Cluster failover error" `
		-Body "The automated failover script encountered an error.  See attached job log." `
		-attachment $log -priority high            
                
		write-host "Failover encountered an error"            
		exit
	}

	out-file -filepath $log -inputobject "$now $InactiveNodeVerification is valid" -Append
}

out-file -filepath $log -inputobject "=======================================================================================================================" -Append

# Open new log file
#
$log = "C:\RemoteClusterFailover_" + $ClusterName + "_" + $logdate + ".log"

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Starting failover job"

# Parameters were validated above. Repeating for new log only.
#
out-file -filepath $log -inputobject "$now Cluster to failover   : $ClusterName" -Append
out-file -filepath $log -inputobject "$now Node to failover from : $FromNode" -Append
out-file -filepath $log -inputobject "$now Node to failover to   : $ToNode" -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

ForEach($item in $ClusterNodes)
{
	$now = (get-date).tostring('HH:mm:ss -')
	$itemName = $item.Name
	out-file -filepath $log -inputobject "$now Resource groups owned by $itemName in cluster $ClusterName -- BEFORE FAILOVER" -Append

	try            
	{            
	$ClusterNode = Get-ClusterNode -Cluster $ClusterName -Name $itemName | Get-ClusterGroup -ErrorAction Stop
	}            
	catch            
	{            
	$ErrorMessage = $_.Exception.Message	
	$now = (get-date).tostring('HH:mm:ss -')            
	out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "$ClusterName failover error" `
	-Body "The automated failover of Cluster ""$ClusterName"" from ""$FromNode"" to ""$ToNode"" encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit            
	}            

	if (($ClusterNode))
	{
		out-file -filepath $log -inputobject $ClusterNode -Append
	}
	else
	{
		out-file -filepath $log -inputobject " " -Append
		out-file -filepath $log -inputobject "[None]" -Append
		out-file -filepath $log -inputobject " " -Append
		out-file -filepath $log -inputobject " " -Append
	}
}

out-file -filepath $log -inputobject "=======================================================================================================================" -Append

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Getting resource groups to move from $FromNode in cluster $ClusterName" -Append

try            
{            
$BeforeFailover = Get-ClusterNode -Cluster $ClusterName -Name $FromNode | Get-ClusterGroup -ErrorAction Stop
}
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "$ClusterName failover error" `
-Body "The automated failover of Cluster ""$ClusterName"" from ""$FromNode"" to ""$ToNode"" encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Failover encountered an error"            
exit            
}            

out-file -filepath $log -inputobject $BeforeFailover -Append

# Check for active jobs
#
try            
{            
# Load SMO extension
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null -ErrorAction Stop
}
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "$ClusterName failover error" `
-Body "The automated failover of Cluster ""$ClusterName"" from ""$FromNode"" to ""$ToNode"" encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Failover encountered an error"            
exit            
}            

ForEach($item in $BeforeFailover)
{
	$IsSQLServer = $item.Name.StartsWith("SQL Server (")
	if ($IsSQLServer -eq "True")
	{
		$ServerName = $item.Name.TrimStart("SQL Server (")
		$ServerName = $ServerName.Trim(")")

		try            
		{            
		$Instances = Get-WmiObject -Query "SELECT PrivateProperties FROM MSCluster_Resource WHERE Type = 'SQL Server'" -Namespace "Root\MSCluster" -ErrorAction Stop
		}
		catch            
		{            
		$ErrorMessage = $_.Exception.Message	
		$now = (get-date).tostring('HH:mm:ss -')            
		out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
		out-file -filepath $log -inputobject "$now Terminating script." -Append
               
		Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
		-Subject "$ClusterName failover error" `
		-Body "The automated failover of Cluster ""$ClusterName"" from ""$FromNode"" to ""$ToNode"" encountered an error.  See attached job log." `
		-attachment $log -priority high            
                
		write-host "Failover encountered an error"            
		exit            
		}            

		ForEach($object in $Instances)
		{
			if ($ServerName -eq $object.PrivateProperties.InstanceName)
			{
				$InstanceName = if ($object.PrivateProperties.InstanceName -eq "MSSQLSERVER") {$object.PrivateProperties.VirtualServerName} else {"$($object.PrivateProperties.VirtualServerName)\$($object.PrivateProperties.InstanceName)"};
				$now = (get-date).tostring('HH:mm:ss -')
				out-file -filepath $log -inputobject "$now Checking for active SQL Server Agent jobs on instance $InstanceName" -Append

				try            
				{            
				$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $InstanceName -ErrorAction Stop
				}
				catch            
				{            
				$ErrorMessage = $_.Exception.Message	
				$now = (get-date).tostring('HH:mm:ss -')            
				out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
				out-file -filepath $log -inputobject "$now Terminating script." -Append
               
				Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
				-Subject "$ClusterName failover error" `
				-Body "The automated failover of Cluster ""$ClusterName"" from ""$FromNode"" to ""$ToNode"" encountered an error.  See attached job log." `
				-attachment $log -priority high            
                
				write-host "Failover encountered an error"            
				exit            
				}            

				foreach($job in $srv.JobServer.Jobs)
				{
					$JobName = $job.Name
					$CurrentRunStatus = $job.CurrentRunStatus
# 1 = Executing
					if ($CurrentRunStatus -eq 1)
					{
						out-file -filepath $log -inputobject "$now Job $JobName is executing on $InstanceName." -Append
    						out-file -filepath $log -inputobject "$now Terminating script." -Append
               
						Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
						-Subject "$ClusterName failover error" `
						-Body "The automated failover of Cluster ""$ClusterName"" from ""$FromNode"" to ""$ToNode"" encountered an error.  See attached job log." `
						-attachment $log -priority high            
                
						write-host "Failover encountered an error"            
						exit
					}
				}

				$now = (get-date).tostring('HH:mm:ss -')
				out-file -filepath $log -inputobject "$now There are no active SQL Server Agent jobs on instance $InstanceName" -Append
				out-file -filepath $log -inputobject " " -Append
			}
		}
	}
}

#Flip
#
ForEach($item in $BeforeFailover)
{
	$now = (get-date).tostring('HH:mm:ss -')
	$itemName = $item.Name
	out-file -filepath $log -inputobject "$now Moving resource group $itemName to $ToNode in cluster $ClusterName" -Append

	try            
	{            
	$MoveClusterGroup = Move-ClusterGroup -Cluster $ClusterName -Name $itemName -Node $ToNode -ErrorAction Stop
	}
	catch            
	{
	$ErrorMessage = $_.Exception.Message
#	$FailedItem = $_.Exception.ItemName
	$now = (get-date).tostring('HH:mm:ss -')            
	out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "$ClusterName failover error" `
	-Body "The automated failover of Cluster ""$ClusterName"" from ""$FromNode"" to ""$ToNode"" encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit            
	}            
}

out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

$ClusterFailedover = $FALSE
ForEach($item in $ClusterNodes)
{
	$itemName = $item.Name
	$now = (get-date).tostring('HH:mm:ss -')
	out-file -filepath $log -inputobject "$now Resource groups owned by $itemName in cluster $ClusterName -- AFTER FAILOVER" -Append

	try            
	{            
	$ClusterNode = Get-ClusterNode -Cluster $ClusterName -Name $itemName | Get-ClusterGroup -ErrorAction Stop
	}            
	catch            
	{            
	$ErrorMessage = $_.Exception.Message	
	$now = (get-date).tostring('HH:mm:ss -')            
	out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "$ClusterName failover error" `
	-Body "The automated failover of Cluster ""$ClusterName"" from ""$FromNode"" to ""$ToNode"" encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Failover encountered an error"            
	exit            
	}            

	$now = (get-date).tostring('HH:mm:ss -')
	if (($ClusterNode))
	{
		out-file -filepath $log -inputobject $ClusterNode -Append
	}
	else
	{
		out-file -filepath $log -inputobject " " -Append
		out-file -filepath $log -inputobject "[None]" -Append
		out-file -filepath $log -inputobject " " -Append
		out-file -filepath $log -inputobject " " -Append
		if ($itemName -eq $FromNode)
		{
		$ClusterFailedover = $TRUE
		}
	}
}

out-file -filepath $log -inputobject "=======================================================================================================================" -Append

if ($ClusterFailedover -eq $TRUE)
{
	$now = (get-date).tostring('HH:mm:ss -')            
	out-file -filepath $log -inputobject "$now Job complete. Sending email." -Append

	Send-MailMessage -to $emailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "$ClusterName failover complete" `
	-Body "The automated failover of Cluster ""$ClusterName"" from ""$FromNode"" to ""$ToNode"" is complete.  See attached job log." `
	-attachment $log

	write-host "Failover is complete"            
} 
else
{
	$now = (get-date).tostring('HH:mm:ss -')            
	out-file -filepath $log -inputobject "$now There are still resource groups located on $FromNode. Failover failed. Sending email." -Append

	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "$ClusterName failover error" `
	-Body "The automated failover of Cluster ""$ClusterName"" from ""$FromNode"" to ""$ToNode"" encountered an error.  See attached job log." `
	-attachment $log -priority high          

	write-host "Failover encountered an error"            
}


























