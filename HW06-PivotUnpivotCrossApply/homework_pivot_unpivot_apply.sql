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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.
Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.
Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT| Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2       |     2
01.02.2013   |      7             |        3           |      4      |      2       |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
GO

;WITH 
	InvoicesByCustomersDataCTE AS 
	(
		SELECT
			si.InvoiceID,
			FORMAT (DATEADD(MONTH, DATEDIFF(month, 0, si.InvoiceDate), 0), 'dd.MM.yyyy') AS InvoiceMonth,
			SUBSTRING(
				sc.CustomerName,
				CHARINDEX('(', sc.CustomerName) + 1,
				CHARINDEX(')', sc.CustomerName) - CHARINDEX('(', sc.CustomerName) - 1) AS ClarifyCustomerName
		FROM [Sales].[Invoices] AS si
		JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
		WHERE si.CustomerID BETWEEN 2 AND 6
	)

SELECT 
	pvt.InvoiceMonth,
	pvt.[Sylvanite, MT],
	pvt.[Peeples Valley, AZ],
	pvt.[Medicine Lodge, KS],
	pvt.[Gasport, NY],
	pvt.[Jessie, ND]
FROM InvoicesByCustomersDataCTE AS ibcCTE
PIVOT(
	COUNT(ibcCTE.InvoiceID) FOR ibcCTE.ClarifyCustomerName
	IN(
		[Sylvanite, MT], 
		[Peeples Valley, AZ], 
		[Medicine Lodge, KS], 
		[Gasport, NY],
		[Jessie, ND])
	) AS pvt
ORDER BY YEAR(pvt.InvoiceMonth), MONTH(pvt.InvoiceMonth)

GO

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.
Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

GO

;WITH 
	CustomerInformationCTE AS 
	(
		SELECT
			sc.CustomerName,
			sc.DeliveryAddressLine1,
			sc.DeliveryAddressLine2,
			sc.PostalAddressLine1,
			sc.PostalAddressLine2
		FROM [Sales].[Customers] AS sc
		WHERE sc.CustomerName LIKE '%Tailspin Toys%'
	)

SELECT 
	sumUpTable.CustomerName,
	sumUpTable.AddressLine
FROM CustomerInformationCTE AS ciCTE
UNPIVOT (
	AddressLine FOR TypeOfAddresses 
	IN (
		ciCTE.DeliveryAddressLine1,
		ciCTE.DeliveryAddressLine2,
		ciCTE.PostalAddressLine1,
		ciCTE.PostalAddressLine2)
	) AS sumUpTable

GO

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.
Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/
GO

;WITH 
	CountryInformationCTE AS 
	(
		SELECT 
			ac.CountryID,
			ac.CountryName,
			ac.IsoAlpha3Code,
			CONVERT(nvarchar(3), ac.IsoNumericCode) AS IsoNumericCode
		FROM [Application].[Countries] AS ac
	)

SELECT 
	sumUpTable.CountryID,
	sumUpTable.CountryName,
	sumUpTable.Code
FROM CountryInformationCTE AS ciCTE
UNPIVOT (
	Code FOR TypesOfCodes 
	IN (
		ciCTE.IsoAlpha3Code,
		ciCTE.IsoNumericCode)
	) AS sumUpTable

GO

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
	
GO

;WITH 
	CustomerInformationCTE(CustomerID, CustomerName) AS
	(
		SELECT 
			sc.CustomerID,
			sc.CustomerName
		FROM [Sales].[Customers] AS sc
	),
	StockItemAndClientInformationWithInvoiceDateCTE (CustomerID, CustomerName, StockItemID, UnitPrice, InvoiceDate, Helper) AS 
	(
		SELECT 
			si.CustomerID,
			(SELECT
				ciCTE.CustomerName 
			FROM CustomerInformationCTE AS ciCTE 
			WHERE ciCTE.CustomerID = si.CustomerID) AS CustomerName,
			wsi.StockItemID,
			wsi.UnitPrice,
			si.InvoiceDate,
			DENSE_RANK() OVER (PARTITION BY si.CustomerID ORDER BY wsi.UnitPrice DESC) AS Helper
		FROM [Sales].[Invoices] AS si
		JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
		JOIN [Sales].[InvoiceLines] AS sil ON sil.InvoiceID = si.InvoiceID
		JOIN [Warehouse].[StockItems] AS wsi ON sil.StockItemID = wsi.StockItemID
		JOIN [Sales].[CustomerTransactions] AS sct ON sct.InvoiceID = si.InvoiceID AND sct.CustomerID = si.CustomerID
		GROUP BY si.CustomerID, wsi.StockItemID, wsi.UnitPrice, si.InvoiceDate
	),
	StockItemAndClientInformationDataCTE (CustomerID, CustomerName, StockItemID, UnitPrice, Helper) as 
	( 
		SELECT 
		* 
		FROM (
			SELECT 
				si.CustomerID,
				(SELECT
					ciCTE.CustomerName 
				FROM CustomerInformationCTE AS ciCTE 
				WHERE ciCTE.CustomerID = si.CustomerID) AS CustomerName,
				wsi.StockItemID,
				wsi.UnitPrice,
				DENSE_RANK() OVER (PARTITION BY si.CustomerID ORDER BY wsi.UnitPrice DESC, wsi.StockItemID DESC) AS Helper
			FROM [Sales].[Invoices] AS si
			JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
			JOIN [Sales].[InvoiceLines] AS sil ON sil.InvoiceID = si.InvoiceID
			JOIN [Warehouse].[StockItems] AS wsi ON sil.StockItemID = wsi.StockItemID
			JOIN [Sales].[CustomerTransactions] AS sct ON sct.InvoiceID = si.InvoiceID AND sct.CustomerID = si.CustomerID
			GROUP BY si.CustomerID, wsi.StockItemID, wsi.UnitPrice ) as temp
		WHERE temp.Helper <= 2
	)

SELECT 
	infExludingInvoiceDateCTE.CustomerID,
	infExludingInvoiceDateCTE.CustomerName,
	infExludingInvoiceDateCTE.StockItemID,
	infExludingInvoiceDateCTE.UnitPrice,
	tempData.InvoiceDate
FROM StockItemAndClientInformationDataCTE AS infExludingInvoiceDateCTE
CROSS APPLY (SELECT TOP 1 *
				FROM StockItemAndClientInformationWithInvoiceDateCTE AS siciCTE
				WHERE siciCTE.Helper <= 2
				AND siciCTE.Helper = infExludingInvoiceDateCTE.Helper 
				AND siciCTE.CustomerID = infExludingInvoiceDateCTE.CustomerID ) AS tempData

GO
