/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT ap.[PersonID], ap.[FullName]
FROM [Application].[People] AS ap
WHERE ap.IsSalesperson = 1 AND ap.PersonID NOT IN (
		SELECT DISTINCT si.SalespersonPersonID
		FROM [Sales].[Invoices] AS si
		GROUP BY SI.SalespersonPersonID, si.InvoiceDate
		HAVING si.InvoiceDate = '2015-07-04')

GO

-- CTE
;WITH InvoicesCTE (SalespersonPersonID) AS 
(
	SELECT DISTINCT 
		SalespersonPersonID 
	FROM [Sales].[Invoices]
	WHERE SalespersonPersonID NOT IN (
		SELECT DISTINCT si.SalespersonPersonID
			FROM [Sales].[Invoices] AS si
			GROUP BY SI.SalespersonPersonID, si.InvoiceDate
			HAVING si.InvoiceDate = '2015-07-04')
)

SELECT ap.[PersonID], ap.[FullName]
FROM [Application].[People] AS ap
JOIN InvoicesCTE AS iCTE ON ap.PersonID = iCTE.SalespersonPersonID
ORDER BY ap.[PersonID]

GO

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT
	ws.StockItemID AS Id,
	ws.StockItemName,
	ws.UnitPrice
FROM [Warehouse].[StockItems] AS ws
WHERE ws.UnitPrice = (SELECT MIN(UnitPrice) FROM [Warehouse].[StockItems])

SELECT
	ws.StockItemID AS Id,
	ws.StockItemName,
	ws.UnitPrice
FROM [Warehouse].[StockItems] AS ws
WHERE ws.UnitPrice <= ALL (SELECT UnitPrice FROM [Warehouse].[StockItems])

GO

-- CTE
;WITH MinPriceCTE (MinUnitPrice) AS 
(
	SELECT MIN(UnitPrice) FROM [Warehouse].[StockItems]
)

SELECT
	ws.StockItemID AS Id,
	ws.StockItemName,
	ws.UnitPrice
FROM [Warehouse].[StockItems] AS ws
JOIN MinPriceCTE AS mpCTE ON ws.UnitPrice = mpCTE.MinUnitPrice

GO

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT 
	sc.CustomerID,
	sc.CustomerName,
	sc.PhoneNumber
FROM [Sales].[Customers] AS sc
JOIN (
	SELECT TOP 5
		CustomerID,
		MAX(TransactionAmount) AS MaxTransactionAmount
	FROM [Sales].[CustomerTransactions]
	WHERE InvoiceID iS NOT NULL
	GROUP BY CustomerID
	ORDER BY MaxTransactionAmount DESC)
	AS tempResult
ON sc.CustomerID = tempResult.CustomerID

GO

-- CTE
;WITH CustomersByMaxTransactionAmount (CustomerID, MaxTransactionAmount) AS 
(
	SELECT TOP 5
		CustomerID,
		MAX(TransactionAmount) AS MaxTransactionAmount
	FROM [Sales].[CustomerTransactions]
	WHERE InvoiceID iS NOT NULL
	GROUP BY CustomerID
	ORDER BY MaxTransactionAmount DESC
)

SELECT 
	sc.CustomerID,
	sc.CustomerName,
	sc.PhoneNumber
FROM [Sales].[Customers] AS sc
JOIN CustomersByMaxTransactionAmount AS cmta
ON sc.CustomerID = cmta.CustomerID

GO

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

-- CTE
;WITH TopStockItems (StockItemID) AS 
(
	SELECT TOP 3 
		ws.StockItemID
	FROM [Warehouse].[StockItems] AS ws
	ORDER BY ws.UnitPrice DESC
)

SELECT DISTINCT
	ac.CityID,
	ac.CityName,
	ap.FullName AS PackedPersonFullName
FROM [Sales].[Invoices] AS si
JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
JOIN [Sales].[InvoiceLines] AS sil ON sil.InvoiceID = si.InvoiceID
JOIN [Application].[Cities] AS ac ON ac.CityID = sc.DeliveryCityID
JOIN [Application].[People] AS ap ON ap.PersonID = si.PackedByPersonID
JOIN TopStockItems AS tsi ON sil.StockItemID = tsi.StockItemID
ORDER BY ac.CityID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
