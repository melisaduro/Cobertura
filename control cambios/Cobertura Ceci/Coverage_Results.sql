--USE [master]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_Results]    Script Date: 03/10/2017 16:06:55 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO


--ALTER procedure [dbo].[sp_MDD_Coverage_Results]
--(
--	@entity as varchar(256),
--	@filter as varchar(256),
--    @sheet as varchar(256),
--    @operator as varchar(256),
--	@Report as varchar (256),
--	@RoadOrange as bit --CAC 26_04_2017: se añaden umbrales especiales para roads de Orange
--)
--as

--use FY1718_VOICE_REST_4G_H1_27
--declare @entity as varchar(256) = 'SITGES'
--use FY1718_VOICE_REST_4G_H1_13
--declare @entity as varchar(256) = 'ALCORCON'
use FY1718_VOICE_VALENCIA_4G_H1
declare @entity as varchar(256) = 'VALENCIA'

----Urbano
--declare @filter as varchar(256) = '''MAIN'', ''SMALLER'' , ''ADDON'', ''TOURISTIC'', ''ROC'''
----Rural
--declare @filter as varchar(256) = '''MAIN HIGHWAYS'', ''ROADS'' , ''RURAL'''
--Total
declare @filter as varchar(256) = '''MAIN'', ''SMALLER'' , ''ADDON'', ''TOURISTIC'', ''ROC'', ''MAIN HIGHWAYS'', ''ROADS'' , ''RURAL'''

declare @sheet as varchar(256) = 'Indoor'
--Outdoor	Indoor	Curves		Samples_Indoor	Samples_Outdoor

declare @Report as varchar(256) = 'MUN'
declare @RoadOrange as bit = 0



declare @ciudTable as varchar(256)=replace(replace(@entity,' ','_'),'-','_')            
declare @2G as varchar (256) = '[lcc_cober2G_50x50_' + @ciudTable + '_' + @Report+'_VALENCIA_NEW]'
declare @3G as varchar (256) = '[lcc_cober3G_50x50_' + @ciudTable + '_' + @Report+'_VALENCIA_NEW]'
declare @4G as varchar (256) = '[lcc_cober4G_50x50_' + @ciudTable + '_' + @Report+'_VALENCIA_NEW]'

declare @2GThres as varchar(10)
declare @3GThres as varchar(10)
declare @4GThres as varchar(10)

declare @cmd as varchar(max)
declare @cmd1 as varchar(max)

-- Inicializamos los umbrales
if  (@sheet='Indoor' or @sheet='Samples_Indoor')
begin
	if @RoadOrange=0
	begin
		--if @operator = 'Orange' 
		if @Report = 'OSP' or  @Report = 'MUN' 
		begin
			set @2GThres = '-65'
			set @3GThres = '-72'
			set @4GThres = '-90'
		end
		--else if @operator = 'Vodafone'
		else if @Report = 'VDF'
		begin
			set @2GThres = '-70'
			set @3GThres = '-80'
			set @4GThres = '-95'
		end		
	end
	else --CAC 26-04-207: Umbrales de roads de Orange (antes tenáin los mismos que el resto de scopes)
	begin
		set @2GThres = '-80'
		set @3GThres = '-85'
		set @4GThres = '-103'
	end
end
else if @sheet='Outdoor' or @sheet='Samples_Outdoor'
begin
	set @2GThres = '-90'
	set @3GThres = '-100'
	set @4GThres = '-113'
end

-- Seleccionamos por el tipo de hoja para mostrar los resultados
if @sheet = 'Curves'
begin
exec(
--print
	'
	select

			isnull(l.RSRP_LTE,-140) as RSRP_LTE,
			isnull(l.RSRP_LTE2600,-140) as RSRP_LTE2600,
			isnull(l.RSRP_LTE2100,-140) as RSRP_LTE2100,
			isnull(l.RSRP_LTE1800,-140) as RSRP_LTE1800,
			isnull(l.RSRP_LTE800,-140) as RSRP_LTE800,
			isnull(l.LTE,0) as LTE,
			isnull(l.LTE2600,0) as LTE2600,
			isnull(l.LTE2100,0) as LTE2100,
			isnull(l.LTE2100_BW5,0) as LTE2100_BW5,
			isnull(l.LTE2100_BW10,0) as LTE2100_BW10,
			isnull(l.LTE2100_BW15,0) as LTE2100_BW15,
			isnull(l.LTE1800,0) as LTE1800,
			isnull(l.LTE1800_BW10,0) as LTE1800_BW10,
			isnull(l.LTE1800_BW15,0) as LTE1800_BW15,
			isnull(l.LTE1800_BW20,0) as LTE1800_BW20,
			isnull(l.LTE800,0) as LTE800,
			isnull(l.LTE800_1800,0) as LTE800_1800,
			isnull(l.LTE800_2100,0) as LTE800_2100,
			isnull(l.LTE800_2600,0) as LTE800_2600,
			isnull(l.LTE1800_2100,0) as LTE1800_2100,
			isnull(l.LTE1800_2600,0) as LTE1800_2600,
			isnull(l.LTE2100_2600,0) as LTE2100_2600,
			isnull(l.LTE800_1800_2100,0) as LTE800_1800_2100,
			isnull(l.LTE800_1800_2600,0) as LTE800_1800_2600,
			isnull(l.LTE800_2100_2600,0) as LTE800_2100_2600,
			isnull(l.LTE1800_2100_2600,0) as LTE1800_2100_2600,
			isnull(l.BS_LTE,0) as BS_LTE,
			isnull(u.RSCP_UMTS,-140) as RSCP_UMTS,
			isnull(u.RSCP_UMTS2100,-140) as RSCP_UMTS2100,
			isnull(u.RSCP_UMTS900,-140) as RSCP_UMTS900,
			isnull(u.[% Pollution],0) as [% Pollution],
			isnull(u.[% Pollution BS],0) as [% Pollution BS],
			isnull(u.UMTS,0) as UMTS,
			isnull(u.UMTS2100,0) as UMTS2100,
			isnull(u.UMTS2100_F1,0) as UMTS2100_F1,
			isnull(u.UMTS2100_F2,0) as UMTS2100_F2,
			isnull(u.UMTS2100_F3,0) as UMTS2100_F3,			
			isnull(u.UMTS2100_Dual_Carrier,0) as UMTS2100_Dual_Carrier,
			isnull(u.UMTS2100_P1,0) as UMTS2100_P1,
			isnull(u.UMTS2100_P2,0) as UMTS2100_P2,
			isnull(u.UMTS2100_P3,0) as UMTS2100_P3,
			
			isnull(u.UMTS900,0) as UMTS900,
			isnull(u.UMTS900_F1,0) as UMTS900_F1,
			isnull(u.UMTS900_F2,0) as UMTS900_F2,
			isnull(u.UMTS900_P1,0) as UMTS900_P1,
			isnull(u.UMTS900_P2,0) as UMTS900_P2,
			
			isnull(u.BS_UMTS,0) as BS_UMTS,
			isnull(g.RxLev_2G,-110) as RxLev_2G,
			isnull(g.RxLev_GSM,-110) as RxLev_GSM,
			isnull(g.RxLev_DCS,-110) as RxLev_DCS,
			isnull(g.[2G],0) as [2G],
			isnull(g.GSM_DCS,0) as GSM_DCS,
			isnull(g.GSM,0) as GSM,
			isnull(g.DCS,0) as DCS,
			isnull(g.BS_GSM,0) as BS_GSM

	from
		(
			select operator as operator from '+@4G+' where operator is not null group by operator
			union
			select operator from '+@3G+' where operator is not null group by operator
			union
			select operator from '+@2G+' where operator is not null group by operator
		) o
		
		left join (
			select 
				gs.operator,
				--max(gci_signal.RxLev_2G) as RxLev_2G,
				--max(gci_signal_band.RxLev_GSM) as RxLev_GSM,
				--max(gci_signal_band.RxLev_DCS) as RxLev_DCS,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(gci_signal.RxLev_2G,0)))/10.0)*gci_signal.RSSI_Outdoor_Samples)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*(gs.Samples-gci_signal.RSSI_Outdoor_Samples)))/sum(gs.Samples)) as RxLev_2G,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(gci_signal_band.RxLev_GSM,0)))/10.0)*gci_signal_band.GSM_Samples)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*(gs.Samples-gci_signal_band.GSM_Samples)))/sum(gs.Samples)) as RxLev_GSM,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(gci_signal_band.RxLev_DCS,0)))/10.0)*gci_signal_band.DCS_Samples)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*(gs.Samples-gci_signal_band.DCS_Samples)))/sum(gs.Samples)) as RxLev_DCS,
				avg((gci.PcobInd * gci.PcobInd_Samples)/gs.Samples) [2G],
				avg((gci_band.GSM * gci_band.GSM_Samples)/gs.Samples) GSM,
				avg((gci_band.DCS * gci_band.DCS_Samples)/gs.Samples) DCS,
				--avg(gci.PcobInd) as [2G],
				--avg(gci_band.GSM) as GSM,
				--avg(gci_band.DCS) as DCS,
				max(gbs.BS_Number) as BS_GSM,
				avg((gci_band_both.GSM_DCS * gci_band_both.GSM_DCS_Samples)/gs.Samples) GSM_DCS

			from 
			(			
				select  gop.operator,
						count(g.samples) as Samples
				from
						(SELECT  1 as enlace,
								count(1) as samples
								
							FROM '+@2G+' g,
									agrids.dbo.lcc_parcelas lp
			 
									where g.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											and lp.entorno in ('+ @filter +')
							group by  g.longitud_50m, g.latitud_50m) g

							left outer join 
								( select 1 as enlace, operator from '+@2G+' group by operator) gop on gop.enlace=g.enlace
				group by gop.operator

			)gs --Todas las parcelas con muestras, sean del operador que sean

			left outer join (					
				select  g.operator,
						count (g.BSIC) as BS_Number
				from
				(
					select  g.operator,
							g.BSIC,
							g.frecuencia
					from
						(
						SELECT  g.latitud_50m,
								g.longitud_50m,
								g.operator,
								g.BSIC,
								g.frecuencia,
								g.RSSI_Outdoor,
								row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator order by g.pcobInd desc,g.frecuencia desc, g.BSIC desc) as id
							FROM '+@2G+' g,
									agrids.dbo.lcc_parcelas lp
			 
									where g.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											and lp.entorno in ('+ @filter +')

						) g

					where g.id=1

					group by g.operator, g.BSIC, g.frecuencia
				) g

				group by g.operator

			) gbs 
				on gbs.operator=gs.operator

			left outer join (					
				select  g.operator,
						count(g.RSSI_Outdoor) as RSSI_Outdoor_Samples,
						10*log10(AVG(POWER(convert(float,10.0), (convert(float,g.RSSI_Outdoor))/10.0))) as RxLev_2G
				from
						(
						SELECT  g.latitud_50m,
								g.longitud_50m,
								g.operator,
								g.BSIC,
								g.frecuencia,
								g.band,
								g.RSSI_Outdoor,
								g.pcobInd,
								row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator order by g.RSSI_Outdoor desc) as id
							FROM '+@2G+' g,
									agrids.dbo.lcc_parcelas lp
			 
									where g.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											and lp.entorno in ('+ @filter +')

						) g

				where g.id=1 --Por parcela, operador nos quedamos con el BS de nivel de señal

				group by g.operator

			) gci_signal 
				on gci_signal.operator=gs.operator

			left outer join (					
				select  g.operator,
						count(g.pcobind) as PcobInd_Samples,
						avg(g.pcobind) as PcobInd
				from
						(
						SELECT  g.latitud_50m,
								g.longitud_50m,
								g.operator,
								g.BSIC,
								g.frecuencia,
								g.band,
								g.RSSI_Outdoor,
								g.pcobInd,
								row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator order by g.pcobInd desc) as id
							FROM '+@2G+' g,
									agrids.dbo.lcc_parcelas lp
			 
									where g.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											and lp.entorno in ('+ @filter +')
						) g
				where g.id=1 --Por parcela, operador nos quedamos con el BS de probabilidad de cobertura
				group by g.operator
			) gci 
				on gci.operator=gs.operator

			left outer join (					
				select  g.operator,
					sum(case when g.band in (''GSM'',''EGSM'') then 1 else 0 end) as GSM_Samples,
					sum(case when g.band = ''DCS'' then 1 else 0 end) as DCS_Samples,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when g.band in (''GSM'', ''EGSM'') then g.RSSI_Outdoor end)))/10.0))) as RxLev_GSM,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when g.band= ''DCS'' then g.RSSI_Outdoor end)))/10.0))) as RxLev_DCS
				from

						(

						SELECT  g.latitud_50m,
								g.longitud_50m,
								g.operator,
								g.BSIC,
								g.frecuencia,
								g.band,
								g.RSSI_Outdoor,
								g.pcobInd,
								row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator, g.band order by g.RSSI_Outdoor desc) as id
							FROM '+@2G+' g,
									agrids.dbo.lcc_parcelas lp
			 
									where g.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											and lp.entorno in ('+ @filter +')

						) g

				where g.id=1 --Por parcela, operador y banda nos quedamos con el BS de nivel de señal

				group by g.operator

			) gci_signal_band 
				on gci_signal_band.operator=gs.operator

			left outer join (					
				select  g.operator,
					sum(case when g.band in (''GSM'',''EGSM'') and g.pcobInd_band is not null then 1 else 0 end) as GSM_Samples,
					sum(case when g.band = ''DCS'' and g.pcobInd_band is not null then 1 else 0 end) as DCS_Samples,
					avg(case when g.band in (''GSM'', ''EGSM'') then g.pcobInd_band end) as GSM,
					avg(case when g.band=''DCS'' then g.pcobInd_band end) as DCS

				from
					(
					SELECT  g.latitud_50m,
							g.longitud_50m,
							g.operator,
							g.BSIC,
							g.frecuencia,
							g.band,
							g.RSSI_Outdoor,
							g.pcobInd_band,
							row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator, g.band order by g.pcobInd_band desc) as id
						FROM '+@2G+' g,
								agrids.dbo.lcc_parcelas lp
			 
								where g.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) g
				where g.id=1 --Por parcela, operador y banda nos quedamos con el BS de probabilidad de cobertura
				group by g.operator

			) gci_band 
				on gci_band.operator=gs.operator
				
			left outer join (
				select	
						operator,	
						avg (case when isnull(GSM_samples,0)+isnull(DCS_samples,0)= 2 then GSM_DCS end) as GSM_DCS,
						sum(case when isnull(GSM_samples,0)+isnull(DCS_samples,0)= 2 then 1 end) as GSM_DCS_Samples
				from	
				(
					select  
						g.operator,						
						min(case when g.band in (''GSM'', ''EGSM'',''DCS'') then g.pcobInd_band end) as GSM_DCS,						
						min(case when g.band in (''GSM'', ''EGSM'') then 1 end) as GSM_samples,
						min(case when g.band in (''DCS'') then 1 end) as DCS_samples
					from
							(
							SELECT  g.latitud_50m,
									g.longitud_50m,
									g.operator,
									g.BSIC,
									g.frecuencia,
									g.band,
									g.RSSI_Outdoor,
									g.pcobInd_band,
									row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator, g.band order by g.pcobInd_band desc) as id
								FROM '+@2G+' g,
										agrids.dbo.lcc_parcelas lp
			 
										where g.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											and lp.entorno in ('+ @filter +')
											

							) g
					where g.id=1 --Por parcela, operador y banda nos quedamos con el BS de probabilidad de cobertura
					group by g.operator,g.latitud_50m, g.longitud_50m	
				) t
				group by t.operator

			) gci_band_both
				on gci_band_both.operator=gs.operator
			group by gs.operator
		) g
		on o.operator = g.operator

		left join(
			select 
				us.operator,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(uci_signal.RSCP_UMTS,0)))/10.0)*uci_signal.RSCP_Outdoor_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(us.Samples-uci_signal.RSCP_Outdoor_Samples)))/sum(us.Samples)) as RSCP_UMTS,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(uci_signal_band.RSCP_UMTS2100,0)))/10.0)*uci_signal_band.UMTS2100_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(us.Samples-uci_signal_band.UMTS2100_Samples)))/sum(us.Samples)) as RSCP_UMTS2100,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(uci_signal_band.RSCP_UMTS900,0)))/10.0)*uci_signal_band.UMTS900_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(us.Samples-uci_signal_band.UMTS900_Samples)))/sum(us.Samples)) as RSCP_UMTS900,

				avg(1.0*isnull(upol.cuadricula_polluter,0)/us.Samples) as [% Pollution],
				avg(1.0*isnull(uci_polluter.Cuadricula_Polluter_BS,0)/us.Samples) as [% Pollution BS],

				avg((uci.PcobInd * uci.PcobInd_Samples)/us.Samples) as UMTS,
				avg((uci_band.UMTS2100 * uci_band.UMTS2100_Samples)/us.Samples) as UMTS2100,

				avg((uci_frec.UMTS2100_F1 * uci_frec.UMTS2100_F1_Samples)/us.Samples) UMTS2100_F1,
				avg((uci_frec.UMTS2100_F2 * uci_frec.UMTS2100_F2_Samples)/us.Samples) UMTS2100_F2,
				avg((uci_frec.UMTS2100_F3 * uci_frec.UMTS2100_F3_Samples)/us.Samples) UMTS2100_F3,
				avg((uci_frec.UMTS2100_Dual_Carrier * uci_frec.UMTS2100_Dual_Carrier_Samples)/us.Samples) UMTS2100_Dual_Carrier,
				avg((uci_frec.UMTS2100_P1 * uci_frec.UMTS2100_P1_Samples)/us.Samples) UMTS2100_P1,
				avg((uci_frec.UMTS2100_P2 * uci_frec.UMTS2100_P2_Samples)/us.Samples) UMTS2100_P2,
				avg((uci_frec.UMTS2100_P3 * uci_frec.UMTS2100_P3_Samples)/us.Samples) UMTS2100_P3,
				
				avg((uci_band.UMTS900 * uci_band.UMTS900_Samples)/us.Samples) as UMTS900,
				avg((uci_frec.UMTS900_F1 * uci_frec.UMTS900_F1_Samples)/us.Samples) UMTS900_F1,
				avg((uci_frec.UMTS900_F2 * uci_frec.UMTS900_F2_Samples)/us.Samples) UMTS900_F2,
				avg((uci_frec.UMTS900_P1 * uci_frec.UMTS900_P1_Samples)/us.Samples) UMTS900_P1,
				avg((uci_frec.UMTS900_P2 * uci_frec.UMTS900_P2_Samples)/us.Samples) UMTS900_P2,
				max(ubs.BS_Number) as BS_UMTS
			from 
			(			
				select  uop.operator,
						count(u.samples) as Samples
				from
						(SELECT  1 as enlace,
								count(1) as samples
								
							FROM '+@3G+' u,
									agrids.dbo.lcc_parcelas lp
			 
									where u.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
											and lp.entorno in ('+ @filter +')
							group by  u.longitud_50m, u.latitud_50m) u

							left outer join 
								( select 1 as enlace, operator from '+@3G+' group by operator) uop on uop.enlace=u.enlace
				group by uop.operator

			)us --Todas las parcelas con muestras, sean del operador que sean
			
			left outer join (					
				select  u.operator,
						count (u.SC) as BS_Number
				from
					(
						select  u.operator,
								u.SC,
								u.frecuencia
						from
							(
							SELECT  u.latitud_50m,
									u.longitud_50m,
									u.operator,
									u.SC,
									u.frecuencia,
									u.RSCP_Outdoor,
									row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.PcobInd desc,u.frecuencia desc, u.SC desc) as id
								FROM '+@3G+' u,
										agrids.dbo.lcc_parcelas lp
			 
										where u.operator is not null
												and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
												and lp.entorno in ('+ @filter +')
							) u

						where u.id=1
						group by u.operator, u.SC, u.frecuencia
					) u
				group by u.operator

			) ubs 
				on ubs.operator=us.operator

			left outer join (					
				select  u.operator,
					count(u.RSCP_Outdoor) as RSCP_Outdoor_Samples,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,u.RSCP_Outdoor))/10.0))) as RSCP_UMTS				
				from
					(
					SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							u.SC,
							u.frecuencia,
							u.RSCP_Outdoor,
							u.band,
							u.PcobInd,
							row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.RSCP_Outdoor desc) as id
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
								where u.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) u
				where u.id=1 --Por parcela y operador nos quedamos con el BS de nivel de señal
				group by u.operator

			) uci_signal
				on uci_signal.operator=us.operator

			left outer join (					
				select  u.operator,
					1.0*count(u.PcobInd) as PcobInd_Samples,
					avg(u.PcobInd) as PcobInd				
				from
					(
					SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							u.SC,
							u.frecuencia,
							u.RSCP_Outdoor,
							u.band,
							u.PcobInd,
							u.Cuadricula_Polluter,
							row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.PcobInd desc, u.Cuadricula_Polluter desc) as id
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
								where u.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) u
				where u.id=1 --Por parcela y operador nos quedamos con el BS de probabilidad de cobertura
				group by u.operator

			) uci 
				on uci.operator=us.operator
			
			left outer join (					
				select  u.operator,
					sum(u.Cuadricula_Polluter) as Cuadricula_Polluter_BS				
				from
					(
					SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							u.SC,
							u.frecuencia,
							u.RSCP_Outdoor,
							u.band,
							u.PcobInd_Channel,
							u.Cuadricula_Polluter,
							row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.PcobInd_Channel desc, u.Cuadricula_Polluter desc) as id
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
								where u.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) u
				where u.id=1 --Por parcela y operador nos quedamos con el BS de probabilidad de cobertura
				group by u.operator

			) uci_polluter
				on uci_polluter.operator=us.operator

			left outer join (					
				select  u.operator,
					sum(case when u.band= ''UMTS2100'' then 1 else 0 end) as UMTS2100_Samples,
					sum(case when u.band= ''UMTS900'' then 1 else 0 end) as UMTS900_Samples,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when u.band= ''UMTS2100'' then u.RSCP_Outdoor end)))/10.0))) as RSCP_UMTS2100,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when u.band= ''UMTS900'' then u.RSCP_Outdoor end)))/10.0))) as RSCP_UMTS900
				from
					(
					SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							u.SC,
							u.frecuencia,
							u.RSCP_Outdoor,
							u.band,
							u.PcobInd,
							row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band order by u.RSCP_Outdoor desc) as id
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
								where u.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
										and lp.entorno in ('+ @filter +')
					) u
				where u.id=1 --Por parcela, operador y banda nos quedamos con el BS de nivel de señal
				group by u.operator
			) uci_signal_band
				on uci_signal_band.operator=us.operator

			left outer join (					
				select  u.operator,
					sum(case when u.band= ''UMTS2100'' and u.pcobInd_band is not null then 1 else 0 end) as UMTS2100_Samples,
					sum(case when u.band= ''UMTS900'' and u.pcobInd_band is not null then 1 else 0 end) as UMTS900_Samples,
					avg(case when u.band=''UMTS2100'' then u.pcobInd_band end) as UMTS2100,
					avg(case when u.band=''UMTS900'' then u.pcobInd_band end) as UMTS900
				from
					(
					SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							u.SC,
							u.frecuencia,
							u.RSCP_Outdoor,
							u.band,
							u.pcobInd_band,
							row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band order by u.pcobInd_band desc) as id
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
								where u.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) u
				where u.id=1 --Por parcela, operador y banda nos quedamos con el BS de probabilidad de cobertura
				group by u.operator

			) uci_band
				on uci_band.operator=us.operator


			left outer join (					
				select
					operator,
					count(UMTS2100_F1) as UMTS2100_F1_Samples,
					count(UMTS2100_F2) as UMTS2100_F2_Samples,
					count(UMTS2100_F3) as UMTS2100_F3_Samples,
					count(UMTS2100_P1) as UMTS2100_P1_Samples,
					count(UMTS2100_P2) as UMTS2100_P2_Samples,
					count(UMTS2100_P3) as UMTS2100_P3_Samples,
					count(UMTS900_F1) as UMTS900_F1_Samples,
					count(UMTS900_F2) as UMTS900_F2_Samples,
					count(UMTS900_P1) as UMTS900_P1_Samples,
					count(UMTS900_P2) as UMTS900_P2_Samples,
					--Solo dos portadoras
					sum(case when isnull(UMTS2100_F1_F2_Samples_ConCober,0) = 2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then 1
						when isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) = 2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then 1
						when isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)= 2 then 1
						else 0
					end) as UMTS2100_Dual_Carrier_Samples,
					
					avg(UMTS2100_F1) as UMTS2100_F1,
					avg(UMTS2100_F2) as UMTS2100_F2,
					avg(UMTS2100_F3) as UMTS2100_F3,
					avg(UMTS2100_P1) as UMTS2100_P1,
					avg(UMTS2100_P2) as UMTS2100_P2,
					avg(UMTS2100_P3) as UMTS2100_P3,
					avg(UMTS900_F1) as UMTS900_F1,
					avg(UMTS900_F2) as UMTS900_F2,
					avg(UMTS900_P1) as UMTS900_P1,
					avg(UMTS900_P2) as UMTS900_P2,
					--Solo dos portadoras
					avg(case when isnull(UMTS2100_F1_F2_Samples_ConCober,0) = 2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then UMTS2100_F1_F2
						when isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) = 2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then UMTS2100_F1_F3
						when isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)= 2 then UMTS2100_F2_F3
					end) as UMTS2100_Dual_Carrier
				from
				(
					select u.operator, 					
						min(case when u.frecuencia in (10713, 10788, 10638, 10563) then u.PcobInd end) as UMTS2100_F1,
						min(case when u.frecuencia in (10738, 10813, 10663, 10588) then u.PcobInd end) as UMTS2100_F2,
						min(case when u.frecuencia in (10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS2100_F3,
						min(case when u.band= ''UMTS2100'' and u.idBand = 1 then u.PcobInd end) as UMTS2100_P1,
						min(case when u.band= ''UMTS2100'' and u.idBand = 2 then u.PcobInd end) as UMTS2100_P2,
						min(case when u.band= ''UMTS2100'' and u.idBand = 3 then u.PcobInd end) as UMTS2100_P3,
						min(case when u.frecuencia in (3087,3011,2959) then u.PcobInd end) as UMTS900_F1,
						min(case when u.frecuencia in (3062,3032) then u.PcobInd end) as UMTS900_F2,
						min(case when u.band= ''UMTS900'' and u.idBand = 1 then u.PcobInd end) as UMTS900_P1,
						min(case when u.band= ''UMTS900'' and u.idBand = 2 then u.PcobInd end) as UMTS900_P2,
						--Probablidad de cobertura minima en cada una de las combinaciones
						min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) then u.PcobInd end) as UMTS2100_F1_F2,
						min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS2100_F1_F3,
						min(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS2100_F2_F3,
						
						sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) and u.PcobInd>0 then 1 end) as UMTS2100_F1_F2_Samples_ConCober,
						sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) and u.PcobInd>0 then 1 end) as UMTS2100_F1_F3_Samples_ConCober,
						sum(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) and u.PcobInd>0 then 1 end) as UMTS2100_F2_F3_Samples_ConCober
					from
						(

						SELECT  u.latitud_50m,
								u.longitud_50m,
								u.operator,
								u.SC,
								u.frecuencia,
								u.RSCP_Outdoor,
								u.band,
								u.PcobInd_Channel as PcobInd,
								row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band,frecuencia  order by u.PcobInd_Channel desc) as id,
								row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band  order by u.PcobInd_Channel desc) as idBand
							FROM '+@3G+' u,
									agrids.dbo.lcc_parcelas lp
			 
									where u.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
											and lp.entorno in ('+ @filter +')

						) u

					where u.id=1 --Por parcela, operador, banda y frecuencia nos quedamos con el BS de probabilidad de cobertura
					group by u.operator,u.latitud_50m,	u.longitud_50m
				) t
				group by t.operator
			) uci_frec
				on uci_frec.operator=us.operator 
									
			left outer join
			(
				select  u.operator,
					sum(u.Cuadricula_Polluter) as Cuadricula_Polluter
				from
					(
					SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							max(u.Cuadricula_Polluter) as Cuadricula_Polluter
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
						where   u.operator is not null
								and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
								and lp.entorno in ('+ @filter +')
						group by u.latitud_50m,	u.longitud_50m, u.operator

					) u
				group by u.operator

			)upol 
				on upol.operator=us.operator
			group by us.operator
		) u
		on u.operator=o.operator
		
		left join(
			select 
				ls.operator,
				--max(lci_signal.RSRP_LTE) as RSRP_LTE,
				--max(lci_signal_band.RSRP_LTE2600) as RSRP_LTE2600,
				--max(lci_signal_band.RSRP_LTE2100) as RSRP_LTE2100,
				--max(lci_signal_band.RSRP_LTE1800) as RSRP_LTE1800,
				--max(lci_signal_band.RSRP_LTE800) as RSRP_LTE800,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(lci_signal.RSRP_LTE,0)))/10.0)*lci_signal.RSRP_Outdoor_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(ls.Samples-lci_signal.RSRP_Outdoor_Samples)))/sum(ls.Samples)) as RSRP_LTE,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(lci_signal_band.RSRP_LTE2600,0)))/10.0)*lci_signal_band.LTE2600_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(ls.Samples-lci_signal_band.LTE2600_Samples)))/sum(ls.Samples)) as RSRP_LTE2600,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(lci_signal_band.RSRP_LTE2100,0)))/10.0)*lci_signal_band.LTE2100_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(ls.Samples-lci_signal_band.LTE2100_Samples)))/sum(ls.Samples)) as RSRP_LTE2100,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(lci_signal_band.RSRP_LTE1800,0)))/10.0)*lci_signal_band.LTE1800_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(ls.Samples-lci_signal_band.LTE1800_Samples)))/sum(ls.Samples)) as RSRP_LTE1800,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(lci_signal_band.RSRP_LTE800,0)))/10.0)*lci_signal_band.LTE800_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(ls.Samples-lci_signal_band.LTE800_Samples)))/sum(ls.Samples)) as RSRP_LTE800,
				avg((lci.PcobInd * lci.PcobInd_Samples)/ls.samples) as LTE,
				avg((lci_band.LTE2600 * lci_band.LTE2600_Samples)/ls.samples) as LTE2600,
				avg((lci_band.LTE2100 * lci_band.LTE2100_Samples)/ls.samples) as LTE2100,
				avg((lci_band.LTE2100_BW5 * lci_band.LTE2100_BW5_Samples)/ls.samples) as LTE2100_BW5,
				avg((lci_band.LTE2100_BW10 * lci_band.LTE2100_BW10_Samples)/ls.samples) as LTE2100_BW10,
				avg((lci_band.LTE2100_BW15 * lci_band.LTE2100_BW15_Samples)/ls.samples) as LTE2100_BW15,
				avg((lci_band.LTE1800 * lci_band.LTE1800_Samples)/ls.samples) as LTE1800,
				avg((lci_band.LTE1800_BW10 * lci_band.LTE1800_BW10_Samples)/ls.samples) as LTE1800_BW10,
				avg((lci_band.LTE1800_BW15 * lci_band.LTE1800_BW15_Samples)/ls.samples) as LTE1800_BW15,
				avg((lci_band.LTE1800_BW20 * lci_band.LTE1800_BW20_Samples)/ls.samples) as LTE1800_BW20,
				avg((lci_band.LTE800 * lci_band.LTE800_Samples)/ls.samples) as LTE800,
				avg((lsd.LTE800_1800 * lsd.LTE800_1800_samples)/ls.samples) as LTE800_1800,
				avg((lsd.LTE800_2100 * lsd.LTE800_2100_samples)/ls.samples) as LTE800_2100,
				avg((lsd.LTE800_2600 * lsd.LTE800_2600_samples)/ls.samples) as LTE800_2600,
				avg((lsd.LTE1800_2100 * lsd.LTE1800_2100_samples)/ls.samples) as LTE1800_2100,
				avg((lsd.LTE1800_2600 * lsd.LTE1800_2600_samples)/ls.samples) as LTE1800_2600,
				avg((lsd.LTE2100_2600 * lsd.LTE2100_2600_samples)/ls.samples) as LTE2100_2600,
				avg((lsd.LTE800_1800_2100 * lsd.LTE800_1800_2100_samples)/ls.samples) as LTE800_1800_2100,
				avg((lsd.LTE800_1800_2600 * lsd.LTE800_1800_2600_samples)/ls.samples) as LTE800_1800_2600,
				avg((lsd.LTE800_2100_2600 * lsd.LTE800_2100_2600_samples)/ls.samples) as LTE800_2100_2600,
				avg((lsd.LTE1800_2100_2600 * lsd.LTE1800_2100_2600_samples)/ls.samples) as LTE1800_2100_2600,
				max(lbs.BS_Number) as BS_LTE


			from 
			(			
				select  lop.operator,
						count(l.samples) as Samples
				from
						(SELECT  1 as enlace,
								count(1) as samples
								
							FROM '+@4G+' l,
									agrids.dbo.lcc_parcelas lp
			 
									where l.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
											and lp.entorno in ('+ @filter +')
							group by  l.longitud_50m, l.latitud_50m) l

							left outer join 
								( select 1 as enlace, operator from '+@4G+' group by operator) lop on lop.enlace=l.enlace
				group by lop.operator

			)ls --Todas las parcelas con muestras, sean del operador que sean

			left outer join (					
				select  l.operator,
						count (l.pci) as BS_Number
				from
				(
					select  l.operator,
							l.pci,
							l.frecuencia
					from
						(
						SELECT  l.latitud_50m,
								l.longitud_50m,
								l.operator,
								l.pci,
								l.frecuencia,
								l.RSRP_Outdoor,
								row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.pCobInd desc,l.frecuencia desc, l.pci desc) as id
							FROM '+@4G+' l,
									agrids.dbo.lcc_parcelas lp
			 
									where l.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
											and lp.entorno in ('+ @filter +')
						) l

					where l.id=1
					group by l.operator, l.pci, l.frecuencia
				) l
				group by l.operator

			) lbs 
				on lbs.operator=ls.operator

			left outer join (					
				select  l.operator,
					count(l.RSRP_Outdoor) as RSRP_Outdoor_Samples,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,l.RSRP_Outdoor))/10.0))) as RSRP_LTE					
				from
					(
					SELECT  l.latitud_50m,
							l.longitud_50m,
							l.operator,
							l.pci,
							l.frecuencia,
							l.RSRP_Outdoor,
							l.band,
							l.PcobInd,
							row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.RSRP_Outdoor desc) as id
						FROM '+@4G+' l,
								agrids.dbo.lcc_parcelas lp
			 
								where l.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) l
				where l.id=1 --Por parcela y operador nos quedamos con el BS de nivel de señal
				group by l.operator

			) lci_signal
				on lci_signal.operator=ls.operator

			left outer join (					
				select  l.operator,
					1.0*count(l.PcobInd) as PcobInd_Samples,
					avg(l.pCobInd) as PcobInd,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,l.RSRP_Outdoor))/10.0))) as RSRP_LTE
				from
					(
					SELECT  l.latitud_50m,
							l.longitud_50m,
							l.operator,
							l.pci,
							l.frecuencia,
							l.RSRP_Outdoor,
							l.band,
							l.PcobInd,
							row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.pCobInd desc) as id
						FROM '+@4G+' l,
								agrids.dbo.lcc_parcelas lp
			 
								where l.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) l
				where l.id=1 --Por parcela y operador nos quedamos con el BS de probabilidad de cobertura
				group by l.operator

			) lci 
				on lci.operator=ls.operator
			
			left outer join (					
				select  l.operator,
					sum(case when l.band =''LTE800'' then 1 else 0 end) as LTE800_Samples,
					sum(case when l.band =''LTE1800'' then 1 else 0 end) as LTE1800_Samples,
					sum(case when l.band =''LTE2100'' then 1 else 0 end) as LTE2100_Samples,
					sum(case when l.band =''LTE2600'' then 1 else 0 end) as LTE2600_Samples,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE2600'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE2600,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE2100'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE2100,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE1800'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE1800,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE800'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE800
				from
					(
					SELECT  l.latitud_50m,
							l.longitud_50m,
							l.operator,
							l.pci,
							l.frecuencia,
							l.RSRP_Outdoor,
							l.band,
							l.PcobInd,
							row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator, l.band order by l.RSRP_Outdoor desc) as id
						FROM '+@4G+' l,
								agrids.dbo.lcc_parcelas lp
			 
								where l.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) l
				where l.id=1 --Por parcela, operador y banda nos quedamos con el BS de nivel de señal
				group by l.operator

			) lci_signal_band
				on lci_signal_band.operator=ls.operator

			left outer join (					
				select  l.operator,
					sum(case when l.band =''LTE800'' then 1 end) as LTE800_Samples,
					sum(case when l.band =''LTE1800'' then 1 end) as LTE1800_Samples,
					sum(case when l.band =''LTE1800'' and l.bandwidth = 10 then 1 end) as LTE1800_BW10_Samples,
					sum(case when l.band =''LTE1800'' and l.bandwidth = 15 then 1 end) as LTE1800_BW15_Samples,
					sum(case when l.band =''LTE1800'' and l.bandwidth = 20 then 1 end) as LTE1800_BW20_Samples,
					sum(case when l.band =''LTE2100'' then 1 end) as LTE2100_Samples,
					sum(case when l.band =''LTE2100'' and l.bandwidth = 5 then 1 end) as LTE2100_BW5_Samples,
					sum(case when l.band =''LTE2100'' and l.bandwidth = 10 then 1 end) as LTE2100_BW10_Samples,
					sum(case when l.band =''LTE2100'' and l.bandwidth = 15 then 1 end) as LTE2100_BW15_Samples,
					sum(case when l.band =''LTE2600'' then 1 end) as LTE2600_Samples,
					avg(case when l.band =''LTE800'' then l.pcobind end) as LTE800,
					avg(case when l.band =''LTE1800'' then l.pcobind end) as LTE1800,
					avg(case when l.band =''LTE1800'' and l.bandwidth = 10 then l.pcobind end) as LTE1800_BW10,
					avg(case when l.band =''LTE1800'' and l.bandwidth = 15 then l.pcobind end) as LTE1800_BW15,
					avg(case when l.band =''LTE1800'' and l.bandwidth = 20 then l.pcobind end) as LTE1800_BW20,
					avg(case when l.band =''LTE2100'' then l.pcobind end) as LTE2100,
					avg(case when l.band =''LTE2100'' and l.bandwidth = 5 then l.pcobind end) as LTE2100_BW5,
					avg(case when l.band =''LTE2100'' and l.bandwidth = 10 then l.pcobind end) as LTE2100_BW10,
					avg(case when l.band =''LTE2100'' and l.bandwidth = 15 then l.pcobind end) as LTE2100_BW15,
					avg(case when l.band =''LTE2600'' then l.pcobind end) as LTE2600

				from
					(
					SELECT  l.latitud_50m,
							l.longitud_50m,
							l.operator,
							l.pci,
							l.frecuencia,
							l.RSRP_Outdoor,
							l.band,
							l.bandwidth,
							l.PcobInd,
							row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator, l.band order by l.pCobInd desc, l.bandwidth desc ) as id
						FROM '+@4G+' l,
								agrids.dbo.lcc_parcelas lp
			 
								where l.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) l
				where l.id=1 --Por parcela, operador y banda nos quedamos con el BS de probabilidad de cobertura
				group by l.operator

			) lci_band
				on lci_band.operator=ls.operator


			left outer join (				
				select
					operator,
					sum(case when LTE800_1800_samples= 2 then 1 end) as LTE800_1800_samples,
					sum(case when LTE800_2100_samples= 2 then 1 end ) as LTE800_2100_samples,
					sum(case when LTE800_2600_samples= 2 then 1 end ) as LTE800_2600_samples,
					sum(case when LTE1800_2100_samples= 2 then 1 end ) as LTE1800_2100_samples,
					sum(case when LTE1800_2600_samples= 2 then 1 end) as LTE1800_2600_samples,
					sum(case when LTE2100_2600_samples= 2 then 1 end ) as LTE2100_2600_samples,
					sum(case when LTE800_1800_2100_samples= 3 then 1 end ) as LTE800_1800_2100_samples,
					sum(case when LTE800_1800_2600_samples= 3 then 1 end ) as LTE800_1800_2600_samples,
					sum(case when LTE800_2100_2600_samples= 3 then 1 end ) as LTE800_2100_2600_samples,
					sum(case when LTE1800_2100_2600_samples= 3 then 1 end ) as LTE1800_2100_2600_samples,
					
					avg(case when LTE800_1800_samples= 2 then LTE800_1800 end) as LTE800_1800,
					avg(case when LTE800_2100_samples= 2 then LTE800_2100 end ) as LTE800_2100,
					avg(case when LTE800_2600_samples= 2 then LTE800_2600 end ) as LTE800_2600,
					avg(case when LTE1800_2100_samples= 2 then LTE1800_2100 end ) as LTE1800_2100,
					avg(case when LTE1800_2600_samples= 2 then LTE1800_2600 end) as LTE1800_2600,
					avg(case when LTE2100_2600_samples= 2 then LTE2100_2600 end ) as LTE2100_2600,
					avg(case when LTE800_1800_2100_samples= 3 then LTE800_1800_2100 end ) as LTE800_1800_2100,
					avg(case when LTE800_1800_2600_samples= 3 then LTE800_1800_2600 end ) as LTE800_1800_2600,
					avg(case when LTE800_2100_2600_samples= 3 then LTE800_2100_2600 end ) as LTE800_2100_2600,
					avg(case when LTE1800_2100_2600_samples= 3 then LTE1800_2100_2600 end ) as LTE1800_2100_2600
				from
				(
					select l.operator, 					
						min(case when l.band in (''LTE800'', ''LTE1800'') then l.PcobInd end) as LTE800_1800,
						min(case when l.band in (''LTE800'', ''LTE2100'') then l.PcobInd end) as LTE800_2100,
						min(case when l.band in (''LTE800'', ''LTE2600'') then l.PcobInd end) as LTE800_2600,
						min(case when l.band in (''LTE1800'', ''LTE2100'') then l.PcobInd end) as LTE1800_2100,
						min(case when l.band in (''LTE1800'', ''LTE2600'') then l.PcobInd end) as LTE1800_2600,
						min(case when l.band in (''LTE2100'', ''LTE2600'') then l.PcobInd end) as LTE2100_2600,
						min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then l.PcobInd end) as LTE800_1800_2100,
						min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then l.PcobInd end) as LTE800_1800_2600,
						min(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then l.PcobInd end) as LTE800_2100_2600,
						min(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then l.PcobInd end) as LTE1800_2100_2600,
						
						sum(case when l.band in (''LTE800'', ''LTE1800'') then 1 end) as LTE800_1800_samples,
						sum(case when l.band in (''LTE800'', ''LTE2100'') then 1 end) as LTE800_2100_samples,
						sum(case when l.band in (''LTE800'', ''LTE2600'') then 1 end) as LTE800_2600_samples,
						sum(case when l.band in (''LTE1800'', ''LTE2100'') then 1 end) as LTE1800_2100_samples,
						sum(case when l.band in (''LTE1800'', ''LTE2600'') then 1 end) as LTE1800_2600_samples,
						sum(case when l.band in (''LTE2100'', ''LTE2600'') then 1 end) as LTE2100_2600_samples,
						sum(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then 1 end) as LTE800_1800_2100_samples,
						sum(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then 1 end) as LTE800_1800_2600_samples,
						sum(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then 1 end) as LTE800_2100_2600_samples,
						sum(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then 1 end) as LTE1800_2100_2600_samples
					from
						(
						SELECT  l.latitud_50m,
								l.longitud_50m,
								l.operator,
								l.pci,
								l.frecuencia,
								l.RSRP_Outdoor,
								l.band,
								l.PcobInd,
								row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator, l.band order by l.pCobInd desc) as id
							FROM '+@4G+' l,
									agrids.dbo.lcc_parcelas lp
			 
									where l.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
											and lp.entorno in ('+ @filter +')

						) l
					where l.id=1 --Por parcela, operador y banda nos quedamos con el BS de probabilidad de cobertura
					group by l.operator,l.latitud_50m,	l.longitud_50m
				) t
				group by t.operator

			) lsd
				on lsd.operator=ls.operator
			group by ls.operator
		) l
		on l.operator=o.operator 	

	order by case when o.operator=''Vodafone'' then '''' else o.operator end
	'
)

end

-- Para los resultados outdoor o indoor por nivel
else if (@sheet='Outdoor' or @sheet='Indoor')
begin
exec (
--print 
	'
	select
			isnull(l.RSRP_LTE,-140) as RSRP_LTE,
			isnull(l.RSRP_LTE2600,-140) as RSRP_LTE2600,
			isnull(l.RSRP_LTE2100,-140) as RSRP_LTE2100,
			isnull(l.RSRP_LTE1800,-140) as RSRP_LTE1800,
			isnull(l.RSRP_LTE800,-140) as RSRP_LTE800,
			isnull(l.LTE,0) as LTE,
			isnull(l.LTE2600,0) as LTE2600,
			isnull(l.LTE2100,0) as LTE2100,
			isnull(l.LTE2100_BW5,0) as LTE2100_BW5,
			isnull(l.LTE2100_BW10,0) as LTE2100_BW10,
			isnull(l.LTE2100_BW15,0) as LTE2100_BW15,
			isnull(l.LTE1800,0) as LTE1800,
			isnull(l.LTE1800_BW10,0) as LTE1800_BW10,
			isnull(l.LTE1800_BW15,0) as LTE1800_BW15,
			isnull(l.LTE1800_BW20,0) as LTE1800_BW20,
			isnull(l.LTE800,0) as LTE800,
			isnull(l.LTE800_1800,0) as LTE800_1800,
			isnull(l.LTE800_2100,0) as LTE800_2100,
			isnull(l.LTE800_2600,0) as LTE800_2600,
			isnull(l.LTE1800_2100,0) as LTE1800_2100,
			isnull(l.LTE1800_2600,0) as LTE1800_2600,
			isnull(l.LTE2100_2600,0) as LTE2100_2600,
			isnull(l.LTE800_1800_2100,0) as LTE800_1800_2100,
			isnull(l.LTE800_1800_2600,0) as LTE800_1800_2600,
			isnull(l.LTE800_2100_2600,0) as LTE800_2100_2600,
			isnull(l.LTE1800_2100_2600,0) as LTE1800_2100_2600,
			isnull(l.BS_LTE,0) as BS_LTE,
			isnull(u.RSCP_UMTS,-140) as RSCP_UMTS,
			isnull(u.RSCP_UMTS2100,-140) as RSCP_UMTS2100,
			isnull(u.RSCP_UMTS900,-140) as RSCP_UMTS900,
			isnull(u.[% Pollution],0) as [% Pollution],
			isnull(u.[% Pollution BS],0) as [% Pollution BS],
			isnull(u.UMTS,0) as UMTS,
			isnull(u.UMTS2100,0) as UMTS2100,
			isnull(u.UMTS2100_Carrier_only,0) as UMTS2100_Carrier_only,
			isnull(u.UMTS2100_F1,0) as UMTS2100_F1,
			isnull(u.UMTS2100_F2,0) as UMTS2100_F2,
			isnull(u.UMTS2100_F3,0) as UMTS2100_F3,
			isnull(u.UMTS2100_Dual_Carrier,0) as UMTS2100_Dual_Carrier,
			isnull(u.UMTS2100_F1_F2,0) as UMTS2100_F1_F2,
			isnull(u.UMTS2100_F1_F3,0) as UMTS2100_F1_F3,
			isnull(u.UMTS2100_F2_F3,0) as UMTS2100_F2_F3,
			isnull(u.UMTS2100_F1_F2_F3,0) as UMTS2100_F1_F2_F3,
			isnull(u.UMTS2100_P1,0) as UMTS2100_P1,
			isnull(u.UMTS2100_P2,0) as UMTS2100_P2,
			isnull(u.UMTS2100_P3,0) as UMTS2100_P3,

			isnull(u.UMTS900,0) as UMTS900,
			isnull(u.UMTS900_F1,0) as UMTS900_F1,
			isnull(u.UMTS900_F2,0) as UMTS900_F2,
			isnull(u.UMTS900_U2100_Carrier_only,0) as UMTS900_U2100_Carrier_only,
			isnull(u.UMTS900_U2100_F1,0) as UMTS900_U2100_F1,
			isnull(u.UMTS900_U2100_F2,0) as UMTS900_U2100_F2,
			isnull(u.UMTS900_U2100_F3,0) as UMTS900_U2100_F3,
			isnull(u.UMTS900_U2100_Dual_Carrier,0) as UMTS900_U2100_Dual_Carrier,
			isnull(u.UMTS900_U2100_F1_F2,0) as UMTS900_U2100_F1_F2,
			isnull(u.UMTS900_U2100_F1_F3,0) as UMTS900_U2100_F1_F3,
			isnull(u.UMTS900_U2100_F2_F3,0) as UMTS900_U2100_F2_F3,
			isnull(u.UMTS900_U2100_F1_F2_F3,0) as UMTS900_U2100_F1_F2_F3,
			isnull(u.UMTS900_P1,0) as UMTS900_P1,
			isnull(u.UMTS900_P2,0) as UMTS900_P2,
			isnull(u.BS_UMTS,0) as BS_UMTS,

			isnull(g.RxLev_2G,-110) as RxLev_2G,
			isnull(g.RxLev_GSM,-110) as RxLev_GSM,
			isnull(g.RxLev_DCS,-110) as RxLev_DCS,
			isnull(g.[2G],0) as [2G],
			isnull(g.GSM_DCS,0) as GSM_DCS,
			isnull(g.GSM,0) as GSM,
			isnull(g.DCS,0) as DCS,
			isnull(g.BS_GSM,0) as BS_GSM

	from
		(
			select operator as operator from '+@4G+' where operator is not null group by operator
			union
			select operator from '+@3G+' where operator is not null group by operator
			union
			select operator from '+@2G+' where operator is not null group by operator
		) o

		left join(
			select 
				gs.operator,
				--max(gci.RxLev_2G) as RxLev_2G,
				--max(gci_band.RxLev_GSM) as RxLev_GSM,
				--max(gci_band.RxLev_DCS) as RxLev_DCS,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(gci.RxLev_2G,0)))/10.0)*isnull(gci.RxLev_2G_Samples,0))+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*(gs.Samples-isnull(gci.RxLev_2G_Samples,0))))/sum(gs.Samples)) as RxLev_2G,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(gci_band.RxLev_GSM,0)))/10.0)*isnull(gci_band.RxLev_GSM_Samples,0))+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*(gs.Samples-isnull(gci_band.RxLev_GSM_Samples,0))))/sum(gs.Samples)) as RxLev_GSM,
				10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(gci_band.RxLev_DCS,0)))/10.0)*isnull(gci_band.RxLev_DCS_Samples,0))+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*(gs.Samples-isnull(gci_band.RxLev_DCS_Samples,0))))/sum(gs.Samples)) as RxLev_DCS,
				isnull(1.0*max(gci.RSSI_Outdoor_Samples)/ nullif(max(gs.samples),0),0) as [2G],
				isnull(1.0*max(gci_band.GSM_Samples)/ nullif(max(gs.samples),0),0) as GSM,
				isnull(1.0*max(gci_band.DCS_Samples)/ nullif(max(gs.samples),0),0) as DCS,
				max(gbs.BS_Number) as BS_GSM,
				isnull(1.0*max(gci_band_both.GSM_DCS)/ nullif(max(gs.samples),0),0) as [GSM_DCS]

			from 
			(			
				select  gop.operator,
						count(g.samples) as Samples
				from
						(SELECT  1 as enlace,
								count(1) as samples
								
							FROM '+@2G+' g,
									agrids.dbo.lcc_parcelas lp
			 
									where g.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											and lp.entorno in ('+ @filter +')
							group by  g.longitud_50m, g.latitud_50m) g

							left outer join 
								( select 1 as enlace, operator from '+@2G+' group by operator) gop on gop.enlace=g.enlace
				group by gop.operator
			)gs --Todas las parcelas con muestras, sean del operador que sean

			left outer join (					
				select  g.operator,
						count (g.BSIC) as BS_Number --Cuantos pilotos diferentes nos dan el BS
				from
				(
					select  g.operator,
							g.BSIC,
							g.frecuencia
					from
						(
						SELECT  g.latitud_50m,
								g.longitud_50m,
								g.operator,
								g.BSIC,
								g.frecuencia,
								row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator order by g.RSSI_Outdoor desc,g.frecuencia desc, g.BSIC desc) as id
							FROM '+@2G+' g,
									agrids.dbo.lcc_parcelas lp			 
							where g.operator is not null
									and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
									and lp.entorno in ('+ @filter +')

						) g

					where g.id=1 --Por parcela, operador nos quedamos con el BS

					group by g.operator, g.BSIC, g.frecuencia
				) g
				group by g.operator

			) gbs 
				on gbs.operator=gs.operator

			left outer join (					
				select  g.operator,
						sum(case when g.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as RSSI_Outdoor_Samples,
						count(g.RSSI_Outdoor) as RxLev_2G_samples,
						10*log10(AVG(POWER(convert(float,10.0), (convert(float,g.RSSI_Outdoor))/10.0))) as RxLev_2G
				from
					(
					SELECT  g.latitud_50m,
							g.longitud_50m,
							g.operator,
							g.BSIC,
							g.frecuencia,
							g.band,
							g.RSSI_Outdoor,
							row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator order by g.RSSI_Outdoor desc) as id
						FROM '+@2G+' g,
								agrids.dbo.lcc_parcelas lp
			 
								where g.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) g
				where g.id=1  --Por parcela, operador nos quedamos con el BS
				group by g.operator

			) gci 
				on gci.operator=gs.operator

			left outer join (					
				select  g.operator,
						sum(case when g.band in (''GSM'',''EGSM'') and g.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as GSM_Samples,
						sum(case when g.band = ''DCS'' and g.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as DCS_Samples,
						sum(case when g.band in (''GSM'',''EGSM'') then 1 else 0 end) as RxLev_GSM_Samples,
						sum(case when g.band = ''DCS'' then 1 else 0 end) as RxLev_DCS_Samples,
						10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when g.band in (''GSM'', ''EGSM'') then g.RSSI_Outdoor end)))/10.0))) as RxLev_GSM,
						10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when g.band= ''DCS'' then g.RSSI_Outdoor end)))/10.0))) as RxLev_DCS
				from
					(
					SELECT  g.latitud_50m,
							g.longitud_50m,
							g.operator,
							g.BSIC,
							g.frecuencia,
							g.band,
							g.RSSI_Outdoor,
							row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator, g.band order by g.RSSI_Outdoor desc) as id
						FROM '+@2G+' g,
								agrids.dbo.lcc_parcelas lp
			 
								where g.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) g 
				where g.id=1  --Por parcela, operador y banda nos quedamos con el BS
				group by g.operator

			) gci_band 
				on gci_band.operator=gs.operator
			
			left outer join (	
				select	
					operator,	
					sum (case when isnull(GSM_samples,0)+isnull(DCS_samples,0)= 2 then GSM_DCS end) as GSM_DCS
				from
				(		
					select g.operator,
							min(case when g.band in (''GSM'', ''EGSM'',''DCS'') and G.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as GSM_DCS,
							min(case when g.band in (''GSM'', ''EGSM'') then 1 end) as GSM_samples,
							min(case when g.band in (''DCS'') then 1 end) as DCS_samples
					from
						(
						SELECT  g.latitud_50m,
								g.longitud_50m,
								g.operator,
								g.BSIC,
								g.frecuencia,
								g.band,
								g.RSSI_Outdoor,
								g.pcobInd,
								row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator, g.band order by g.RSSI_Outdoor desc) as id
							FROM '+@2G+' g,
									agrids.dbo.lcc_parcelas lp
			 
									where g.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
										and lp.entorno in ('+ @filter +')									

						) g

					where g.id=1 --Por parcela 50x50, operador nos quedamos con el BS de nivel de señal

					group by g.operator,g.latitud_50m, g.longitud_50m	
				) t
				group by t.operator
			) gci_band_both
				on gci_band_both.operator=gs.operator
			group by gs.operator
		) g
		on g.operator=o.operator

		left join(
			select 
					us.operator,
					10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(uci.RSCP_UMTS,0)))/10.0)*uci.RSCP_UMTS_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(us.Samples-uci.RSCP_UMTS_Samples)))/sum(us.Samples)) as RSCP_UMTS,
					10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(uci_band.RSCP_UMTS2100,0)))/10.0)*uci_band.RSCP_UMTS2100_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(us.Samples-uci_band.RSCP_UMTS2100_Samples)))/sum(us.Samples)) as RSCP_UMTS2100,
					10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(uci_band.RSCP_UMTS900,0)))/10.0)*uci_band.RSCP_UMTS900_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(us.Samples-uci_band.RSCP_UMTS900_Samples)))/sum(us.Samples)) as RSCP_UMTS900,

					avg(1.0*isnull(upol.cuadricula_polluter,0)/us.Samples) as [% Pollution],
					avg(1.0*isnull(uci.Cuadricula_Polluter_BS,0)/us.Samples) as [% Pollution BS],					
					isnull(1.0*max(uci.RSCP_Outdoor_Samples)/ nullif(max(us.samples),0),0) as UMTS,
					isnull(1.0*max(uci_band.UMTS2100_Samples)/ nullif(max(us.samples),0),0) as UMTS2100,
					isnull(1.0*max(uci_frec.UMTS2100_F1_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_F1,
					isnull(1.0*max(uci_frec.UMTS2100_F2_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_F2,
					isnull(1.0*max(uci_frec.UMTS2100_F3_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_F3,
					isnull(1.0*max(uci_frec.UMTS2100_P1_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_P1,
					isnull(1.0*max(uci_frec.UMTS2100_P2_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_P2,
					isnull(1.0*max(uci_frec.UMTS2100_P3_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_P3,
					isnull(1.0*max(uci_frec.UMTS2100_F1_F2_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_F1_F2,
					isnull(1.0*max(uci_frec.UMTS2100_F1_F3_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_F1_F3,
					isnull(1.0*max(uci_frec.UMTS2100_F2_F3_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_F2_F3,
					isnull(1.0*max(uci_frec.UMTS2100_F1_F2_F3_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_F1_F2_F3,
					isnull(1.0*max(uci_band.UMTS900_Samples)/ nullif(max(us.samples),0),0) as UMTS900,
					isnull(1.0*max(uci_frec.UMTS900_F1_Samples)/ nullif(max(us.samples),0),0) as UMTS900_F1,
					isnull(1.0*max(uci_frec.UMTS900_F2_Samples)/ nullif(max(us.samples),0),0) as UMTS900_F2,
					isnull(1.0*max(uci_frec.UMTS900_P1_Samples)/ nullif(max(us.samples),0),0) as UMTS900_P1,
					isnull(1.0*max(uci_frec.UMTS900_P2_Samples)/ nullif(max(us.samples),0),0) as UMTS900_P2,
					isnull(1.0*max(uci_frec.UMTS900_U2100_F1_Samples)/ nullif(max(us.samples),0),0) as UMTS900_U2100_F1,
					isnull(1.0*max(uci_frec.UMTS900_U2100_F2_Samples)/ nullif(max(us.samples),0),0) as UMTS900_U2100_F2,
					isnull(1.0*max(uci_frec.UMTS900_U2100_F3_Samples)/ nullif(max(us.samples),0),0) as UMTS900_U2100_F3,
					isnull(1.0*max(uci_frec.UMTS900_U2100_F1_F2_Samples)/ nullif(max(us.samples),0),0) as UMTS900_U2100_F1_F2,
					isnull(1.0*max(uci_frec.UMTS900_U2100_F1_F3_Samples)/ nullif(max(us.samples),0),0) as UMTS900_U2100_F1_F3,
					isnull(1.0*max(uci_frec.UMTS900_U2100_F2_F3_Samples)/ nullif(max(us.samples),0),0) as UMTS900_U2100_F2_F3,
					isnull(1.0*max(uci_frec.UMTS900_U2100_F1_F2_F3_Samples)/ nullif(max(us.samples),0),0) as UMTS900_U2100_F1_F2_F3,
					max(ubs.BS_Number) as BS_UMTS,
					isnull(1.0*max(uci_frec.UMTS2100_Carrier_only_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_Carrier_only,
					isnull(1.0*max(uci_frec.UMTS2100_Dual_Carrier_Samples)/ nullif(max(us.samples),0),0) as UMTS2100_Dual_Carrier,
					isnull(1.0*max(uci_frec.UMTS900_U2100_Carrier_only_Samples)/ nullif(max(us.samples),0),0) as UMTS900_U2100_Carrier_only,
					isnull(1.0*max(uci_frec.UMTS900_U2100_Dual_Carrier_Samples)/ nullif(max(us.samples),0),0) as UMTS900_U2100_Dual_Carrier
			from 
			(			
				select  uop.operator,
						count(u.samples) as Samples
				from
						(SELECT  1 as enlace,
								count(1) as samples
								
							FROM '+@3G+' u,
									agrids.dbo.lcc_parcelas lp
			 
									where u.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
											and lp.entorno in ('+ @filter +')
							group by  u.longitud_50m, u.latitud_50m) u

							left outer join 
								( select 1 as enlace, operator from '+@3G+' group by operator) uop on uop.enlace=u.enlace
				group by uop.operator

			)us --Todas las parcelas con muestras, sean del operador que sean
			
			left outer join (					
				select  u.operator,
						count (u.SC) as BS_Number
				from
				(
					select  u.operator,
							u.SC,
							u.frecuencia
					from
						(
						SELECT  u.latitud_50m,
								u.longitud_50m,
								u.operator,
								u.SC,
								u.frecuencia,
								u.RSCP_Outdoor,
								row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.RSCP_Outdoor desc,u.frecuencia desc, u.SC desc) as id
							FROM '+@3G+' u,
									agrids.dbo.lcc_parcelas lp
			 
									where u.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
											and lp.entorno in ('+ @filter +')
						) u
					where u.id=1
					group by u.operator, u.SC, u.frecuencia
				) u
				group by u.operator

			) ubs 
				on ubs.operator=us.operator
			
			left outer join (					
				select  u.operator,
						1.0*sum(case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) as RSCP_Outdoor_Samples,
						count(u.RSCP_Outdoor) as RSCP_UMTS_Samples,
						10*log10(AVG(POWER(convert(float,10.0), (convert(float,u.RSCP_Outdoor))/10.0))) as RSCP_UMTS,
						sum(u.Cuadricula_Polluter) as Cuadricula_Polluter_BS						
				from
					(
					SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							u.SC,
							u.frecuencia,
							u.band,
							u.RSCP_Outdoor,
							u.Cuadricula_Polluter,
							row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.RSCP_Outdoor desc, u.Cuadricula_Polluter desc) as id
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
						where u.operator is not null
								and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
								and lp.entorno in ('+ @filter +')

					) u
				where u.id=1
				group by u.operator
			) uci 
				on uci.operator=us.operator

			left outer join (					
				select  u.operator,
						10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when u.band= ''UMTS2100'' then u.RSCP_Outdoor end)))/10.0))) as RSCP_UMTS2100,
						10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when u.band= ''UMTS900'' then u.RSCP_Outdoor end)))/10.0))) as RSCP_UMTS900,
						sum(case when u.band= ''UMTS2100'' then 1 else 0 end) as RSCP_UMTS2100_Samples,
						sum(case when u.band= ''UMTS900'' then 1 else 0 end) as RSCP_UMTS900_Samples,
						sum(case when u.band= ''UMTS2100'' and u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) as UMTS2100_Samples,
						sum(case when u.band= ''UMTS900'' and u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) as UMTS900_Samples
				from
					(
					SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							u.SC,
							u.frecuencia,
							u.band,
							u.RSCP_Outdoor,
							row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band order by u.RSCP_Outdoor desc) as id
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
								where u.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
										and lp.entorno in ('+ @filter +')

					) u
				where u.id=1 --Por parcela, operador y banda nos quedamos con el BS
				group by u.operator

			) uci_band
				on uci_band.operator=us.operator
			
			left outer join (	
				select
					operator, 
					sum(UMTS2100_F1) as UMTS2100_F1_Samples,
					sum(UMTS2100_F2) as UMTS2100_F2_Samples,
					sum(UMTS2100_F3) as UMTS2100_F3_Samples,
					sum(UMTS2100_P1) as UMTS2100_P1_Samples,
					sum(UMTS2100_P2) as UMTS2100_P2_Samples,
					sum(UMTS2100_P3) as UMTS2100_P3_Samples,
					sum(UMTS900_F1) as UMTS900_F1_Samples,
					sum(UMTS900_F2) as UMTS900_F2_Samples,
					sum(UMTS900_P1) as UMTS900_P1_Samples,
					sum(UMTS900_P2) as UMTS900_P2_Samples,
					sum(case when UMTS2100_F1_F2_Samples= 2 then UMTS2100_F1_F2 end) as UMTS2100_F1_F2_Samples,
					sum(case when UMTS2100_F1_F3_Samples= 2 then UMTS2100_F1_F3 end ) as UMTS2100_F1_F3_Samples,
					sum(case when UMTS2100_F2_F3_Samples= 2 then UMTS2100_F2_F3 end ) as UMTS2100_F2_F3_Samples,
					sum(case when UMTS2100_F1_F2_F3_Samples= 3 then UMTS2100_F1_F2_F3 end ) as UMTS2100_F1_F2_F3_Samples,

					sum(case when UMTS900_Samples+UMTS2100_F1_Samples= 2 and U900>0 and UMTS2100_F1>0 then 1 else 0 end) as UMTS900_U2100_F1_Samples,
					sum(case when UMTS900_Samples+UMTS2100_F2_Samples= 2 and U900>0 and UMTS2100_F2>0 then 1 else 0 end ) as UMTS900_U2100_F2_Samples,
					sum(case when UMTS900_Samples+UMTS2100_F3_Samples= 2 and U900>0 and UMTS2100_F3>0 then 1 else 0 end) as UMTS900_U2100_F3_Samples,
					sum(case when UMTS900_Samples+UMTS2100_F1_F2_Samples= 3 and U900>0 and UMTS2100_F1_F2>0 then 1 else 0 end) as UMTS900_U2100_F1_F2_Samples,
					sum(case when UMTS900_Samples+UMTS2100_F1_F3_Samples= 3 and U900>0 and UMTS2100_F1_F3>0 then 1 else 0 end) as UMTS900_U2100_F1_F3_Samples,
					sum(case when UMTS900_Samples+UMTS2100_F2_F3_Samples= 3 and U900>0 and UMTS2100_F2_F3>0 then 1 else 0 end) as UMTS900_U2100_F2_F3_Samples,
					sum(case when UMTS900_Samples+UMTS2100_F1_F2_F3_Samples= 4 and U900>0 and UMTS2100_F1_F2_F3>0 then 1 else 0 end) as UMTS900_U2100_F1_F2_F3_Samples,
					--Solo una portadora
					sum(case when isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)= 1 then 1 else 0 end) as UMTS2100_Carrier_only_Samples,
					--Solo dos portadoras
					sum(case when isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)= 2 then 1 else 0 end) as UMTS2100_Dual_Carrier_Samples,
					--U900 y solo una portadora
					sum(case when U900>0 and isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)=1
						then 1 else 0 end) as UMTS900_U2100_Carrier_only_Samples,
					--U900 y dos portadoras
					sum(case when U900>0 and isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)=2
						then 1 else 0 end) as UMTS900_U2100_Dual_Carrier_Samples
				from
					(
					select u.operator, 					
						min(case when u.frecuencia in (10713, 10788, 10638, 10563) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1,
						min(case when u.frecuencia in (10738, 10813, 10663, 10588) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F2,
						min(case when u.frecuencia in (10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F3,
						min(case when u.band= ''UMTS2100'' and u.idBand = 1 then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_P1,
						min(case when u.band= ''UMTS2100'' and u.idBand = 2 then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_P2,
						min(case when u.band= ''UMTS2100'' and u.idBand = 3 then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_P3,
						min(case when u.frecuencia in (3087,3011,2959) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS900_F1,
						min(case when u.frecuencia in (3062,3032) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS900_F2,
						min(case when u.band= ''UMTS900'' and u.idBand = 1 then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS900_P1,
						min(case when u.band= ''UMTS900'' and u.idBand = 2 then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS900_P2,
						--Exista cobertura U2100 en las dos frecuencias de cada desglose
						min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1_F2,
						min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1_F3,
						min(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F2_F3,
						min(case when u.frecuencia in (10713, 10788, 10638, 10563,10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1_F2_F3,
						--Exista cobertura en alguna de frecuencias de UMTS900 
						max(case when u.band= ''UMTS900'' then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as U900,

						sum(case when u.frecuencia in (10713, 10788, 10638, 10563) then 1 end) as UMTS2100_F1_Samples,
						sum(case when u.frecuencia in (10738, 10813, 10663, 10588) then 1 end) as UMTS2100_F2_Samples,
						sum(case when u.frecuencia in (10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F3_Samples,
						sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) then 1 end) as UMTS2100_F1_F2_Samples,
						sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F1_F3_Samples,
						sum(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F2_F3_Samples,
						sum(case when u.frecuencia in (10713, 10788, 10638, 10563,10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F1_F2_F3_Samples,
						min(case when u.band= ''UMTS900'' then 1 end) as UMTS900_Samples
					from 
						(
						SELECT  u.latitud_50m,
								u.longitud_50m,
								u.operator,
								u.SC,
								u.frecuencia,
								u.band,
								u.RSCP_Outdoor,
								row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band,frecuencia order by u.RSCP_Outdoor desc) as id,
								row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band order by u.RSCP_Outdoor desc) as idBand
							FROM '+@3G+' u,
									agrids.dbo.lcc_parcelas lp
			 
									where u.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
											and lp.entorno in ('+ @filter +')
						) u 
					where u.id=1 --Por parcela, operador, banda y frecuencia nos quedamos con el BS
					group by u.operator,u.latitud_50m,	u.longitud_50m	
					) t
				group by t.operator

			) uci_frec
				on uci_frec.operator=us.operator
			
			left outer join
			(
				select  u.operator,
						sum(u.Cuadricula_Polluter) as Cuadricula_Polluter

				from
					(
					SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							max(u.Cuadricula_Polluter) as Cuadricula_Polluter
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
						where   u.operator is not null
								and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
								and lp.entorno in ('+ @filter +')
						group by u.latitud_50m,	u.longitud_50m, u.operator

					) u
				group by u.operator

			)upol 
				on upol.operator=us.operator
			group by us.operator
		) u
		on u.operator = o.operator

		left join(
			select 
					ls.operator,
					10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(lci.RSRP_LTE,0)))/10.0)*lci.RSRP_LTE_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(ls.Samples-lci.RSRP_LTE_Samples)))/sum(ls.Samples)) as RSRP_LTE,
					10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(lci_band.RSRP_LTE2600,0)))/10.0)*lci_band.RSRP_LTE2600_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(ls.Samples-lci_band.RSRP_LTE2600_Samples)))/sum(ls.Samples)) as RSRP_LTE2600,
					10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(lci_band.RSRP_LTE2100,0)))/10.0)*lci_band.RSRP_LTE2100_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(ls.Samples-lci_band.RSRP_LTE2100_Samples)))/sum(ls.Samples)) as RSRP_LTE2100,
					10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(lci_band.RSRP_LTE1800,0)))/10.0)*lci_band.RSRP_LTE1800_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(ls.Samples-lci_band.RSRP_LTE1800_Samples)))/sum(ls.Samples)) as RSRP_LTE1800,
					10*log10((sum(POWER(convert(float,10.0),(convert(float,isnull(lci_band.RSRP_LTE800,0)))/10.0)*lci_band.RSRP_LTE800_Samples)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*(ls.Samples-lci_band.RSRP_LTE800_Samples)))/sum(ls.Samples)) as RSRP_LTE800,
					max(lci.RSRP_Outdoor_samples)/nullif(max(ls.samples),0) as LTE,
					isnull(1.0*max(lci_band.LTE2600_samples)/ nullif(max(ls.samples),0),0) as LTE2600,
					isnull(1.0*max(lci_band.LTE2100_samples)/ nullif(max(ls.samples),0),0) as LTE2100,
					isnull(1.0*max(lci_band.LTE2100_BW5_samples)/ nullif(max(ls.samples),0),0) as LTE2100_BW5,
					isnull(1.0*max(lci_band.LTE2100_BW10_samples)/ nullif(max(ls.samples),0),0) as LTE2100_BW10,
					isnull(1.0*max(lci_band.LTE2100_BW15_samples)/ nullif(max(ls.samples),0),0) as LTE2100_BW15,
					isnull(1.0*max(lci_band.LTE1800_samples)/ nullif(max(ls.samples),0),0) as LTE1800,
					isnull(1.0*max(lci_band.LTE1800_BW10_samples)/ nullif(max(ls.samples),0),0) as LTE1800_BW10,
					isnull(1.0*max(lci_band.LTE1800_BW15_samples)/ nullif(max(ls.samples),0),0) as LTE1800_BW15,
					isnull(1.0*max(lci_band.LTE1800_BW20_samples)/ nullif(max(ls.samples),0),0) as LTE1800_BW20,
					isnull(1.0*max(lci_band.LTE800_samples)/ nullif(max(ls.samples),0),0) as LTE800,					
					isnull(1.0*max(lsd.LTE800_1800_samples)/ nullif(max(ls.samples),0),0) as LTE800_1800,
					isnull(1.0*max(lsd.LTE800_2100_samples)/ nullif(max(ls.samples),0),0) as LTE800_2100,
					isnull(1.0*max(lsd.LTE800_2600_samples)/ nullif(max(ls.samples),0),0) as LTE800_2600,
					isnull(1.0*max(lsd.LTE1800_2100_samples)/ nullif(max(ls.samples),0),0) as LTE1800_2100,
					isnull(1.0*max(lsd.LTE1800_2600_samples)/ nullif(max(ls.samples),0),0) as LTE1800_2600,
					isnull(1.0*max(lsd.LTE2100_2600_samples)/ nullif(max(ls.samples),0),0) as LTE2100_2600,
					isnull(1.0*max(lsd.LTE800_1800_2100_samples)/ nullif(max(ls.samples),0),0) as LTE800_1800_2100,
					isnull(1.0*max(lsd.LTE800_1800_2600_samples)/ nullif(max(ls.samples),0),0) as LTE800_1800_2600,
					isnull(1.0*max(lsd.LTE800_2100_2600_samples)/ nullif(max(ls.samples),0),0) as LTE800_2100_2600,
					isnull(1.0*max(lsd.LTE1800_2100_2600_samples)/ nullif(max(ls.samples),0),0) as LTE1800_2100_2600,
					max(lbs.BS_Number) as BS_LTE
			from 
			(			
				select  lop.operator,
						count(l.samples) as Samples
				from
						(SELECT  1 as enlace,
								count(1) as samples								
							FROM '+@4G+' l,
									agrids.dbo.lcc_parcelas lp
			 
									where l.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
											and lp.entorno in ('+ @filter +')
							group by  l.longitud_50m, l.latitud_50m) l

							left outer join 
								( select 1 as enlace, operator from '+@4G+' group by operator) lop on lop.enlace=l.enlace
				group by lop.operator

			)ls

			left outer join (					
				select  l.operator,
						count (l.pci) as BS_Number
				from
				(
					select  l.operator,
							l.pci,
							l.frecuencia
					from
						(
						SELECT  l.latitud_50m,
								l.longitud_50m,
								l.operator,
								l.pci,
								l.frecuencia,
								l.RSRP_Outdoor,
								row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.RSRP_Outdoor desc,l.frecuencia desc, l.pci desc) as id
							FROM '+@4G+' l,
									agrids.dbo.lcc_parcelas lp
			 
									where l.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
											and lp.entorno in ('+ @filter +')

						) l
					where l.id=1
					group by l.operator, l.pci, l.frecuencia
				) l
				group by l.operator

			) lbs 
				on lbs.operator=ls.operator
			
			left outer join (					
				select  l.operator,
						count (l.pci) as BS_Number,
						1.0*isnull(sum(case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end),0) as RSRP_Outdoor_Samples,
						count(l.RSRP_Outdoor) as RSRP_LTE_Samples,
						10*log10(AVG(POWER(convert(float,10.0), (convert(float,l.RSRP_Outdoor))/10.0))) as RSRP_LTE
				from
				(
					select  l.operator,
							l.pci,
							l.frecuencia,
							l.band,
							l.RSRP_Outdoor
					from
						(
						SELECT  l.latitud_50m,
								l.longitud_50m,
								l.operator,
								l.pci,
								l.frecuencia,
								l.RSRP_Outdoor,
								l.band,
								row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.RSRP_Outdoor desc) as id
							FROM '+@4G+' l,
									agrids.dbo.lcc_parcelas lp
			 
									where l.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
											and lp.entorno in ('+ @filter +')
						) l
					where l.id=1 --Por parcela y operador nos quedamos con el BS
				) l
				group by l.operator
			) lci 
				on lci.operator=ls.operator

			left outer join (					
				select  l.operator,						
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE2600'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE2600,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE2100'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE2100,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE1800'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE1800,
					10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE800'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE800,
					sum(case when l.band =''LTE800'' then 1 else 0 end) as RSRP_LTE800_Samples,
					sum(case when l.band =''LTE1800'' then 1 else 0 end) as RSRP_LTE1800_Samples,
					sum(case when l.band =''LTE2100'' then 1 else 0 end) as RSRP_LTE2100_Samples,
					sum(case when l.band =''LTE2600'' then 1 else 0 end) as RSRP_LTE2600_Samples,
					sum(case when l.band =''LTE800'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE800_Samples,
					sum(case when l.band =''LTE1800'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800_Samples,
					sum(case when l.band =''LTE1800'' and l.bandwidth = 10 and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800_BW10_Samples,
					sum(case when l.band =''LTE1800'' and l.bandwidth = 15 and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800_BW15_Samples,
					sum(case when l.band =''LTE1800'' and l.bandwidth = 20 and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800_BW20_Samples,
					sum(case when l.band =''LTE2100'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100_Samples,
					sum(case when l.band =''LTE2100'' and l.bandwidth = 5 and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100_BW5_Samples,
					sum(case when l.band =''LTE2100'' and l.bandwidth = 10 and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100_BW10_Samples,
					sum(case when l.band =''LTE2100'' and l.bandwidth = 15 and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100_BW15_Samples,
					sum(case when l.band =''LTE2600'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2600_Samples
				from
				(
					select  l.operator,
							l.pci,
							l.frecuencia,
							l.band,
							l.bandwidth,
							l.RSRP_Outdoor
					from
						(
						SELECT  l.latitud_50m,
								l.longitud_50m,
								l.operator,
								l.pci,
								l.frecuencia,
								l.RSRP_Outdoor,
								l.band,
								l.bandwidth,
								row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator,l.band order by l.RSRP_Outdoor desc, l.bandwidth desc) as id
							FROM '+@4G+' l,
									agrids.dbo.lcc_parcelas lp
			 
									where l.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
											and lp.entorno in ('+ @filter +')

						) l
					where l.id=1 --Por parcela, operador y banda nos quedamos con el BS
				) l
				group by l.operator

			) lci_band
				on lci_band.operator=ls.operator

			left outer join (
				select
					operator,
					sum(case when LTE800_1800_samples= 2 then LTE800_1800 end) as LTE800_1800_samples,
					sum(case when LTE800_2100_samples= 2 then LTE800_2100 end ) as LTE800_2100_samples,
					sum(case when LTE800_2600_samples= 2 then LTE800_2600 end ) as LTE800_2600_samples,
					sum(case when LTE1800_2100_samples= 2 then LTE1800_2100 end ) as LTE1800_2100_samples,
					sum(case when LTE1800_2600_samples= 2 then LTE1800_2600 end) as LTE1800_2600_samples,
					sum(case when LTE2100_2600_samples= 2 then LTE2100_2600 end ) as LTE2100_2600_samples,
					sum(case when LTE800_1800_2100_samples= 3 then LTE800_1800_2100 end ) as LTE800_1800_2100_samples,
					sum(case when LTE800_1800_2600_samples= 3 then LTE800_1800_2600 end ) as LTE800_1800_2600_samples,
					sum(case when LTE800_2100_2600_samples= 3 then LTE800_2100_2600 end ) as LTE800_2100_2600_samples,
					sum(case when LTE1800_2100_2600_samples= 3 then LTE1800_2100_2600 end ) as LTE1800_2100_2600_samples
				from
					(
						select  l.operator,					
								min(case when l.band in (''LTE800'', ''LTE1800'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_1800,
								min(case when l.band in (''LTE800'', ''LTE2100'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_2100,
								min(case when l.band in (''LTE800'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_2600,
								min(case when l.band in (''LTE1800'', ''LTE2100'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE1800_2100,
								min(case when l.band in (''LTE1800'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE1800_2600,
								min(case when l.band in (''LTE2100'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE2100_2600,
								min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_1800_2100,
								min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_1800_2600,
								min(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_2100_2600,
								min(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE1800_2100_2600,
								
								sum(case when l.band in (''LTE800'', ''LTE1800'') then 1 end) as LTE800_1800_samples,
								sum(case when l.band in (''LTE800'', ''LTE2100'') then 1 end) as LTE800_2100_samples,
								sum(case when l.band in (''LTE800'', ''LTE2600'') then 1 end) as LTE800_2600_samples,
								sum(case when l.band in (''LTE1800'', ''LTE2100'') then 1 end) as LTE1800_2100_samples,
								sum(case when l.band in (''LTE1800'', ''LTE2600'') then 1 end) as LTE1800_2600_samples,
								sum(case when l.band in (''LTE2100'', ''LTE2600'') then 1 end) as LTE2100_2600_samples,
								sum(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then 1 end) as LTE800_1800_2100_samples,
								sum(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then 1 end) as LTE800_1800_2600_samples,
								sum(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then 1 end) as LTE800_2100_2600_samples,
								sum(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then 1 end) as LTE1800_2100_2600_samples

						from
						(
							SELECT  l.latitud_50m,
									l.longitud_50m,
									l.operator,
									l.pci,
									l.frecuencia,
									l.RSRP_Outdoor,
									l.band,
									row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator,l.band order by l.RSRP_Outdoor desc) as id
							FROM '+@4G+' l,
									agrids.dbo.lcc_parcelas lp
			 
									where l.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
											and lp.entorno in ('+ @filter +')

						) l

						where l.id=1 --Por parcela, operador y banda nos quedamos con el BS
						group by l.operator,l.latitud_50m,	l.longitud_50m	
					) t	
				group by t.operator
			) lsd
				on lsd.operator=ls.operator
			group by ls.operator
		) l
		on l.operator = o.operator
	
	order by case when o.operator=''Vodafone'' then '''' else o.operator end
	'
	)
end

else if @sheet = 'Samples_Indoor' or @sheet = 'Samples_Outdoor'
begin

exec(
--print
	'select
			isnull(l.LTE_Samples,0) as LTE_Samples,
			isnull(l.LTE,0) as LTE,
			isnull(l.LTE2600,0) as LTE2600,
			isnull(l.LTE2100,0) as LTE2100,
			isnull(l.LTE2100_BW5,0) as LTE2100_BW5,
			isnull(l.LTE2100_BW10,0) as LTE2100_BW10,
			isnull(l.LTE2100_BW15,0) as LTE2100_BW15,
			isnull(l.LTE1800,0) as LTE1800,
			isnull(l.LTE1800_BW10,0) as LTE1800_BW10,
			isnull(l.LTE1800_BW15,0) as LTE1800_BW15,
			isnull(l.LTE1800_BW20,0) as LTE1800_BW20,
			isnull(l.LTE800,0) as LTE800,
			isnull(l_frec.LTE800_1800,0) as LTE800_1800,
			isnull(l_frec.LTE800_2100,0) as LTE800_2100,
			isnull(l_frec.LTE800_2600,0) as LTE800_2600,
			isnull(l_frec.LTE1800_2100,0) as LTE1800_2100,
			isnull(l_frec.LTE1800_2600,0) as LTE1800_2600,
			isnull(l_frec.LTE2100_2600,0) as LTE2100_2600,
			isnull(l_frec.LTE800_1800_2100,0) as LTE800_1800_2100,
			isnull(l_frec.LTE800_1800_2600,0) as LTE800_1800_2600,
			isnull(l_frec.LTE800_2100_2600,0) as LTE800_2100_2600,
			isnull(l_frec.LTE1800_2100_2600,0) as LTE1800_2100_2600,
			isnull(u.UMTS_Samples,0) as UMTS_Samples,
			isnull(u.UMTS,0) as UMTS,
			isnull(u.UMTS2100,0) as UMTS2100,
			isnull(u_frec.UMTS2100_Carrier_only,0) as UMTS2100_Carrier_only,
			isnull(u_frec.UMTS2100_F1,0) as UMTS2100_F1,
			isnull(u_frec.UMTS2100_F2,0) as UMTS2100_F2,
			isnull(u_frec.UMTS2100_F3,0) as UMTS2100_F3,
			isnull(u_frec.UMTS2100_Dual_Carrier,0) as UMTS2100_Dual_Carrier,
			isnull(u_frec.UMTS2100_F1_F2,0) as UMTS2100_F1_F2,
			isnull(u_frec.UMTS2100_F1_F3,0) as UMTS2100_F1_F3,
			isnull(u_frec.UMTS2100_F2_F3,0) as UMTS2100_F2_F3,
			isnull(u_frec.UMTS2100_F1_F2_F3,0) as UMTS2100_F1_F2_F3,
			isnull(u_frec.UMTS2100_P1,0) as UMTS2100_P1,
			isnull(u_frec.UMTS2100_P2,0) as UMTS2100_P2,
			isnull(u_frec.UMTS2100_P3,0) as UMTS2100_P3,
			isnull(u.UMTS900,0) as UMTS900,
			isnull(u_frec.UMTS900_F1,0) as UMTS900_F1,
			isnull(u_frec.UMTS900_F2,0) as UMTS900_F2,
			isnull(u_frec.UMTS900_U2100_Carrier_only,0) as UMTS900_U2100_Carrier_only,
			isnull(u_frec.UMTS900_U2100_F1,0) as UMTS900_U2100_F1,
			isnull(u_frec.UMTS900_U2100_F2,0) as UMTS900_U2100_F2,
			isnull(u_frec.UMTS900_U2100_F3,0) as UMTS900_U2100_F3,
			isnull(u_frec.UMTS900_U2100_Dual_Carrier,0) as UMTS900_U2100_Dual_Carrier,
			isnull(u_frec.UMTS900_U2100_F1_F2,0) as UMTS900_U2100_F1_F2,
			isnull(u_frec.UMTS900_U2100_F1_F3,0) as UMTS900_U2100_F1_F3,
			isnull(u_frec.UMTS900_U2100_F2_F3,0) as UMTS900_U2100_F2_F3,
			isnull(u_frec.UMTS900_U2100_F1_F2_F3,0) as UMTS900_U2100_F1_F2_F3,
			isnull(u_frec.UMTS900_P1,0) as UMTS900_P1,
			isnull(u_frec.UMTS900_P2,0) as UMTS900_P2,
			isnull(g.[2G_Samples],0) as [2G_Samples],
			isnull(g.[2G],0) as [2G],
			isnull(g.GSM_DCS,0) as GSM_DCS,
			isnull(g.GSM,0) as GSM,
			isnull(g.DCS,0) as DCS

	from
		(
			select operator as operator from '+@4G+' where operator is not null group by operator
			union
			select operator from '+@3G+' where operator is not null group by operator
			union
			select operator from '+@2G+' where operator is not null group by operator
		) o

		left join(
			select 
				gs.operator,
				gs.samples [2G_Samples],
				gci.RSSI_Outdoor_Samples as [2G],
				g.GSM,
				g.DCS,
				gci_band.GSM_DCS
			from 
				(			
					select  gop.operator,
							count(g.samples) as Samples
					from
							(SELECT  1 as enlace,
									count(1) as samples
								
								FROM '+@2G+' g,
										agrids.dbo.lcc_parcelas lp
			 
										where g.operator is not null
												and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
												and lp.entorno in ('+ @filter +')
								group by  g.longitud_50m, g.latitud_50m) g

								left outer join 
									( select 1 as enlace, operator from '+@2G+' group by operator) gop on gop.enlace=g.enlace
					group by gop.operator

				)gs  --Todas las parcelas con muestras, sean del operador que sean				

				left outer join
				(
					select g.operator,
						sum(case when g.band in (''GSM'', ''EGSM'') and G.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as GSM,
						sum(case when g.band = ''DCS'' and G.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as DCS
					from 
					(SELECT  g.latitud_50m,
							g.longitud_50m,
							g.operator,
							g.BSIC,
							g.frecuencia,
							g.band,
							g.RSSI_Outdoor,
							g.pcobInd,
							row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator,g.band order by g.RSSI_Outdoor desc) as id
						FROM '+@2G+' g,
								agrids.dbo.lcc_parcelas lp
			 
								where g.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
										and lp.entorno in ('+ @filter +')
					) g
					where g.id=1 
					group by g.operator
				)g --id=1 Por parcela, operador y banda nos quedamos con el BS			
					on gs.operator=g.operator

				left outer join (					
					select 
						g.operator,
						sum(case when g.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as RSSI_Outdoor_Samples
					from
						(
						SELECT  g.latitud_50m,
								g.longitud_50m,
								g.operator,
								g.BSIC,
								g.frecuencia,
								g.band,
								g.RSSI_Outdoor,
								row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator order by g.RSSI_Outdoor desc) as id
							FROM '+@2G+' g,
									agrids.dbo.lcc_parcelas lp
			 
									where g.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											and lp.entorno in ('+ @filter +')											

						) g 

					where g.id=1  --Por parcela, operador nos quedamos con el BS
					group by g.operator

				) gci 
					on gci.operator=g.operator

				left outer join (	
					select	
						operator,	
						sum (case when isnull(GSM_samples,0)+isnull(DCS_samples,0)= 2 then GSM_DCS end) as GSM_DCS
					from
					(		
						select  g.operator,
								min(case when g.band in (''GSM'', ''EGSM'',''DCS'') and G.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as GSM_DCS,
								min(case when g.band in (''GSM'', ''EGSM'') then 1 end) as GSM_samples,
								min(case when g.band in (''DCS'') then 1 end) as DCS_samples
						from
							(
							SELECT  g.latitud_50m,
									g.longitud_50m,
									g.operator,
									g.BSIC,
									g.frecuencia,
									g.band,
									g.RSSI_Outdoor,
									g.pcobInd,
									row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator, g.band order by g.RSSI_Outdoor desc) as id
								FROM '+@2G+' g,
										agrids.dbo.lcc_parcelas lp
			 
										where g.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											and lp.entorno in ('+ @filter +')		
											

							) g

						where g.id=1 --Por parcela 50x50, operador nos quedamos con el BS de nivel de señal

						group by g.operator,g.latitud_50m, g.longitud_50m	
					) t
					group by t.operator
				) gci_band
					on gci_band.operator=g.operator			

		) g
		on g.operator = o.operator

		left join(
			select 
					us.operator,
					us.samples as UMTS_Samples,
					uci.RSCP_Outdoor_Samples as UMTS,
					u.UMTS2100,
					u.UMTS900			
			from 
				(			
					select  uop.operator,
							count(u.samples) as Samples
					from
							(SELECT  1 as enlace,
									count(1) as samples
								
								FROM '+@3G+' u,
										agrids.dbo.lcc_parcelas lp
			 
										where u.operator is not null
												and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
												and lp.entorno in ('+ @filter +')
								group by  u.longitud_50m, u.latitud_50m) u

								left outer join 
									( select 1 as enlace, operator from '+@3G+' group by operator) uop on uop.enlace=u.enlace
					group by uop.operator

				)us --Todas las parcelas con muestras, sean del operador que sean
				
				left outer join
				(
					select u.operator,
						sum(case when u.band= ''UMTS2100'' and u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) as UMTS2100,
						sum(case when u.band= ''UMTS900'' and u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) as UMTS900						
					from
					(SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							u.SC,
							u.frecuencia,
							u.band,
							u.RSCP_Outdoor,
							row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band order by u.RSCP_Outdoor desc) as id
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
								where u.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
										and lp.entorno in ('+ @filter +')
					)u
					where u.id=1 --Por parcela, operador y banda nos quedamos con el BS
					group by u.operator
				) u --id=1 Por parcela, operador y banda nos quedamos con el BS
				on us.operator=u.operator

				left outer join (					
					select  
						u.operator,
						sum(case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) as RSCP_Outdoor_Samples						
					from
						(
						SELECT  u.latitud_50m,
								u.longitud_50m,
								u.operator,
								u.SC,
								u.frecuencia,
								u.band,
								u.RSCP_Outdoor,
								u.Cuadricula_Polluter,
								row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.RSCP_Outdoor desc, u.Cuadricula_Polluter desc) as id
							FROM '+@3G+' u,
									agrids.dbo.lcc_parcelas lp			 
							where u.operator is not null
								and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
								and lp.entorno in ('+ @filter +')
											

						) u
					where u.id=1
					group by u.operator
				) uci 
					on uci.operator=u.operator		

		) u
		on u.operator = o.operator
		
		left join(	
			select
				operator,
				sum(UMTS2100_F1) as UMTS2100_F1,
				sum(UMTS2100_F2) as UMTS2100_F2,
				sum(UMTS2100_F3) as UMTS2100_F3,
				sum(UMTS2100_P1) as UMTS2100_P1,
				sum(UMTS2100_P2) as UMTS2100_P2,
				sum(UMTS2100_P3) as UMTS2100_P3,
				sum(UMTS900_F1) as UMTS900_F1,
				sum(UMTS900_F2) as UMTS900_F2,
				sum(UMTS900_P1) as UMTS900_P1,
				sum(UMTS900_P2) as UMTS900_P2,
				sum(case when UMTS2100_F1_F2_Samples= 2 then UMTS2100_F1_F2 end) as UMTS2100_F1_F2,
				sum(case when UMTS2100_F1_F3_Samples= 2 then UMTS2100_F1_F3 end ) as UMTS2100_F1_F3,
				sum(case when UMTS2100_F2_F3_Samples= 2 then UMTS2100_F2_F3 end ) as UMTS2100_F2_F3,
				sum(case when UMTS2100_F1_F2_F3_Samples= 3 then UMTS2100_F1_F2_F3 end ) as UMTS2100_F1_F2_F3,
				--Solo una portadora
				sum(case when isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)= 1 then 1 else 0 end) as UMTS2100_Carrier_only,
				--Solo dos portadoras
				sum(case when isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)= 2 then 1 else 0 end) as UMTS2100_Dual_Carrier,

				sum(case when UMTS900_Samples+UMTS2100_F1_Samples= 2 and U900>0 and UMTS2100_F1>0 then 1 else 0 end) as UMTS900_U2100_F1,
				sum(case when UMTS900_Samples+UMTS2100_F2_Samples= 2 and U900>0 and UMTS2100_F2>0 then 1 else 0 end ) as UMTS900_U2100_F2,
				sum(case when UMTS900_Samples+UMTS2100_F3_Samples= 2 and U900>0 and UMTS2100_F3>0 then 1 else 0 end) as UMTS900_U2100_F3,
				sum(case when UMTS900_Samples+UMTS2100_F1_F2_Samples= 3 and U900>0 and UMTS2100_F1_F2>0 then 1 else 0 end) as UMTS900_U2100_F1_F2,
				sum(case when UMTS900_Samples+UMTS2100_F1_F3_Samples= 3 and U900>0 and UMTS2100_F1_F3>0 then 1 else 0 end) as UMTS900_U2100_F1_F3,
				sum(case when UMTS900_Samples+UMTS2100_F2_F3_Samples= 3 and U900>0 and UMTS2100_F2_F3>0 then 1 else 0 end) as UMTS900_U2100_F2_F3,
				sum(case when UMTS900_Samples+UMTS2100_F1_F2_F3_Samples= 4 and U900>0 and UMTS2100_F1_F2_F3>0 then 1 else 0 end) as UMTS900_U2100_F1_F2_F3,
				--U900 y solo una portadora
				sum(case when U900>0 and isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)=1
					then 1 else 0 end) as UMTS900_U2100_Carrier_only,
				--U900 y dos portadoras
				sum(case when U900>0 and isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)=2
					then 1 else 0 end) as UMTS900_U2100_Dual_Carrier
			from
				(
				select u.operator, 					
					min(case when u.frecuencia in (10713, 10788, 10638, 10563) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1,
					min(case when u.frecuencia in (10738, 10813, 10663, 10588) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F2,
					min(case when u.frecuencia in (10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F3,
					min(case when u.band= ''UMTS2100'' and u.idBand = 1 then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_P1,
					min(case when u.band= ''UMTS2100'' and u.idBand = 2 then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_P2,
					min(case when u.band= ''UMTS2100'' and u.idBand = 3 then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_P3,
					min(case when u.frecuencia in (3087,3011,2959) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS900_F1,
					min(case when u.frecuencia in (3062,3032) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS900_F2,
					min(case when u.band= ''UMTS900'' and u.idBand = 1 then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS900_P1,
					min(case when u.band= ''UMTS900'' and u.idBand = 2 then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS900_P2,
					--Exista cobertura U2100 en las dos frecuencias de cada desglose
					min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1_F2,
					min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1_F3,
					min(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F2_F3,
					min(case when u.frecuencia in (10713, 10788, 10638, 10563,10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1_F2_F3,
					--Exista cobertura en alguna de frecuencias de UMTS900
					max(case when u.band= ''UMTS900'' then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as U900,

					sum(case when u.frecuencia in (10713, 10788, 10638, 10563) then 1 end) as UMTS2100_F1_Samples,
					sum(case when u.frecuencia in (10738, 10813, 10663, 10588) then 1 end) as UMTS2100_F2_Samples,
					sum(case when u.frecuencia in (10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F3_Samples,
					sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) then 1 end) as UMTS2100_F1_F2_Samples,
					sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F1_F3_Samples,
					sum(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F2_F3_Samples,
					sum(case when u.frecuencia in (10713, 10788, 10638, 10563,10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F1_F2_F3_Samples,
					min(case when u.band= ''UMTS900'' then 1 end) as UMTS900_Samples
				from 
					(
					SELECT  u.latitud_50m,
							u.longitud_50m,
							u.operator,
							u.SC,
							u.frecuencia,
							u.band,
							u.RSCP_Outdoor,
							row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band,frecuencia order by u.RSCP_Outdoor desc) as id,
							row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band order by u.RSCP_Outdoor desc) as idBand
						FROM '+@3G+' u,
								agrids.dbo.lcc_parcelas lp
			 
								where u.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
										and lp.entorno in ('+ @filter +')
					) u 
				where u.id=1 --Por parcela, operador, banda y frecuencia nos quedamos con el BS
				group by u.operator,u.latitud_50m,	u.longitud_50m	
				) t
			group by t.operator
		) u_frec
		on u_frec.operator=o.operator

		left join(
			select 
					ls.operator,
					ls.Samples as LTE_Samples,
					lci.RSRP_Outdoor_samples as LTE,
					l.LTE2600,
					l.LTE2100,
					l.LTE2100_BW5,
					l.LTE2100_BW10,
					l.LTE2100_BW15,
					l.LTE1800,
					l.LTE1800_BW10,
					l.LTE1800_BW15,
					l.LTE1800_BW20,
					l.LTE800
			from 
			(			
				select  lop.operator,
						count(l.samples) as Samples
				from
						(SELECT  1 as enlace,
								count(1) as samples
								
							FROM '+@4G+' l,
									agrids.dbo.lcc_parcelas lp
			 
									where l.operator is not null
											and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
											and lp.entorno in ('+ @filter +')
							group by  l.longitud_50m, l.latitud_50m) l

							left outer join 
								( select 1 as enlace, operator from '+@4G+' group by operator) lop on lop.enlace=l.enlace
				group by lop.operator
			)ls --Todas las parcelas con muestras, sean del operador que sean
				

			left outer join(
				select l.operator,
					sum(case when l.band= ''LTE2600'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2600,
					sum(case when l.band= ''LTE2100'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100,
					sum(case when (l.band= ''LTE2100'' and l.bandwidth=5) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100_BW5,
					sum(case when (l.band= ''LTE2100'' and l.bandwidth=10) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100_BW10,
					sum(case when (l.band= ''LTE2100'' and l.bandwidth=15) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100_BW15,
					sum(case when l.band= ''LTE1800'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800,
					sum(case when (l.band= ''LTE1800'' and l.bandwidth=10) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800_BW10,
					sum(case when (l.band= ''LTE1800'' and l.bandwidth=15) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800_BW15,
					sum(case when (l.band= ''LTE1800'' and l.bandwidth=20) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800_BW20,
					sum(case when l.band= ''LTE800'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE800
				from
					(
					SELECT  l.latitud_50m,
							l.longitud_50m,
							l.operator,
							l.pci,
							l.frecuencia,
							l.band,
							l.bandwidth,
							l.RSRP_Outdoor,
							row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator,l.band order by l.RSRP_Outdoor desc, l.bandwidth desc) as id
						FROM '+@4G+' l,
								agrids.dbo.lcc_parcelas lp
			 
								where l.operator is not null
										and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
										and lp.entorno in ('+ @filter +')
					) l
				where l.id=1 --Por parcela, operador y banda nos quedamos con el BS
				group by l.operator
			) l	
				
			on ls.operator=l.operator

			left outer join (					
				select
					l.operator,
					isnull(sum(case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end),0) as RSRP_Outdoor_Samples
				from
				(
					select l.operator,
						l.pci,
						l.frecuencia,
						l.band,
						l.RSRP_Outdoor
					from
						(
						SELECT  
								l.latitud_50m,
								l.longitud_50m,
								l.operator,
								l.pci,
								l.frecuencia,
								l.RSRP_Outdoor,
								l.band,
								row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.RSRP_Outdoor desc) as id
							FROM '+@4G+' l,
									agrids.dbo.lcc_parcelas lp
			 
							where l.operator is not null
								and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
								and lp.entorno in ('+ @filter +')
											

						) l

					where l.id=1 --Por parcela y operador nos quedamos con el BS
				) l
				group by l.operator

			) lci 
				on lci.operator=l.operator
		) l
		on l.operator = o.operator

		left join(
			 select
				operator,
				sum(case when LTE800_1800_samples= 2 then LTE800_1800 end) as LTE800_1800,
				sum(case when LTE800_2100_samples= 2 then LTE800_2100 end ) as LTE800_2100,
				sum(case when LTE800_2600_samples= 2 then LTE800_2600 end ) as LTE800_2600,
				sum(case when LTE1800_2100_samples= 2 then LTE1800_2100 end ) as LTE1800_2100,
				sum(case when LTE1800_2600_samples= 2 then LTE1800_2600 end) as LTE1800_2600,
				sum(case when LTE2100_2600_samples= 2 then LTE2100_2600 end ) as LTE2100_2600,
				sum(case when LTE800_1800_2100_samples= 3 then LTE800_1800_2100 end ) as LTE800_1800_2100,
				sum(case when LTE800_1800_2600_samples= 3 then LTE800_1800_2600 end ) as LTE800_1800_2600,
				sum(case when LTE800_2100_2600_samples= 3 then LTE800_2100_2600 end ) as LTE800_2100_2600,
				sum(case when LTE1800_2100_2600_samples= 3 then LTE1800_2100_2600 end ) as LTE1800_2100_2600
			 from
				(
				select 
						l.operator,					
						min(case when l.band in (''LTE800'', ''LTE1800'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_1800,
						min(case when l.band in (''LTE800'', ''LTE2100'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_2100,
						min(case when l.band in (''LTE800'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_2600,
						min(case when l.band in (''LTE1800'', ''LTE2100'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE1800_2100,
						min(case when l.band in (''LTE1800'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE1800_2600,
						min(case when l.band in (''LTE2100'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE2100_2600,
						min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_1800_2100,
						min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_1800_2600,
						min(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_2100_2600,
						min(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE1800_2100_2600,
						sum(case when l.band in (''LTE800'', ''LTE1800'') then 1 end) as LTE800_1800_samples,
						sum(case when l.band in (''LTE800'', ''LTE2100'') then 1 end) as LTE800_2100_samples,
						sum(case when l.band in (''LTE800'', ''LTE2600'') then 1 end) as LTE800_2600_samples,
						sum(case when l.band in (''LTE1800'', ''LTE2100'') then 1 end) as LTE1800_2100_samples,
						sum(case when l.band in (''LTE1800'', ''LTE2600'') then 1 end) as LTE1800_2600_samples,
						sum(case when l.band in (''LTE2100'', ''LTE2600'') then 1 end) as LTE2100_2600_samples,
						sum(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then 1 end) as LTE800_1800_2100_samples,
						sum(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then 1 end) as LTE800_1800_2600_samples,
						sum(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then 1 end) as LTE800_2100_2600_samples,
						sum(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then 1 end) as LTE1800_2100_2600_samples
				from 
				(
				SELECT  l.latitud_50m,
						l.longitud_50m,
						l.operator,
						l.pci,
						l.frecuencia,
						l.band,
						l.bandwidth,
						l.RSRP_Outdoor,
						row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator,l.band order by l.RSRP_Outdoor desc, l.bandwidth desc) as id
					FROM '+@4G+' l,
							agrids.dbo.lcc_parcelas lp
			 
							where l.operator is not null
									and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
									and lp.entorno in ('+ @filter +')
				) l
				where l.id=1 --Por parcela, operador y banda nos quedamos con el BS
				group by l.operator,l.latitud_50m,	l.longitud_50m	
				) t
			group by t.operator

		) l_frec
		on l_frec.operator=o.operator	
	order by case when o.operator=''Vodafone'' then '''' else o.operator end	
'
)


end

