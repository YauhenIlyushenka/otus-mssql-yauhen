/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters;

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".

Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT 
	StockItemID,
	StockItemName
FROM [Warehouse].[StockItems]
WHERE StockItemName LIKE '%urgent%' OR StockItemName LIKE 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.

Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT 
	ps.SupplierID,
	ps.SupplierName
FROM [Purchasing].[Suppliers] AS ps
LEFT JOIN [Purchasing].[PurchaseOrders] AS pp ON pp.SupplierID = ps.SupplierID
WHERE pp.SupplierID IS NULL

/*
3. Заказы (Orders) с товарами ценой (UnitPrice) более 100$
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).

Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ (10.01.2011)
* название месяца, в котором был сделан заказ (используйте функцию FORMAT или DATENAME)
* номер квартала, в котором был сделан заказ (используйте функцию DATEPART)
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT DISTINCT 
	   so.OrderID,
	   FORMAT(so.OrderDate, 'dd.MM.yyyy') AS OrderDate,
       DATENAME(mm, so.OrderDate) AS [Month],
	   DATEPART(qq, so.OrderDate) AS [Quarter],
	   CASE
			WHEN MONTH(so.OrderDate) <= 4 THEN 1
			WHEN MONTH(so.OrderDate) BETWEEN 5 AND 8 THEN 2
			ELSE 3
	   END AS ThirdOfTheYear,
	   sc.CustomerName
FROM [Sales].[Orders] AS so
JOIN [Sales].[OrderLines] AS sol ON sol.OrderID = so.OrderID
JOIN [Sales].[Customers] AS sc ON so.CustomerID = sc.CustomerID
WHERE sol.UnitPrice > 100 OR (sol.Quantity > 20 AND sol.PickingCompletedWhen IS NOT NULL)
ORDER BY [Quarter], ThirdOfTheYear, OrderDate

-- with offset
SELECT DISTINCT 
	   so.OrderID,
	   FORMAT(so.OrderDate, 'dd.MM.yyyy') AS OrderDate,
       DATENAME(mm, so.OrderDate) AS [Month],
	   DATEPART(qq, so.OrderDate) AS [Quarter],
	   CASE
			WHEN MONTH(so.OrderDate) <= 4 THEN 1
			WHEN MONTH(so.OrderDate) BETWEEN 5 AND 8 THEN 2
			ELSE 3
	   END AS ThirdOfTheYear,
	   sc.CustomerName
FROM [Sales].[Orders] AS so
JOIN [Sales].[OrderLines] AS sol ON sol.OrderID = so.OrderID
JOIN [Sales].[Customers] AS sc ON so.CustomerID = sc.CustomerID
WHERE sol.UnitPrice > 100 OR (sol.Quantity > 20 AND sol.PickingCompletedWhen IS NOT NULL)
ORDER BY [Quarter], ThirdOfTheYear, OrderDate
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).

Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT
	ad.DeliveryMethodName,
	PP.ExpectedDeliveryDate,
	ps.SupplierName,
	ap.PreferredName AS ContactPerson
FROM [Purchasing].[Suppliers] AS ps
JOIN [Purchasing].[PurchaseOrders] AS pp ON pp.SupplierID = ps.SupplierID
JOIN [Application].[People] AS ap ON ap.PersonID = pp.ContactPersonID
JOIN [Application].[DeliveryMethods] AS ad ON ad.DeliveryMethodID = pp.DeliveryMethodID
WHERE MONTH(pp.ExpectedDeliveryDate) = 1 
	  AND YEAR(pp.ExpectedDeliveryDate) = 2013
      AND ad.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight')
	  AND pp.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи - InvoiceDate) с именем клиента (клиент - CustomerID) и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.

Вывести: ИД продажи (InvoiceID), дата продажи (InvoiceDate), имя заказчика (CustomerName), имя сотрудника (SalespersonFullName)
Таблицы: Sales.Invoices, Sales.Customers, Application.People.
*/

SELECT TOP (10)
	si.InvoiceID,
	si.InvoiceDate,
	sc.CustomerName,
	ap.FullName AS SalespersonPerson
FROM [Sales].[Invoices] AS si
JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
JOIN [Application].[People] AS ap ON ap.PersonID = si.SalespersonPersonID
ORDER BY si.InvoiceDate DESC

/*
6. Все ид и имена клиентов (клиент - CustomerID) и их контактные телефоны (PhoneNumber),
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems, имена клиентов и их контакты в таблице Sales.Customers.

Таблицы: Sales.Invoices, Sales.InvoiceLines, Sales.Customers, Warehouse.StockItems.
*/

SELECT 
	sc.CustomerID,
	sc.CustomerName,
	sc.PhoneNumber
FROM [Sales].[Invoices] AS si
JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
JOIN [Sales].[InvoiceLines] AS sil ON sil.InvoiceID = si.InvoiceID
JOIN [Warehouse].[StockItems] AS ws on ws.StockItemID = sil.StockItemID
WHERE ws.StockItemName = 'Chocolate frogs 250g'
