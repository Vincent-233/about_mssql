USE test_db
GO

IF OBJECT_ID('dbo.sp_dev_sql_gen_add_cols') IS NOT NULL 
    DROP PROC dbo.sp_dev_sql_gen_add_cols
GO

CREATE PROC dbo.sp_dev_sql_gen_add_cols 
    @type VARCHAR(29) = 'ADD' -- ADD/ DROP
AS
BEGIN
    SET XACT_ABORT ON;
    SET NOCOUNT ON;
    DECLARE @vMsg VARCHAR(1999),
            @newline VARCHAR(10) = CHAR(13) + CHAR(10);
	
    IF OBJECT_ID('tempdb..#T_add_cols_config') IS NULL
		BEGIN
			SET @vMsg
				= @newline + 'Please create temp table #T_add_cols_config AND INSERT data to it firstly.' + @newline + @newline
				  + 'IF OBJECT_ID(''tempdb..#T_add_cols_config'') IS NOT NULL DROP TABLE #T_add_cols_config;' + @newline
				  + 'CREATE TABLE #T_add_cols_config(db_name VARCHAR(255) ,table_name VARCHAR(255), column_name VARCHAR(255), data_type VARCHAR(255))'
				  + @newline + 'INSERT INTO #T_add_cols_config' + @newline + '    ...';
			THROW 51996, @vMsg, 1;
		END;
    DECLARE @sql_add_cols VARCHAR(4000)
        = 'IF NOT EXISTS(SELECT * FROM sys.columns WHERE name = ''%s'' AND object_id = object_id(''%s''))' + @newline + '    '
          + 'ALTER TABLE %s ADD %s %s;' + @newline + 'GO' + @newline + @newline;
    DECLARE @sql_drop_cols VARCHAR(4000)
        = 'IF EXISTS(SELECT * FROM sys.columns WHERE name = ''%s'' AND object_id = object_id(''%s''))' + @newline + '    '
          + 'ALTER TABLE %s DROP COLUMN %s;' + @newline + 'GO' + @newline + @newline;

    DECLARE @T_db TABLE
    (
        id INT IDENTITY(1, 1),
        db_name VARCHAR(255)
    );

    DECLARE @T_worktable TABLE
    (
        id INT,
        sql_statement VARCHAR(4000)
    );
    
    DECLARE @db_name VARCHAR(255),
            @id_max_1 INT,
            @id_1 INT = 1,
            @id_max_2 INT,
            @id_2 INT,
            @sql_statement VARCHAR(4000);

    INSERT INTO @T_db
    (
        db_name
    )
    SELECT DISTINCT
           db_name
    FROM #T_add_cols_config;
    SELECT @id_max_1 = @@ROWCOUNT;

    WHILE @id_1 <= @id_max_1
        BEGIN
            SELECT @db_name = db_name
            FROM @T_db
            WHERE id = @id_1;
            DELETE FROM @T_worktable;
            INSERT INTO @T_worktable
            (
                id,
                sql_statement
            )
            SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
                   CASE @type
                       WHEN 'ADD' THEN
                           FORMATMESSAGE(@sql_add_cols, column_name, table_name, table_name, column_name, data_type)
                       ELSE
                           FORMATMESSAGE(@sql_drop_cols, column_name, table_name, table_name, column_name)
                   END
            FROM #T_add_cols_config
            WHERE db_name = @db_name;

            SELECT @id_2 = 1,
                   @id_max_2 = @@ROWCOUNT;
            PRINT ('USE ' + @db_name + @newline + 'GO' + @newline + @newline);
        
            WHILE @id_2 <= @id_max_2
                BEGIN
                    SELECT @sql_statement = sql_statement
                    FROM @T_worktable
                    WHERE id = @id_2;
                    PRINT @sql_statement;
                    SET @id_2 += 1;
                END;
            SET @id_1 += 1;
        END;
END;
GO



--------------------- Usage
IF OBJECT_ID('tempdb..#T_add_cols_config') IS NOT NULL DROP TABLE #T_add_cols_config;
CREATE TABLE #T_add_cols_config(db_name VARCHAR(255) ,table_name VARCHAR(255), column_name VARCHAR(255), data_type VARCHAR(255))
INSERT INTO #T_add_cols_config
    SELECT 'emp_db','dbo.department','col_a','int' UNION ALL
    SELECT 'emp_db','dbo.department','col_b','int' UNION ALL
    SELECT 'emp_db','dbo.department','col_c','int' UNION ALL
    SELECT 'pay_db','dbo.salary','col_x','varchar(50)' UNION ALL
    SELECT 'pay_db','dbo.salary','col_y','varchar(80)' 
GO

EXEC dbo.sp_dev_sql_gen_add_cols 'Add';

--------------------- Result
/*
USE emp_db
GO

IF NOT EXISTS(SELECT * FROM sys.columns WHERE name = 'col_a' AND object_id = object_id('dbo.department'))
    ALTER TABLE dbo.department ADD col_a int;
GO

IF NOT EXISTS(SELECT * FROM sys.columns WHERE name = 'col_b' AND object_id = object_id('dbo.department'))
    ALTER TABLE dbo.department ADD col_b int;
GO

IF NOT EXISTS(SELECT * FROM sys.columns WHERE name = 'col_c' AND object_id = object_id('dbo.department'))
    ALTER TABLE dbo.department ADD col_c int;
GO

USE pay_db
GO

IF NOT EXISTS(SELECT * FROM sys.columns WHERE name = 'col_x' AND object_id = object_id('dbo.salary'))
    ALTER TABLE dbo.salary ADD col_x varchar(50);
GO

IF NOT EXISTS(SELECT * FROM sys.columns WHERE name = 'col_y' AND object_id = object_id('dbo.salary'))
    ALTER TABLE dbo.salary ADD col_y varchar(80);
GO

*/