use FY1718_Coverage_Union_H1

DECLARE @names TABLE(
  id   INT IDENTITY(1,1),
  name NVARCHAR(100) NULL
)

DECLARE @space TABLE(
  name     NVARCHAR(100) NULL,
  rows     CHAR(11),
  reserved NVARCHAR (15),
  data     NVARCHAR (18),
  indexes  NVARCHAR (18),
  unused   NVARCHAR (18)
)

DECLARE @ROWCOUNT INT
DECLARE @i INT = 1
DECLARE @str nvarchar(100)

INSERT INTO @names(name) SELECT name FROM sys.Tables where name like 'lcc_cober2G_50x50_%_MUN'
														or name like 'lcc_cober3G_50x50_%_MUN'
														or name like 'lcc_cober4G_50x50_%_MUN'
SET @ROWCOUNT = @@ROWCOUNT


WHILE @i <= @ROWCOUNT
BEGIN
  SELECT @str = name FROM @names WHERE id = @i
  INSERT INTO @space
  EXEC   sp_spaceused @str
  SET    @i += 1
END

--SELECT * FROM @space
--ORDER  BY CONVERT( BIGINT, rows ) DESC


select base.entidad,
	case when t2G.Tecn is not null then t2G.Tecn+'_' else '' end + case when t3G.Tecn is not null then t3G.Tecn+'_' else '' end + isnull(t4G.Tecn,'') as 'Tec',
	case when isnull(t2G.rows,0)>=isnull(t3G.rows,0) and isnull(t2G.rows,0)>=isnull(t4G.rows,0) then isnull(t2G.rows,0)
		when isnull(t3G.rows,0)>=isnull(t2G.rows,0) and isnull(t3G.rows,0)>=isnull(t4G.rows,0) then isnull(t3G.rows,0)
		else isnull(t4G.rows,0) end as 'Rows'
from (SELECT replace(replace(replace(replace(name,'lcc_cober2G_50x50_',''),'lcc_cober3G_50x50_',''),'lcc_cober4G_50x50_',''),'_MUN','') as entidad
	FROM @space
	group by replace(replace(replace(replace(name,'lcc_cober2G_50x50_',''),'lcc_cober3G_50x50_',''),'lcc_cober4G_50x50_',''),'_MUN','')) base
	left join
	(SELECT replace(replace(replace(replace(name,'lcc_cober2G_50x50_',''),'lcc_cober3G_50x50_',''),'lcc_cober4G_50x50_',''),'_MUN','') as entidad,
		'2G' as Tecn, rows
	FROM @space
	where name like '%2G%' and rows >0) t2G
	on base.entidad=t2G.entidad
	left join
	(SELECT replace(replace(replace(replace(name,'lcc_cober2G_50x50_',''),'lcc_cober3G_50x50_',''),'lcc_cober4G_50x50_',''),'_MUN','') as entidad,
		'3G' as Tecn, rows
	FROM @space
	where name like '%3G%' and rows >0) t3G
	on base.entidad=t3G.entidad
	left join
	(SELECT replace(replace(replace(replace(name,'lcc_cober2G_50x50_',''),'lcc_cober3G_50x50_',''),'lcc_cober4G_50x50_',''),'_MUN','') as entidad,
		'4G' as Tecn, rows
	FROM @space
	where name like '%4G%' and rows >0) t4G
	on base.entidad=t4G.entidad

