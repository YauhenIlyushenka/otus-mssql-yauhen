USE [WideWorldImporters];

-- There are some queries for checking of some information about Service Broker
/*
SELECT * FROM sys.service_contract_message_usages; 
SELECT * FROM sys.service_contract_usages;
SELECT * FROM sys.service_queue_usages;
 
SELECT * FROM sys.transmission_queue; -- If something data was lost or wasn't delivered, we'll checked this one using this query

select name, is_broker_enabled
from sys.databases;
*/