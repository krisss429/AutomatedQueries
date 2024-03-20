set nocount on

select '
set nocount on

use '+name +';

select ''use ' + name + '; ALTER TABLE [''+TABLE_SCHEMA +''].[''+ TABLE_NAME+''] WITH CHECK CHECK CONSTRAINT [''+CONSTRAINT_NAME+ ''];''
from INFORMATION_SCHEMA .TABLE_CONSTRAINTS
where (CONSTRAINT_TYPE = ''FOREIGN KEY'' or CONSTRAINT_TYPE = ''CHECK'' )
and objectproperty (object_id ( CONSTRAINT_NAME), ''CnstIsNotTrusted'') = 1
and objectproperty (object_id ( CONSTRAINT_NAME), ''CnstIsNotRepl'') = 0
and objectproperty (object_id ( CONSTRAINT_NAME), ''CnstIsDisabled'') = 0
'
from sysdatabases
where dbid > 4
  and name not in ( 'SSISDB')
