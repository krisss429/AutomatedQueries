----Enable EKM Provider

sp_configure 'show advanced', 1
GO
RECONFIGURE
GO
sp_configure 'EKM provider enabled', 1
GO
RECONFIGURE
GO


----To create\register the Luna EKM Provider

CREATE CRYPTOGRAPHIC PROVIDER <Name of Cryptographic Provider>
FROM FILE = '<Location of Luna EKM Provider Library>'
--where CRYPTOGRAPHIC PROVIDER can be any user defined unique name.


----To view the list of EKM providers

SELECT [provider_id]
,[name]
,[guid]
,[version]
,[dll_path]
,[is_enabled]
FROM [model].[sys].[cryptographic_providers]


----To view the provider properties

SELECT [provider_id],[guid],[provider_version]
,[sqlcrypt_version]
,[friendly_name]
,[authentication_type]
,[symmetric_key_support]
,[symmetric_key_persistance]
,[symmetric_key_export]
,[symmetric_key_import]
,[asymmetric_key_support]
,[asymmetric_key_persistance]
,[asymmetric_key_export]
,[asymmetric_key_import]
FROM [master].[sys].[dm_cryptographic_provider_properties]


----To create\map the CREDENTIAL for Luna EKM Provider

CREATE CREDENTIAL <Name of credential>
WITH IDENTITY='<Name of EKM User>', SECRET='<HSM partition password>'
FOR CRYPTOGRAPHIC PROVIDER LunaEKMProvider
--Where CREDENTIAL and IDENTITY can be any user defined unique name.


----To map the LunaEKMCred with SQL User or Login:

ALTER LOGIN [Domain\Login Name]
ADD CREDENTIAL <Name of Credential created>


----To create the asymmetric key using Luna EKM Provider

CREATE ASYMMETRIC KEY SQL_EKM_RSA_2048_Key
FROM Provider LunaEKMProvider
WITH ALGORITHM = RSA_2048,
PROVIDER_KEY_NAME = 'EKM_RSA_2048_Key',
CREATION_DISPOSITION=CREATE_NEW
-----RSA_512, RSA_1024, RSA_2048


----To create a symmetric Key encrypted by an asymmetric Key on HSM

Create SYMMETRIC KEY key1
WITH ALGORITHM = AES_256
ENCRYPTION BY Asymmetric Key SQL_EKM_RSA_1024_Key;
--where SQL_EKM_RSA_1024_Key is an existing asymmetric key. Before using the key you need to open the key. Following command can be executed to open the symmetric key.
OPEN SYMMETRIC KEY key1 DECRYPTION BY Asymmetric Key SQL_EKM_RSA_1024_Key;
--Close the symmetric key by executing command
CLOSE SYMMETRIC KEY key1


---------Using Extensible Key Management on a SQL Server Failover Cluster
This section focuses on the preparation of the environment for 2-node SQL Server Cluster in Windows Server 2008 R2.
1. Refer to SQL Server documentation to install a failover cluster.
Setting up a Shared Storage
To set up a shared storage disk for SQL Server Cluster, refer to the configuration procedures that apply for your shared storage solution. Plan the size of the shared storage depending on the number of certificates that you are enrolling.
2. Once the cluster is up and running, install Luna SA client on both the nodes.
3. Configure and setup the appliance on both the nodes and register the same partition on both node of SQL Server Cluster.
4. Install Luna EKM client on both the nodes.
5. Configure the Luna EKM provider on both the nodes.
6. Open the SQL Server management studio to register the Luna EKM provider on the first node.
7. Setup the credential on the first node.
8. Now create some keys using the Luna EKM provider on the first node.
9. Create a table and encrypt some column with the Luna EKM key with the first node.
10. Shutdown the first node.
11. Now login to the second node and decrypt the data encrypted on the first node.
12. Data is decrypted successfully.
Extensible Key Management using Luna EKM is working fine on a SQL Server cluster.

----DROPPING-------

----To drop the SQL EKM provider:
--Drop the credential by executing the following commands:

ALTER LOGIN <login_name> DROP CREDENTIAL <credential_name>
DROP CREDENTIAL <credential_name>
DROP LOGIN <login_name>

--To Drop Keys 
DROP ASYMMETRIC KEY <key name in database> REMOVE PROVIDER KEY 
DROP ASYMMETRIC KEY <key name in database> --will remove asymmetric key in server but not in provider--Drop the EKM provider by executing the following commands:
DROP CRYPTOGRAPHIC PROVIDER safenetSQLEKM



