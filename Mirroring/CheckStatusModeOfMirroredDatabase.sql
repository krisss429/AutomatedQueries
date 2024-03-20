SELECT
DB_NAME(database_id) As DatabaseName,
CASE WHEN mirroring_guid IS NOT NULL THEN 'Mirroring is On' ELSE 'No mirror configured' END AS IsMirrorOn,
mirroring_state_desc,
CASE WHEN mirroring_safety_level=1 THEN 'High Performance' WHEN mirroring_safety_level=2 THEN 'High Safety' ELSE NULL END AS MirrorSafety,
mirroring_role_desc,
mirroring_partner_instance AS MirrorServer
FROM sys.database_mirroring WHERE CASE WHEN mirroring_guid IS NOT NULL THEN 'Mirroring is On' ELSE 'No mirror configured' END ='mirroring is on'
GO
