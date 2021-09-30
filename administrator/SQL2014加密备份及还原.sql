use master  
go  
--1.备份操作 
--创建主密钥  
create master key encryption by password = N'Hello@MyMasterKey'  
go  
  
--创建证书  
create certificate Mycertificate    
with subject = N'EnryptData certificate',    
start_date = N'20160101',    
expiry_date = N'20990101';    
go    
--备份主密钥  
backup master key   
to file = N'H:\Database\master_SMK1.key'     
encryption by password = N'Hello@MyMasterKey'  
go  

--备份证书和私钥  
backup certificate Mycertificate     
to file = N'H:\Database\Mycertificate.cer' --用于加密的证书备份路径    
with private key (     
    file = N'H:\Database\Mycertificate_saleskey.pvk' ,--用于解密证书私钥文件路径     
    encryption by password = N'Hello@Mycertificate' );--对私钥进行加密的密码    
go  

--证书加密备份数据库  
backup database PB  
to disk = N'h:\database\pb.bak'    
with    
    compression, stats = 10,   
    encryption     
    (    
    algorithm = aes_256,    
    server certificate = mycertificate    
    )  
go    
  
---2.以下异机还原操作，本机可省密钥和证书还原步骤
--还原主密钥  
USE master  
GO  
RESTORE MASTER KEY  
FROM FILE = N'h:\database\master_SMK1.key'  
DECRYPTION BY PASSWORD = N'Hello@MyMasterKey'  
ENCRYPTION BY PASSWORD = N'Hello@MyMasterKey' FORCE  
GO  
  
/*还原主密,两实例的服务启动账户必须相同，否则出现以下错误：  
  
消息 15317，级别 16，状态 2，第 22 行  
主密钥文件不存在或格式无效。  
The master key file does not exist or has invalid format  
*/  
  
  
--打开密钥  
OPEN MASTER KEY DECRYPTION BY PASSWORD = N'Hello@MyMasterKey'  
GO  
  
--还原证书  
CREATE CERTIFICATE Mycertificate     
FROM FILE = N'h:\database\Mycertificate.cer'     
WITH PRIVATE KEY (    
    FILE = N'h:\database\Mycertificate_saleskey.pvk',     
    DECRYPTION BY PASSWORD = 'Hello@Mycertificate');    
GO  
  
  
-- 再还原数据库，正常！  
USE [master]  
GO  
RESTORE DATABASE PB1  
FROM  DISK = N'h:\database\PB.bak'   
WITH  FILE = 1,  
MOVE N'HRE6IES_Data' TO N'h:\database\PB1.mdf', 
MOVE N'HRE6IES_Log' TO N'h:\database\PB_log.ldf',    
NOUNLOAD,  STATS = 5  
GO  

  
