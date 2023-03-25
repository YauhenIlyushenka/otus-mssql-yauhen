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
FROM InvoicesByCustomersDataCTE as ibcCTE
PIVOT(
	COUNT(ibcCTE.InvoiceID) FOR ibcCTE.ClarifyCustomerName
	IN([Sylvanite, MT], 
       [Peeples Valley, AZ], 
       [Medicine Lodge, KS], 
       [Gasport, NY],
	   [Jessie, ND])) 
	   AS pvt
ORDER BY MONTH(pvt.InvoiceMonth), YEAR(pvt.InvoiceMonth)

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
--UNPIVOT
напишите здесь свое решение

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
- CROSS APPLY
напишите здесь свое решение
