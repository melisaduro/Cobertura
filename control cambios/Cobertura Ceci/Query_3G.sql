--USE [master]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_3G_Query]    Script Date: 03/10/2017 15:59:35 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--ALTER procedure [dbo].[sp_MDD_Coverage_3G_Query] (
--		-- Variables de entrada
--		@provincia as varchar(256),			-- si NED: '%%',	si paso1: valor
--		@ciudad as varchar(256),			-- si NED: valor,	si paso1: '%%'				
--		@simOperator as int,
--		--@umbralIndoor as int, 'Si se quiere normalizar a partir de cierto umbral
--		@Date as varchar (256),
--		@Road as int,
--		@Report as varchar (256)
--		)
--as

-----------------------------
----- Testing Variables -----
-----------------------------

--use FY1718_VOICE_REST_4G_H1_27
--declare @ciudad as varchar(256) = 'SITGES'
--use FY1718_VOICE_REST_4G_H1_13
--declare @ciudad as varchar(256) = 'ALCORCON'
use FY1718_VOICE_VALENCIA_4G_H1
declare @ciudad as varchar(256) = 'VALENCIA'
declare @Road as int = 0
declare @Report as varchar (256)= 'MUN'




CREATE TABLE #cuad_50_50(
	[Longitud_50m] [float] NULL,
	[Latitud_50m] [float] NULL,
	[frecuencia] [int] NULL,
	[operator] [varchar](255) NULL,
	[SC] [int] NULL,
	[RSCP_Outdoor] [float] NULL,
	[RSCP_Indoor] [float] NULL,
	[EcIo_max] [float] NULL,
	[PcobInd] [float] NULL,
	[PcobInd_Band] [float] NULL,
	[PcobInd_Channel] [float] NULL,
	[num_pilots] [int] NULL,
	[num_Pilots_Band] [int] NULL,
	[num_Pilots_Channel] [int] NULL,
	[ind_ord] [bigint] NULL,
	[ind_ord_operator] [bigint] NULL,
	[ind_ord_band] [bigint] NULL,
	[NoPolluters] [int] NULL,
	[Polluters] [int] NULL,
	[Cuadricula_Polluter] [int] NULL,
	[band] [varchar] (255) NULL,
	--[RSCP1] [float] NULL,
	--[SC1] [float] NULL, 
	[RSCP2] [float] NULL,
	[SC2] [float] NULL, 
	[RSCP3] [float] NULL,
	[SC3] [float] NULL,
	[RSCP4] [float] NULL,
	[SC4] [float] NULL,
	[RSCP5] [float] NULL,
	[SC5] [float] NULL
)


exec sp_lcc_dropifexists '#cober_level_50'

CREATE TABLE #cober_level_50(
	[longitude] [float] NULL,
	[latitude] [float] NULL,
	[lonid] [float] NULL,
	[latid] [float] NULL,
	[Channel] [int] NULL,
	[SCode] [int] NULL,
	[rscp_avg] [float] NULL,
	[EcIo_avg] [float] NULL

)


--Declaramos la tabla a usar
declare @GridTable as varchar (256)

If @Report = 'VDF'
begin
	Set @GridTable = 'lcc_position_Entity_List_Vodafone'
end

Else If @Report = 'OSP'
begin
	Set @GridTable = 'lcc_position_Entity_List_Orange'
end

Else If @Report = 'MUN'
begin
	Set @GridTable = 'lcc_position_Entity_List_Municipio'
end

Else If @Report = 'ROAD'
begin
	Set @GridTable = 'lcc_position_Entity_List_Roads'
end

-- ***************************************************************************************
-- DGP 03/11/2015: Se crea tabla con la info de polución por cuadricula de 50x50
-- ***************************************************************************************
--------------------------------------------------------------------------------
-- Tabla con niveles de señal por cudricula de 50 y frecuencia 
--------------------------------------------------------------------------------

if @road=0
begin

	insert into #cober_level_50
	exec ('
	select 
		--l.sessionid,
		(l.lonid/2224.0)*(1/(cos(2*pi()*l.latid/(2224.0*360)))) as longitude,
		l.latid/2224.0 as latitude,
		l.lonid,  --LonID parcela 50x50
		l.latid,							       --LatID parcela 50x50
		l.Channel,
		l.SCode,
		10*LOG10(AVG(POWER(CAST(10 AS float), (l.RSCP_Median)/10.0))) as rscp_avg, 
		10*LOG10(AVG(POWER(CAST(10 AS float), (l.EcI0_Median)/10.0))) as EcIo_avg    

	from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW l,
		'+ @GridTable +' b
	where  l.lonid=b.lonid and l.latid=b.latid
		and b.[entity_name] = '''+@ciudad+''' 
		and b.[type] in (''Urban'', ''Indoor'')
	group by 
		l.lonid,
		l.latid,
		l.Channel,
		l.SCode'
	)

end

else

begin
	insert into #cober_level_50
	exec ('
	select 
		--l.sessionid,
		(l.lonid/2224.0)*(1/(cos(2*pi()*l.latid/(2224.0*360)))) as longitude,
		l.latid/2224.0 as latitude,
		l.lonid,  --LonID parcela 50x50
		l.latid,							       --LatID parcela 50x50
		l.Channel,
		l.SCode,
		10*LOG10(AVG(POWER(CAST(10 AS float), (l.RSCP_Median)/10.0))) as rscp_avg, 
		10*LOG10(AVG(POWER(CAST(10 AS float), (l.EcI0_Median)/10.0))) as EcIo_avg    

	from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW l,
		'+ @GridTable +' b
	where  l.lonid=b.lonid and l.latid=b.latid
		and b.[entity_name] = '''+@ciudad+'''
		and b.[type] in (''Road'', ''RW-Road'', ''RW'')
	group by 
		l.lonid,
		l.latid,
		l.Channel,
		l.SCode'
	)

end

-------------------------------------------------------------------------------------------
-- Tabla con info de polluters en cuadriculas de 50x50 --
-------------------------------------------------------------------------------------------

select  s.longitude, s.latitude, s.channel,
	--master.dbo.fn_lcc_longitude2lonid (s.longitude, s.latitude) as lonid,
	--master.dbo.fn_lcc_latitude2latid (s.latitude) as latid,  /*Contamos Polluters por parcelas de 50x50*/
	s.lonid,s.latid,
	sum(s.polluter) as Polluters,
    sum(s.NoPolluter) as NoPolluters,
    case when SUM(s.polluter)>= 4 then 1 else 0 end as Cuadricula_Polluter,
	max(r.[1]) RSCP1, max(s.[1]) SC1, 
	max(r.[2]) RSCP2, max(s.[2]) SC2, 
	max(r.[3]) RSCP3, max(s.[3]) SC3,
	max(r.[4]) RSCP4, max(s.[4]) SC4,
	max(r.[5]) RSCP5, max(s.[5]) SC5
  
   into #Pilot_Pollution_50x50
  
   from 
		  (select w.lonid,w.latid,
			w.longitude, w.latitude, 
		   w.Channel,w.SCode, w.Scode as SCode_Ref,th.bestserver,
		   (10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0)))) as Rscp,
		   case when (10*LOG10(AVG(POWER(CAST(10 AS float), (w.rscp_avg)/10.0)))) = th.bestserver then 1 else 0 end BestServ,
		   case when ((10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0))))<(th.BestServer) and 
		   (10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0))))> (th.bestserver -10)) then 1 else 0 end as Polluter,
		   case when ((10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0))))<(th.BestServer) and 
		   (10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0))))< (th.bestserver -10)) then 1 else 0 end as NoPolluter,

		   row_number () over (partition by w.longitude, w.latitude, w.Channel order by (10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0)))) desc) as [Rank]
            
			from
			   (select
				   m.lonid,m.latid,
				   m.longitude,m.latitude,m.Channel,
				   case when max(m.Rscp_medio) > -90 then max(m.Rscp_medio) else 0 end As BestServer /*Calculamos las BestServer*/

			   

					 from 
					   (Select  s.longitude,  /*calculamos el RSCP medio por cuadricula y SC*/
								s.latitude,
								s.lonid,s.latid,
								s.SCode,s.Channel,
								(10*LOG10(AVG(POWER(CAST(10 AS float), (s.rscp_avg)/10.0)))) as Rscp_medio
              
						 from #cober_level_50 s
       
						 Group by s.longitude,
								  s.latitude,
								  s.lonid,s.latid,
								  s.Channel,
								  s.SCode) m

        			Group by m.lonid,m.latid,m.longitude,m.latitude,m.Channel
		 )th,      
    
			 #cober_level_50 w       

		Where  th.latitude =  w.latitude
			   and th.longitude = w.longitude
			   and th.Channel = w.Channel
			   and th.lonid =  w.lonid and th.latid =  w.latid
		Group by w.lonid,w.latid,w.longitude,
			   w.latitude,
			   w.Channel,th.BestServer,w.SCode
		) l pivot (max(SCode_Ref) for [rank] in ([1],[2],[3],[4],[5])) s,

		(select w.lonid,w.latid,
			w.longitude, w.latitude, 
		   w.Channel,w.SCode,th.bestserver,
		   (10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0)))) as Rscp,
		   case when (10*LOG10(AVG(POWER(CAST(10 AS float), (w.rscp_avg)/10.0)))) = th.bestserver then 1 else 0 end BestServ,
		   case when ((10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0))))<(th.BestServer) and 
		   (10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0))))> (th.bestserver -10)) then 1 else 0 end as Polluter,
		   case when ((10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0))))<(th.BestServer) and 
		   (10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0))))< (th.bestserver -10)) then 1 else 0 end as NoPolluter,

		   row_number () over (partition by w.longitude, w.latitude, w.Channel order by (10*LOG10(AVG(POWER(CAST(10 AS float),(w.rscp_avg)/10.0)))) desc) as [Rank]
            
			from
			   (select
				   m.lonid,m.latid,
				   m.longitude,m.latitude,m.Channel,
				   case when max(m.Rscp_medio) > -90 then max(m.Rscp_medio) else 0 end As BestServer /*Calculamos las BestServer*/

			   

					 from 
					   (Select  s.longitude,  /*calculamos el RSCP medio por cuadricula y SC*/
								s.latitude,
								s.lonid,s.latid,
								s.SCode,s.Channel,
								(10*LOG10(AVG(POWER(CAST(10 AS float), (s.rscp_avg)/10.0)))) as Rscp_medio
              
						 from #cober_level_50 s
       
						 Group by s.lonid,s.latid,
								s.longitude,
								  s.latitude,
								  s.Channel,
								  s.SCode) m

        			Group by m.lonid,m.latid,m.longitude,m.latitude,m.Channel
		 )th,      
    
			 #cober_level_50 w       

		Where  th.latitude =  w.latitude
			   and th.longitude = w.longitude
			   and th.Channel = w.Channel
			   and th.lonid =  w.lonid and th.latid =  w.latid
		Group by w.lonid,w.latid, w.longitude,
			   w.latitude,
			   w.Channel,th.BestServer,w.SCode
		) l pivot (max(rscp) for [rank] in ([1],[2],[3],[4],[5])) r


where r.longitude=s.longitude and r.latitude=s.latitude 
and s.channel=r.channel and r.SCode=s.SCode
and r.lonid =  s.lonid and r.latid =  s.latid

Group by s.longitude, s.latitude, s.channel,s.lonid,s.latid
order by  s.longitude, s.latitude,s.channel


 -- ***************************************************************************************


------------------------------------------------------------------------------
--tabla de las frecuencias por cuadrícula
------------------------------------------------------------------------------

--Valores de normalización para la cobertura Indoor respecto a la banda 900
declare @normalizacionBand2100 as float=0 -- normalizando a banda 900:-3   -- Sin simplificar seía -3.3

--Valores maximos por earfcn en parcelas 50x50

if @road=0
begin
	
	insert into #cuad_50_50
	exec ('
	select
		c.longitude as Longitud_50m,
		c.latitude as Latitud_50m,
		c.Channel as frecuencia,
		sof.ServingOperator as operator,
		c.SCode as SC,
		c.RSCP_median as RSCP_Outdoor,
		case when sof.Band = ''UMTS2100'' then c.RSCP_median+'+@normalizacionBand2100+'	  --U2100
			 else c.RSCP_median	 	  	  	  	  	  	  	  	  	  	  	  --U900
		end as RSCP_Indoor,
		c.EcI0_median as EcIo_max,
		c.PcobInd_voice as PcobInd,
		c.PcobInd_voice_Band as PcobInd_Band,
		c.PcobInd_voice_Channel as PcobInd_Channel,
		c.num_pilots,
		c.num_Pilots_Band,
		c.num_Pilots_Channel,
		1 as ind_ord,
		c.operator_ord as ind_ord_operator,
		c.operator_band_ord as ind_ord_band,
		isnull(pol.NoPolluters,0) as NoPolluters,
		isnull(pol.Polluters,0) as Polluters,
		isnull(pol.Cuadricula_Polluter,0) as Cuadricula_Polluter,
		c.band,
		--pol.RSCP1, pol.SC1, 
		pol.RSCP2, pol.SC2, 
		pol.RSCP3, pol.SC3,
		pol.RSCP4, pol.SC4,
		pol.RSCP5, pol.SC5

	from '+ @GridTable +' b,
		lcc_UMTSScanner_50x50_ProbCobIndoor_VALENCIA_NEW c
		LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof on c.Channel=sof.Frequency
	-- ***************************************************************************************
	-- DGP 03/11/2015: Se agrega la info de polución por cuadricula de 50x50
	-- ***************************************************************************************
		LEFT OUTER JOIN #Pilot_Pollution_50x50 pol on pol.lonid=c.lonid and pol.latid=c.latid and c.Channel=pol.channel
	-- ***************************************************************************************

	where b.lonid=c.lonid and b.latid=c.latid
	and b.[entity_name] = '''+@ciudad+''' 
	and b.[type] in (''Urban'', ''Indoor'')

	group by c.longitude, c.latitude, c.Channel, sof.ServingOperator, c.SCode, c.RSCP_median,
		case when sof.Band = ''UMTS2100'' then c.RSCP_median+'+@normalizacionBand2100+'	  --U2100
			 else c.RSCP_median	 	  	  	  	  	  	  	  	  	  	  	  --U900
		end,
		c.EcI0_median, c.PcobInd_Voice, c.PcobInd_voice_Band,c.PcobInd_voice_Channel,
		c.num_pilots, c.num_Pilots_Band, c.num_Pilots_Channel,
		c.operator_ord,	c.operator_band_ord,
		isnull(pol.NoPolluters,0), isnull(pol.Polluters,0),
		isnull(pol.Cuadricula_Polluter,0), c.band, pol.RSCP2, pol.SC2, pol.RSCP3, pol.SC3, pol.RSCP4, pol.SC4,
		pol.RSCP5, pol.SC5'
	)

end

else
begin

	insert into #cuad_50_50
	exec ('
	select 
		c.longitude as Longitud_50m,
		c.latitude as Latitud_50m,
		c.Channel as frecuencia,
		sof.ServingOperator as operator,
		c.SCode as SC,
		c.RSCP_median as RSCP_Outdoor,
		case when sof.Band = ''UMTS2100'' then c.RSCP_median+'+@normalizacionBand2100+'	  --U2100
			 else c.RSCP_median	 	  	  	  	  	  	  	  	  	  	  	  --U900
		end as RSCP_Indoor,
		c.EcI0_median as EcIo_max,
		c.PcobInd_Voice as PcobInd,
		c.PcobInd_voice_Band as PcobInd_Band,
		c.PcobInd_voice_Channel as PcobInd_Channel,
		c.num_pilots,
		c.num_Pilots_Band,
		c.num_Pilots_Channel,
		1 as ind_ord,
		c.operator_ord as ind_ord_operator,
		c.operator_band_ord as ind_ord_band,
		isnull(pol.NoPolluters,0) as NoPolluters,
		isnull(pol.Polluters,0) as Polluters,
		isnull(pol.Cuadricula_Polluter,0) as Cuadricula_Polluter,
		c.band,
		--pol.RSCP1, pol.SC1, 
		pol.RSCP2, pol.SC2, 
		pol.RSCP3, pol.SC3,
		pol.RSCP4, pol.SC4,
		pol.RSCP5, pol.SC5

	from '+ @GridTable +' b,
		lcc_UMTSScanner_50x50_ProbCobIndoor_VALENCIA_NEW c
		LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof on c.Channel=sof.Frequency
	-- ***************************************************************************************
	-- DGP 03/11/2015: Se agrega la info de polución por cuadricula de 50x50
	-- ***************************************************************************************
		LEFT OUTER JOIN #Pilot_Pollution_50x50 pol on pol.lonid=c.lonid and pol.latid=c.latid and c.Channel=pol.channel
	-- ***************************************************************************************

	where b.lonid=c.lonid and b.latid=c.latid
	and b.[entity_name] = '''+@ciudad+'''
	and b.[type] in (''Road'', ''RW-Road'', ''RW'')

	group by 
		c.longitude, c.latitude, c.Channel, sof.ServingOperator, c.SCode, c.RSCP_median,
		case when sof.Band = ''UMTS2100'' then c.RSCP_median+'+@normalizacionBand2100+'	  --U2100
			 else c.RSCP_median	 	  	  	  	  	  	  	  	  	  	  	  --U900
		end,
		c.EcI0_median, c.PcobInd_Voice, c.PcobInd_voice_Band,c.PcobInd_voice_Channel,
		c.num_pilots, c.num_Pilots_Band, c.num_Pilots_Channel,
		c.operator_ord,	c.operator_band_ord,
		isnull(pol.NoPolluters,0), isnull(pol.Polluters,0),
		isnull(pol.Cuadricula_Polluter,0), c.band, pol.RSCP2, pol.SC2, pol.RSCP3, pol.SC3, pol.RSCP4, pol.SC4,
		pol.RSCP5, pol.SC5'
	)

end

------------------------------------------------------------------------------
-- guardar en una tabla por provincia para que no se sobreescriban los datos
------------------------------------------------------------------------------
--Para las provincias con más de una palabra
declare @ciudTable as varchar(256)=replace(replace(@ciudad,' ','_'),'-','_')
  
--if OBJECT_ID('lcc_cober3G_50x50_'+@ciudTable) is not null  exec ('drop table lcc_cober3G_50x50_'+@ciudTable)
exec ('sp_lcc_dropifexists ''lcc_cober3G_50x50_'+@ciudTable+'_'+@Report+'_VALENCIA_NEW''' )

exec (' select * into [lcc_cober3G_50x50_'+@ciudTable+'_'+@Report+'_VALENCIA_NEW] from #cuad_50_50')


  

drop table	#cuad_50_50, #cober_level_50, #Pilot_Pollution_50x50


select 'TABLE: lcc_cober3G_50x50_'+@ciudad+' created Successfully' as result
