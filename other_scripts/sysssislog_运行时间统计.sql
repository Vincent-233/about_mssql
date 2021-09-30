--------- 可以前台做成gantt图
-- ssis log of last x-th runing
declare @executionid uniqueidentifier,@last_run_order int = 1;
with cte_executionid as
(
	select executionid
	from (
		select row_number() over(order by id desc) as rn,executionid
		from dbo.sysssislog where message like '%%'
	) as a
	where a.rn = @last_run_order
)
SELECT
    a.computer
   ,a.operator
   ,a.source
   ,a.sourceid
   ,a.executionid
   ,a.starttime
   ,b.endtime
   ,DATEDIFF(SECOND, a.starttime, b.endtime) AS [duration(s)]
   ,CAST(ROUND(DATEDIFF(SECOND, a.starttime, b.endtime)/60.0,2) AS DECIMAL(18,2))  AS [duration(min)]
FROM dbo.sysssislog a
INNER JOIN dbo.sysssislog b
    ON a.source = b.source
        AND a.executionid = b.executionid
        AND a.event = 'OnPreExecute'
        AND b.event = 'OnPostExecute'
INNER JOIN cte_executionid c on a.executionid = c.executionid