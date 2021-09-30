------------------------------------------------------------------
--                      CHECKSUM / BINARY CHECKSUM
------------------------------------------------------------------
----- ## expression		   
SELECT CHECKSUM('abc')		   --> 34400
      ,CHECKSUM('aBC')		   --> 34400      (same with above, checksum is case in-sensitive, same compare rules as = operator)
	  ,BINARY_CHECKSUM('abc')  --> 26435
	  ,BINARY_CHECKSUM('aBC')  --> 25955      (not the same with above, binary_checksum is case sensitive)
	  ,CHECKSUM(123.45)        --> -358698202
	  ,CHECKSUM(-123.45)	   --> -358698202 (same with above)


----- ## multiple columns / expression
SELECT CHECKSUM(Name,ProductNumber,MakeFlag,FinishedGoodsFlag,Color,SafetyStockLevel,ReorderPoint)
FROM AdventureWorks2012.Production.Product;


----- ## entire rows
/* Error: Argument data type xml is invalid for argument 10 of checksum function. */
-- checksum return error if encounter noncomparable data type, such as: cursor, image, ntextm, text, xml 
SELECT CHECKSUM(*)
FROM AdventureWorks2012.Person.Person;

SELECT 
	 -- BINARY_CHECKSUM will ignore noncomparable data type
	 BINARY_CHECKSUM(*) AS binary_checksum_a
     -- all columns except `Demographics` which is xml type (result is the same with above)
	,BINARY_CHECKSUM(BusinessEntityID,PersonType,NameStyle,Title,FirstName,MiddleName,LastName,Suffix,EmailPromotion,AdditionalContactInfo,rowguid,ModifiedDate) AS binary_checksum_b
FROM AdventureWorks2012.Person.Person;

SELECT CHECKSUM(*)
FROM AdventureWorks2012.Production.Product;


----- ## CHECKSUM automatically ignore dash / nchar(45)
SELECT CHECKSUM(N'abc', N' ', N'xyz')        --> 1126857523
      ,CHECKSUM(N'abc', N'-',N'xyz')         --> 1126857523 ( same as above )
	  ,BINARY_CHECKSUM(N'abc', N'', N'xyz')	 --> 6765802
      ,BINARY_CHECKSUM(N'abc', N'-',N'xyz'); --> 6766138

/*
	Other Notes:
		- compared with MD5, checksum/binary_checksum has relatively high possibility of hash collision
		- it's more easy to use and support multiple parameters and data types
		- ouput of checksum and binary_checksum are different so don't compare output between them
*/



