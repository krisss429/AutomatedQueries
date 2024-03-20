SELECT 
--SERVERPROPERTY('ComputerNamePhysicalNetBIOS') [Machine Name],
SERVERPROPERTY('MachineName')
--,
   --SERVERPROPERTY('InstanceName') AS [Instance Name]
   ,LOCAL_NET_ADDRESS AS [IP Address Of SQL Server]
   --,CLIENT_NET_ADDRESS AS [IP Address Of Client]
   ,local_tcp_port
 FROM SYS.DM_EXEC_CONNECTIONS 
 WHERE SESSION_ID = @@SPID
