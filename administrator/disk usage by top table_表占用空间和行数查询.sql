------------------------------------------------------------------------
--                           Method 1
------------------------------------------------------------------------
-- by table, file_group ( all partition )
SELECT TOP 1000
       DB_NAME() AS [database]
     , CONCAT(s.name, '.', t.name) AS table_full_name
     , s.name AS SchemaName
     , t.name AS TableName
     , SUM(CASE WHEN i.index_id < 2 THEN p.rows ELSE 0 END) AS RowCounts
     , COUNT(DISTINCT p.partition_number) AS PartitionCount
     , f.name AS fileGrouopName
     , CASE MAX(CASE WHEN i.type IN (0,1,5) THEN i.type ELSE 0 END) WHEN 0 THEN 'Heap' WHEN 1 THEN 'B-Tree' WHEN 5 THEN 'Clustered Columnstore' END AS TableType
     , CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Used_MB
     , CAST(ROUND((SUM(a.total_pages) - SUM(a.used_pages)) / 128.00, 2) AS NUMERIC(36, 2)) AS Unused_MB
     , CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Total_MB
     , CAST(ROUND((SUM(a.total_pages) / 128.00 / 1024), 2) AS NUMERIC(36, 2)) AS Total_GB
     , t.modify_date
FROM sys.tables t
    INNER JOIN sys.indexes i ON t.object_id = i.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.filegroups f ON a.data_space_id = f.data_space_id
GROUP BY s.name
       , t.name
       , f.name
       , t.modify_date
ORDER BY Total_MB DESC;
GO

-- by table, file_group, partition ( each partition )
SELECT TOP 1000
       DB_NAME() AS [database]
     , CONCAT(s.name, '.', t.name) AS table_full_name
     , s.name AS SchemaName
     , t.name AS TableName
     , p.partition_number
     , SUM(CASE WHEN i.index_id < 2 THEN p.rows ELSE 0 END) AS RowCounts
     , COUNT(DISTINCT i.index_id) AS IndexCount
     , f.name AS FileGrouopName
     , p.data_compression_desc
     , CASE MAX(CASE WHEN i.type IN (0,1,5) THEN i.type ELSE 0 END) WHEN 0 THEN 'Heap' WHEN 1 THEN 'B-Tree' WHEN 5 THEN 'Clustered Columnstore' END AS TableType
     , CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Used_MB
     , CAST(ROUND((SUM(a.total_pages) - SUM(a.used_pages)) / 128.00, 2) AS NUMERIC(36, 2)) AS Unused_MB
     , CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Total_MB
     , CAST(ROUND((SUM(a.total_pages) / 128.00 / 1024), 2) AS NUMERIC(36, 2)) AS Total_GB
     , t.modify_date
FROM sys.tables t
    INNER JOIN sys.indexes i ON t.object_id = i.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.filegroups f ON a.data_space_id = f.data_space_id
GROUP BY s.name
       , t.name
       , f.name
       , t.modify_date
       , p.partition_number
       ,p.data_compression_desc
ORDER BY Total_MB DESC;
GO


------------------------------------------------------------------------
--           Method 2 -> from SSMS standard report
------------------------------------------------------------------------
-- disk usage by top table ( the same result with sp_spaceused )
SELECT TOP 1000
       ROW_NUMBER() OVER (ORDER BY (a1.reserved + ISNULL(a4.reserved, 0)) DESC) AS rn
     , a3.name AS [schemaname]
     , a2.name AS [tablename]
     , a1.rows AS row_count
     , a1.data / 128.0 AS data_MB
     , (CASE WHEN (a1.used + ISNULL(a4.used, 0)) > a1.data 
             THEN (a1.used + ISNULL(a4.used, 0)) - a1.data 
             ELSE 0 
        END) / 128.0 AS index_size_MB
     , (CASE WHEN (a1.reserved + ISNULL(a4.reserved, 0)) > a1.used 
             THEN (a1.reserved + ISNULL(a4.reserved, 0)) - a1.used 
             ELSE 0 
        END) / 128.0 AS unused_MB
     , (a1.reserved + ISNULL(a4.reserved, 0)) / 128.0 AS reserved_MB
FROM
(
    SELECT ps.object_id
         , SUM(CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows]
         , SUM(ps.reserved_page_count) AS reserved
         , SUM(CASE WHEN (ps.index_id < 2) 
                    THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                    ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)
               END) AS data
         , SUM(ps.used_page_count) AS used
    FROM sys.dm_db_partition_stats ps
    WHERE ps.object_id NOT IN (SELECT object_id FROM sys.tables WHERE is_memory_optimized = 1)
    GROUP BY ps.object_id
) AS a1
LEFT OUTER JOIN
(
    SELECT it.parent_id
            , SUM(ps.reserved_page_count) AS reserved
            , SUM(ps.used_page_count) AS used
    FROM sys.dm_db_partition_stats ps
        INNER JOIN sys.internal_tables it
            ON (it.object_id = ps.object_id)
    WHERE it.internal_type IN ( 202, 204 )
    GROUP BY it.parent_id
) AS a4 ON (a4.parent_id = a1.object_id)
INNER JOIN sys.all_objects a2 ON (a1.object_id = a2.object_id)
INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
WHERE a2.type <> N'S'
  AND a2.type <> N'IT';
GO


------------------------------------------------------------------------
--           Method 3 -> sp_spaceused
------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#result_set') IS NOT NULL
    DROP TABLE #result_set;

CREATE TABLE #result_set (
    tablename VARCHAR(200)
   ,rows VARCHAR(200)
   ,reserved VARCHAR(200)
   ,data VARCHAR(200)
   ,index_size VARCHAR(200)
   ,unused VARCHAR(200)
);
INSERT INTO #result_set
    EXEC sp_msforeachtable 'EXEC sp_spaceused ''?''';

SELECT tablename
     , CAST(rows AS INT) AS row_count
     , CAST(REPLACE(reserved, ' KB', '') AS INT) / 1024.0 AS reserved_MB
     , CAST(REPLACE(data, ' KB', '') AS INT) / 1024.0 AS data_MB
     , CAST(REPLACE(index_size, ' KB', '') AS INT) / 1024.0 AS index_size_MB
     , CAST(REPLACE(unused, ' KB', '') AS INT) / 1024.0 AS unused_MB
FROM #result_set
ORDER BY 3 DESC;
GO

