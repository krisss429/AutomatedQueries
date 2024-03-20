--Figure this could be helpful in looking into deadlocks.

--You can use this to view deadlock graphs.  Run query and click the DeadlockGraph XML and save it as a .xdl file.  You can then open that .xdl file in SSMS and see the deadlock info in a graph format.


Use Master 

SELECT
       CAST(xed.value('(data/value)[1]', 'varchar(max)') as xml) as DeadlockGraph,
       dateadd(hh,-5,xed.value('@timestamp', 'datetime')) as Creation_Date, --GMT time
       xed.query('.') AS Extend_Event
FROM
(
       SELECT CAST([target_data] AS XML) AS Target_Data
       FROM sys.dm_xe_session_targets AS xt
       INNER JOIN sys.dm_xe_sessions AS xs ON xs.address = xt.event_session_address
       WHERE xs.name = N'system_health'
       AND xt.target_name = N'ring_buffer'
) AS XML_Data
CROSS APPLY Target_Data.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(xed)
ORDER BY Creation_Date DESC
