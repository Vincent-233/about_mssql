-- 导出
bcp AdventureWorks2012.HumanResources.Department OUT D:\Department.txt -c -T -t\t

-- 导出（查询 queryout）
bcp "SELECT * FROM DBName.dbo.aBalance WHERE ExpiredDate > '20180501'" queryout D:\aBalance.txt -c -t\t -S 172.28.11.195 -U pwdx -P pwdxtem

-- 导入（无格式文件）
bcp AdventureWorks2012.dbo.Department_Copy IN D:\Department.txt -c -T -t\t

-- 导入（忽略表头，管道符分隔，从第二行开始导入）
bcp TestDB.dbo.Kids IN C:\Kids.csv -c -T -t"|" -S p7xyxy\BI -F 2

-- 生成 格式文件
bcp AdventureWorks2012.HumanResources.Department format nul -f D:\TestFormatFile.xml -c -x -T

--  格式文件导入 （bcp）
bcp AdventureWorks2012.dbo.Department_Test in D:\Department.txt -f D:\TestFormatFile.xml -T

-- 导入到远程服务器（bcp 含格式文件）
bcp TestDB.dbo.Department_Test in D:\Department.txt -f D:\TestFormatFile.xml -S WIN-XYXYXY\SQL2012,1433 -U sa -P pwd

-- 导入远程服务器（无格式文件）
bcp TestDB.dbo.Department IN D:\Department.txt -c -t\t -S 192.168.1.23,1433 -U xxxx_owner -P pwd

-- 格式文件导入（Bulk Insert）
BULK INSERT AdventureWorks2012.dbo.Department_Test
FROM 'D:\Department.txt'
WITH (FORMATFILE = 'D:\TestFormatFile.xml');

-- 导入模板
bcp {target_table} in {file_path} -c -T -t"|" -S {server_name} -F 2

-- 导入UTF-8编码的数据，-C 65001 指 UTF8
-- Versions prior to version 13 (SQL Server 2016 (13.x)) do not support code page 65001 (UTF-8 encoding). 
-- Versions beginning with 13 can import UTF-8 encoding to earlier versions of SQL Server.
bcp TestDB.dbo.Consumer in C:\consumer.csv -c -T -t, -S mysqlserver\BI -F 2 -C 65001



-- 格式文件：Record表示数据文件的列，Row表示数据库对应表的列
/*
<?xml version="1.0"?>
<BCPFORMAT xmlns="http://schemas.microsoft.com/sqlserver/2004/bulkload/format" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 <RECORD>
  <FIELD ID="1" xsi:type="CharTerm" TERMINATOR="\t" MAX_LENGTH="7"/>
  <FIELD ID="2" xsi:type="CharTerm" TERMINATOR="\t" MAX_LENGTH="100" COLLATION="SQL_Latin1_General_CP1_CI_AS"/>
  <FIELD ID="3" xsi:type="CharTerm" TERMINATOR="\t" MAX_LENGTH="100" COLLATION="SQL_Latin1_General_CP1_CI_AS"/>
  <FIELD ID="4" xsi:type="CharTerm" TERMINATOR="\r\n" MAX_LENGTH="24"/>
 </RECORD>
 <ROW>
  <COLUMN SOURCE="1" NAME="DepartmentID" xsi:type="SQLSMALLINT"/>
  <COLUMN SOURCE="2" NAME="Name" xsi:type="SQLNVARCHAR"/>
  <!-- <COLUMN SOURCE="3" NAME="GroupName" xsi:type="SQLNVARCHAR"/> -->
  <COLUMN SOURCE="4" NAME="ModifiedDate" xsi:type="SQLDATETIME"/>	
 </ROW>
</BCPFORMAT>
*/

--------- 本地格式（在无扩展字段或双字节字符的前提下可用，并可提升速度）
-- export to a native file 
bcp test_db.dbo.physcial_checkup out D:\Users\xxxx\Desktop\Temp\2014-Medical-native.dat -S xxx -n -T
-- import a native file
bcp test_db.dbo.physcial_checkup in D:\Users\xxxx\Desktop\Temp\2014-Medical-native.dat -S xxx -n -T

