USE WideWorldImporters
GO

CREATE SCHEMA Customers;
GO

CREATE PROCEDURE [Customers].[GetSumPriceOfPurchasesByCustomer]
	@CustomerId INT 
AS   
    SET NOCOUNT ON;
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION

			SELECT
				SUM(sil.Quantity * sil.UnitPrice) as SumPrice
			FROM [Sales].[Invoices] AS si
			JOIN [Sales].[Customers] AS sc ON sc.CustomerID = si.CustomerID
			JOIN [Sales].[InvoiceLines] AS sil ON sil.InvoiceID = si.InvoiceID
			WHERE sc.CustomerID = @customerId
			GROUP BY sc.CustomerID

			if @@trancount > 0 COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			DECLARE @err NVARCHAR(4000) = error_message();
			if @@trancount > 0 ROLLBACK TRAN;
			RAISERROR(@err, 16, 10);
		END CATCH
	END
GO 

exec [Customers].[GetSumPriceOfPurchasesByCustomer] @customerID = 0

--drop procedure [Customers].[GetSumPriceOfPurchasesByCustomer]