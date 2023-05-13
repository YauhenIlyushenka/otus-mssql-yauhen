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

--CleanUP
--DECLARE @Conversation uniqueidentifier;

--WHILE EXISTS(SELECT 1 FROM sys.transmission_queue)
--BEGIN
--  SET @Conversation = 
--                (SELECT TOP(1) conversation_handle 
--                                FROM sys.transmission_queue);
--  END CONVERSATION @Conversation WITH CLEANUP;
--END;

--END CONVERSATION 'E4C176F1-B9F1-ED11-9DDC-E470B84B6DDC' with CLEANUP;

-- 1. The first step. Enable Service Broker on MS SQL Server
USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;  -- NO WAIT --prod

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; -- Connect to DB without certificate

ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];

--An exception occurred while enqueueing a message in the target queue. Error: 33009, State: 2. 
--The database owner SID recorded in the master database differs from the database owner SID recorded in database 'WideWorldImporters'. 
--You should correct this situation by resetting the owner of database 'WideWorldImporters' using the ALTER AUTHORIZATION statement.

-- 2. The second step. Create MessageTypes for Request and Response and Contract for attitude;
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

-- 3.The Third step. Create Target and Initial Queues and services henses.
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

-- 4.The forth step.
-- Create stored procedure, which added the message in queue;

--drop procedure Sales.CreateNewReport
CREATE PROCEDURE Sales.CreateNewReport
	@CustomerId INT,
	@StartedDate DATETIME2,
	@FinishedDate DATETIME2
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRY
	BEGIN TRANSACTION 
		-- Prepare the Message
		SELECT @RequestMessage = (
			SELECT 
				si.[CustomerID],
				COUNT(so.OrderID) AS [OrdersCount],
				@StartedDate AS StartedDate, 
				@FinishedDate AS FinishedDate
			FROM [WideWorldImporters].[Sales].[Invoices] AS si
			INNER JOIN  Sales.Orders AS so ON so.OrderID = si.OrderID
			WHERE si.CustomerID = @CustomerId AND si.InvoiceDate BETWEEN @StartedDate AND @FinishedDate
			GROUP BY si.CustomerID
			FOR XML PATH('Cusotmer'), ROOT('RequestMessage')
		); 
	
		-- Determine the Initiator Service, Target Service and the Contract 
		BEGIN DIALOG @InitDlgHandle
		FROM SERVICE
		[//WWI/SB/InitiatorService]
		TO SERVICE
		'//WWI/SB/TargetService'
		ON CONTRACT
		[//WWI/SB/Contract]
		WITH ENCRYPTION=OFF; 

		--Send the Message
		SEND ON CONVERSATION @InitDlgHandle 
		MESSAGE TYPE
		[//WWI/SB/RequestMessage]
		(@RequestMessage);
	
		--SELECT @RequestMessage AS SentRequestMessage;
	
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		DECLARE @err NVARCHAR(4000) = error_message();
		if @@trancount > 0 ROLLBACK TRAN;
		RAISERROR(@err, 16, 10);
	END CATCH
END
GO

--5. The fifth step.
-- Create activation stored procedures Sales.SaveNewReport AND Sales.ConfirmSavingReport;

--drop procedure Sales.SaveNewReport
CREATE PROCEDURE Sales.SaveNewReport
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@CusotmerID INT,
			@OrdersCount INT,
			@StartedDate DATETIME2,
			@FinishedDate DATETIME2,
			@xml XML; 
	
	BEGIN TRY
	BEGIN TRANSACTION;

		--Receive message from Initiator
		RECEIVE TOP(1)
			@TargetDlgHandle = Conversation_Handle,
			@Message = Message_Body,
			@MessageType = Message_Type_Name
		FROM dbo.TargetQueueWWI; 

		SELECT @Message;

		SET @xml = CAST(@Message AS XML);

		SELECT 
			@CusotmerID = temporaryRow.Customer.value('(CustomerID)[1]', 'INT'),
			@OrdersCount = temporaryRow.Customer.value('(OrdersCount)[1]', 'INT'),
			@StartedDate = temporaryRow.Customer.value('(StartedDate)[1]', 'DATETIME2'),
			@FinishedDate = temporaryRow.Customer.value('(FinishedDate)[1]', 'DATETIME2')
		FROM @xml.nodes('/RequestMessage/Customer') AS temporaryRow(Customer);

		BEGIN
			INSERT INTO Sales.Reports 
			(
				CustomerId,
				OrdersCount,
				StartedDate,
				FinishedDate
			)
			VALUES 
			(
				@CusotmerID,
				@OrdersCount,
				@StartedDate,
				@FinishedDate
			)
		END;
	
		--SELECT @Message AS ReceivedRequestMessage, @MessageType; 
	
		-- Confirm and Send a reply
		IF @MessageType=N'//WWI/SB/RequestMessage'
		BEGIN
			SET @ReplyMessage =N'<ReplyMessage> Message with CustomerID: ' + @CusotmerID + N' received</ReplyMessage>'; 
	
			SEND ON CONVERSATION @TargetDlgHandle
			MESSAGE TYPE
			[//WWI/SB/ReplyMessage]
			(@ReplyMessage);
			END CONVERSATION @TargetDlgHandle;
		END 
	
	--SELECT @ReplyMessage AS SentReplyMessage; 

	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		DECLARE @err NVARCHAR(4000) = error_message();
		if @@trancount > 0 ROLLBACK TRAN;
		RAISERROR(@err, 16, 10);
	END CATCH
END
GO

--drop procedure Sales.ConfirmSavingReport
CREATE PROCEDURE Sales.ConfirmSavingReport
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRY
	BEGIN TRANSACTION; 

		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueueWWI; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		--SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; 

	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		DECLARE @err NVARCHAR(4000) = error_message();
		if @@trancount > 0 ROLLBACK TRAN;
		RAISERROR(@err, 16, 10);
	END CATCH
END
GO

--6. The 6 step.
-- After setup, which we mentioned above, we always use only our Initial and Target queues.
ALTER QUEUE [dbo].[InitiatorQueueWWI] 
	WITH STATUS = ON, -- TURN ON or TURN OFF queue. If queue is turned OFF, we can't send anything to queue. (We sent message, but queue wasn't save this message)
	RETENTION = OFF,
	POISON_MESSAGE_HANDLING (STATUS = OFF), -- The separate feature (separate queue) for messages with some errors, which can't handle and execute
	ACTIVATION 
	(   
		STATUS = ON, -- turn ON or OFF Handling of messages from queue;
		PROCEDURE_NAME = Sales.ConfirmSavingReport, -- There are stored procedure activation in DB, in which is happened to handling of message which is stayed in queue;
		MAX_QUEUE_READERS = 0, -- The count of handlers for queue. It can be more then 1. (It dependents on loading)
		EXECUTE AS OWNER
	); 

GO
ALTER QUEUE [dbo].[TargetQueueWWI] 
	WITH STATUS = ON,
	RETENTION = OFF,
	POISON_MESSAGE_HANDLING (STATUS = OFF),
	ACTIVATION 
	(  
		STATUS = ON,
		PROCEDURE_NAME = Sales.SaveNewReport,
		MAX_QUEUE_READERS = 0,
		EXECUTE AS OWNER
	); 
GO

--exec Sales.CreateNewReport 
--	@CustomerId = 1,
--	@StartedDate = '2013-01-01',
--	@FinishedDate = '2016-01-01'

--SELECT CAST(message_body AS XML),*
--FROM dbo.TargetQueueWWI;

--SELECT CAST(message_body AS XML),*
--FROM dbo.InitiatorQueueWWI;

----Target
--EXEC Sales.SaveNewReport;

----Initiator
--EXEC Sales.ConfirmSavingReport;