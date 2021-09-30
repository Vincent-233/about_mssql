------------------------------------------------------------------
--                          HASHBYTES
------------------------------------------------------------------
-- all hash algorithms other than SHA2_256 and SHA2_512 are deprecated
SELECT 
	HASHBYTES('SHA2_256','test')  -- return a 256 bit varbinary  0x....
   ,HASHBYTES('SHA2_512','test'); -- return a 512 bit varbinary  0x....


-- only support a single parameter with data type varchar, nvarchar, varbinary
SELECT type,HASHBYTES('SHA2_256', [type])
FROM master..spt_values;


-- workaround for hash multiple columns: `for xml raw`
SELECT
     a.*
    ,(SELECT a.* FOR XML RAW) AS row_xml_raw
    ,HASHBYTES('SHA2_256',(SELECT a.* FOR XML RAW)) AS hash_row_xml_raw
    ,HASHBYTES('SHA2_256',CAST((SELECT a.* FOR XML RAW) AS varchar(8000))) AS hash_row_xml_raw_varchar_8000
FROM master..spt_values AS a;


/*
    - [compare with checksum/binary_checksum](https://www.indie-dev.at/2020/01/15/checksum-vs-binary_checksum-vs-hashbytes/)
*/