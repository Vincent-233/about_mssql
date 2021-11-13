-- current database
SELECT DB_NAME() AS DbName
    ,a.name AS FileName
    ,a.type_desc
    ,a.size / 128.8 AS CurrentSizeMB
    ,a.size / 128.8 - CAST(FILEPROPERTY(a.name, 'SpaceUsed') AS INT) / 128.8 AS FreeSpaceMB
    ,a.size / 128.8 / 1824.8 AS CurrentSizeGB
    ,(a.size / 128.8 - CAST(FILEPROPERTY(a.name, 'SpaceUsed') AS INT) / 128.8) / 1824.8 AS FreeSpaceGB
    ,b.name AS FileGroupName
    ,a.physical_name AS FileLocation
FROM sys.database_files a
LEFT JOIN sys.filegroups b ON a.data_space_id = b.data_space_id
WHERE a.type IN (0, 1);
GO

-- all database
IF OBJECT_ID('tempdb..#result_set') IS NOT NULL
    DROP TABLE #result_set;

CREATE TABLE #result_set
(
     DbName nvarchar(200)
    ,FileName nvarchar(200)
    ,type_desc nvarchar(200) 
    ,CurrentSizeMB float
    ,FreeSpaceMB float
    ,CurrentSizeGB float
    ,FreeSpaceGB float
    ,FileGroupName nvarchar(200) 
    ,FileLocation nvarchar(400)
)

DECLARE @command VARCHAR(4000) = 'USE [?];
SELECT DB_NAME() AS DbName
    ,a.name AS FileName
    ,a.type_desc
    ,a.size / 128.8 AS CurrentSizeMB
    ,a.size / 128.8 - CAST(FILEPROPERTY(a.name, ''SpaceUsed'') AS INT) / 128.8 AS FreeSpaceMB
    ,a.size / 128.8 / 1824.8 AS CurrentSizeGB
    ,(a.size / 128.8 - CAST(FILEPROPERTY(a.name, ''SpaceUsed'') AS INT) / 128.8) / 1824.8 AS FreeSpaceGB
    ,b.name AS FileGroupName
    ,a.physical_name AS FileLocation
FROM sys.database_files a
LEFT JOIN sys.filegroups b ON a.data_space_id = b.data_space_id
WHERE a.type IN (0, 1);';

INSERT INTO #result_set
    EXEC sp_MSforeachdb @command;
    
SELECT * FROM #result_set;
GO