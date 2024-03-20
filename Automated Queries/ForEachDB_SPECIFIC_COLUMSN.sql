EXECUTE master.sys.sp_MSforeachdb 
'USE [?]; 
select db_name();
IF (DB_NAME() = ''hs_service_info'')
	SELECT st.name as Table_Name,sc.name as Column_Name FROM sys.tables st
	JOIN  sys.COLUMNS sc 
	ON st.OBJECT_ID=sc.OBJECT_ID
	WHERE st.name LIKE (''%_ENC'')
	AND sc.name LIKE (''Encrypted%'')
	AND SC.NAME NOT LIKE (''%SSN%'')
	AND SC.NAME NOT LIKE (''%SOCIAL%'')
	AND SC.NAME NOT LIKE (''%bank%'')
	AND SC.NAME NOT LIKE (''%ACCT%'')
	AND SC.NAME NOT LIKE (''%SOC%'')
	AND SC.NAME NOT LIKE (''%TAX%'')
	AND SC.NAME NOT LIKE (''%ACCOUNT%'')
	AND SC.NAME NOT LIKE (''%ftin%'')
	--AND SC.NAME NOT LIKE (''%_pci'')
	ORDER BY ST.name
ELSE
	SELECT st.name as Table_Name,sc.name as Column_Name FROM sys.tables st
	JOIN  sys.COLUMNS sc 
	ON st.OBJECT_ID=sc.OBJECT_ID
	WHERE st.name LIKE (''%_ENC'')
	AND sc.name LIKE (''Encrypted%'')
	AND SC.NAME NOT LIKE (''%SSN%'')
	AND SC.NAME NOT LIKE (''%SOCIAL%'')
	AND SC.NAME NOT LIKE (''%bank%'')
	AND SC.NAME NOT LIKE (''%ACCT%'')
	AND SC.NAME NOT LIKE (''%SOC%'')
	AND SC.NAME NOT LIKE (''%TAX%'')
	AND SC.NAME NOT LIKE (''%ACCOUNT%'')
	AND SC.NAME NOT LIKE (''%ftin%'')
	AND SC.NAME NOT LIKE (''%_pci'')
	ORDER BY ST.name'
