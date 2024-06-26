######################################################################################################################################################
# Script Title:    .\Cluster_Compare_Hotfixes.ps1
# Script Version:  Version 1.0 September 19, 2012
# Script Authors:  Rick Bergman & Ray Zabilla, Microsoft Corporation
#                  Stane Močnik - stane.mocnik@mobitel.si - http://gallery.technet.microsoft.com/178249bf-6d7f-4137-b473-e9351607163f                                    
#                                                                                         
# Script Purpose:  Uses an import file consisting of the Failover Cluster names, to connect to each node in the cluster, and compare the installed
#                  Hotfixes on each node.  It then creates 2 reports, one text and one html.  The Reports showing which nodes are missing which Hotfix 
#                  and a table of all of nodes and Hotfixes.  
#
# Script Paramaters:  None at this time
#                                                                                         
# Result:          Script generates the following files:
#                  .\Hotfix Comparison Table for <ClusterName> <DateTimeSTamp>.txt
#                  .\Hotfix Comparison Table for <ClusterName> <DateTimeSTamp>.html
#
######################################################################################################################################################

# ---------------------------------------------------------------------------------------------------- 
$IFN = ".\Clusters.csv"
$IFile = Import-Csv $IFN 
$DT = Get-Date -Format "yyyymmddHHmmss"
$Computers = @()
$Hotfixes = @() 
$Result = @() 
$Rlog = @()

# Start lopping through the Clusters.csv input file
ForEach ($Obj in $IFile)
{
    $ClusName = $Obj.ClusName
    $Outputfile = ".\Hotfix Comparison Table For " + $ClusName + " " + $DT + ".txt"
    $HTMLOutputFile = ".\Hotfix Comparison Table For " + $ClusName + " " + $DT + ".html"
    $header = "<H3>Hotfix Comparison Table for Cluster " + $ClusName + "</H3>"
    $MHeader =  "<H3>Missing Hotfixes Table for Cluster " + $ClusName + "</H3>"
    $head = '<!--mce:0-->'  

    # Get the node names from the cluster
    $ClusNodeInfo = Get-WmiObject -Namespace root/mscluster -Class MSCluster_Node -ComputerName $ClusName -EnableAllPrivileges -Authentication 6

    # Loop through each node name and place it in the $Computers variable
    ForEach ($Node in $ClusNodeInfo)
    {
        $Computers += $Node.Name
    }
    
    # Loop though Each Computer Node
    ForEach ($computer in $computers) 
    { 
        # Get the Hotfixes using Get-Hotfix 
        ForEach ($hotfix in (get-hotfix -computer $computer | select HotfixId)) 
        { 
            # Filter out returned Hotfixes named "File 1" - mainly happens on WS03
            # Store system names and hotfixes in the $Hotfixes HashTable 
            If ($Hotfix -notlike "*File 1*") 
            {
                $h = New-Object System.Object 
                $h | Add-Member -type NoteProperty -name "Server" -value $computer 
                $h | Add-Member -type NoteProperty -name "Hotfix" -value $hotfix.HotfixId 
                $hotfixes += $h
            }
        } 
    } 
         
    # Goes through the HashTable and ensures there are only Unique Computer Names
    $ComputerList = $hotfixes | Select-Object -unique Server | Sort-Object Server 
     
    # Loop Thru all the sorted unique Hotfixes
    ForEach ($hotfix in $hotfixes | Select-Object -unique Hotfix | Sort-Object Hotfix) 
    { 
        $h = New-Object System.Object 
        $h | Add-Member -type NoteProperty -name "Hotfix" -value $hotfix.Hotfix 
             
        # Loop through the Computers to match up the Hotfixes to the Computer
        ForEach ($computer in $ComputerList) 
        { 
            # Check to see if Hotfixes are present or missing.  If hotfix is present on computer add a "*" to the NodeName
            # If Computer is missing Hotfix add Hotfix and Computer to additional HashTable $RL, and add a "---" the $h HashTable
            If ($hotfixes | Select-Object |Where-Object {($computer.server -eq $_.server) -and ($hotfix.Hotfix -eq $_.Hotfix)})  
            {
                $h | Add-Member -type NoteProperty -name $computer.server -value "*"
            } 
            else 
            {
                $h | Add-Member -type NoteProperty -name $computer.server -value "---"
                $RL = New-Object System.Object
                $RL  | Add-Member -type NoteProperty -name "Server" -value $computer.server
                $RL  | Add-Member -type NoteProperty -name "Hotfix" -value $hotfix.Hotfix
                $RLog += $RL
            } 
        }
        # Adds the either the "*" or "---" to the server name
        $result += $h 
    } 
     
    # Checks to see if any results were added to the HashTable $RLog.  If none added then add 
    # "None" and "None Missing" to help make the report readable
    If ($RLog.count -eq 0)
    {
        $RL = New-Object System.Object
        $RL  | Add-Member -type NoteProperty -name "Server" -value "None"
        $RL  | Add-Member -type NoteProperty -name "Hotfix" -value "None Missing"
        $Rlog += $RL
    }
    
    $Rlog | ConvertTo-Html -head $head -body $Mheader | Out-File $HTMLOutputFile 
    $Result | ConvertTo-Html -head $head -body $header | Out-File $HTMLOutputFile -Append
    Invoke-Item $HTMLOutputFile

    # Write out the Missing Hotfix table to the text file
    "---------------------------------" | ft | Out-File -FilePath $OutputFile
    "The following Table is a list of Hotfixes that are missing on the nodes of the cluster" | ft | Out-File -FilePath $OutputFile -Append
    "---------------------------------" | ft | Out-File -FilePath $OutputFile -Append
    $RLog | Out-File -FilePath $OutputFile -Append

    # Write out the entire Hotfix table to the text file
    "---------------------------------" | ft | Out-File -FilePath $OutputFile -Append
    "The following Table is a list of all Hotfixes on all nodes of the cluster" | ft | Out-File -FilePath $OutputFile -Append
    "---------------------------------" | ft | Out-File -FilePath $OutputFile -Append
    $Result | Out-File -FilePath $OutputFile -Append
    
    # Clear the Array's
    $Computers = @()
    $Hotfixes = @()
    $Result = @() 
    $Rlog = @()
}
