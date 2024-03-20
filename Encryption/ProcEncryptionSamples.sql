
CREATE DATABASE JATestDB
go

/***  Steps to turn on encryption in a database  ***/
USE JATestDB ;
--Step 1: create a Database Master Key
--The master key must be created within the database containing encrypted data
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$"HT&K?qFwX#&M5"[IqJb%^#=B:4Sn' ;
GO

--Step 2: create a Certificate
CREATE CERTIFICATE PIICert 
	WITH SUBJECT = 'Certificate for PII data' ;
GO

--Step 3: create Symmetric Key and protect it with the Certificate
CREATE SYMMETRIC KEY PIISymKey --DATABASE ENCRYPTION KEY WITH
	WITH ALGORITHM = AES_256 
	ENCRYPTION BY CERTIFICATE PIICert ;
GO

--Step 4: create a user for the certificate
--		  this will allow for code signing
create user PIICertUser for certificate PIICert
go

--Step 5: grant the user access to the symmetric key
grant view definition
on symmetric key :: PIISymKey
to PIICertUser
go

--Step 6: grant the user access to the certificate
grant control
on certificate :: PIICert
to PIICertUser
go

----------------------------------------------------------------------------------------------

use JATestDB
go

create table PIIData(
	col1 int identity (1,1),
	col2 varchar(50),
	col3 varbinary(1000))
go


/***  Steps to create and sign stored procedure for inserting encrypted data  ***/
--Step 1: create procedure
create proc dbo.p_InsertEncryptedData
	@data  varchar(50)
as
	
	--Step 1: open symmetric key using certificate
	--must open symmetric key before inserting data or else data does not get inserted
	--opening of key is session based
	open symmetric key PIISymKey
	decryption by certificate PIICert

	--Step 2: insert data, specifying which symmetric key to use during encryption
	insert into PIIData (col2, col3)
	select
		'something secret next door',
		ENCRYPTBYKEY(key_guid('PIISymKey'),@data)

	--Step 3: close symmetric key
	close symmetric key PIISymKey
go

--Step 2: add signature using certificate
--        altering object drops signature, therefore must be recreated
ADD SIGNATURE TO dbo.p_InsertEncryptedData 
    BY CERTIFICATE PIICert;
GO

--Step 3: grant permissions to execute proc
grant execute on p_InsertEncryptedData to JAtestuser
go


/***  Steps to create and sign function/stored prcedure to decrypt data  ***/
--Step 1: create function that contains decrypt code
create function dbo.f_PIIDecrypt (@EncryptedData varbinary(1000))
returns varchar(50)
as
	begin
		return convert( VARCHAR(50), decryptbykeyautocert(cert_id('PIICert'),null,@EncryptedData ))
	END
go


--Step 2: sign function using certificate
--		  this allows procs/users to decrypt data without having decrypt permissions
add signature to dbo.f_PIIDecrypt
    by certificate PIICert;
GO


--Step 3: create proc to decrypt data
--		  users have access to proc, proc then calls function to decrypt
--		  users do not need permissions to function or encryption keys
create proc dbo.p_DecryptData
as

	--Step 1: select data, auto-decrypt using certificate called by function
	select 
		col1,
		col2,
		col3,
		dbo.f_PIIDecrypt(col3)
	from dbo.PIIData
go


--Step 4: grant permissions to execute proc
grant execute on p_DecryptData to JATestUser
go


execute as user = 'JAtestuser'
exec p_InsertEncryptedData '1234123412341234'
revert

execute as user = 'JAtestuser'
exec p_DecryptData
revert

execute as user = 'JAtestuser'
	select dbo.f_PIIDecrypt(0x00F5CF2C537A4047A86A9C72C7329955010000000060F49384C67E55F853ACE64CCB3700D9E0C1133A0AF4C426BB0D9F7CA4B853F551430D5A639743C280F9CA230D8698)
	revert
	
select col1, col2, col3, dbo.f_PIIDecrypt(col3) from PIIdata
go

----------------------------------------------------------------------------------------------

--/***  Steps to backup keys  ***/
--USE JATestDB ;
--GO
--BACKUP SERVICE MASTER KEY TO FILE = 'd:\DBA\Encryption\Backup\SQL08DEV1_ServiceMasterKey.dat'
--ENCRYPTION BY PASSWORD = '+Z-&?Ta6J<T-HJyK{f#u*Z58Z]Xc77'

--BACKUP MASTER KEY TO FILE = 'd:\DBA\Encryption\Backup\JATestDB_DatabaseMasterKey.dat'
--ENCRYPTION BY PASSWORD = 'GvESa>uu&$Bv0k4%xH^:gpcIgv*kiI'

--BACKUP CERTIFICATE PIICert TO FILE = 'd:\DBA\Encryption\Backup\JATestDB_Certificate.dat'
--WITH PRIVATE KEY (FILE = 'd:\DBA\Encryption\Backup\JATestDB_PrivateKey.dat',
--ENCRYPTION BY PASSWORD = ';gryi%fPi;`9nBEO@b3KNW5m9A}{Pu' ) ;
--GO


--/***  Steps to take after restoring to another server  ***/
----Note: only needed if data needs to be decrypted on destination server
----      without having to enter password everytime
--use JATestDB
--GO
----Step 1: on destination server, open Database Master Key using original password
----from when key was created
--OPEN MASTER KEY DECRYPTION BY PASSWORD = '$"HT&K?qFwX#&M5"[IqJb%^#=B:4Sn' ;

----Step 2: regenerate the Database Master Key using either the same original password
----or a new password
--ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = '$"HT&K?qFwX#&M5"[IqJb%^#=B:4Sn';
--GO