---------------------------------------------
-- The below code leverages data from the street tree censuses for NYC to date.
-- This assumes that data are in a PostGIS database as follows; the content on 
-- the right side of the hyphen denotes the databas schema and table (schema.table)
--   - NYC NTA boundaries (no water) - admin.nycdcp_nta2010_nowater
--   - NYC Community District boundaries (no water) - admin.nycdcp_commdists_nowater
--   - NYC Council District boundaries (no water) - admin.nycdcp_coundists2010_nowater
--   - NYC Borough boundaries (no water) - admin.nycdcp_borough_nowater
--   - NYC LION dataset, version 16a - infrastructure.lion16a
--   - NYC Parks Street Tree Capacity - env_assets.nycdpr_blockface_capacity
--	 - 1995-1996 Street Tree Census - env_assets.streettrees1995
--	 - 2005-2006 Street Tree Census - env_assets.streettrees2005
--	 - 2015-2016 Street Tree Census - env_assets.streettrees2015
--
-- Results in each step get written to a schema called 'results_streettrees' that should be
-- created before running the queries. Final product for each geography is in a table called
-- following a convention of: 'results_streettrees.treecensus_summaries_[unit]_final'  


---------------------
-------Street Tree Metrics for Neighborhood Tabulation Areas
---------------------
-- Compute 2015 Street Tree Summaries - pct living < 6", >30", most common species, total #, # Not Stump (live + dead), 
-- and # Live Based on spatial overlay W/ Respective boundaries
create table results_streettrees.treecensus2015_summaries_ntas2010 as 
	select foo1.ntacode, foo1.ntaname, foo1.geom_2263,
		treecount2015_all, 
		treecount2015_notstump, 
		treecount2015_alive, 
		spc_mostcommon_living,
		round(roadlength, 2) as roadmiles, 
		case when roadlength = 0 then NULL else
			(round(treecount2015_alive::numeric/roadlength::numeric, 2))
			end as livingtree_x_mile2015,
		round(avg_dbh_living, 2) as avg_dbh_living, 
		med_dbh_living,
		cnt_dbh_lt6_notstump,
		cnt_dbh_lt6_living,
		case when treecount2015_alive = 0 then NULL else
			(round(cnt_dbh_lt6_living::numeric/treecount2015_alive::numeric*100, 3))
			end as pct_lt6_dbh_living,
		cnt_dbh_gt30_notstump,
		cnt_dbh_gt30_living,
		case when treecount2015_alive = 0 then NULL else
			(round(cnt_dbh_gt30_living::numeric/treecount2015_alive::numeric*100, 3))
			end as pct_gt30_dbh_living
		from   
	(select 
		count(*) as treecount2015_all,
		avg(tree_dbh::numeric) filter(where status like 'Alive') as avg_dbh_living, 
		percentile_disc(0.5) within group (order by tree_dbh::numeric) filter(where status like 'Alive') as med_dbh_living, 
		mode() within group (order by spc_common) filter(where status like 'Alive') as spc_mostcommon_living,
		count(*) filter (where status not like 'Stump' and tree_dbh::numeric<6) as cnt_dbh_lt6_notstump,
		count(*) filter (where status like 'Alive' and tree_dbh::numeric<6) as cnt_dbh_lt6_living,
		count(*) filter (where status not like 'Stump' and tree_dbh::numeric>30) as cnt_dbh_gt30_notstump,
		count(*) filter (where status like 'Alive' and tree_dbh::numeric>30) as cnt_dbh_gt30_living,
		count(*) filter (where status not like 'Stump') as treecount2015_notstump,
		count(*) filter (where status like 'Alive') as treecount2015_alive,-- Number of Trees
		ntacode, ntaname,
		bnd.geom_2263 from 
			admin.nycdcp_nta2010_nowater bnd --Neighborhood Tabulation Areas
			left join env_assets.streettrees2015 streettree2015 on st_intersects(streettree2015.geom_2263, bnd.geom_2263)
			group by ntacode, ntaname, bnd.geom_2263) as foo1 --Join street trees based on intersect
			left join 
	(select sum(st_length(st_intersection(roads.geom_2263, bnd.geom_2263)))::numeric/5280 as roadlength, --Length of Road miles intersecting each Community District
	ntacode, ntaname from
			admin.nycdcp_nta2010_nowater bnd --Neighborhood Tabulation Areas
			left join infrastructure.lion16a roads on st_intersects(roads.geom_2263, bnd.geom_2263)
			where  --join roads based on intersect
			(rw_type like ' 1' and featuretyp not like '6' and  --road is street and pvt
				("segmenttyp" like 'U' or "segmenttyp" like 'B' or "segmenttyp" like 'R') and --only includes features that represent roadbeds
				nonped not like 'V') -- not vehicle only street (generally not places that would have street trees)
		group by ntacode, ntaname) as foo4 on foo1.ntacode=foo4.ntacode;

-- Calculate Max Capacity based on Stree Tree Capacity Estimates
create table results_streettrees.max_capacity_nta as
	select 
		ntacode,
		sum(st_length(geom_2263)/orig_length*max_trees) as max_trees_new
		from (
			select 
			bnd.ntacode, 
			st_intersection(nbc.geom_2263, bnd.geom_2263) as geom_2263, 
			st_length(nbc.geom_2263) as orig_length,
			max_trees 
			from
				env_assets.nycdpr_blockface_capacity_20210108 nbc 
				left join admin.nycdcp_nta2010_nowater bnd
					on st_intersects(nbc.geom_2263, bnd.geom_2263)) as foo
			group by ntacode;
			
-- Join Max Capacity data onto 2015 street tree summaries and calculate stocking rates
create table results_streettrees.treecensus2015_summaries_newcapacity_nta2010 as
select tsf.*, round(max_trees_new::numeric, 0) as max_capacity_new,
round(treecount2015_notstump/round(max_trees_new::numeric, 0),4) as stockingrate_2015_notstump,
round(treecount2015_alive/round(max_trees_new::numeric, 0),4) as stockingrate_2015_living
from results_streetrees.max_capacity_nta edt
full join results_streettrees.treecensus2015_summaries_ntas2010 tsf
on edt.ntacode=tsf.ntacode;

--Calculate Desired Metrics for 1995 and 2005
create table results_streettrees.streettree_counts_1995_2005_ntas as
	select nta_2010 as ntacode, treeecount1995_notplantingspace,treeecount1995_notps_notstump, treecount1995_living,
		treecount2005_all, treecount2005_living from 
		(select
			nta_2010 ,
			count(*) filter (where condition not like 'Planting Space') as treeecount1995_notplantingspace,
			count(*) filter (where condition not like 'Planting Space' and condition not like 'Stump') as treeecount1995_notps_notstump,
			count(*) filter (where condition not like 'Dead' and
							condition not like 'Planting Space' and 
							condition not like 'Shaft' and 
							condition not like 'Stump') as treecount1995_living
			from env_assets.streettrees1995 s 
			group by nta_2010) as foo1
			full join
		(select 
			nta,
			count(*) as treecount2005_all,
			count(*) filter (where status not like 'Dead') as treecount2005_living
			from env_assets.streettrees2005
			group by nta) as foo2 
		on nta_2010=nta;

-- Add in data on 1995 and 2005 tree censuses to full tables for final result
create table results_streettrees.treecensus_summaries_nta_final as 
select a.*, treeecount1995_notplantingspace,treeecount1995_notps_notstump, treecount1995_living,
		treecount2005_all, treecount2005_living
		from results_streettrees.treecensus2015_summaries_newcapacity_nta2010 a
full join results_streettrees.streettree_counts_1995_2005_ntas	 b on a.ntacode=b.ntacode;

-- Drop non-final tables created in the process above
drop table results_streettrees.max_capacity_nta, results_streettrees.streettree_counts_1995_2005_ntas,
results_streettrees.treecensus2015_summaries_newcapacity_nta2010, results_streettrees.treecensus2015_summaries_ntas2010;



---------------------
-------Street Tree Metrics for Community Districts
---------------------
-- Compute 2015 Street Tree Summaries - pct living < 6", >30", most common species, total #, # Not Stump (live + dead), 
-- and # Live Based on spatial overlay W/ Respective boundaries
create table results_streettrees.treecensus2015_summaries_commdists as 
	select foo1.borocd, foo1.geom_2263,
		treecount2015_all, 
		treecount2015_notstump, 
		treecount2015_alive, 
		spc_mostcommon_living,
		round(roadlength, 2) as roadmiles, 
		round(treecount2015_alive::numeric/roadlength::numeric, 2) as livingtree_x_mile2015,
		round(avg_dbh_living, 2) as avg_dbh_living, 
		med_dbh_living,
		cnt_dbh_lt6_notstump,
		cnt_dbh_lt6_living,
		round(cnt_dbh_lt6_living::numeric/treecount2015_alive::numeric*100, 3) as pct_lt6_dbh_living,
		cnt_dbh_gt30_notstump,
		cnt_dbh_gt30_living,
		round(cnt_dbh_gt30_living::numeric/treecount2015_alive::numeric*100, 3) as pct_gt30_dbh_living
		from   
	(select 
		count(*) as treecount2015_all,
		avg(tree_dbh::numeric) filter(where status like 'Alive') as avg_dbh_living, 
		percentile_disc(0.5) within group (order by tree_dbh::numeric) filter(where status like 'Alive') as med_dbh_living, 
		mode() within group (order by spc_common) filter(where status like 'Alive') as spc_mostcommon_living,
		count(*) filter (where status not like 'Stump' and tree_dbh::numeric<6) as cnt_dbh_lt6_notstump,
		count(*) filter (where status like 'Alive' and tree_dbh::numeric<6) as cnt_dbh_lt6_living,
		count(*) filter (where status not like 'Stump' and tree_dbh::numeric>30) as cnt_dbh_gt30_notstump,
		count(*) filter (where status like 'Alive' and tree_dbh::numeric>30) as cnt_dbh_gt30_living,
		count(*) filter (where status not like 'Stump') as treecount2015_notstump,
		count(*) filter (where status like 'Alive') as treecount2015_alive,-- Number of Trees
		borocd,
		bnd.geom_2263 from 
			admin.nycdcp_commdists_nowater bnd --Community District Boundaries
			left join env_assets.streettrees2015 streettree2015 on st_intersects(streettree2015.geom_2263, bnd.geom_2263)
			group by borocd, bnd.geom_2263) as foo1 --Join street trees based on intersect
			left join 
	(select sum(st_length(st_intersection(roads.geom_2263, bnd.geom_2263)))::numeric/5280 as roadlength, --Length of Road miles intersecting each Community District
	borocd from
			admin.nycdcp_commdists_nowater bnd --Community District Boundaries
			left join infrastructure.lion16a roads on st_intersects(roads.geom_2263, bnd.geom_2263)
			where  --join roads based on intersect
			(rw_type like ' 1' and featuretyp not like '6' and  --road is street and pvt
				("segmenttyp" like 'U' or "segmenttyp" like 'B' or "segmenttyp" like 'R') and --only includes features that represent roadbeds
				nonped not like 'V') -- not vehicle only street (generally not places that would have street trees)
		group by borocd) as foo4 on foo1.borocd=foo4.borocd;
		
-- Calculate Max Capacity based on Stree Tree Capacity Estimates
create table results_streettrees.max_capacity_commdist as
	select 
		borocd,
		sum(st_length(geom_2263)/orig_length*max_trees) as max_trees_new
		from (
			select 
			bnd.borocd, 
			st_intersection(nbc.geom_2263, bnd.geom_2263) as geom_2263, 
			st_length(nbc.geom_2263) as orig_length,
			max_trees 
			from
				env_assets.nycdpr_blockface_capacity_20210108 nbc 
				left join admin.nycdcp_commdists_nowater bnd
					on st_intersects(nbc.geom_2263, bnd.geom_2263)) as foo
			group by borocd;
			
-- Join Max Capacity data onto 2015 street tree summaries and calculate stocking rates
create table results_streettrees.treecensus2015_summaries_newcapacity_commdist as
select tsf.*, round(max_trees_new::numeric, 0) as max_capacity_new,
round(treecount2015_notstump/round(max_trees_new::numeric, 0),4) as stockingrate_2015_notstump,
round(treecount2015_alive/round(max_trees_new::numeric, 0),4) as stockingrate_2015_living
from results_streetrees.max_capacity_commdist edt
full join results_streettrees.treecensus2015_summaries_commdist tsf
on edt.borocd=tsf.borocd;

--Calculate Desired Metrics for 1995 and 2005
create table results_streettrees.streettree_counts_1995_2005_commdist as
	select cb_num as borocd, treeecount1995_notplantingspace,treeecount1995_notps_notstump, treecount1995_living,
		treecount2005_all, treecount2005_living from 
		(select
			cb_new,
			count(*) filter (where condition not like 'Planting Space') as treeecount1995_notplantingspace,
			count(*) filter (where condition not like 'Planting Space' and condition not like 'Stump') as treeecount1995_notps_notstump,
			count(*) filter (where condition not like 'Dead' and
							condition not like 'Planting Space' and 
							condition not like 'Shaft' and 
							condition not like 'Stump') as treecount1995_living
			from env_assets.streettrees1995 s 
			group by cb_new) as foo1
			join
		(select 
			cb_num,
			count(*) as treecount2005_all,
			count(*) filter (where status not like 'Dead') as treecount2005_living
			from env_assets.streettrees2005
			group by cb_num) as foo2 
		on cb_num::integer=cb_new;

-- Add in data on 1995 and 2005 tree censuses to full tables
create table results_streettrees.treecensus_summaries_commdists_final as 
select a.*, treeecount1995_notplantingspace,treeecount1995_notps_notstump, treecount1995_living,
		treecount2005_all, treecount2005_living
		from results_streettrees.treecensus2015_summaries_newcapacity_commdist a
full join results_streettrees.streettree_counts_1995_2005_commdist b on a.borocd=b.borocd::integer;

-- Drop non-final tables created in the process above
drop table results_streettrees.max_capacity_commdist, results_streettrees.streettree_counts_1995_2005_commdist,
results_streettrees.treecensus2015_summaries_newcapacity_commdist, results_streettrees.treecensus2015_summaries_commdists;


---------------------
-------Street Tree Metrics for City Council Districts
---------------------
-- Compute 2015 Street Tree Summaries - pct living < 6", >30", most common species, total #, # Not Stump (live + dead), 
-- and # Live Based on spatial overlay W/ Respective boundaries
create table results_streettrees.treecensus2015_summaries_councildists as 
	select foo1.coundist, foo1.geom_2263,
		treecount2015_all, 
		treecount2015_notstump, 
		treecount2015_alive, 
		spc_mostcommon_living,
		round(roadlength, 2) as roadmiles, 
		round(treecount2015_alive::numeric/roadlength::numeric, 2) as livingtree_x_mile2015,
		round(avg_dbh_living, 2) as avg_dbh_living, 
		med_dbh_living,
		cnt_dbh_lt6_notstump,
		cnt_dbh_lt6_living,
		round(cnt_dbh_lt6_living::numeric/treecount2015_alive::numeric*100, 3) as pct_lt6_dbh_living,
		cnt_dbh_gt30_notstump,
		cnt_dbh_gt30_living,
		round(cnt_dbh_gt30_living::numeric/treecount2015_alive::numeric*100, 3) as pct_gt30_dbh_living
		from   
	(select 
		count(*) as treecount2015_all,
		avg(tree_dbh::numeric) filter(where status like 'Alive') as avg_dbh_living, 
		percentile_disc(0.5) within group (order by tree_dbh::numeric) filter(where status like 'Alive') as med_dbh_living, 
		mode() within group (order by spc_common) filter(where status like 'Alive') as spc_mostcommon_living,
		count(*) filter (where status not like 'Stump' and tree_dbh::numeric<6) as cnt_dbh_lt6_notstump,
		count(*) filter (where status like 'Alive' and tree_dbh::numeric<6) as cnt_dbh_lt6_living,
		count(*) filter (where status not like 'Stump' and tree_dbh::numeric>30) as cnt_dbh_gt30_notstump,
		count(*) filter (where status like 'Alive' and tree_dbh::numeric>30) as cnt_dbh_gt30_living,
		count(*) filter (where status not like 'Stump') as treecount2015_notstump,
		count(*) filter (where status like 'Alive') as treecount2015_alive,-- Number of Trees
		coundist,
		bnd.geom_2263 from 
			admin.nycdcp_coundists2010_nowater bnd --Council District Boundaries
			left join env_assets.streettrees2015 streettree2015 on st_intersects(streettree2015.geom_2263, bnd.geom_2263)
			group by coundist, bnd.geom_2263) as foo1 --Join street trees based on intersect
			left join 
	(select sum(st_length(st_intersection(roads.geom_2263, bnd.geom_2263)))::numeric/5280 as roadlength, --Length of Road miles intersecting each Community District
	coundist from
			admin.nycdcp_coundists2010_nowater bnd --Council District Boundaries
			left join infrastructure.lion16a roads on st_intersects(roads.geom_2263, bnd.geom_2263)
			where  --join roads based on intersect
			(rw_type like ' 1' and featuretyp not like '6' and  --road is street and pvt
				("segmenttyp" like 'U' or "segmenttyp" like 'B' or "segmenttyp" like 'R') and --only includes features that represent roadbeds
				nonped not like 'V') -- not vehicle only street (generally not places that would have street trees)
		group by coundist) as foo4 on foo1.coundist=foo4.coundist;	

-- Calculate Max Capacity based on Stree Tree Capacity Estimates
create table results_streettrees.max_capacity_councildist as
	select 
		coundist,
		sum(st_length(geom_2263)/orig_length*max_trees) as max_trees_new
		from (
			select 
			bnd.coundist, 
			st_intersection(nbc.geom_2263, bnd.geom_2263) as geom_2263, 
			st_length(nbc.geom_2263) as orig_length,
			max_trees 
			from
				env_assets.nycdpr_blockface_capacity_20210108 nbc 
				left join admin.nycdcp_coundists2010_nowater bnd
					on st_intersects(nbc.geom_2263, bnd.geom_2263)) as foo
			group by coundist;
			
-- Join Max Capacity data onto 2015 street tree summaries and calculate stocking rates
create table results_streettrees.treecensus2015_summaries_newcapacity_councildists as
select tsf.*, round(max_trees_new::numeric, 0) as max_capacity_new,
round(treecount2015_notstump/round(max_trees_new::numeric, 0),4) as stockingrate_2015_notstump,
round(treecount2015_alive/round(max_trees_new::numeric, 0),4) as stockingrate_2015_living
from results_streettrees.max_capacity_councildist edt
full join results_streettrees.treecensus2015_summaries_councildists tsf
on edt.coundist=tsf.coundist;

--Calculate Desired Metrics for 1995 and 2005
-- Note - used spatial data from 1995 tree count for Council Districts, as otherwise about half had no entry
create table results_streettrees.streettree_counts_1995_2005_coundist as
	select coundist as coundist, treeecount1995_notplantingspace,treeecount1995_notps_notstump, treecount1995_living,
		treecount2005_all, treecount2005_living from 
		(select
			coundist,
			count(*) filter (where condition not like 'Planting Space') as treeecount1995_notplantingspace,
			count(*) filter (where condition not like 'Planting Space' and condition not like 'Stump') as treeecount1995_notps_notstump,
			count(*) filter (where condition not like 'Dead' and
							condition not like 'Planting Space' and 
							condition not like 'Shaft' and 
							condition not like 'Stump') as treecount1995_living
			from env_assets.streettrees1995 a 
			join admin.nycdcp_coundists2010_nowater b on st_intersects(a.geom_2263, b.geom_2263)
			group by coundist) as foo1
			full join
		(select 
			cncldist,
			count(*) as treecount2005_all,
			count(*) filter (where status not like 'Dead') as treecount2005_living
			from env_assets.streettrees2005
			group by cncldist) as foo2 
		on coundist=cncldist::integer;
		
-- Add in data on 1995 and 2005 tree censuses to full tables
create table results_streettrees.treecensus_summaries_coundists_final as 
select a.*, treeecount1995_notplantingspace,treeecount1995_notps_notstump, treecount1995_living,
		treecount2005_all, treecount2005_living
		from results_streettrees.treecensus2015_summaries_newcapacity_councildists a
full join results_streettrees.streettree_counts_1995_2005_coundist b on a.coundist=b.coundist;

-- Drop non-final tables created in the process above
drop table results_streettrees.max_capacity_councildist, results_streettrees.streettree_counts_1995_2005_coundist ,
results_streettrees.treecensus2015_summaries_newcapacity_councildists, results_streettrees.treecensus2015_summaries_councildists;


---------------------
-------Street Tree Metrics for Boroughs
---------------------
-- Compute 2015 Street Tree Summaries - pct living < 6", >30", most common species, total #, # Not Stump (live + dead), 
-- and # Live Based on spatial overlay W/ Respective boundaries
create table results_streettrees.treecensus2015_summaries_boro as 
	select foo1.borocode, foo1.boroname, foo1.geom_2263,
		treecount2015_all, 
		treecount2015_notstump, 
		treecount2015_alive, 
		spc_mostcommon_living,
		round(roadlength, 2) as roadmiles, 
		round(treecount2015_alive::numeric/roadlength::numeric, 2) as livingtree_x_mile2015,
		round(avg_dbh_living, 2) as avg_dbh_living, 
		med_dbh_living,
		cnt_dbh_lt6_notstump,
		cnt_dbh_lt6_living,
		round(cnt_dbh_lt6_living::numeric/treecount2015_alive::numeric*100, 3) as pct_lt6_dbh_living,
		cnt_dbh_gt30_notstump,
		cnt_dbh_gt30_living,
		round(cnt_dbh_gt30_living::numeric/treecount2015_alive::numeric*100, 3) as pct_gt30_dbh_living
		from   
	(select 
		count(*) as treecount2015_all,
		avg(tree_dbh::numeric) filter(where status like 'Alive') as avg_dbh_living, 
		percentile_disc(0.5) within group (order by tree_dbh::numeric) filter(where status like 'Alive') as med_dbh_living, 
		mode() within group (order by spc_common) filter(where status like 'Alive') as spc_mostcommon_living,
		count(*) filter (where status not like 'Stump' and tree_dbh::numeric<6) as cnt_dbh_lt6_notstump,
		count(*) filter (where status like 'Alive' and tree_dbh::numeric<6) as cnt_dbh_lt6_living,
		count(*) filter (where status not like 'Stump' and tree_dbh::numeric>30) as cnt_dbh_gt30_notstump,
		count(*) filter (where status like 'Alive' and tree_dbh::numeric>30) as cnt_dbh_gt30_living,
		count(*) filter (where status not like 'Stump') as treecount2015_notstump,
		count(*) filter (where status like 'Alive') as treecount2015_alive,-- Number of Trees
		bnd.borocode,
		bnd.boroname,
		bnd.geom_2263 from 
			admin.nycdcp_borough_nowater bnd --borough boundaries
			left join env_assets.streettrees2015 streettree2015 on st_intersects(streettree2015.geom_2263, bnd.geom_2263)
			group by bnd.borocode, bnd.boroname, bnd.geom_2263) as foo1 --Join street trees based on intersect
			left join 
	(select sum(st_length(st_intersection(roads.geom_2263, bnd.geom_2263)))::numeric/5280 as roadlength, --Length of Road miles intersecting each Community District
	borocode, boroname from
			admin.nycdcp_borough_nowater bnd --borough boundaries
			left join infrastructure.lion16a roads on st_intersects(roads.geom_2263, bnd.geom_2263)
			where  --join roads based on intersect
			(rw_type like ' 1' and featuretyp not like '6' and  --road is street and pvt
				("segmenttyp" like 'U' or "segmenttyp" like 'B' or "segmenttyp" like 'R') and --only includes features that represent roadbeds
				nonped not like 'V') -- not vehicle only street (generally not places that would have street trees)
		group by borocode, boroname) as foo4 on foo1.borocode=foo4.borocode;
		
-- Calculate Max Capacity based on Stree Tree Capacity Estimates
create table results_streettrees.max_capacity_boros as
	select 
		boroname,
		sum(st_length(geom_2263)/orig_length*max_trees) as max_trees_new
		from (
			select 
			bnd.boroname, 
			st_intersection(nbc.geom_2263, bnd.geom_2263) as geom_2263, 
			st_length(nbc.geom_2263) as orig_length,
			max_trees 
			from
				env_assets.nycdpr_blockface_capacity_20210108 nbc 
				left join admin.nycdcp_borough_nowater bnd
					on st_intersects(nbc.geom_2263, bnd.geom_2263)) as foo
			group by boroname;

-- Join Max Capacity data onto 2015 street tree summaries and calculate stocking rates
create table results_streettrees.treecensus2015_summaries_newcapacity_boro as
select tsf.*, round(max_trees_new::numeric, 0) as max_capacity_new,
round(treecount2015_notstump/round(max_trees_new::numeric, 0),4) as stockingrate_2015_notstump,
round(treecount2015_alive/round(max_trees_new::numeric, 0),4) as stockingrate_2015_living
from results_streettrees.max_capacity_boros edt
full join results_streettrees.treecensus2015_summaries_boro tsf
on edt.boroname=tsf.boroname;

--Calculate Desired Metrics for 1995 and 2005
create table results_streettrees.streettree_counts_1995_2005_boro as
	select borough as boroname, treeecount1995_notplantingspace,treeecount1995_notps_notstump, treecount1995_living,
		treecount2005_all, treecount2005_living from 
		(select
			borough,
			count(*) filter (where condition not like 'Planting Space') as treeecount1995_notplantingspace,
			count(*) filter (where condition not like 'Planting Space' and condition not like 'Stump') as treeecount1995_notps_notstump,
			count(*) filter (where condition not like 'Dead' and
							condition not like 'Planting Space' and 
							condition not like 'Shaft' and 
							condition not like 'Stump') as treecount1995_living
			from env_assets.streettrees1995  
			group by borough) as foo1
			full join
		(select 
			boroname,
			count(*) as treecount2005_all,
			count(*) filter (where status not like 'Dead') as treecount2005_living
			from env_assets.streettrees2005
			group by boroname) as foo2 
		on borough=boroname;

-- Add in data on 1995 and 2005 tree censuses to full tables
create table results_streettrees.treecensus_summaries_boro_final as 
select a.*, treeecount1995_notplantingspace,treeecount1995_notps_notstump, treecount1995_living,
		treecount2005_all, treecount2005_living
		from results_streettrees.treecensus2015_summaries_newcapacity_boro a
full join results_streettrees.streettree_counts_1995_2005_boro b on a.boroname=b.boroname;

-- Drop non-final tables created in the process above
drop table results_streettrees.max_capacity_boros, results_streettrees.streettree_counts_1995_2005_boro,
results_streettrees.treecensus2015_summaries_newcapacity_boro, results_streettrees.treecensus2015_summaries_boro;