/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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

USE WideWorldImporters;

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

-- The first way is OPENXML

GO

DECLARE @xmlDocument XML;

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'D:\SQL\OtusSqlDev\otus-mssql-yauhen\HW09-xmlJson\StockItems.xml', 
 SINGLE_CLOB)
AS data;

-- Checking
--SELECT @xmlDocument AS [@xmlDocument];

DECLARE @docHandle INT;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;

--SELECT @docHandle AS docHandle;
DROP TABLE IF EXISTS #StockItemsInserted;

CREATE TABLE #StockItemsInserted(
	[StockItemName] NVARCHAR(100) NOT NULL,
	[SupplierID] INT NOT NULL,
	[UnitPackageID] INT NOT NULL,
	[OuterPackageID] INT NOT NULL,
	[QuantityPerOuter] INT NOT NULL,
	[TypicalWeightPerUnit] DECIMAL(18, 3) NOT NULL,
	[LeadTimeDays] INT NOT NULL,
	[IsChillerStock] BIT NOT NULL,
	[TaxRate] DECIMAL(18, 3) NOT NULL,
	[UnitPrice] DECIMAL(18, 2) NOT NULL
);

INSERT INTO #StockItemsInserted
SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] NVARCHAR(100) '@Name',
	[SupplierID] INT 'SupplierID',
	[UnitPackageID] INT 'Package/UnitPackageID',
	[OuterPackageID] INT 'Package/OuterPackageID',
	[QuantityPerOuter] INT 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] DECIMAL(18, 3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] INT 'LeadTimeDays',
	[IsChillerStock] BIT 'IsChillerStock',
	[TaxRate] DECIMAL(18, 3) 'TaxRate',
	[UnitPrice] DECIMAL(18, 2) 'UnitPrice');

-- Removing handle
EXEC sp_xml_removedocument @docHandle;

--SELECT * FROM #StockItemsInserted;

MERGE [Warehouse].[StockItems] AS target
USING (SELECT * FROM #StockItemsInserted) AS source
	ON (target.StockItemName = source.StockItemName COLLATE SQL_Latin1_General_CP1_CI_AS)
WHEN MATCHED 
	THEN UPDATE SET [SupplierID] = source.SupplierID,
					[UnitPackageID] = source.UnitPackageID,
					[OuterPackageID] = source.OuterPackageID,
					[QuantityPerOuter] = source.QuantityPerOuter,
					[TypicalWeightPerUnit] = source.TypicalWeightPerUnit,
					[LeadTimeDays] = source.LeadTimeDays,
					[IsChillerStock] = source.IsChillerStock,
					[TaxRate] = source.TaxRate,
					[UnitPrice] = source.UnitPrice
WHEN NOT MATCHED
	THEN INSERT (
		[StockItemName],
		[SupplierID],
		[ColorID],
		[UnitPackageID],
		[OuterPackageID],
		[Brand],
		[Size],
		[LeadTimeDays],
		[QuantityPerOuter],
		[IsChillerStock],
		[Barcode],
		[TaxRate],
		[UnitPrice],
		[RecommendedRetailPrice],
		[TypicalWeightPerUnit],
		[MarketingComments],
		[InternalComments],
		[Photo],
		[CustomFields],
		[LastEditedBy])
	VALUES (
		source.StockItemName,
		source.SupplierID,
		NULL,
		source.UnitPackageID,
		source.OuterPackageID,
		NULL,
		NULL,
		source.LeadTimeDays,
		source.QuantityPerOuter,
		source.IsChillerStock,
		NULL,
		source.TaxRate,
		source.UnitPrice,
		NULL,
		source.TypicalWeightPerUnit,
		NULL,
		NULL,
		NULL,
		NULL,
		2
	);

DROP TABLE IF EXISTS #StockItemsInserted;

GO

-- The second way is OPENXML



/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

-- напишите здесь свое решение

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

-- напишите здесь свое решение

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

-- напишите здесь свое решение
