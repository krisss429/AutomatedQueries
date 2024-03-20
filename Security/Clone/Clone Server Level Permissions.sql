SET NOCOUNT ON
DECLARE @OldUser sysname, @NewUser sysname

SET @OldUser = 'admin_tool_Q416' --The user or role from which to copy the permissions from
SET @NewUser = 'admin_tool_Q217'  --The user or role to which to copy the permissions to

SELECT 'ALTER SERVER ROLE [' + role.name + '] ADD MEMBER [' + @NewUser + ']' AS "--Server Level Permissions"
FROM sys.server_role_members  
JOIN sys.server_principals AS role  
    ON sys.server_role_members.role_principal_id = role.principal_id  
JOIN sys.server_principals AS member  
    ON sys.server_role_members.member_principal_id = member.principal_id
WHERE   member.name = @OldUser

