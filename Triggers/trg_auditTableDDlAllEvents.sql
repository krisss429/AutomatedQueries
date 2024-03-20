USE [DM_BILLING_PROD]
GO

/****** Object:  DdlTrigger [trg_auditTableDDlAllEvents]    Script Date: 04/11/2016 15:24:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [trg_auditTableDDlAllEvents]
 ON DATABASE for
   create_table,
   alter_table,
   drop_table,
  
   create_procedure,
   alter_procedure,
   drop_procedure,

   create_index,
   alter_index,
   drop_index,

   create_view,
   alter_view,
   drop_view,

   create_function,
   alter_function,
   drop_function,

   create_trigger,
   alter_trigger,
   drop_trigger
    
as
set ansi_warnings on
SET ARITHABORT ON
declare @eventData as XML;
set @eventData = eventdata();

declare @loginName varchar(20)
declare @msg varchar(200)

INSERT INTO DBA_Utility.dbo.tbl_auditTableDDL
(
  postTime ,    
  eventType,
  serverName ,
  databasename ,
  loginName    ,
  userName     ,
  schemaName   ,
  objectName   ,
  ObjectType ,
  code  ,
  xmlEventData
)
values
(
  @eventdata.value('(/EVENT_INSTANCE/PostTime)[1]', 'varchar(23)' ),
  @eventdata.value('(/EVENT_INSTANCE/EventType)[1]', 'varchar(100)' ),
  @eventdata.value('(/EVENT_INSTANCE/ServerName)[1]', 'varchar(100)' ),
  @eventdata.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'varchar(100)' ),
  @eventdata.value('(/EVENT_INSTANCE/LoginName)[1]', 'varchar(100)' ),
  @eventdata.value('(/EVENT_INSTANCE/UserName)[1]', 'varchar(100)' ),
  @eventdata.value('(/EVENT_INSTANCE/SchemaName)[1]', 'varchar(100)' ),
  @eventdata.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(100)' ),
  @eventdata.value('(/EVENT_INSTANCE/ObjectType)[1]', 'varchar(100)' ),
  @eventdata.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'varchar(100)' ),
  @eventdata 
  
  
)
if 
 (
    (
    @eventdata.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(100)' )
    ) = 'tbl_auditTableDDL'

    and

   (
    @eventdata.value('(/EVENT_INSTANCE/EventType)[1]', 'varchar(100)' )
   ) = 'drop_table'
)

BEGIN
 RAISERROR('NOT ALLOWED TO DROP Table',16,1);
 ROLLBACK;
 RETURN;
END

GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

DISABLE TRIGGER [trg_auditTableDDlAllEvents] ON DATABASE
GO

ENABLE TRIGGER [trg_auditTableDDlAllEvents] ON DATABASE
GO


