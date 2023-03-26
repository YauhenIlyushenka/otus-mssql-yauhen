/*
Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.
Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.
Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

GO

-- Variables;
DECLARE @dynamicSqlCommand AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

;WITH 
	InvoicesByCustomersDataCTE AS 
	(
		SELECT
			si.InvoiceID,
			FORMAT (DATEADD(MONTH, DATEDIFF(month, 0, si.InvoiceDate), 0), 'dd.MM.yyyy') AS InvoiceMonth,
			sc.CustomerName
		FROM [Sales].[Invoices] AS si
		JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
	),
	UniqueCustomerNamesCTE (UniqueCustomerName) AS
	(
		SELECT DISTINCT 
			sc.CustomerName
		FROM [Sales].[Invoices] AS si
		JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
	)

SELECT 
	@ColumnName = ISNULL(@ColumnName + ',', '') + QUOTENAME(dataCustomerNamesCTE.UniqueCustomerName)
FROM UniqueCustomerNamesCTE as dataCustomerNamesCTE

--SELECT @ColumnName AS ColumnName

SET @dynamicSqlCommand = 
N';WITH 
	InvoicesByCustomersDataCTE AS 
	(
		SELECT
			si.InvoiceID,
			FORMAT (DATEADD(MONTH, DATEDIFF(month, 0, si.InvoiceDate), 0), ''dd.MM.yyyy'') AS InvoiceMonth,
			sc.CustomerName
		FROM [Sales].[Invoices] AS si
		JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
	),
	UniqueCustomerNamesCTE (UniqueCustomerName) AS
	(
		SELECT DISTINCT 
			sc.CustomerName
		FROM [Sales].[Invoices] AS si
		JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
	) ' 
+ 
N'SELECT pvt.InvoiceMonth, '
+ @ColumnName +
' FROM InvoicesByCustomersDataCTE AS ibcCTE
	PIVOT(
	COUNT(ibcCTE.InvoiceID) FOR ibcCTE.CustomerName
IN(' + @ColumnName + ')) AS pvt
ORDER BY YEAR(pvt.InvoiceMonth), MONTH(pvt.InvoiceMonth)'

--SELECT @dynamicSqlCommand AS dynamicSqlCommand
EXEC sp_executesql @dynamicSqlCommand

GO
