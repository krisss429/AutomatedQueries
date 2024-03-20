# Use this Powershell script to stop all services in cluster
# Format :  .\ [cluster name]
# Example:  .\Cluster_StopServices CAMBOSUATCLTST
#
#
$logdate = (get-date).tostring('yyyy-MM-dd_HH-mm-ss')
$log = "C:\scripts\Cluster_Patching\Logs\Cluster_StopServices_" + $logdate + ".log"            

$emailrecipients = "ITDatabaseOperations@homesite.com"
$erroremailrecipients = "ITDatabaseOperations@homesite.com"

$emailfrom = "Lower_Cluster_StopServices@homesite.com"
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
-Subject "ERROR- Unable To Stop Cluster Services" `
-Body "The automated 'Cluster_StopServices' script encountered an error. See attached log." `
-attachment $log -priority high            
                
write-host "Stopping Cluster Services encountered an error"            
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
	-Subject "ERROR- Unable To Stop Cluster Services" `
	-Body "The automated 'Cluster_StopServices' script encountered an error. See attached log." `
	-attachment $log -priority high            
                
	write-host "Stopping Cluster Services encountered an error"            
	exit            
	}            
}            

out-file -filepath $log -inputobject "=======================================================================================================================" -Append

# Check that all arguments were supplied
#
if ($args.length -ne 1)
{
	$now = (get-date).tostring('HH:mm:ss -')            
    	out-file -filepath $log -inputobject "$now Invalid script format." -Append
    	out-file -filepath $log -inputobject "$now Format :  .\Cluster_StopServices [cluster name]" -Append
    	out-file -filepath $log -inputobject "$now Example:  .\Cluster_StopServices CAMBOSUATCLTST" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "ERROR- Unable To Stop Cluster Services" `
	-Body "The automated 'Cluster_StopServices' script encountered an error. See attached log." `
	-attachment $log -priority high            
                
	write-host "Stopping Cluster Services encountered an error"            
	exit
}

#Assign arguments
#
$ClusterName = $args[0]

$now = (get-date).tostring('HH:mm:ss -')

	out-file -filepath $log -inputobject "$now Input parameters are: $ClusterName" -Append


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
-Subject "ERROR- Unable To Stop Cluster Services" `
-Body "The automated 'Cluster_StopServices' script encountered an error. See attached log." `
-attachment $log -priority high            
                
write-host "Stopping Cluster Services encountered an error"            
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
out-file -filepath $log -inputobject "$now Validating parameter $ClusterName (cluster name)" -Append

if ($ClusterArray -notcontains $ClusterName)
{
	out-file -filepath $log -inputobject "$now $ClusterName is not a valid cluster name." -Append
	out-file -filepath $log -inputobject "$now parameter should be one of the following: $ClusterArray" -Append
    	out-file -filepath $log -inputobject "$now Terminating script." -Append
               
	Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject "ERROR- Unable To Stop Cluster Services" `
	-Body "The automated 'Cluster_StopServices' script encountered an error. See attached log." `
	-attachment $log -priority high            
                
	write-host "Stopping Cluster Services encountered an error"            
	exit
}

out-file -filepath $log -inputobject "$now $ClusterName is valid" -Append

# Open new log file
#
$log = "C:\scripts\Cluster_Patching\Logs\Cluster_StopServices_" + $ClusterName + "_" + $logdate + ".log"

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Starting 'Cluster_StopServices' Script"

# Parameters were validated above. Repeating for new log only.
#
out-file -filepath $log -inputobject "$now Cluster to StopServices : $ClusterName" -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Getting resource groups status in cluster ""$ClusterName"" -- BEFORE Stopping Services" -Append

try            
{            
$BeforeStopping = Get-ClusterGroup -Cluster $ClusterName |sort-object name -ErrorAction Stop
}
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "ERROR- ""$ClusterName"" - Unable To Stop Cluster Services" `
-Body "The automated script to stop services on Cluster ""$ClusterName"" encountered an error. See attached log." `
-attachment $log -priority high            
                
write-host "Stopping Cluster Services encountered an error"            
exit            
}            
out-file -filepath $log -inputobject $BeforeStopping -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append


#StopServices
#
ForEach($item in $BeforeStopping)
{
	$now = (get-date).tostring('HH:mm:ss -')
	$itemName = $item.Name
	$itemNode = $item.OwnerNode
	$itemStatus = $item.Status

	if ($itemName -ne "Cluster Group")
	{
		$now = (get-date).tostring('HH:mm:ss -')
		out-file -filepath $log -inputobject "$now Stopping resource group ""$itemName"" in cluster ""$ClusterName""" -Append
		try            
		{            
		$StopClusterGroup = Stop-ClusterGroup -Cluster $ClusterName -Name $itemName -ErrorAction Stop
		}
		catch            
		{
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
		$now = (get-date).tostring('HH:mm:ss -')            
		out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
		out-file -filepath $log -inputobject "$now Terminating script." -Append
				  
		Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
		-Subject "ERROR- ""$ClusterName"" - Unable To Stop Cluster Services" `
		-Body "The automated script to stop services on Cluster ""$ClusterName"" encountered an error. See attached log." `
		-attachment $log -priority high            
				   
		write-host "Stopping Cluster Services encountered an error"            
		exit 	   
		}
	}
}

out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append

$now = (get-date).tostring('HH:mm:ss -')
out-file -filepath $log -inputobject "$now Getting resource groups status in cluster ""$ClusterName"" -- AFTER Stopping Services" -Append

try            
{            
$AfterStopping = $AfterStopping = Get-ClusterGroup -Cluster $ClusterName |sort-object name -ErrorAction Stop
}
catch            
{            
$ErrorMessage = $_.Exception.Message	
$now = (get-date).tostring('HH:mm:ss -')            
out-file -filepath $log -inputobject "$now $ErrorMessage" -Append
out-file -filepath $log -inputobject "$now Terminating script." -Append
               
Send-MailMessage -to $erroremailrecipients -from $emailfrom -smtpserver $emailserver `
-Subject "ERROR- ""$ClusterName"" - Unable To Stop Cluster Services" `
-Body "The automated script to stop services on Cluster ""$ClusterName"" encountered an error. See attached log." `
-attachment $log -priority high            
                
write-host "Stopping Cluster Services encountered an error"            
exit            
}            
out-file -filepath $log -inputobject $AfterStopping -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject "**** Note: NEVER take resource group ""Cluster Group""(Quorum) Offline, as it will take whole cluster down ****"  -Append
out-file -filepath $log -inputobject " " -Append
out-file -filepath $log -inputobject "=======================================================================================================================" -Append


	$now = (get-date).tostring('HH:mm:ss -')            
	out-file -filepath $log -inputobject "$now Script completed successfully. Sending email." -Append

	Send-MailMessage -to $emailrecipients -from $emailfrom -smtpserver $emailserver `
	-Subject """$ClusterName"" - Stopped Cluster Services" `
	-Body "The automated script to stop services on Cluster ""$ClusterName"" completed successfully. See attached log." `
	-attachment $log
 
	write-host "Stopped Services on ""$ClusterName"""      

		
