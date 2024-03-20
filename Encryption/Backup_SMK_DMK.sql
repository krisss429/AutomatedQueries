-- Creates a backup of the service master key.
USE master;
GO
BACKUP SERVICE MASTER KEY TO FILE = 'c:\temp_backups\keys\service_master_ key'
    ENCRYPTION BY PASSWORD = '3dH85Hhk003GHk2597gheij4';
GO

-- Creates a backup of the Database Master Key. Because this master key is not encrypted by the service master key, a password must be specified when it is opened.  
USE ISO_Prod;   
GO  
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'j66hNe?Pd_JmSRXk_&ecxX^kS*LM9ya7';   

BACKUP MASTER KEY TO FILE = 'D:\EncryptionKeys_Backups\DMK\ISO_Prod_DMK_Backup_03052018'   
    ENCRYPTION BY PASSWORD = 'D&UeS%jMa8f9e4mWcuq_4Nrf?7bbbAyp';   
GO  

-- Restores the service master key from a backup file.  
RESTORE SERVICE MASTER KEY   
    FROM FILE = 'c:\temp_backups\keys\service_master_key'   
    DECRYPTION BY PASSWORD = '3dH85Hhk003GHk2597gheij4';  
GO  

-- Restores the database master key of the AdventureWorks2012 database.  
USE AdventureWorks2012;  
GO  
RESTORE MASTER KEY   
    FROM FILE = 'c:\backups\keys\AdventureWorks2012_master_key'   
    DECRYPTION BY PASSWORD = '3dH85Hhk003#GHkf02597gheij04'   
    ENCRYPTION BY PASSWORD = '259087M#MyjkFkjhywiyedfgGDFD';  
GO  
