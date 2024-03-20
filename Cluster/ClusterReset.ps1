# Use this powershell script to perform a local cluster reset
# Format :  .\ClusterReset [node 1] [node 2]
# Example:  .\ClusterReset camakrsqln1 camakrsqln2
#
#
$logdate = (get-date).tostring('yyyy-MM-dd_HH-mm-ss')
$log = "C:\ClusterReset_" + $logdate + ".log"            

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
-Subject "Cluster reset error" `
-Body "The cluster reset script encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Reset encountered an error"            
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
	-Subject "Cluster reset error" `
	-Body "The cluster reset script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Reset encountered an error"            
	exit            
	}            
}            

out-file -filepath $log -inputobject "=======================================================================================================================" -Append

# Check that all arguments were supplied
#
if ($args.length -ne 2)
{
	$now = (get-date).tostring('HH:mm:ss -')            
    	out-file -filepath $log -inputobject "$now Invalid script format." -Append
    	out-file -filepath $log -inputobject "$now Format :  .\ClusterReset [node 1] [node 2]" -Append
    	out-file -filepath $log -inputobject "$now Example:  .\ClusterReset camakrsqln1 camakrsqln2" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "Cluster reset error" `
	-Body "The automated reset script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Reset encountered an error"            
	exit
}

$Node1 = $args[0]
$Node2 = $args[1]

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Input parameters are: $Node1 and $Node2" -Append

try            
{            
$ClusterName = Get-Cluster -ErrorAction Stop
}            
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "Cluster reset error" `
-Body "The cluster reset script encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Reset encountered an error"            
exit            
}            

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
-Subject "Cluster reset error" `
-Body "The cluster reset script encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Reset encountered an error"            
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
	-Subject "Cluster reset error" `
	-Body "The cluster reset script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Reset encountered an error"            
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
	-Subject "Cluster reset error" `
	-Body "The cluster reset script encountered an error.  See attached job log." `
	-attachment $log -priority high            
                
	write-host "Reset encountered an error"            
	exit
}

out-file -filepath $log -inputobject "$now $Node2 is valid" -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

# Open new log file
#
$log = "C:\ClusterReset_" + $ClusterName + "_" + $logdate + ".log"

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
out-file -filepath $log -inputobject "$now Getting resource groups from $Node1 and $Node2 in cluster $ClusterName -- BEFORE RESET" -Append

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
-Subject "$ClusterName reset error" `
-Body "The automated reset of Cluster ""$ClusterName"" between ""$Node1"" and ""$Node2"" encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Reset encountered an error"            
exit            
}            

out-file -filepath $log -inputobject $BeforeReset -Append

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
-Subject "$ClusterName reset error" `
-Body "The automated reset of Cluster ""$ClusterName"" between ""$Node1"" and ""$Node2"" encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Reset encountered an error"            
exit            
}            

ForEach($item in $BeforeReset)
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
		-Subject "$ClusterName reset error" `
		-Body "The automated reset of Cluster ""$ClusterName"" between ""$Node1"" and ""$Node2"" encountered an error.  See attached job log." `
		-attachment $log -priority high            
                
		write-host "Reset encountered an error"            
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
				-Subject "$ClusterName reset error" `
				-Body "The automated reset of Cluster ""$ClusterName"" between ""$Node1"" and ""$Node2"" encountered an error.  See attached job log." `
				-attachment $log -priority high            
                
				write-host "Reset encountered an error"            
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
						-Subject "$ClusterName reset error" `
						-Body "The automated reset of Cluster ""$ClusterName"" between ""$Node1"" and ""$Node2"" encountered an error.  See attached job log." `
						-attachment $log -priority high            
                
						write-host "Reset encountered an error"            
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

	$IsDTC = $item.Name.ToUpper().Contains("DTC")
	if ($IsDTC -eq "True")
	{
		$targetNode = $Node1
	}

	if ($itemName -eq "Cluster Group")
	{
		$targetNode = $Node2
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
		out-file -filepath $log -inputobject "$now Moving resource group $itemName to $targetNode in cluster $ClusterName" -Append
		try            
		{            
		$MoveClusterGroup = Move-ClusterGroup -Cluster $ClusterName -Name $itemName -Node $targetNode -ErrorAction Stop
		}
		catch            
		{
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
		$now = (get-date).tostring('HH:mm:ss -')            
		out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
		out-file -filepath $log -inputobject "$now Terminating script." -Append
               
		Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
		-Subject "$ClusterName reset error" `
		-Body "The automated reset of Cluster ""$ClusterName"" between ""$Node1"" and ""$Node2"" encountered an error.  See attached job log." `
		-attachment $log -priority high            
                
		write-host "Reset encountered an error"            
		exit            
		}            
	}
}

out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Getting resource groups from $Node1 and $Node2 in cluster $ClusterName -- AFTER RESET" -Append

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
-Subject "$ClusterName reset error" `
-Body "The automated reset of Cluster ""$ClusterName"" between ""$Node1"" and ""$Node2"" encountered an error.  See attached job log." `
-attachment $log -priority high            
                
write-host "Reset encountered an error"            
exit            
}            

out-file -filepath $log -inputobject $AfterReset -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

#if ($ClusterReset -eq $TRUE)
#{
	$now = (get-date).tostring('HH:mm:ss -')            
	out-file -filepath $log -inputobject "$now Job complete. Sending email." -Append

	Send-MailMessage -to $emailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "$ClusterName reset complete" `
	-Body "The automated reset of Cluster ""$ClusterName"" between ""$Node1"" and ""$Node2"" is complete.  See attached job log." `
	-attachment $log
 
	write-host "Reset is complete"            
#} 
#else
#{
#	$now = (get-date).tostring('HH:mm:ss -')            
#	out-file -filepath $log -inputobject "$now There are still resource groups located on $Node1. Reset failed. Sending email." -Append

#	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
#	-Subject "$ClusterName reset error" `
#	-Body "The automated reset of Cluster ""$ClusterName"" between ""$Node1"" and ""$Node2"" encountered an error.  See attached job log." `
#	-attachment $log -priority high          

#	write-host "Reset encountered an error"            
#}


























