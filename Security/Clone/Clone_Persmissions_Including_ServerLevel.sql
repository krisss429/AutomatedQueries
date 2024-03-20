-----------------------------------------------------------------------------------------------------------------------------------------------
--- Scripting out the Role Memberships
-----------------------------------------------------------------------------------------------------------------------------------------------

SELECT 'ALTER SERVER ROLE [' + role.name + '] ADD MEMBER [' + member.name + ']' AS "--- Server Level Permissions ---"
FROM sys.server_role_members
    JOIN sys.server_principals AS role
        ON sys.server_role_members.role_principal_id = role.principal_id
    JOIN sys.server_principals AS member
        ON sys.server_role_members.member_principal_id = member.principal_id
WHERE member.type IN ( 'S', 'G', 'U' )
      AND member.name NOT LIKE '##%##'
      AND member.name NOT LIKE 'NT AUTHORITY%'
      AND member.name NOT LIKE 'NT SERVICE%'
      AND member.name <> ('sa');

-----------------------------------------------------------------------------------------------------------------------------------------------
--- Scripting out the Permissions
-----------------------------------------------------------------------------------------------------------------------------------------------

SELECT CASE
           WHEN SrvPerm.state_desc <> 'GRANT_WITH_GRANT_OPTION' THEN
               SrvPerm.state_desc
           ELSE
               'GRANT'
       END + ' ' + SrvPerm.permission_name + ' TO [' + SP.name + ']'
       + CASE
             WHEN SrvPerm.state_desc <> 'GRANT_WITH_GRANT_OPTION' THEN
                 ''
             ELSE
                 ' WITH GRANT OPTION'
         END COLLATE DATABASE_DEFAULT AS [---Server Level Permissions ---]
FROM sys.server_permissions AS SrvPerm
    JOIN sys.server_principals AS SP
        ON SrvPerm.grantee_principal_id = SP.principal_id
WHERE SP.type IN ( 'S', 'U', 'G' )
      AND SP.name NOT LIKE '##%##'
      AND SP.name NOT LIKE 'NT AUTHORITY%'
      AND SP.name NOT LIKE 'NT SERVICE%'
      AND SP.name <> ('sa');

-----------------------------------------------------------------------------------------------------------------------------------------------
--- Scripting out Create_User and Database roles
-----------------------------------------------------------------------------------------------------------------------------------------------

SELECT roles.name Role_Name,
       members.name Member_Name,
       --'IF EXISTS (SELECT * FROM sys.database_principals WHERE name = N''' + members.name + ''') DROP USER [' + members. name + '];' +CHAR(13)+CHAR (10) AS [Drop_User],
       'IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = N''' + members.name + ''') CREATE USER ['
       + members.name + '] FOR LOGIN [' + members.name + '] '
       + CASE
             WHEN members.default_schema_name IS NOT NULL THEN
                 'WITH DEFAULT_SCHEMA = [' + members.default_schema_name + '];'
             ELSE
                 ';'
         END + CHAR(13) + CHAR(10) AS [Create_User],
       ISNULL(
                 'EXEC sp_addrolemember @rolename = ' + QUOTENAME(USER_NAME(drm.role_principal_id), '')
                 + ', @membername = ' + QUOTENAME(USER_NAME(drm.member_principal_id), '') + ';' + CHAR(13) + CHAR(10),
                 ''
             ) AS [Grant_Permission]
FROM sys.database_principals members
    LEFT JOIN sys.database_role_members drm
        ON members.principal_id = drm.member_principal_id
    LEFT JOIN sys.database_principals roles
        ON drm.role_principal_id = roles.principal_id
WHERE 1 = 1
      AND members.name NOT IN ( 'dbo', 'sys', 'INFORMATION_SCHEMA', 'guest', 'public' )
      AND members.name NOT LIKE 'db[_]%'
ORDER BY members.name

-----------------------------------------------------------------------------------------------------------------------------------------------
--- Scripting out Permissions on Objects Keys and Certs
-----------------------------------------------------------------------------------------------------------------------------------------------

;
WITH AllAccess
AS (
   -- The best solution for explicit permissions
   SELECT perm.class_desc AS ObjectType,
          o.name ObjectName,
          perm.permission_name,
          perm.state_desc,
          prin.name Username,
          perm.state_desc + ' ' + perm.permission_name + ' on ' + o.name + ' to [' + prin.name
          + '];' COLLATE SQL_Latin1_General_CP1_CI_AS AS GrantSQL
   FROM sys.database_principals prin
       JOIN sys.database_role_members rm
           ON prin.principal_id = rm.member_principal_id
       JOIN sys.database_permissions perm
           ON rm.role_principal_id = perm.grantee_principal_id
       JOIN sys.objects o
           ON o.object_id = perm.major_id
   WHERE o.name NOT LIKE 'dt[_]%'
         AND o.name <> 'dtproperties'
   --prin. name = 'TestUser'

   UNION ALL
   SELECT perm2.class_desc,
          o2.name,
          perm2.permission_name,
          perm2.state_desc,
          prin2.name,
          perm2.state_desc + ' ' + perm2.permission_name + ' on [' + sc.name + '].[' + o2.name + '] to [' + prin2.name
          + '];' COLLATE SQL_Latin1_General_CP1_CI_AS
   FROM sys.database_principals prin2
       JOIN sys.database_permissions perm2
           ON prin2.principal_id = perm2.grantee_principal_id
       JOIN sys.objects o2
           ON o2.object_id = perm2.major_id
       JOIN sys.schemas sc
           ON sc.schema_id = o2.schema_id
   --WHERE prin2.name = 'TestUser';
   WHERE o2.name NOT LIKE 'dt[_]%'
         AND o2.name <> 'dtproperties'
   UNION ALL

   --- Database Level Permissions
   SELECT prmssn.class_desc,
          DB_NAME(),
          [permission_name],
          state_desc,
          grantee_principal.name,
          state_desc + ' ' + [permission_name] + ' TO [' + grantee_principal.name
          + ']' COLLATE SQL_Latin1_General_CP1_CI_AS
   FROM sys.database_permissions AS prmssn
       INNER JOIN sys.database_principals AS grantor_principal
           ON grantor_principal.principal_id = prmssn.grantor_principal_id
       INNER JOIN sys.database_principals AS grantee_principal
           ON grantee_principal.principal_id = prmssn.grantee_principal_id
   WHERE (prmssn.class = 0)
         AND [permission_name] <> 'CONNECT' --(grantee_principal.name='RMFCORP\bijayd')

   UNION ALL

   --- Table Types
   SELECT perm2.class_desc,
          tt.name,
          perm2.permission_name,
          perm2.state_desc,
          prin.name,
          perm2.state_desc + ' ' + perm2.permission_name + ' on TYPE::[' + sc.name + '].[' + tt.name + '] to ['
          + prin.name + '];' COLLATE SQL_Latin1_General_CP1_CI_AS
   FROM sys.objects o2
       JOIN sys.table_types AS tt
           ON tt.type_table_object_id = o2.object_id
       JOIN sys.schemas sc
           ON sc.schema_id = tt.schema_id
       INNER JOIN sys.schemas AS stt
           ON stt.schema_id = tt.schema_id
       INNER JOIN sys.database_permissions AS perm2
           ON perm2.major_id = tt.user_type_id
              AND perm2.minor_id = 0
              AND perm2.class = 6
       INNER JOIN sys.database_principals AS prin
           ON prin.principal_id = perm2.grantee_principal_id
   --order by 1

   UNION ALL

   --- Symmetric Keys & Certs
   SELECT p.class_desc AS ObjectType,
          CASE class_desc
              WHEN 'SYMMETRIC_KEYS' THEN
                  sm.name
              WHEN 'CERTIFICATE' THEN
                  [cert].name
          END AS ObjectName,
          p.permission_name,
          state_desc,
          u.name,
          state_desc + ' ' + p.permission_name + ' ON ' + CASE p.class_desc
                                                              WHEN 'SYMMETRIC_KEYS' THEN
                                                                  'SYMMETRIC KEY'
                                                              ELSE
                                                                  p.class_desc
                                                          END + ' :: ' + CASE class_desc
                                                                             WHEN 'SYMMETRIC_KEYS' THEN
                                                                                 sm.name
                                                                             WHEN 'CERTIFICATE' THEN
                                                                                 [cert].name
                                                                         END + ' TO [' + u.name
          + '];' COLLATE SQL_Latin1_General_CP1_CI_AS AS GrantSQL
   --    , ObjectNameForObjectORColumn = object_name(p.major_id) 
   FROM sys.database_permissions p
       INNER JOIN sys.database_principals u
           ON p.grantee_principal_id = u.principal_id
       LEFT OUTER JOIN sys.symmetric_keys sm
           ON p.major_id = sm.symmetric_key_id
              AND p.class_desc = 'SYMMETRIC_KEYS'
       LEFT OUTER JOIN sys.certificates [cert]
           ON p.major_id = [cert].[certificate_id]
              AND p.class_desc = 'CERTIFICATE'
   WHERE class_desc IN ( 'SYMMETRIC_KEYS', 'CERTIFICATE' ))
SELECT *
FROM AllAccess
--where Username in ()
ORDER BY 1,
         2,
         5
