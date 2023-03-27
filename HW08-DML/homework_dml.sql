/*
Задания выполняются с использованием базы данных WideWorldImporters.
Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak
Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

-- Create table for new adding Customers
GO

SELECT CustomerID INTO [Sales].[NewCustomers]
FROM [Sales].[Customers]
WHERE 1 = 2

GO

--SELECT * FROM [Sales].[NewCustomers]

GO
INSERT INTO [Sales].[Customers]
(
	[CustomerID],
	[CustomerName],
    [BillToCustomerID],
    [CustomerCategoryID],
    [BuyingGroupID],
    [PrimaryContactPersonID],
    [AlternateContactPersonID],
    [DeliveryMethodID],
    [DeliveryCityID],
    [PostalCityID],
    [CreditLimit],
    [AccountOpenedDate],
    [StandardDiscountPercentage],
    [IsStatementSent],
    [IsOnCreditHold],
    [PaymentDays],
    [PhoneNumber],
    [FaxNumber],
    [DeliveryRun],
    [RunPosition],
    [WebsiteURL],
    [DeliveryAddressLine1],
    [DeliveryAddressLine2],
    [DeliveryPostalCode],
    [DeliveryLocation],
    [PostalAddressLine1],
    [PostalAddressLine2],
    [PostalPostalCode],
    [LastEditedBy]
)
	OUTPUT inserted.CustomerID INTO [Sales].[NewCustomers] (CustomerID)
VALUES
(NEXT VALUE FOR Sequences.CustomerID, 'Yauhen', 1, 3, 1, 1001, 1002, 3, 19586, 19586, NULL, '2023-03-27', 0.000, 0, 0, 7, '(308) 937-9992', '(308) 937-9992', NULL, NULL, 'http://www.DLM.com', 'Shop 38', '1877 Mittal Road', '90410', NULL, 'PO Box 8975', 'Ribeiroville', '90410', 1),
(NEXT VALUE FOR Sequences.CustomerID, 'Vitalik', 1, 3, 1, 1001, 1002, 3, 19586, 19586, NULL, '2023-03-27', 0.000, 0, 0, 7, '(308) 937-9992', '(308) 937-9992', NULL, NULL, 'http://www.DLM.com', 'Shop 38', '1877 Mittal Road', '90410', NULL, 'PO Box 8975', 'Ribeiroville', '90410', 1),
(NEXT VALUE FOR Sequences.CustomerID, 'Inessa', 1, 3, 1, 1001, 1002, 3, 19586, 19586, NULL, '2023-03-27', 0.000, 0, 0, 7, '(308) 937-9992', '(308) 937-9992', NULL, NULL, 'http://www.DLM.com', 'Shop 38', '1877 Mittal Road', '90410', NULL, 'PO Box 8975', 'Ribeiroville', '90410', 1),
(NEXT VALUE FOR Sequences.CustomerID, 'Anastasiya', 1, 3, 1, 1001, 1002, 3, 19586, 19586, NULL, '2023-03-27', 0.000, 0, 0, 7, '(308) 937-9992', '(308) 937-9992', NULL, NULL, 'http://www.DLM.com', 'Shop 38', '1877 Mittal Road', '90410', NULL, 'PO Box 8975', 'Ribeiroville', '90410', 1),
(NEXT VALUE FOR Sequences.CustomerID, 'Alexandr', 1, 3, 1, 1001, 1002, 3, 19586, 19586, NULL, '2023-03-27', 0.000, 0, 0, 7, '(308) 937-9992', '(308) 937-9992', NULL, NULL, 'http://www.DLM.com', 'Shop 38', '1877 Mittal Road', '90410', NULL, 'PO Box 8975', 'Ribeiroville', '90410', 1)

GO

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

GO
DECLARE 
	@MaxNewCustomerId AS INT;
SET @MaxNewCustomerId = (SELECT MAX(CustomerID) FROM [Sales].[NewCustomers])

;WITH 
	MaxNewCustomerIdCTE (MaxCustomerId) AS 
	(
		SELECT 
			MAX(CustomerID)
		FROM [Sales].[NewCustomers] as sc
	)

DELETE FROM sc
FROM [Sales].[Customers] AS sc
JOIN MaxNewCustomerIdCTE AS scn ON sc.CustomerID = scn.MaxCustomerId
WHERE sc.CustomerID = scn.MaxCustomerId

--SELECT @MaxNewCustomerId AS MaxNewCustomerId;

DELETE FROM [Sales].[NewCustomers] 
WHERE CustomerID = @MaxNewCustomerId

GO


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

GO
DECLARE 
	@MaxNewCustomerId AS INT;
SET @MaxNewCustomerId = (SELECT MAX(CustomerID) FROM [Sales].[NewCustomers])

UPDATE [Sales].[Customers]
SET AccountOpenedDate = '2023-03-29',
	DeliveryCityID = 31564,
	PostalCityID = 31564
WHERE CustomerID = @MaxNewCustomerId

GO

/*
4. Написать MERGE, который вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

напишите здесь свое решение

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

напишите здесь свое решение
