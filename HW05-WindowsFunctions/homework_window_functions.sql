/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

GO

SET STATISTICS IO ON
SET STATISTICS TIME ON 
GO

;WITH MainTempResult (InvoiceID, CustomerName, InvoiceDate, SumAmountPerInvoice) AS 
(
	SELECT 
		si.InvoiceID,
		(SELECT 
			CustomerName 
		FROM [Sales].[Customers]
		WHERE [Sales].[Customers].CustomerID = si.CustomerID) AS CustomerName,
		si.InvoiceDate,
		SUM(sil.Quantity * sil.UnitPrice) AS SumAmountPerInvoice
	FROM [Sales].[Invoices] AS si
	JOIN [Sales].[InvoiceLines] AS sil ON sil.InvoiceID = si.InvoiceID
	JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
	WHERE YEAR(si.InvoiceDate) = 2015
	GROUP BY si.InvoiceID, si.CustomerID, si.InvoiceDate
)

SELECT 
	mtp.InvoiceID,
	mtp.InvoiceDate,
	mtp.CustomerName,
	mtp.SumAmountPerInvoice,
	(SELECT 
		SUM(mtp1.SumAmountPerInvoice) 
	 FROM MainTempResult AS mtp1
	 WHERE MONTH(mtp.InvoiceDate) >= MONTH(mtp1.InvoiceDate)) AS SumUp
FROM MainTempResult AS mtp
ORDER BY mtp.InvoiceDate, mtp.InvoiceID

GO

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

/*
SQL Server Execution Times:
CPU time = 52937 ms,  elapsed time = 71422 ms.
*/

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

GO

SET STATISTICS IO ON
SET STATISTICS TIME ON 
GO

;WITH MainTempResult (InvoiceID, CustomerName, InvoiceDate, SumAmountPerInvoice) AS 
(
	SELECT 
		si.InvoiceID,
		(SELECT 
			CustomerName 
		FROM [Sales].[Customers]
		WHERE [Sales].[Customers].CustomerID = si.CustomerID) AS CustomerName,
		si.InvoiceDate,
		SUM(sil.Quantity * sil.UnitPrice) AS SumAmountPerInvoice
	FROM [Sales].[Invoices] AS si
	JOIN [Sales].[InvoiceLines] AS sil ON sil.InvoiceID = si.InvoiceID
	JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
	WHERE YEAR(si.InvoiceDate) = 2015
	GROUP BY si.InvoiceID, si.CustomerID, si.InvoiceDate
)

SELECT 
	mtp.InvoiceID,
	mtp.InvoiceDate,
	mtp.CustomerName,
	mtp.SumAmountPerInvoice,
	SUM(mtp.SumAmountPerInvoice) OVER(ORDER BY MONTH(mtp.InvoiceDate) RANGE UNBOUNDED PRECEDING) AS SumUp
FROM MainTempResult AS mtp
ORDER BY mtp.InvoiceDate, mtp.InvoiceID

GO

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

/*
SQL Server Execution Times:
CPU time = 78 ms,  elapsed time = 360 ms.

To sum up, the second query (with window function) was completed faster then the first one.
*/

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

GO

;WITH MainPopularItems (StockItemID, [Month], SumQuantity, Popularity) AS
(
	SELECT
		sil.StockItemID,
		MONTH(si.InvoiceDate) AS [Month],
		SUM(sil.Quantity) AS SumQuantity,
		ROW_NUMBER() OVER (PARTITION BY MONTH(si.InvoiceDate) ORDER BY MONTH(si.InvoiceDate)) AS Popularity
	FROM [Sales].[Invoices] AS si
	JOIN [Sales].[InvoiceLines] AS sil ON sil.InvoiceID = si.InvoiceID
	JOIN [Warehouse].[StockItems] AS wsi ON sil.StockItemID = wsi.StockItemID
	WHERE YEAR(si.InvoiceDate) = 2016
	GROUP BY sil.StockItemID, MONTH(si.InvoiceDate)
)

SELECT
	mpi.StockItemID,
	mpi.Month,
	mpi.SumQuantity,
	mpi.Popularity
FROM MainPopularItems AS mpi
WHERE mpi.Popularity <= 2
ORDER BY mpi.Month, mpi.SumQuantity DESC

GO

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

GO

SELECT 
	wsi.StockItemID,
	wsi.StockItemName,
	wsi.Brand,
	wsi.UnitPrice,
	ROW_NUMBER() OVER (PARTITION BY LEFT(wsi.StockItemName,1) ORDER BY wsi.StockItemName) AS RowNumber,
	COUNT(*) OVER() AS StockItemCount,
	COUNT(*) OVER (PARTITION BY LEFT(wsi.StockItemName,1)) AS StockItemCountPerFirstLetter,
	LEAD(wsi.StockItemID) OVER(ORDER BY wsi.StockItemName) AS LeadStockItemId,
	LAG(wsi.StockItemID) OVER(ORDER BY wsi.StockItemName) AS LagStockItemId,
	LAG(wsi.StockItemName, 2, 'No items') OVER(ORDER BY wsi.StockItemName) AS LagStockItemNameScipingTwoRecords,
	NTILE(30) OVER (ORDER BY wsi.TypicalWeightPerUnit) AS GroupNumber
FROM [Warehouse].[StockItems] AS wsi
GROUP BY wsi.StockItemName, wsi.StockItemID, wsi.Brand, wsi.UnitPrice, wsi.TypicalWeightPerUnit
ORDER BY wsi.StockItemName

GO

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

GO

;WITH SalesPersonInformationCTE(SalesPersonID, salesFullName) AS
	(
		SELECT 
			ap.PersonID,
			ap.FullName 
		FROM [Application].[People] AS ap
	),

	CustomerInformationCTE(CustomerID, CustomerName) AS
	(
		SELECT 
			sc.CustomerID,
			sc.CustomerName
		FROM [Sales].[Customers] AS sc
	),

	ResultCustomersAndSalesInformationCTE (SalespersonPersonID, SalesPersonFullName, CustomerID, CustomerName, InvoiceDate, TransactionAmount, RowNumber) AS
	(
		SELECT
			si.SalespersonPersonID,
			(SELECT 
				spiCTE.salesFullName 
			FROM SalesPersonInformationCTE AS spiCTE 
			WHERE spiCTE.SalesPersonID = si.SalespersonPersonID) AS SalesPersonFullName,
			si.CustomerID,
			(SELECT 
				ciCTE.CustomerName 
			FROM CustomerInformationCTE AS ciCTE 
			WHERE ciCTE.CustomerID = si.CustomerID) AS CustomerName,
			si.InvoiceDate,
			sct.TransactionAmount,
			ROW_NUMBER() OVER (PARTITION BY si.SalespersonPersonID ORDER BY si.InvoiceDate DESC, si.InvoiceID DESC) AS RowNumber
		FROM [Sales].[Invoices] AS si
		JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
		JOIN [Application].[People] AS ap ON ap.PersonID = si.SalespersonPersonID
		JOIN [Sales].[CustomerTransactions] AS sct ON sct.InvoiceID = si.InvoiceID AND sct.CustomerID = si.CustomerID
		GROUP BY si.InvoiceID, si.InvoiceDate, si.SalespersonPersonID, si.CustomerID, sct.TransactionAmount
	)

SELECT 
	rcsi.SalespersonPersonID,
	rcsi.SalesPersonFullName,
	rcsi.CustomerID,
	rcsi.CustomerName,
	rcsi.InvoiceDate,
	rcsi.TransactionAmount
FROM ResultCustomersAndSalesInformationCTE AS rcsi
WHERE rcsi.RowNumber = 1

GO

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
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
	StockItemAndClientInformationCTE (CustomerID, CustomerName, StockItemID, UnitPrice, InvoiceDate, Helper) AS 
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
	TwoMainExpensiveItemsPerCustomersCTE(CustomerID, CustomerName, StockItemID, UnitPrice, InvoiceDate, Helper, FirstInvoiceDatePerCustomer, LastInvoiceDatePerCustomer ) AS
	(
		SELECT
			TempResult.CustomerID,
			TempResult.CustomerName,
			TempResult.StockItemID,
			TempResult.UnitPrice,
			TempResult.InvoiceDate,
			TempResult.Helper,
			FIRST_VALUE(TempResult.InvoiceDate) OVER (PARTITION BY TempResult.CustomerID,TempResult.Helper ORDER BY TempResult.CustomerID) AS FirstInvoiceDatePerCustomer,
			LAST_VALUE(TempResult.InvoiceDate) OVER (PARTITION BY TempResult.CustomerID, TempResult.Helper ORDER BY TempResult.CustomerID) AS LastInvoiceDatePerCustomer
		FROM (
				SELECT
					siciCTE.CustomerID,
					siciCTE.CustomerName,
					siciCTE.StockItemID,
					siciCTE.UnitPrice,
					siciCTE.InvoiceDate,
					siciCTE.Helper
				FROM StockItemAndClientInformationCTE AS siciCTE
				WHERE siciCTE.Helper <= 2) AS TempResult
	)

SELECT
	tmeipcCTE.CustomerID,
	tmeipcCTE.CustomerName,
	tmeipcCTE.StockItemID,
	tmeipcCTE.UnitPrice,
	tmeipcCTE.InvoiceDate
FROM TwoMainExpensiveItemsPerCustomersCTE AS tmeipcCTE
WHERE (tmeipcCTE.Helper = 1 AND tmeipcCTE.InvoiceDate = tmeipcCTE.FirstInvoiceDatePerCustomer)
OR (tmeipcCTE.Helper = 2 AND tmeipcCTE.InvoiceDate = tmeipcCTE.LastInvoiceDatePerCustomer)

GO

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 