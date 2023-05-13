USE [WideWorldImporters];

-- There are some queries for checking of some information about Service Broker;
/*
SELECT * FROM sys.service_contract_message_usages; 
SELECT * FROM sys.service_contract_usages;
SELECT * FROM sys.service_queue_usages;
 
SELECT * FROM sys.transmission_queue; -- If something data was lost or wasn't delivered, we'll checked this one using this query

select name, is_broker_enabled
from sys.databases;

SELECT conversation_handle, is_initiator, s.name as 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints ce
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;
*/

-- Enable Service Broker on MS SQL Server
USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;  -- NO WAIT --prod

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; -- Connect to DB without certificate

ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];

--An exception occurred while enqueueing a message in the target queue. Error: 33009, State: 2. 
--The database owner SID recorded in the master database differs from the database owner SID recorded in database 'WideWorldImporters'. 
--You should correct this situation by resetting the owner of database 'WideWorldImporters' using the ALTER AUTHORIZATION statement.

-- Create MessageTypes for Request and Response;
-- The Attitude between services is happened by XML, but you can use format JSON without validation. The validatation is setup only for XML.
USE WideWorldImporters
-- For Request
CREATE MESSAGE TYPE
[//WWI/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML; --To delete this instruction, using JSON
-- For Reply
CREATE MESSAGE TYPE
[//WWI/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 

GO

-- Create contract
CREATE CONTRACT [//WWI/SB/Contract] -- contract
      ([//WWI/SB/RequestMessage] -- Message type for initiator service
         SENT BY INITIATOR,
       [//WWI/SB/ReplyMessage] -- Message type for target service
         SENT BY TARGET
      );
GO

-- Create Target Queue
CREATE QUEUE TargetQueueWWI;
-- Create target service, which is binded to this Target queue
CREATE SERVICE [//WWI/SB/TargetService]
       ON QUEUE TargetQueueWWI
       ([//WWI/SB/Contract]); --by contract
GO

-- Create Initiator Queue
CREATE QUEUE InitiatorQueueWWI;
-- Create Initiator service, which is binded to this Initiator queue
CREATE SERVICE [//WWI/SB/InitiatorService]
       ON QUEUE InitiatorQueueWWI
       ([//WWI/SB/Contract]); -- by contract
GO