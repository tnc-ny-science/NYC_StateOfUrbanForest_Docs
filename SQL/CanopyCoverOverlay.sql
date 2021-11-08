-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Generic/Template code for canopy cover and chanopy change analysis; See below for two examples.
--
-- Example 1 is fairly general (canopy change analysis by borough)
-- Example 2 illustrates multiple steps - developing buffers of NYC Neighborhood Tabulation Areas (by 1/4 mile), clipped
--  to borough boundaries, setting up spatial indexes, and then doing the canopy change analysis for those units.
--  Example 2 results were used for in analyses presented in Chapter 4 of the report.

--
--  The query below is designed to take canopy change data layer (representing gain, loss, or no change polygons)
--  and another polygon layer that one wants canopy change metrics for (e.g., borough boundaries), and output a 
--  spatial layer with the original polygons from the overlay layer, a specific identifier field (e.g., borough name)
--  and various metrics for canopy and canopy change for each polygon. This assumes a foot-based coordinate reference system.
--  The metrics returned are: polygon area (unit_ft2); area of canopy gain (gain_ft2); area for which canopy did not change
--  (nochange_ft2); area of canopy loss (loss_ft2); canopy area in 2010 (canopy_2010_ft2); canopy area in 2017 (canopy_2017_ft2)
--  percentage of area covered by canopy in 2010 and 2017 (canopy_2010_pct and canopy_2017_pct, respectively); change in canopy area
--  from 2010 to 2017 (canopy_17min10_ft2); change in percent land covered by canopy (canopy_17min10_pct); relative change in canopy,
--  expressed as a decimal (canopy_17min10_div10).
--
--In example code below, results are rounded to two decimals. 
-- 
--  The canopy change layer is assumed to be stored in schema 'env_assets' as table 'canopychange_2010_2017'
--  "class" is the class of polygons for the canopy change layer (e.g., gain, loss, or no change)
--  The layer that the canopy change layer is being overlayed with is schema.table name; in the code below: sch.intable
--      e.g., if overlaying canopy change by boroughs, it might be in schema="admin" and table="boroughs_nowater"
--  The field in data that serves as the unit of aggregation (e.g., administrative or political units): infield
--      e.g., if overlaying canopy change by boroughs, infield may be "boroname"
--  The results go into the table defined below as: results_utc_landcover.canopyvector_outtable
--      Users can use whatever schema and table they desire
--  This also assumes geometry fields in both datasets are called 'geom_2263'
--
-- Note - in many cases users will want to create spatial indexes for the data. Examle code for that is provide below
--
--    CREATE INDEX sidx_[layername]_geom_2263 ON 
--    [schemaname].[tablename]
 --    USING GIST(geom_2263);

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Heuristic example
-- Define output table
create table results_utc_landcover.canopyvector_outtable as 
    --Set up common table expression (CTE); calculate, for every area with a unique identifier based on infield in overlay layer
    -- the sum of area of gain, loss, and no change 
    with cte as (
    select
        infield,
        sum(st_area(geom_2263)) as cliparea,
        class
    from
        --This portion of the code selects the intersection  of each set of canopy change polygons within each polygon for the overlay layer
        --Note - if using more recent versions of PostGIS (e.g., 3.1.1) everything from "case when" to "end" can be replaced by
        --"st_multi(st_intersection(cc.geom_2263, su.geom_2263))"  (the "case when" statement with st_coveredby can improve performance in older versions)
        (select cc.class,
            su.infield,
            case when st_CoveredBy(cc.geom_2263, su.geom_2263) then cc.geom_2263
            else st_multi(ST_Intersection(cc.geom_2263, su.geom_2263))
            end as geom_2263
        from
            env_assets.canopychange_2010_2017 as cc
            inner join sch.intable as su on (st_Intersects(cc.geom_2263, su.geom_2263))) as foo
        group by
        infield,
        class)
    --From the common table expression, calculate - for every unique id in 'infield' (e.g., borough identifier or similar)
    -- a number of metrics for area, canopy, and canpy change. 
    select
        su.infield,
        su.geom_2263,
        round(st_area(su.geom_2263)::numeric, 2) as unit_ft2,
        round(sum(case when cte.class = 'Gain' then cte.cliparea else 0 end)::numeric, 2) as gain_ft2,
        round(sum(case when cte.class = 'No Change' then cte.cliparea else 0 end)::numeric, 2) as nochange_ft2,
        round(sum(case when cte.class = 'Loss' then cte.cliparea else 0 end)::numeric, 2) as loss_ft2,
        round(sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)::numeric, 2) as canopy_2010_ft2,
        round(sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)::numeric, 2) as canopy_2017_ft2,
        round(((sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100)::numeric, 2) as canopy_2010_pct,
        round(((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100)::numeric, 2) as canopy_2017_pct,
        round(((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)) - (sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)))::numeric, 2) as canopy_17min10_ft2,
        round((((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100) - ((sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100))::numeric, 2) as canopy_17min10_pct,
        round((case when sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)>0 then (((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)) - (sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)))/(sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end))) else 0 end)::numeric, 2) as canopy_17min10_div10
    --Join the results of the above to the original geometry data for the overlay layer
    -- which results in the output being a spatial layer with the 'infield' 
    from sch.intable as su
    left join cte 
    on su.infield = cte.infield
    group by
    su.infield,
    su.geom_2263;


--NOTE: Users can leverage parallel processing on CPUs. Run the below (with adjusted parameters) before running the code above
-- define number of threads PostgreSQL will be able to use for parallel operations
-- e.g., on a 6 core machine with 12 logical threads, one may set this value to 10
set max_parallel_workers =10;
-- set the max number of parallel threads that will be leveraged within a single 'gather'
-- set to 6 in this case
set max_parallel_workers_per_gather=6;
-- Confirm the parameter above is set correctly
show max_parallel_workers_per_gather;
SET work_mem='2097151';



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Example 1, assuming borough boundaries data are in schema 'admin' and table 'boroughs_nowater'
create table results_utc_landcover.canopyvector_outtable as 
    --Set up common table expression (CTE); calculate, for every area with a unique identifier based on infield in overlay layer
    -- the sum of area of gain, loss, and no change 
    with cte as (
    select
        boroname,
        sum(st_area(geom_2263)) as cliparea,
        class
    from
          (select cc.class,
          su.boroname,
          case when st_CoveredBy(cc.geom_2263, su.geom_2263) then cc.geom_2263
          else st_multi(ST_Intersection(cc.geom_2263, su.geom_2263))
          end as geom_2263
        from
            env_assets.canopychange_2010_2017 as cc
            inner join admin.boroughs_nowater as su on (st_Intersects(cc.geom_2263, su.geom_2263))) as foo
        group by
        boroname,
        class)
    select
        su.boroname,
        su.geom_2263,
        round(st_area(su.geom_2263)::numeric, 2) as unit_ft2,
        round(sum(case when cte.class = 'Gain' then cte.cliparea else 0 end)::numeric, 2) as gain_ft2,
        round(sum(case when cte.class = 'No Change' then cte.cliparea else 0 end)::numeric, 2) as nochange_ft2,
        round(sum(case when cte.class = 'Loss' then cte.cliparea else 0 end)::numeric, 2) as loss_ft2,
        round(sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)::numeric, 2) as canopy_2010_ft2,
        round(sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)::numeric, 2) as canopy_2017_ft2,
        round(((sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100)::numeric, 2) as canopy_2010_pct,
        round(((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100)::numeric, 2) as canopy_2017_pct,
        round(((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)) - (sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)))::numeric, 2) as canopy_17min10_ft2,
        round((((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100) - ((sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100))::numeric, 2) as canopy_17min10_pct,
        round((case when sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)>0 then (((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)) - (sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)))/(sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end))) else 0 end)::numeric, 2) as canopy_17min10_div10
    from  admin.boroughs_nowater as su
    left join cte 
    on su.boroname = cte.boroname
    group by
    su.boroname,
    su.geom_2263;



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Example 2, canopy cahnge for NYC Neighborhood Tabulation Areas + 1/4 mile buffer (Clipped to Boroughs)
-- Used in Equity correlation analyses
--summary unit table name: sonyct_misc.nycnta_qtr_mi_buff
--summary unit group by field: ntacode
--results table name: results_utc_landcover.canopyvector_nycnta_qtr_mi_buff


-- Code sets up buffer of NTAs, clipped to boroughs
create table sonyct_misc.nycnta_qtr_mi_buff as 
select nna.ntacode, nna.ntaname, st_union(st_multi(st_intersection(st_buffer(nna.geom_2263, 1320), nbna.geom_2263))) as geom_2263 
from admin.nycdcp_nycnta2010 nna
join admin.nycdcp_borough_nowater nbna 
on st_intersects(nna.geom_2263, nbna.geom_2263)
group by nna.ntacode, nna.ntaname;

--Geometry type is specified for the column
alter table sonyct_misc.nycnta_qtr_mi_buff
ALTER COLUMN geom_2263 TYPE geometry(MultiPolygon,2263) 
                        USING ST_SetSRID(geom_2263,2263)

--primary key is set
alter table sonyct_misc.nycnta_qtr_mi_buff
add pgid serial primary key;

--spatial index is created
create index nycnta_qtr_mi_buffgeom_idx on sonyct_misc.nycnta_qtr_mi_buff
using gist(geom_2263);

-- set things up to run across multiple CPU cores and with ~2GB per core
set max_parallel_workers = 8;
set max_parallel_workers_per_gather=6;
show max_parallel_workers_per_gather;
SET work_mem='2097151';

--Run Query to calculate canopy metrics by NTA+1/4 mile (clipped to land)
create table results_utc_landcover.canopyvector_nycnta_qtr_mi_buff as 
with cte as (
select
	ntacode,
	ntaname,
	sum(st_area(geom_2263)) as cliparea,
	class
from
	(select cc.class,
		su.ntacode,
		su.ntaname,
		case when st_CoveredBy(cc.geom_2263, su.geom_2263) then cc.geom_2263
		else st_multi(ST_Intersection(cc.geom_2263, su.geom_2263))
		end as geom_2263
	from
		env_assets.canopychange_2010_2017 as cc
		inner join sonyct_misc.nycnta_qtr_mi_buff as su on (st_Intersects(cc.geom_2263, su.geom_2263))) as foo
	group by
	ntacode,
	ntaname,
	class)
select
	su.ntacode,
	su.ntaname,
	su.geom_2263,
	round(st_area(su.geom_2263)::numeric, 2) as unit_ft2,
	round(sum(case when cte.class = 'Gain' then cte.cliparea else 0 end)::numeric, 2) as gain_ft2,
	round(sum(case when cte.class = 'No Change' then cte.cliparea else 0 end)::numeric, 2) as nochange_ft2,
	round(sum(case when cte.class = 'Loss' then cte.cliparea else 0 end)::numeric, 2) as loss_ft2,
	round(sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)::numeric, 2) as canopy_2010_ft2,
	round(sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)::numeric, 2) as canopy_2017_ft2,
	round(((sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100)::numeric, 2) as canopy_2010_pct,
	round(((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100)::numeric, 2) as canopy_2017_pct,
	round(((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)) - (sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)))::numeric, 2) as canopy_17min10_ft2,
	round((((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100) - ((sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)/ st_area(su.geom_2263))* 100))::numeric, 2) as canopy_17min10_pct,
	round((case when sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)>0 then (((sum(case when cte.class = 'No Change' or cte.class = 'Gain' then cte.cliparea else 0 end)) - (sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end)))/(sum(case when cte.class = 'No Change' or cte.class = 'Loss' then cte.cliparea else 0 end))) else 0 end)::numeric, 2) as canopy_17min10_div10
from sonyct_misc.nycnta_qtr_mi_buff as su
left join cte 
on su.ntacode = cte.ntacode
group by
su.ntacode,
su.ntaname,
su.geom_2263;
