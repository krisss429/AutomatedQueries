select  @@SERVERNAME AS Server, DB_NAME() AS Database_Name,rp.name as Role ,mp.name as User_Name, mp.type_desc as Login_Type from sys.database_role_members rm
inner join sys.database_principals rp on rm.role_principal_id = rp.principal_id
inner join sys.database_principals mp on rm.member_principal_id = mp.principal_id
order by User_Name