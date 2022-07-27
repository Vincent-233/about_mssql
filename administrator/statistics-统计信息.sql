-- 默认自动创建为新表的第一个字段创建统计信息
-- 后面查询到其它列时，也会自动在对应上创建统计信息

-- view detail statistics for specific table
DBCC SHOW_STATISTICS('stg.stage_check_data',userid)


-- view only one type of statistics
DBCC SHOW_STATISTICS('stg.stage_check_data',userid) WITH HISTOGRAM
DBCC SHOW_STATISTICS('stg.stage_check_data',userid) WITH STAT_HEADER 
DBCC SHOW_STATISTICS('stg.stage_check_data',userid) WITH DENSITY_VECTOR 


-- summary statistics info for all tables in current database
SELECT obj.name, obj.object_id, stat.name, stat.stats_id, last_updated, modification_counter
      ,obj.type,i.type_desc AS table_type  
FROM sys.objects AS obj   
INNER JOIN sys.stats AS stat ON stat.object_id = obj.object_id  
INNER JOIN sys.indexes i ON obj.object_id = i.object_id AND i.index_id < 2
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp  
WHERE obj.type NOT IN ('S', 'IT')


-- statistics and according columns
SELECT s.name AS stats_name
      ,OBJECT_SCHEMA_NAME(s.object_id) + N'.' + OBJECT_NAME(s.object_id) AS [object_name]
      ,c.name AS column_name, s.auto_created
      ,sc.stats_column_id
FROM sys.stats AS s
INNER JOIN sys.stats_columns AS sc ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id
INNER JOIN sys.columns AS c ON sc.object_id = c.object_id AND sc.column_id = c.column_id
INNER JOIN sys.objects o ON s.object_id = o.object_id
WHERE o.type NOT IN ('S', 'IT');