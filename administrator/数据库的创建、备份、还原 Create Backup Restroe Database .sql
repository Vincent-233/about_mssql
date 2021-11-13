-- 数据库创建
CREATE DATABASE [TDEDataBase]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'TDEDataBase',
  FILENAME = N'C:\MyTest\DB\TDEDataBase.mdf' , 
  SIZE = 3072KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'TDEDataBase_log', 
  FILENAME = N'C:\MyTest\DB\TDEDataBase_log.ldf' ,
  SIZE = 1024KB , FILEGROWTH = 10%)
GO

-- 备份
BACKUP DATABASE [ContainedTestDB] TO  DISK = N'C:\MyTest\DB Backup\ContainedTestDB.bak' 
GO

-- 普通还原
RESTORE DATABASE [Sample_Test] 
FROM  DISK = N'E:\DB Backup\Sample_backup_2017_12_28.bak' WITH  FILE = 1,
MOVE N'HRIS_dat' TO N'D:\Database\Sample_Test.mdf',  
MOVE N'HRIS_Log' TO N'D:\Database\Sample_Test.ldf',  NOUNLOAD,  STATS = 5
/*,REPLACE -- 覆盖*/

-- 含事务日志还原 【Begin】
RESTORE DATABASE [Sample] 
FROM  DISK = N'E:\DB-File\Database Backup\Sample-DB Backup-20180116\Sample_backup_2018_01_17_000001_5549559.bak' WITH  FILE = 1,
MOVE N'HRIS_dat' TO N'D:\DB-File\Sample.mdf',  
MOVE N'HRIS_Log' TO N'D:\DB-File\Sample.ldf',  NOUNLOAD,  STATS = 5,NORECOVERY
/*,REPLACE -- 覆盖*/

RESTORE LOG [Sample] 
FROM  DISK = N'E:\DB-File\Database Backup\Sample-DB Backup-20180116\Sample_backup_2018_01_17_080001_0131627.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10,NORECOVERY
Go

RESTORE LOG [Sample] 
FROM  DISK = N'E:\DB-File\Database Backup\Sample-DB Backup-20180116\Sample_backup_2018_01_17_100001_4794303.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10,NORECOVERY
GO

RESTORE DATABASE [Sample] WITH RECOVERY
Go
-- 含事务日志还原 【End】












