---------------------------------------------
-- The below code takes the NYC 2010-2017 tree canopy change polygon data
-- and creates a new data layer from it, in which there are no polygons 
-- that "intersect" other polygons. This dataset was used to estimate (with caveats)
-- the amount of canopy gain attributable to new tree plantings vs expansion 
-- of existing tree canopy.
--
-- Note - after running this, users will want to create a spatial index for the data.
-- this can be done via point and click operations in QGIS (via the Database Manager tool)
-- or via the example query that follows the main analytical query below

--Query for analysis
create table results_utc_landcover.non_touching_canopychange as 
SELECT * FROM env_assets.canopychange_2010_2017 t1
WHERE NOT EXISTS (SELECT * FROM env_assets.canopychange_2010_2017 t2
                  WHERE h1.pgid!=h2.pgid AND ST_INTERSECTS(h1.geom_2263, h2.geom_2263)
);

--Query to create spatial index
CREATE INDEX sidx_non_touching_canopychange_geom_2263 ON 
results_utc_landcover.non_touching_canopychange
USING GIST(geom_2263);
