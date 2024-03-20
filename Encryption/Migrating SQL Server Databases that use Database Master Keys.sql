----Firstly verify whether there are any Database Master Keys encrypted by the Service Master Key
select name
from sys.databases
where is_master_key_encrypted_by_server = 1

----(Optional) If you don’t know a valid password for the Database Master Key you can create a new one. (Remember that multiple passwords can encrypt the DMK)
use <database>
go
alter master key 
add encryption by password = 'migration_password'
go

----Drop the encryption by the Service Master Key
use <database>
go
alter master key drop encryption by service master key
go

----Migrate the database using either backup and restore, or detach and attach.

----Open the Database Master Key with a password (this could be the password created at step 2) and re-activate the encryption by Service Master Key – this will be mapped to the SMK on the new SQL instance:

use <database>
go
open master key decryption by password = '<Password>'
alter master key add encryption by service master key
go

----(Optional) If you created a password specifically for the migration in step 2, then you should drop it:

use <database>
go
alter master key 
drop encryption by password = 'migration_password'
go

---Update Admin Tool web-page config


----SET ANSI PADDING to TRUE