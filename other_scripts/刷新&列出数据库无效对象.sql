CREATE PROC Sp_RefreshDataBaseObj
AS
BEGIN
	IF OBJECT_ID('ErrorObjName') IS NOT NULL
		DROP TABLE ErrorObjName;

	CREATE TABLE ErrorObjName(ID INT IDENTITY(1,1) PRIMARY KEY,ObjName NVARCHAR(300),ErrorMsg NVARCHAR(1000),objType VARCHAR(50))

	DECLARE @sql VARCHAR(1000),@ObjName VARCHAR(400),@objType VARCHAR(50),@Index INT = 1,@CNT INT = 0;
	DECLARE @T_Obj TABLE(ID INT,ObjName VARCHAR(500),ObjType VARCHAR(50))

	INSERT INTO @T_Obj(ID,ObjName,ObjType)
		SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)),name,[Type]
		FROM sys.objects 
		WHERE [type] IN ('V','P','IF', 'TF', 'FN') AND name NOT IN ('Sp_RefreshDataBaseObj')
	

	SET @CNT = @@ROWCOUNT;

	WHILE @Index <= @CNT
		BEGIN
			SELECT @ObjName = ObjName
			      ,@ObjType = CASE  
				                  WHEN ObjType = 'V' THEN 'View'
				                  WHEN ObjType IN ('IF', 'TF', 'FN') THEN 'Function'
								  WHEN ObjType = 'P' THEN 'Procedure'
							  END
			FROM @T_Obj 
			WHERE ID = @Index;
			
			SELECT @sql = 'EXEC sp_refreshsqlmodule ' + @ObjName; 
			
			BEGIN TRY
				--PRINT @sql
				EXEC (@sql);
			END TRY
			BEGIN CATCH
				INSERT INTO ErrorObjName(ObjName,objType,ErrorMsg) VALUES(@ObjName,@ObjType,ERROR_MESSAGE());
			END CATCH
			SET @Index += 1;
		END
	
	SELECT * FROM ErrorObjName;
END