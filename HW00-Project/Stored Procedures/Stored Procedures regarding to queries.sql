USE RentalFirm
GO

PRINT N'Create stored procedure [Users].[GetClientsByBrand]'
GO

CREATE PROCEDURE [Users].[GetClientsByBrand]
	@BrandName NVARCHAR(100) 
AS   
    SET NOCOUNT ON;
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION

			;WITH CTE2 (ClientID) AS 
			(
				SELECT 
					dc.ClientID
				FROM Users.Clients AS uc
				INNER JOIN Deal.Contracts AS dc ON dc.ClientID = uc.ClientID
				INNER JOIN Car.Cars AS cc ON dc.CarID = cc.CarID
				INNER JOIN Car.Models AS cm ON cm.ModelID = cc.ModelID
				INNER JOIN Car.Brands AS cb ON cb.BrandID = cm.BrandID
				WHERE cb.[Description] = @BrandName
				GROUP BY dc.ClientID
			)

			SELECT 
				uc.ClientID,
				uc.FirstName,
				uc.LastName,
				uc.Email,
				uc.Phone
			FROM Users.Clients AS uc
			WHERE uc.ClientID in (SELECT CTE2.ClientID FROM CTE2)

		COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			DECLARE @err NVARCHAR(4000) = error_message();
			if @@trancount > 0 ROLLBACK TRAN;
			RAISERROR(@err, 16, 10);
		END CATCH
	END
GO

--EXEC [Users].[GetClientsByBrand] @BrandName = 'BMW'

PRINT N'Create stored procedure [Users].[GetDataOfEmployeesByDate]'
GO

CREATE PROCEDURE [Users].[GetDataOfEmployeesByDate]
	@CreatedDate DATETIME2 
AS   
    SET NOCOUNT ON;
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION

			;WITH cte AS 
			(
				SELECT DISTINCT
					dc.EmployeeID
				FROM Deal.Contracts AS dc
				WHERE dc.CreatedDate = @CreatedDate
			)

		SELECT 
			ue.LastName,
			ue.Phone
		FROM Users.Employees AS ue WITH(NOLOCK) 
		INNER JOIN cte AS temp ON ue.EmployeeID = temp.EmployeeID

		COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			DECLARE @err NVARCHAR(4000) = error_message();
			if @@trancount > 0 ROLLBACK TRAN;
			RAISERROR(@err, 16, 10);
		END CATCH
	END
GO

--EXEC [Users].[GetDataOfEmployeesByDate] @CreatedDate = '2023-05-02'
--drop procedure [Users].[GetDataOfEmployeesByDate]

PRINT N'Create stored procedure [Car].[GeCarsByBrandAndInsurancePrice]'
GO

CREATE PROCEDURE [Car].[GeCarsByBrandAndInsurancePrice]
	@BrandName NVARCHAR(100), 
	@Price DECIMAL(18,3)
AS   
    SET NOCOUNT ON;
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION

			SELECT 
				ii.CarID,
				cc.ColorID,
				cc.ModelID,
				cc.PurchasedDate
			FROM Insurance.Insurances AS ii
			INNER JOIN Car.Cars AS cc ON ii.CarID = cc.CarID
			INNER JOIN Car.Models AS cm ON cm.ModelID = cc.ModelID
			INNER JOIN Car.Brands AS cb ON cb.BrandID = cm.BrandID
			WHERE ii.Price < @Price AND cb.[Description] = @BrandName

		COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			DECLARE @err NVARCHAR(4000) = error_message();
			if @@trancount > 0 ROLLBACK TRAN;
			RAISERROR(@err, 16, 10);
		END CATCH
	END
GO