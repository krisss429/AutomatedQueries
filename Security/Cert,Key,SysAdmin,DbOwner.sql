/*------------------------SYS_ADMINS------------------------*/

SELECT name AS User_Name FROM sys.syslogins WHERE sysadmin =1
AND name NOT LIKE ('%NT Service%')
ORDER BY name


/*------------------------DB_OWNERS------------------------*/

SELECT
    DB_NAME() Database_Name,USER_NAME(sm.memberuid) AS User_Name, USER_NAME(sm.groupuid) AS Permission_Name
FROM
    sys.sysmembers sm
	JOIN sys.server_principals sp
ON USER_NAME(sm.memberuid)=sp.name
WHERE
    USER_NAME(sm.groupuid) IN ('db_owner')
AND sp.is_disabled <> 1


/*------------------------CERT_PERMISSIONS------------------------*/

SELECT  DB_NAME() Database_Name,u.name  AS User_Name ,
        p.Permission_Name ,-- p.class_desc, 
		--object_name(p.major_id) ObjectName, state_desc, k.name , p.major_id, c.name,
        CASE 
			--WHEN p.class_desc = 'SYMMETRIC_KEYS' THEN k.name
             WHEN p.class_desc = 'CERTIFICATE' THEN c.name
        END AS Cerificate_Name
FROM    sys.database_permissions p
        JOIN sys.database_principals u ON p.grantee_principal_id = u.principal_id
		JOIN sys.server_principals sp ON sp.name=u.name
        --LEFT JOIN sys.symmetric_keys k ON p.major_id = k.symmetric_key_id
        --                                  AND p.class_desc = 'SYMMETRIC_KEYS'
        LEFT JOIN sys.certificates c ON p.major_id = c.certificate_id
                                        AND p.class_desc = 'CERTIFICATE'
WHERE   class_desc IN 
--( 'SYMMETRIC_KEYS')--, 
('CERTIFICATE' )
AND sp.is_disabled <> 1
ORDER BY u.name;


/*------------------------KEY_PERMISSIONS------------------------*/

SELECT  DB_NAME() Database_Name,u.name AS User_Name ,
        p.Permission_Name ,-- p.class_desc, 
		--object_name(p.major_id) ObjectName, state_desc, k.name , p.major_id, c.name,
        CASE WHEN p.class_desc = 'SYMMETRIC_KEYS' THEN k.name
             --WHEN p.class_desc = 'CERTIFICATE' THEN c.name
        END AS Key_Name
FROM    sys.database_permissions p
        JOIN sys.database_principals u ON p.grantee_principal_id = u.principal_id
		JOIN sys.server_principals sp ON sp.name=u.name
        LEFT JOIN sys.symmetric_keys k ON p.major_id = k.symmetric_key_id
                                          AND p.class_desc = 'SYMMETRIC_KEYS'
        --LEFT JOIN sys.certificates c ON p.major_id = c.certificate_id
        --                                AND p.class_desc = 'CERTIFICATE'
WHERE   class_desc IN ( 'SYMMETRIC_KEYS')
--, 'CERTIFICATE' )
AND sp.is_disabled <> 1
ORDER BY u.name;













