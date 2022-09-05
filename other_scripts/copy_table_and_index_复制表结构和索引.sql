USE TestDB
GO

IF OBJECT_ID('dbo.sp_clone_index_from_table') IS NOT NULL
    DROP PROC dbo.sp_clone_index_from_table;
GO


/*
Note:
    - copy:
        - cluster/noncluster/columnstore
        - primary key/unique constraint
    - don't copy:
        - with options such as fill_factor, is_padding etc
        - other new kinds of index, such as xml,hash etc
    - Assume:
        - destination table have the same column names with source table, at least the ones with index
        - same data compression on all partitions
        - with table name in constraint name (avoid duplicated constraint name)
        - destination table exists without index
*/

CREATE PROC dbo.sp_clone_index_from_table
     @inSourceTable nvarchar(255)
    ,@inDestinationTable nvarchar(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @vIndexId int, @vIndexName nvarchar(255), @vIsUnique bit, @vIsUniqueConstraint bit,@vIsPrimaryKey bit
               ,@vFilterDeFinition nvarchar(max), @vIndex_type int, @vIndex_type_desc nvarchar(200),@vDataCompression nvarchar(200);
        DECLARE @vID int,@vSQL nvarchar(max), @vMsg nvarchar(max);

        IF OBJECT_ID(@inSourceTable) IS NULL
            BEGIN
                SET @vMsg = @inSourceTable + ' does not exist.';
                THROW 51000, @vMsg , 1;
            END

        IF OBJECT_ID(@inDestinationTable) IS NULL
            BEGIN
                SET @vMsg = @inDestinationTable + ' does not exist.';
                THROW 51000, @vMsg , 1;
            END
        
        IF @inSourceTable = @inDestinationTable
            BEGIN
                SET @vMsg = 'source table and destination table can not be the same';
                THROW 51999, @vMsg , 1;
            END

        IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id(@inDestinationTable) AND [type] in (1,2,5,6))
            BEGIN
                SET @vMsg = 'please drop existing index in destination table';
                THROW 51999, @vMsg , 1;
            END

        -- create new index
        DECLARE
             @vSourceSchema nvarchar(255) = object_schema_name(object_id(@inSourceTable))
            ,@vSourceTable nvarchar(255) = object_name(object_id(@inSourceTable))
            ,@vDestinationSchema nvarchar(255) = object_schema_name(object_id(@inDestinationTable))
            ,@vDestinationTable nvarchar(255) = object_name(object_id(@inDestinationTable));

        IF OBJECT_ID('tempdb..#TEMP_INDEX') IS NOT NULL DROP TABLE #TEMP_INDEX;

        SELECT  index_id,name,type,type_desc,filter_definition,is_unique,is_unique_constraint,is_primary_key
               ,RN = ROW_NUMBER() OVER(ORDER BY type DESC)
        INTO #TEMP_INDEX 
        FROM sys.indexes
        WHERE [type] in (1,2,5,6)
          AND object_id = object_id(@inSourceTable);

        SET @vID = @@ROWCOUNT;
        WHILE @vID >= 1
            BEGIN
                SELECT @vIndexId = index_id,@vIndexName = name,@vIsUnique = is_unique
                      ,@vIsUniqueConstraint = is_unique_constraint,@vIsPrimaryKey = is_primary_key
                      ,@vIndex_type = type,@vIndex_type_desc = type_desc, @vFilterDefinition = filter_definition
                FROM #TEMP_INDEX
                WHERE RN = @VID;

                DECLARE @vKeyColumns nvarchar(MAX), @vIncludedColumns nvarchar(MAX),@vUnique nvarchar(255);

                SELECT @vKeyColumns = '',@vIncludedColumns = ''
                      ,@vUnique = CASE WHEN @vIsUnique = 1 THEN ' UNIQUE ' ELSE '' END;
            
                SELECT @vKeyColumns = @vKeyColumns + '[' + c.name + '] ' + CASE WHEN is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END + ','
                FROM sys.index_columns ic
                INNER JOIN sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
                WHERE ic.index_id = @vIndexId and ic.object_id = object_id('[' + @vSourceSchema + '].[' + @vSourceTable + ']')
                 AND ic.is_included_column = 0
                ORDER BY ic.key_ordinal;

                SELECT @vIncludedColumns = @vIncludedColumns + '[' + c.name + '],'
                FROM sys.index_columns ic
                INNER JOIN sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
                WHERE index_id = @vIndexId and ic.object_id = object_id('[' + @vSourceSchema + '].[' + @vSourceTable + ']')
                AND ic.is_included_column = 1
                ORDER BY ic.index_column_id;

                IF LEN(@vKeyColumns) > 0
                    SET @vKeyColumns = LEFT(@vKeyColumns, LEN(@vKeyColumns) - 1);

                IF LEN(@vIncludedColumns) > 0
                    BEGIN
                    SET @vIncludedColumns = ' INCLUDE (' + LEFT(@vIncludedColumns, LEN(@vIncludedColumns) - 1) + ')';
                    END

                IF @vFilterDefinition IS NULL
                    SET @vFilterDefinition = '';
                ELSE
                    SET @vFilterDefinition = 'WHERE ' + @vFilterDefinition + ' ';

                IF @vIsUniqueConstraint = 1
                    BEGIN
                        SET @vIndexName = REPLACE(@vIndexName, @vSourceTable, @vDestinationTable) + LTRIM(ABS(CHECKSUM(NEWID())));
                        SET @VSQL = 'ALTER TABLE [' + @vDestinationSchema + '].[' + @vDestinationTable + '] ADD CONSTRAINT [' +
                                     @vIndexName + '] ' + @vUnique + @vIndex_type_desc + ' (' + @vKeyColumns + ')';
                    END
                ELSE IF @vIsPrimaryKey = 1
                    BEGIN
                        SET @vIndexName = REPLACE(@vIndexName, @vSourceTable, @vDestinationTable) + LTRIM(ABS(CHECKSUM(NEWID())));
                        SET @VSQL = 'ALTER TABLE [' + @vDestinationSchema + '].[' + @vDestinationTable + '] ADD CONSTRAINT [' +
                            @vIndexName + '] PRIMARY KEY ' + @vIndex_type_desc + ' (' + @vKeyColumns + ')';
                    END
                ELSE
                    SET @VSQL = 'CREATE ' + @VUnique + @vIndex_type_desc + ' INDEX [' + @vIndexName + '] ON [' +
                                 @vDestinationSchema + '].[' + @VDestinationTable + ']' +
                                 CASE WHEN @vIndex_type IN (1,2) THEN '(' + @vKeyColumns + ')' + @vIncludedColumns + @vFilterDefinition ELSE '' END;
                
                    RAISERROR (@VSQL, 0, 1) WITH NOWAIT;
                    EXEC sp_executesql @VSQL;
                    SET @vID = @vID - 1;
                END;

                -- step 3 data compression option
                SELECT TOP (1) @vDataCompression = data_compression_desc FROM sys.partitions WHERE object_id = object_id(@inSourceTable)
                ORDER BY CASE WHEN index_id = 1 THEN 0 ELSE 1 END;

                IF @vDataCompression <> 'NONE'
                    BEGIN
                        SET @vSQL = 'ALTER TABLE ' + @inDestinationTable + ' REBUILD PARTITION = ALL WITH (DATA_CONPRESSION = ' + @vDataCompression + ')';
                        RAISERROR (@VSQL, 0, 1) WITH NOWAIT;
                        EXEC sp_executesql @VSQL;
                    END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION
            END
        SELECT ERROR_MESSAGE();
        THROW
    END CATCH
END

GO

--SET NOEXEC ON;

-------------------------------------------------------------------------
--                               Usage
-------------------------------------------------------------------------
-- source table
DROP TABLE IF EXISTS dbo.table_a;
CREATE TABLE dbo.table_a(col_1 INT PRIMARY KEY, col_2 VARCHAR(200), col_3 VARCHAR(300));
CREATE INDEX idx_table_a ON dbo.table_a(col_2);
ALTER TABLE dbo.table_a ADD CONSTRAINT table_a_unique_col_3 UNIQUE (col_3);
GO 

-- desc table
DROP TABLE IF EXISTS dbo.table_b;
CREATE TABLE dbo.table_b(col_1 INT NOT NULL, col_2 VARCHAR(200), col_3 VARCHAR(300));
GO

-- see index info before clone index
EXEC sp_helpindex 'dbo.table_a';
/*
    | index_name                    | index_description                                   | index_keys |
    |-------------------------------|-----------------------------------------------------|------------|
    | idx_table_a                   | nonclustered located on PRIMARY                     | col_2      |
    | PK__table_a__9014219BC6BEA0A0 | clustered, unique, primary key located on PRIMARY   | col_1      |
    | table_a_unique_col_3          | nonclustered, unique, unique key located on PRIMARY | col_3      |
*/


EXEC sp_helpindex 'dbo.table_b'
/*
    The object 'dbo.table_b' does not have any indexes, or you do not have permissions.
*/


EXEC dbo.sp_clone_index_from_table 'dbo.table_a', 'dbo.table_b';

EXEC sp_helpindex 'dbo.table_b'
/*
    | index_name                             | index_description                                   | index_keys |
    |----------------------------------------|-----------------------------------------------------|------------|
    | idx_table_a                            | nonclustered located on PRIMARY                     | col_2      |
    | PK__table_b__9014219BC6BEA0A0674073074 | clustered, unique, primary key located on PRIMARY   | col_1      |
    | table_b_unique_col_31836879325         | nonclustered, unique, unique key located on PRIMARY | col_3      |
*/