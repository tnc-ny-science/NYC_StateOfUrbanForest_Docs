# NYC_StateOfTheForest
This repository is intended to document analytics for The Nature Conservancy's inaugural State of the NYC Forest report. This Readme serves as a main documentation page with the following information:

****note - toc generated easily via https://ecotrust-canada.github.io/markdown-toc/
- [NYC_StateOfTheForest](#nyc-stateoftheforest)
  * [Data](#data)
    + [Datasets Used](#datasets-used)
  * [Canopy by Geographic Area](#canopy-by-geographic-area)
  * [Street Trees per Road Mile by Geographic Area](#street-trees-per-road-mile-by-geographic-area)


## Some Key Code

* [Street Tree Census 2015 Metrics](https://github.com/tnc-ny-science/NYC_StateOfTheForest/blob/master/streetTrees/streetTrees_x_roadmile.sql)
* [Under-utilized Tree Beds](https://github.com/tnc-ny-science/NYC_StateOfTheForest/blob/master/streetTrees/streetTrees_emptyPits.sql)
* [Canopy and Canopy Change/Gain/Loss](https://github.com/tnc-ny-science/NYC_StateOfTheForest/blob/master/Canopy/CanopyCover_Vector/CanopyCoverAnalyses.sql)
* [NTA Equity Analyses](https://github.com/tnc-ny-science/NYC_StateOfTheForest/blob/master/EnvJustice/nta_equity_revised.R)
* [Figures for Equity Analyses](https://github.com/tnc-ny-science/NYC_StateOfTheForest/blob/master/EnvJustice/nta_equity_figures_revised.R)




## Data
In all spatial work, unless otherwise mentioned, the New York State Plane coordinate system for eastern NY/Long Island was used (EPSG 2263). We accessioned accessioned all into a PostgreSQL/PostGIS database for storage, conducting analyses using tools including PostGIS, QGIS (version 3.2.x), and R (version 3.X). Where required for compatibility, curves were converted to line features. Documentation for accessioning data into this database is available in [this repository](https://github.com/tnc-ny-science/NYC_PostGISDB_Setup).

### Datasets Used

| Description             			| Version/Date	|
|---------------------------		|--------------	|
| *Geographic & Admin Boundaries*	|              	|
| [Boroughs](https://data.cityofnewyork.us/City-Government/Borough-Boundaries/tqmj-j8zm)					| NA         	|
| [Census Tracts](https://data.cityofnewyork.us/City-Government/2010-Census-Tracts/fxpq-c8ku)				| 2010         	|
| [City Council Districts](https://data.cityofnewyork.us/City-Government/City-Council-Districts/yusd-j4xi)	| 2010			|
| [Community Districts](https://data.cityofnewyork.us/City-Government/Community-Districts/yfnk-k7r4)		|              	|
| [Community Districts](https://data.cityofnewyork.us/City-Government/Community-Districts/yfnk-k7r4)		|              	|
| [Parcel Boundaries (MapPLUTO)](https://www1.nyc.gov/site/planning/data-maps/open-data/dwn-pluto-mappluto.page)	| 18v1 |
| 			  		      	|				|
| *Land Cover*			  	|              	|
| [2010 Land Cover (6 inch)](https://data.cityofnewyork.us/Environment/Landcover-Raster-Data-2010-6in-Resolution/sknu-4f6s)	| 2010	|
| 			  		      	|				|
| 			  		      	|				|
| *Planimetrics and similar*|				|
| [Planimetrics](https://data.cityofnewyork.us/Transportation/NYC-Planimetrics/wt4d-p43d)					| 2016 (2014 Imagery)	|
| [LION road lines (version 18c)](https://www1.nyc.gov/site/planning/data-maps/open-data/dwn-lion.page)		| 18c |



## Canopy by Geographic Area

Canopy per geographic area gives a sense of where the urban forest physically exists, at least in one measure. Ideally, canopy would be associated with individual trees, though those data simply don't exist comprehensively for New York City. Thus, Canopy as a measure gives a reasonable measure of where this critical piece of infrastructure exists.

~~To calculate canopy cover per geographic area, we loaded geographic boundaries and high resolution (6 in. resolution) land cover data into QGIS and used the ‘zonal histogram’ tool, in which the number of pixels per unique value (land cover class) are calculated for every polygon (counts are based on the overlap of the center of pixels alignment with polygons). We attempted to do this calculation in PostGIS, but faced challenges due to a [bug](https://trac.osgeo.org/postgis/ticket/3457) and used QGIS. Data are currently stored as # of pixels of different land cover types (and proportion of Canopy, as per below), and area can be calculated by simply multiplying the number of pixels by 0.25 (each pixel is 0.5' x 0.5' in dimensions, or 0.25 square feet in area).~~


* TESTING - To calculate area and percentage of geographies occupied by canopy cover (and other land cover classes) we used used [queries in PostgreSQL](Canopy/2010_Area_Pct_LandCover.sql). Results are stored in new tables with key identifiers (e.g., bbl [borough/block/lot for MapPLUTO]). *At this point, proportion is calculated as (# of pixels for the focal land cover class)/(total # of pixels per geography).*

Of note, the pixels are square and regularly-arranged, they do not perfectly align with focal geographic boundaries, though given the high resolution of the land cover data, we consider these calculations robust approximations. Furthermore, the same effect is seen in calculations run by DPR in the [Canopy Assessment Metrics](https://data.cityofnewyork.us/Environment/NYC-Urban-Tree-Canopy-Assessment-Metrics-2010/hnxz-kkn5) as many values are fractions in quarters of a square foot. 

### Proportion of Land Cover per Geography

Proportion of canopy (and other cover classes) was estimated in two ways:
	1) As the number of pixels representing canopy divided by the total number of land pixels (i.e., not NoData and not Water). In cases where were no land pixels were present for a focal geography, a 1 was added to the denominator so the percentage of classes would simply be indicated as 0 rather than return a Divide by 0 error.
	2) Area of pixels representing canopy divided by the total area of the focal polygon.
	
This was [scripted from R](Canopy/PctCanopy_x_Geog_AddCols.R) using functions found [here](Canopy/Functions/PctCanopy_x_Geog_functions.R).
	
*Of note - though some of these calculations are replicated from in the Canopy Assessment Metrics data, results sometimes differ slightly, primarily due to slightly different boundary layers used. For example, the Census Tract boundaries used in these analyses had been clipped to shorelines and slightly adjusted otherwise from the federal data, and the Community Districts have since been better clipped to shorelines and such since the Canopy Assessment Metrics had been created. Additionally, the 2010 Land Cover Data occasionally has inland NoData pixels.*

Datasets were exported to geopackage (.gpkg) files for others to work with via QGIS the QGIS Database Manager, and to shapefiles using pgsql2shp.exe in bash as follows: 

	 pgsql2shp.exe -f "[Directory]/treecensus_trees_per_rdmile_ct2010" -h localhost -u postgres -p 5432 nycgis_v2 results_streetrees.treecensus_trees_per_rdmile_ct2010



## Street Trees per Road Mile by Geographic Area

Street Trees are one critical component of the Urban Forest. They exist in the public right of way, typically in or along the sidewalk, against the curb. In some areas of the city, where yards or open space is non-existent or limited, they are the only trees. Furthermore, given their placement they can help mitigate particular matter from vehicular traffic, reduce air temperatures, and provide shade for passersby.

We considered street trees from the 3 street tree censuses that have been conducted, in 1995, 2005, and 2015. Based on fields related to condition or status (depending on the dataset version) we only considered trees that were known/assumed to be alive, or had an unknown status.

SQL code for pulling this from the datasets looked as follows:

    --SQL Code
	-- 1995 Tree Census
	
	-- First see all 'condition' names and counts
	select "condition", count(*) from env_assets.streettrees1995
		group by "condition";
		
	-- Use the above (plus metadata) to exclude appropriate rows for count of live trees.
	select count(*) from env_assets.streettrees1995 where ("condition" not like 'Dead' and 
		"condition" not like 'Dead' and
		"condition" not like 'Planting Space' and 
		"condition" not like 'Shaft' and 
		"condition" not like 'Stump');
	
	
	
	-- 2005 Tree Census. 
	-- Again, see all status names and counts
	select status, count(*) from env_assets.streettrees2005
		group by status;
	
	-- Use the above to exclude rows for count of live trees
	select count(*) from env_assets.streettrees2005 where conditoin not like 'Dead';
	
	
	-- 2015 Tree Census
	-- See all status names and counts
	select status, count(*) from env_assets.streettrees2015
		group by status;

	-- Use the above to exclude rows for count of live trees
	select count(*) from env_assets.streettrees2015 where status like 'Alive';
	
	
	-- WORKING VERSION to estimate tree treebeds that are empty or have dead trees - Ignores Date updated and such - as long as Planting site status is 'Empty' and condition is not something that seems to be living, and pssite like Street counted as empty/dead treebed
	select * from forestry_ms.plantingspaces20190801 p 
	full outer join forestry_ms.treepoints20190801 t on p.globalid = t.plantingspaceglobalid
	where pssite like 'Street' and 
	psstatus like 'Empty' and tpcondition not like 'Critical' and tpcondition not like 'Excellent' 
	and tpcondition not like 'Fair' and tpcondition not like 'Good'and tpcondition not like 'Poor';
	
	
	-- Keeps points and joins boro info for subsequent aggregation.
	select p.geom_2263, p.globalid as ps_globalid, b.boroname from forestry_ms.plantingspaces20190801 p 
	join forestry_ms.treepoints20190801 t on p.globalid = t.plantingspaceglobalid
	join admin.boroughs_nowater b on st_intersects(b.geom_2263, p.geom_2263)
	where pssite like 'Street' and 
	psstatus like 'Empty' and tpcondition not like 'Critical' and tpcondition not like 'Excellent' 
	and tpcondition not like 'Fair' and tpcondition not like 'Good'and tpcondition not like 'Poor';
	
	
	-- Empty Treebeds by specific Geographies
	create table results_streetrees.empty_dead_treebeds_20190801_boro as
	select b.geom_2263, b.boroname, count(*) from forestry_ms.plantingspaces20190801 p 
	join forestry_ms.treepoints20190801 t on p.globalid = t.plantingspaceglobalid
	join admin.boroughs_nowater b on st_intersects(b.geom_2263, p.geom_2263)
	where pssite like 'Street' and 
	psstatus like 'Empty' and tpcondition not like 'Critical' and tpcondition not like 'Excellent' 
	and tpcondition not like 'Fair' and tpcondition not like 'Good'and tpcondition not like 'Poor'
	group by b.geom_2263 , b.boroname;


	create table results_streetrees.empty_dead_treebeds_20190801_commdist as
	select c.geom_2263, c.boro_cd , count(*) from forestry_ms.plantingspaces20190801 p 
	join forestry_ms.treepoints20190801 t on p.globalid = t.plantingspaceglobalid
	join admin.commdists c on st_intersects(c.geom_2263, p.geom_2263)
	where pssite like 'Street' and 
	psstatus like 'Empty' and tpcondition not like 'Critical' and tpcondition not like 'Excellent' 
	and tpcondition not like 'Fair' and tpcondition not like 'Good'and tpcondition not like 'Poor'
	group by c.geom_2263, c.boro_cd;

	create table results_streetrees.empty_dead_treebeds_20190801_nta as
	select n.geom_2263, n.ntacode, n.ntaname, count(*) from forestry_ms.plantingspaces20190801 p 
	join forestry_ms.treepoints20190801 t on p.globalid = t.plantingspaceglobalid
	join admin.nyc_nta n on st_intersects(n.geom_2263, p.geom_2263)
	where pssite like 'Street' and 
	psstatus like 'Empty' and tpcondition not like 'Critical' and tpcondition not like 'Excellent' 
	and tpcondition not like 'Fair' and tpcondition not like 'Good'and tpcondition not like 'Poor'
	group by n.geom_2263, n.ntacode, n.ntaname;




## Land Ownership

Understanding land ownership and tenure in NYC is complex and challenging but it is necessary for understanding *who* might be most important to work with for conservation efforts of our environmental assets including our urban forest. For NYC, land ownership is captured to a degree in a data compilation integrating information from: NYC Dept. of Finance; Dept. of City Planning; Dept. of Citywide Administrative Services; Dept. of Parks and Recreation; NYS Office of Parks, Recreation, and Historic Preservation; and the Federal Emergency Management Agency.

line for testing