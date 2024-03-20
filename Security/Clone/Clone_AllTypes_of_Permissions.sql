
SET NOCOUNT ON
DECLARE @OldUser sysname, --The user or role from which to copy the permissions from
		@NewUser sysname, --The user or role to which to copy the permissions to
		@NewLoginName sysname = NULL, --When a NewLogin name is provided, create user script will also gets created
		@dbName nvarchar(128),
		@sql nvarchar(max),
		@msg nvarchar(max)

SET @OldUser = 'admin_tool_Q217' --The user or role from which to copy the permissions from
SET @NewUser = 'admin_tool_Q218'  --The user or role to which to copy the permissions to
SET @NewLoginName = 'admin_tool_Q218' --NEW LOGIN NAME

SELECT  '--CLONING PERMISSIONS FROM' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(@NewUser) + ' --SERVER_LEVEL'
	BEGIN
		SET @sql=N' 
		SELECT ''ALTER SERVER ROLE ['' + role.name + ''] ADD MEMBER ['' + @NewUser + '']'' AS "--Server_Level_Permissions"
		FROM sys.server_role_members  
		JOIN sys.server_principals AS role  
		ON sys.server_role_members.role_principal_id = role.principal_id  
		JOIN sys.server_principals AS member  
		ON sys.server_role_members.member_principal_id = member.principal_id
		WHERE   member.name = @OldUser'
		
		EXEC sp_executesql @sql, N'@OldUser sysname, @NewUser sysname', @OldUser = @OldUser, @NewUser = @NewUser
	END

SELECT @sql= N'',
@dbName = QUOTENAME(DB_NAME())

SELECT  '--CLONING PERMISSIONS FROM' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(@NewUser) + ' --DATABASE_LEVEL'

IF (NOT EXISTS(SELECT 1 FROM sys.database_principals where name = @oldUser))
    BEGIN
        SET @msg = 'Source user ' + QUOTENAME(@oldUser) + ' doesn''t exists in database ' + @dbName
        RAISERROR(@msg, 11,1)
        RETURN
    END   

	SELECT 'USE' + SPACE(1) + @dbName + CHAR(13) +  'SET XACT_ABORT ON' AS  "--Database Context"

IF (ISNULL(@NewLoginName, '') <> '')
    BEGIN       
        SET @sql = N'
		IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @newUser)
        BEGIN
            SELECT 
                ''CREATE USER '' + QUOTENAME(@NewUser) + '' FOR LOGIN ''
				 + QUOTENAME(@NewLoginName) 
				 --+ CASE WHEN ISNULL(default_schema_name, '''') <> '''' THEN '' WITH DEFAULT_SCHEMA = '' + QUOTENAME(dp.default_schema_name)
     --                   ELSE ''''
     --               END 
					AS "--Create_User_Script"
            FROM sys.database_principals dp
            INNER JOIN sys.server_principals sp ON dp.sid = sp.sid
            WHERE dp.name = @OldUser
        END'
        
		EXEC sp_executesql @sql, N'@OldUser sysname, @NewUser sysname, @NewLoginName sysname', @OldUser = @OldUser, @NewUser = @NewUser, @NewLoginName=@NewLoginName
    END

	BEGIN
		SET @sql = N'
		SELECT    CASE WHEN perm.state <> ''W'' THEN perm.state_desc ELSE ''GRANT'' END
		+ SPACE(1) + perm.permission_name + SPACE(1)
		+ SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(@NewUser) COLLATE database_default
		+ CASE WHEN perm.state <> ''W'' THEN SPACE(0) ELSE SPACE(1) + ''WITH GRANT OPTION'' END AS "--Database_Level_Permissions"
		FROM    sys.database_permissions AS perm
		INNER JOIN
		sys.database_principals AS usr
		ON perm.grantee_principal_id = usr.principal_id
		WHERE    usr.name = @OldUser
		AND    perm.major_id = 0
		ORDER BY perm.permission_name ASC, perm.state_desc ASC'
		
		EXEC sp_executesql @sql, N'@OldUser sysname, @NewUser sysname', @OldUser = @OldUser, @NewUser = @NewUser
	END
    
	BEGIN
		SET @sql = N'
		SELECT ''EXEC sp_addrolemember @rolename ='' 
			+ SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''''''') + '', @membername ='' + SPACE(1) + QUOTENAME(@NewUser, '''''''') AS "--Role_Memberships"
		FROM    sys.database_role_members AS rm
		WHERE    USER_NAME(rm.member_principal_id) = @OldUser
		ORDER BY rm.role_principal_id ASC'
		
		EXEC sp_executesql @sql, N'@OldUser sysname, @NewUser sysname', @OldUser = @OldUser, @NewUser = @NewUser
	END
	
	BEGIN
		SET @sql = N'
		SELECT    CASE WHEN perm.state <> ''W'' THEN perm.state_desc ELSE ''GRANT'' END
		+ SPACE(1) + perm.permission_name + SPACE(1) + ''ON '' + QUOTENAME(USER_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name) 
		+ CASE WHEN cl.column_id IS NULL THEN SPACE(0) ELSE ''('' + QUOTENAME(cl.name) + '')'' END
		+ SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(@NewUser) COLLATE database_default
		+ CASE WHEN perm.state <> ''W'' THEN SPACE(0) ELSE SPACE(1) + ''WITH GRANT OPTION'' END AS "--Object_Level_Permissions"
		FROM    sys.database_permissions AS perm
		INNER JOIN
		sys.objects AS obj
		ON perm.major_id = obj.[object_id]
		INNER JOIN
		sys.database_principals AS usr
		ON perm.grantee_principal_id = usr.principal_id
		LEFT JOIN
		sys.columns AS cl
		ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id
		WHERE    usr.name = @OldUser
		ORDER BY perm.permission_name ASC, perm.state_desc ASC'
		
		EXEC sp_executesql @sql, N'@OldUser sysname, @NewUser sysname', @OldUser = @OldUser, @NewUser = @NewUser
	END

	BEGIN
		SET @sql = N'
		SELECT 
		''GRANT '' + p.permission_name + '' ON '' + 
		case 
			when p.class_desc = ''SYMMETRIC_KEYS'' then ''SYMMETRIC KEY''
			when p.class_desc = ''CERTIFICATE'' then ''CERTIFICATE''
		end 
		+ ''::''
		--object_name(p.major_id) ObjectName, state_desc, k.name , p.major_id, c.name,
		+ case 
			when p.class_desc = ''SYMMETRIC_KEYS'' then k.name
			when p.class_desc = ''CERTIFICATE'' then c.name
		end 
		+ '' TO '' 
		+ QUOTENAME(@NewUser) COLLATE database_default  as ''--Permission_On_Keys_Certificates''
		from sys.database_permissions  p 
		join sys.database_principals u
		on p.grantee_principal_id = u.principal_id
		left join sys.symmetric_keys k
		on p.major_id = k.symmetric_key_id and p.class_desc = ''SYMMETRIC_KEYS''
		left join sys.certificates c
		on p.major_id = c.certificate_id and p.class_desc = ''CERTIFICATE''
		where class_desc in (''SYMMETRIC_KEYS'',''CERTIFICATE'')
		and u.name = @OldUser
		order by u.NAME'
        
		EXEC sp_executesql @sql, N'@OldUser sysname, @NewUser sysname', @OldUser = @OldUser, @NewUser = @NewUser
	END
