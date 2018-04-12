-- Declaración de variables
declare @cmd nvarchar(4000)	
declare @cmd2 nvarchar(4000)
declare @cmd3 nvarchar(4000)
declare @cmd4 nvarchar(4000)	
declare @cmd5 nvarchar(4000)	
declare @cmd6 nvarchar(4000)				
DECLARE @nameTabla varchar(256)							
DECLARE @pattern varchar(256) = 'FY1617%Data%4G%%H2%' -- Queremos recorrer las BBDD que tengan este formato	
--DECLARE @pattern varchar(256) = 'OSP1617%Data%4G%%H2%'			
DECLARE @nameBD varchar(256)				
declare @it2 bigint				
declare @MaxBBDD bigint					
declare @MaxTab bigint	
declare @bbdd varchar(256)	

-- Inicializamos @it2 a 1					
set @it2 = 1	

-- Eliminamos las posibles tamblas temporales ya creadas				
exec sp_lcc_dropifexists '_tmp_BBDD' 	
exec sp_lcc_dropifexists '_tmp_YOI_1691_CE'
exec sp_lcc_dropifexists '_tmp_YOI_1691_NC'
exec sp_lcc_dropifexists '_tmp_YOI_1655_CE'
exec sp_lcc_dropifexists '_tmp_YOI_1655_NC'
exec sp_lcc_dropifexists '_tmp_YOI_126_CE'
exec sp_lcc_dropifexists '_tmp_YOI_126_NC'

-- Creamos la tabla donde vamos a incluir la información de la consulta	
create table _tmp_YOI_1691_CE (CollectionName char (50), [Throughput_DL_CE] float, [Nº_TestId_DL_CE] int, [Throughput_UL_CE] float, [Nº_TestId_UL_CE] int)
create table _tmp_YOI_1691_NC (CollectionName char (50), [Throughput_DL_NC] float, [Nº_TestId_DL_NC] int, [Throughput_UL_NC] float, [Nº_TestId_UL_NC] int)
create table _tmp_YOI_1655_CE (CollectionName char (50), [Throughput_DL_CE] float, [Nº_TestId_DL_CE] int, [Throughput_UL_CE] float, [Nº_TestId_UL_CE] int)
create table _tmp_YOI_1655_NC (CollectionName char (50), [Throughput_DL_NC] float, [Nº_TestId_DL_NC] int, [Throughput_UL_NC] float, [Nº_TestId_UL_NC] int)
create table _tmp_YOI_126_CE (CollectionName char (50), [Throughput_DL_CE] float, [Nº_TestId_DL_CE] int, [Throughput_UL_CE] float, [Nº_TestId_UL_CE] int)
create table _tmp_YOI_126_NC (CollectionName char (50), [Throughput_DL_NC] float, [Nº_TestId_DL_NC] int, [Throughput_UL_NC] float, [Nº_TestId_UL_NC] int)

-- Arrancamos la consulta 				
select IDENTITY(int,1,1) id,name				
into _tmp_BBDD -- Introduces en una tabla las BBDD		
from sys.databases	-- Todas las BBDD del sistema
where name like @pattern	
and name not like 'FY1617_Data_Main_4G_H2'
	
				
select @MaxBBDD = MAX(id) 				
from _tmp_BBDD				
				
while @it2 <= @MaxBBDD	
begin				
				
	select @nameBD = name			
	from _tmp_BBDD			
	where id =@it2			
	print 'Nombre de la bbdd:  ' + @nameBD			
	
	--Lo metemos en una variable cmd para poder pintarla posteriormente y así detectar si en esta parte del código dinámico estamos haciendo algo mal
	
	--Frecuencia 1691
	set @cmd='insert into _tmp_YOI_1691_CE 
				select t1.CollectionName, t1.Throughput_DL_CE, t1.[Nº_TestId_DL_CE], t2.Throughput_UL_CE, t2.[Nº_TestId_UL_CE]
				from
					(SELECT d.CollectionName, AVG(d.Throughput) "Throughput_DL_CE", count(d.TestId) "Nº_TestId_DL_CE"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_DL] d, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (d.TestId=t.TestId) and t.valid=1 and d.MNC=04 and d.earfcn_ini in (1691) and d.info like ''%Completed%'' and d.TestType like ''DL_CE''
						GROUP BY d.CollectionName) t1

					FULL JOIN

					(SELECT u.CollectionName, AVG(u.Throughput) "Throughput_UL_CE", count(u.TestId) "Nº_TestId_UL_CE"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_UL] u, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (u.TestId=t.TestId) and t.valid=1 and u.MNC=04 and u.earfcn_ini in (1691) and u.info like ''%Completed%'' and u.TestType like ''UL_CE''
						GROUP BY u.CollectionName) t2

					ON t1.collectionname = t2.collectionname

				WHERE Throughput_UL_CE>Throughput_DL_CE
				ORDER by t1.CollectionName'

	set @cmd2='insert into _tmp_YOI_1691_NC 
				select t1.CollectionName, t1.Throughput_DL_NC, t1.[Nº_TestId_DL_NC], t2.Throughput_UL_NC, t2.[Nº_TestId_UL_NC]
				from
					(SELECT d.CollectionName, AVG(d.Throughput) "Throughput_DL_NC", count(d.TestId) "Nº_TestId_DL_NC"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_DL] d, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (d.TestId=t.TestId) and t.valid=1 and d.MNC=04 and d.earfcn_ini in (1691) and d.info like ''%Completed%'' and d.TestType like ''DL_NC''
						GROUP BY d.CollectionName) t1

					FULL JOIN

					(SELECT u.CollectionName, AVG(u.Throughput) "Throughput_UL_NC", count(u.TestId) "Nº_TestId_UL_NC"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_UL] u, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (u.TestId=t.TestId) and t.valid=1 and u.MNC=04 and u.earfcn_ini in (1691) and u.info like ''%Completed%'' and u.TestType like ''UL_NC''
						GROUP BY u.CollectionName) t2

					ON t1.collectionname = t2.collectionname

				WHERE Throughput_UL_NC>Throughput_DL_NC
				ORDER by t1.CollectionName'

	--Frecuencia 1655
	set @cmd3='insert into _tmp_YOI_1655_CE 
				select t1.CollectionName, t1.Throughput_DL_CE, t1.[Nº_TestId_DL_CE], t2.Throughput_UL_CE, t2.[Nº_TestId_UL_CE]
				from
					(SELECT d.CollectionName, AVG(d.Throughput) "Throughput_DL_CE", count(d.TestId) "Nº_TestId_DL_CE"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_DL] d, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (d.TestId=t.TestId) and t.valid=1 and d.MNC=04 and d.earfcn_ini in (1655) and d.info like ''%Completed%'' and d.TestType like ''DL_CE''
						GROUP BY d.CollectionName) t1

					FULL JOIN

					(SELECT u.CollectionName, AVG(u.Throughput) "Throughput_UL_CE", count(u.TestId) "Nº_TestId_UL_CE"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_UL] u, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (u.TestId=t.TestId) and t.valid=1 and u.MNC=04 and u.earfcn_ini in (1655) and u.info like ''%Completed%'' and u.TestType like ''UL_CE''
						GROUP BY u.CollectionName) t2

					ON t1.collectionname = t2.collectionname

				WHERE Throughput_UL_CE>Throughput_DL_CE
				ORDER by t1.CollectionName'

	set @cmd4='insert into _tmp_YOI_1655_NC 
				select t1.CollectionName, t1.Throughput_DL_NC, t1.[Nº_TestId_DL_NC], t2.Throughput_UL_NC, t2.[Nº_TestId_UL_NC]
				from
					(SELECT d.CollectionName, AVG(d.Throughput) "Throughput_DL_NC", count(d.TestId) "Nº_TestId_DL_NC"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_DL] d, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (d.TestId=t.TestId) and t.valid=1 and d.MNC=04 and d.earfcn_ini in (1655) and d.info like ''%Completed%'' and d.TestType like ''DL_NC''
						GROUP BY d.CollectionName) t1

					FULL JOIN

					(SELECT u.CollectionName, AVG(u.Throughput) "Throughput_UL_NC", count(u.TestId) "Nº_TestId_UL_NC"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_UL] u, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (u.TestId=t.TestId) and t.valid=1 and u.MNC=04 and u.earfcn_ini in (1655) and u.info like ''%Completed%'' and u.TestType like ''UL_NC''
						GROUP BY u.CollectionName) t2

					ON t1.collectionname = t2.collectionname

				WHERE Throughput_UL_NC>Throughput_DL_NC
				ORDER by t1.CollectionName'

	--Frecuencia 126
	set @cmd5='insert into _tmp_YOI_126_CE 
				select t1.CollectionName, t1.Throughput_DL_CE, t1.[Nº_TestId_DL_CE], t2.Throughput_UL_CE, t2.[Nº_TestId_UL_CE]
				from
					(SELECT d.CollectionName, AVG(d.Throughput) "Throughput_DL_CE", count(d.TestId) "Nº_TestId_DL_CE"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_DL] d, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (d.TestId=t.TestId) and t.valid=1 and d.MNC=04 and d.earfcn_ini in (126) and d.info like ''%Completed%'' and d.TestType like ''DL_CE''
						GROUP BY d.CollectionName) t1

					FULL JOIN

					(SELECT u.CollectionName, AVG(u.Throughput) "Throughput_UL_CE", count(u.TestId) "Nº_TestId_UL_CE"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_UL] u, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (u.TestId=t.TestId) and t.valid=1 and u.MNC=04 and u.earfcn_ini in (126) and u.info like ''%Completed%'' and u.TestType like ''UL_CE''
						GROUP BY u.CollectionName) t2

					ON t1.collectionname = t2.collectionname

				WHERE Throughput_UL_CE>Throughput_DL_CE
				ORDER by t1.CollectionName'

	set @cmd6='insert into _tmp_YOI_126_NC 
				select t1.CollectionName, t1.Throughput_DL_NC, t1.[Nº_TestId_DL_NC], t2.Throughput_UL_NC, t2.[Nº_TestId_UL_NC]
				from
					(SELECT d.CollectionName, AVG(d.Throughput) "Throughput_DL_NC", count(d.TestId) "Nº_TestId_DL_NC"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_DL] d, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (d.TestId=t.TestId) and t.valid=1 and d.MNC=04 and d.earfcn_ini in (126) and d.info like ''%Completed%'' and d.TestType like ''DL_NC''
						GROUP BY d.CollectionName) t1

					FULL JOIN

					(SELECT u.CollectionName, AVG(u.Throughput) "Throughput_UL_NC", count(u.TestId) "Nº_TestId_UL_NC"
						FROM ' + @nameBD+'.[dbo].[Lcc_Data_HTTPTransfer_UL] u, ' + @nameBD+'.[dbo].[TestInfo] t
						WHERE (u.TestId=t.TestId) and t.valid=1 and u.MNC=04 and u.earfcn_ini in (126) and u.info like ''%Completed%'' and u.TestType like ''UL_NC''
						GROUP BY u.CollectionName) t2
                    
					ON t1.collectionname = t2.collectionname

				WHERE Throughput_UL_NC>Throughput_DL_NC
				ORDER by t1.CollectionName'

	
				

	--print @cmd
	--print @cmd2
	--print @cmd3
	--print @cmd4
	--print @cmd5
	--print @cmd6
			
	exec (@cmd)
	exec (@cmd2) 
	exec (@cmd3) 
	exec (@cmd4)
	exec (@cmd5) 
	exec (@cmd6) 
	
				
	set @it2 = @it2 +1			
end				


-- Abrimos la tabla  temporal con la información				
select * from _tmp_BBDD	--BBDD con entidades afectadas
select * from _tmp_YOI_1691_CE 
select * from _tmp_YOI_1691_NC where collectionname like '%barcelona%' order by collectionname
select * from _tmp_YOI_1655_CE
select * from _tmp_YOI_1655_NC
select * from _tmp_YOI_126_CE 
select * from _tmp_YOI_126_NC 





-- Al terminar la consulta eliminamos las tablas temporales				
exec sp_lcc_dropifexists '_tmp_BBDD'
exec sp_lcc_dropifexists '_tmp_YOI_1691_CE'
exec sp_lcc_dropifexists '_tmp_YOI_1691_NC'				
exec sp_lcc_dropifexists '_tmp_YOI_1655_CE'
exec sp_lcc_dropifexists '_tmp_YOI_1655_NC'
exec sp_lcc_dropifexists '_tmp_YOI_126_CE'
exec sp_lcc_dropifexists '_tmp_YOI_126_NC'	

use FY1617_Data_Main_4G_H2
select distinct collectionname
from filelist	
		
		

