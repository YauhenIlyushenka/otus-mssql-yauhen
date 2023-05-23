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
				FROM Users.Clients AS uc WITH(NOLOCK)
				INNER JOIN Deal.Contracts AS dc ON dc.ClientID = uc.ClientID
				INNER JOIN Car.Cars AS cc WITH(NOLOCK) ON dc.CarID = cc.CarID
				INNER JOIN Car.Models AS cm WITH(NOLOCK) ON cm.ModelID = cc.ModelID
				INNER JOIN Car.Brands AS cb WITH(NOLOCK) ON cb.BrandID = cm.BrandID
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