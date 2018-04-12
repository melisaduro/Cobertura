select ciudad,
		max(date_ini) as date,
		'W' + cast(datepart(ww,max(date_ini)) as varchar(256)) as week 
from dashboard.[dbo].[lcc_executions_aggr]
where [aggr-entity-report-mnc] like '%coverage%'
group by ciudad
order by max(date_ini) desc