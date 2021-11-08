## The below code leverages functions from dataloadingfunctions.R to load data
## into a PostgreSQL database with the PostGIS extension installed. This assumes a
## working version of PostgreSQL on the user's computer (or on a server). Various
##  tutorials exist for PostgreSQL/PostGIS such as this one
##  http://zevross.com/blog/2019/12/04/install-postgres-postgis-and-get-started-with-spatial-sql/
##
## Warning - error handling in the functions (dataloadingfunctions.R) is not well
## developed at this point; users should inspect results and browse throuh R
## terminal for any errors as they use these functions. Furthermore, some of the
## datasets are large and will require sufficient computational capacity (possibly
## 32+ GB of RAM). 
## 
## NOTE - any queries using the functions 'dbGetQuery,' 'dbSendQuery' or similar
## can also be run through other database clients such as pgAdmin, DBeaver, and the
## QGIS Database Manager
##
## For any code that calls on local files, users will need to adjust file paths for local files
##
## For political and administrative layers, the versions used in the report were
## from 2020, and based on layers downloaded. The boundaries may be very slightly
## different from the geojson files used as examples here, and the examples here
## use the most recent available data. 
##
## Some of these operations take time to run. Thus, "system.time()" is used to
## track how long some steps take
##
## This code is provided as an example at the time written, sometimes with local
# files.  Users may need to adjust parameters, file paths, etc. for this to work.
##
## Code developed by Mike Treglia, The Nature Conservancy (michael.treglia@tnc.org)

# Load required packages
library(sf)
library(RPostgres)
library(readxlsx)
library(lwgeom)
library(Hmisc)
library(readxl)
library(dplyr)

# Load functions from the associated file - you may need to adjust your working directory or
# explicitly name the file path
source("dataloadingfunctions.R")

######Setting up Database ################
###### THIS IS ONLY DONE ONCE#############
# Define connection to Postgres (Additional fields may be required such as password and port number)
con <-
  dbConnect(RPostgres::Postgres(), user = 'postgres', host = 'localhost')
#create database
dbGetQuery(con, "CREATE DATABASE nyc_urbanforest;")


#create connection to actual database (Additional fields may be required such as password and port number)
con <-
  dbConnect(
    RPostgres::Postgres(),
    user = 'postgres',
    host = 'localhost',
    dbname = "nyc_urbanforest"
  )

#make the db spatially enabled & confirm version
dbGetQuery(con, "CREATE EXTENSION postgis;")
dbGetQuery(con, "CREATE EXTENSION postgis_raster;")
dbGetQuery(con, "CREATE EXTENSION postgis_topology;")
dbGetQuery(con, "CREATE EXTENSION postgis_sfcgal;")

# Use the following to check that postgres
dbGetQuery(con, "SELECT postgis_full_version();")

#create schemas as needed
RPostgreSQL::dbSendQuery(con, "CREATE SCHEMA admin;")
RPostgreSQL::dbSendQuery(con, "CREATE SCHEMA env_assets;")
RPostgreSQL::dbSendQuery(con, "CREATE SCHEMA infrastructure;")
RPostgreSQL::dbSendQuery(con, "CREATE SCHEMA socioeconomic_health;")

###### Once databsase is set up, use the below code to start bringing data in#########


# Connect to database (Add in password, port number, as needed, depending on your local settings)
con <-
  dbConnect(Postgres(),
            user = 'postgres',
            host = 'localhost',
            dbname = "nyc_urbanforest")


###############################
## Load in data to PostGIS
## Note - some of this code automatically downloads large datasets that then get imported for these examples
## and in other cases data must be manually downloaded first
###############################

########
# MapPLUTO version 20v6 as GDB
# Download file (Adjust file destination file path)
download.file(
  "https://www1.nyc.gov/assets/planning/download/zip/data-maps/open-data/nyc_mappluto_20v6_unclipped_fgdb.zip",
  "D:/mappluto.zip"
)

# Unzip
unzip("D:/mappluto.zip", exdir = "D:/mappluto")

# Accession into the database (system.time tracks how long it takes)
system.time(
  gdbpathpoly2postgis(
    path = "D:/mappluto/MapPLUTO_20v6_unclipped.gdb",
    layer = "MapPLUTO_20v6_unclipped",
    schema = "admin",
    lyrname = "mappluto_citywide_20v6_unclipped"
  )
)

# Delete the downloaded and extracted files
unlink("D:/mappluto.zip", recursive = TRUE)
unlink("D:/mappluto", recursive = TRUE)

# use PostGIS functions to check for and fix invalid geometries. (The work heres is being 100% done by PostGIS - just sent through R)
# This was not a common issue across datasets, but occasionally was needed
dbGetQuery(
  con,
  "UPDATE admin.mappluto_citywide_20v6_unclipped
   SET geom_2263 = ST_Multi(ST_CollectionExtract(ST_MakeValid(geom_2263), 3)) where st_isvalid(geom_2263) = false;"
)
########


########
# Some sample administrative boundaries - these levarage geojson files from a REST service, but comparable code would work with shapefiles stored locally
# The layername is automatically stored here with the date this is done on in the format YYYYMMDD.
# Borough Boundaries
vectorpathpoly2postgis(
  path = "https://services5.arcgis.com/GfwWNkhOj9bNBqoJ/arcgis/rest/services/NYC_Borough_Boundary/FeatureServer/0/query?where=1=1&outFields=*&outSR=4326&f=pgeojson",
  schema = "admin",
  lyrname = paste("boroughs_nowater", gsub("-", "", as.character(Sys.Date(
    
  ))), sep = "")
)

#Community Districts
vectorpathpoly2postgis(
  path = "https://services5.arcgis.com/GfwWNkhOj9bNBqoJ/arcgis/rest/services/NYC_Community_Districts/FeatureServer/0/query?where=1=1&outFields=*&outSR=4326&f=pgeojson",
  schema = "admin",
  lyrname = paste("commdists_", gsub("-", "", as.character(Sys.Date(
    
  ))), sep = "")
)
########

########
## Canopy change data (after being downloaded from NYC OpenData manually at https://data.cityofnewyork.us/Environment/Tree-Canopy-Change-2010-2017-/by9k-vhck)
## NOTE - after unzipping the file, a ".gdb" extension likely needs to be added onto the folder name unless this has been fixed on the Open Data portal
x <-
  st_read(dsn = "D:/NYC_TreeCanopyChange_2010_2017.gdb", layer = "NYC_TreeCanopyChange_2010_2017")

# NOTE - the original dataset had multisurface objects in addition to multipolygon objects which can poses challenges
# when working with the data in postgres. We used sf::st_cast in R to convert make consistent geometry type
x <- st_cast(x, "MULTIPOLYGON")

# write multipolygon data out to gpkg temporarily and then load the data into PostGIS
#  Alternatively, one can use the robjpoly2postgis without writing the data out to a geojson
st_write(x, dsn = "NYC_TreeCanopyChange_2010_2017.gpkg", layer = "NYC_TreeCanopyChange_2010_2017")
system.time(
  gpkgpathpoly2postgis(
    path = "NYC_TreeCanopyChange_2010_2017.gpkg",
    layer = "NYC_TreeCanopyChange_2010_2017",
    schema = "env_assets",
    lyrname = "treecanopychange_2010_2017_nyc"
  )
)

# Remove the object from workspace and delete the geopackage from the local computer
rm(x)
unlink("NYC_TreeCanopyChange_2010_2017.gpkg")

# Address any issues of invalid polygons
dbSendQuery(
  con,
  "UPDATE env_assets.treecanopychange_2010_2017_nyc_v2_fixed
SET geom_2263 = ST_Multi(ST_CollectionExtract(ST_MakeValid(geom_2263), 3)) where st_isvalid(geom_2263) = false;"
)
########

########
## Load Street Tree Census Dataa
########
# 2015 Tree Census - https://data.cityofnewyork.us/Environment/2015-Street-Tree-Census-Tree-Data/pi5s-9p35
# Metadata at https://data.cityofnewyork.us/api/views/pi5s-9p35/files/2e1e0292-20b4-4678-bea5-6936180074b3?download=true&filename=StreetTreeCensus2015TreesDataDictionary20161102.pdf
system.time(
  vectorpathpnt2postgis(
    path = "https://data.cityofnewyork.us/api/geospatial/pi5s-9p35?method=export&format=GeoJSON",
    schema = "env_assets",
    lyrname = "streettrees2015_v2"
  )
)

#2005 Tree Census - https://data.cityofnewyork.us/Environment/2005-Street-Tree-Census/29bw-z7pj
# Metadata at https://data.cityofnewyork.us/api/views/29bw-z7pj/files/89627e6e-7d68-47a2-9e21-7822e3bd9c25?download=true&filename=NewYorkCity_StreetTreeCensus2005_DataDescription.pdf
system.time(
  vectorpathpnt2postgis(
    path = "https://data.cityofnewyork.us/api/geospatial/ye4j-rp7z?method=export&format=GeoJSON",
    schema = "env_assets",
    lyrname = "streettrees2005_v2"
  )
)

## Had to fix boroname for SI in 2005 dataset because it was originally stored as borocode
dbSendQuery(
  con,
  "update env_assets.streettrees2005
                  set boroname='Staten Island' where boroname like '5'"
)


#1995 Tree Census - https://data.cityofnewyork.us/Environment/1995-Street-Tree-Census/tn4g-ski5
# metadata at https://data.cityofnewyork.us/api/views/tn4g-ski5/files/1JFmze_FoZt7nuxgfO_20gzhvmcEYbG673kbl8fiBp4?download=true&filename=NewYorkCity_StreetTreeCensus1995_Description.pdf
system.time(
  xycsvpnt2postgis(
    "https://data.cityofnewyork.us/api/views/tn4g-ski5/rows.csv?accessType=DOWNLOAD",
    xcoord = "X",
    ycoord = "Y",
    crs = 2263,
    schema = "env_assets",
    lyrname = "streettrees1995_v2"
  )
)
########

########
# Load Lion 16a (latest version of Lion available at https://www1.nyc.gov/site/planning/data-maps/open-data/dwn-lion.page)

#read data after downloading and unzipping
system.time(x <- st_read("D:/nyclion_16a/lion.gdb", "lion"))

# Cast all lines to multilinestring objects, as the gdb some as multicurves which poses challenges if they're
# in the same table in postgres
x <- st_cast(x, "MULTILINESTRING")

#  Write to geojson file temporarily for using the data import function and write into database.
#  Alternatively, one can use the robjline2postgis without writing the data out to a geojson
st_write(x, "lion16a.geojson")
system.time(vectorpathlines2postgis("lion16a.geojson", "infrastructure", "lion16a"))

# Delete the temporary geojson file that was created and remove the object "x" from R
unlink(lion16a.geojson)
rm(x)
########


########## Some more complex or different types of operations #########

########
## NYC NTA boundaries with unpopulated areas split up
# Read NTA data into R
ntas <-
  st_read(
    "https://services5.arcgis.com/GfwWNkhOj9bNBqoJ/arcgis/rest/services/NYC_Neighborhood_Tabulation_Areas/FeatureServer/0/query?where=1=1&outFields=*&outSR=4326&f=geojson",
    stringsAsFactors = FALSE
  ) %>% st_transform(crs = 2263)

# Lowecase column names for simplicity
names(ntas) <- tolower(name(ntas))

# Split data into populated and unpopulated areas based on nta codes
ntas.pop <-
  ntas[which(ntas$ntacode %nin% c("SI99", "QN99", "QN98", "MN99", "BX99", "BX98",  "BK99")),]
ntas.unpop <-
  ntas[which(ntas$ntacode %in% c("SI99", "QN99", "QN98", "MN99", "BX99", "BX98",  "BK99")),]

# Cast to Polygon (instead of Multipolygon) which splits them up into different rows of data
ntas.unpop_polygon <- st_cast(ntas.unpop, "POLYGON")

# Make NTA codes something like...  SI99-1
ntas.unpop_polygon <-
  cbind(ntas.unpop_polygon, id = seq(1:nrow(ntas.unpop_polygon)))
head(ntas.unpop_polygon)
ntas.unpop_polygon$ntacode <-
  paste(ntas.unpop_polygon$ntacode, ntas.unpop_polygon$id, sep = "-")
ntas.unpop_polygon$id <- NULL

# Make the polygons of unopopulated areas into a "MULTIPOLYGON" Geometry type for consistency with the other data
ntas.unpop_polygon <- st_cast(ntas.unpop_polygon, "MULTIPOLYGON")

# Append the new unpopulated area polygons to the data of populated areas
ntas.final <- rbind(ntas.pop, ntas.unpop_polygon)

# Calculate area and perimter to have with the data
ntas.final$shape_area <- st_area(ntas.final)
ntas.final$shape_leng <- lwgeom::st_perimeter(ntas.final)

# Write to a geojson (Geojsons follow a convention of being stored in EPGS 4326, hence the transformation in this line)
st_write(st_transform(ntas.final, crs = 4326),
         "~/ntas_unpopulatedareas_separated.geojson")

# Remove the nta data from local memory
rm(ntas.final, ntas.pop, ntas.unpop, ntas.unpop_polygon, ntas)

# Lead into the database
vectorpathpoly2postgis(
  path = "~/ntas_unpopulatedareas_separated.geojson",
  schema = "admin",
  lyrname = paste(
    "nyc_nta_unpopareas_separated_",
    gsub("-", "", as.character(Sys.Date())),
    sep = ""
  )
)

# Get rid of the geojson file that was created.
unlink("~/ntas_unpopulatedareas_separated.geojson")
########

########
## Load Social Vulnerability Index data
## This joins the Social Vulnerability data to NYC-specific census tract
## boundaries from the NYC Department of City Planning and accessions them into the database
## Social Vulnerability Data downloadable as csv file (or shapefile) by going through menus at
## https://www.atsdr.cdc.gov/placeandhealth/svi/data_documentation_download.html

sovi <- read.csv("D:/NewYork.csv")

# Select only the rows desired based on filtering on column mame
sovi <-
  sovi[sovi$COUNTY %in% c("Bronx", "Richmond", "New York", "Kings", "Queens"), ]

# Crate and fill in new column for boro/census tract code that will match the NYC-based census tract spatial data
sovi$boroct <- as.character("NA")
sovi$BoroCode <- as.character("NA")
sovi$BoroCode[which(sovi$COUNTY == "New York")] <- "1"
sovi$BoroCode[which(sovi$COUNTY == "Bronx")] <- "2"
sovi$BoroCode[which(sovi$COUNTY == "Kings")] <- "3"
sovi$BoroCode[which(sovi$COUNTY == "Queens")] <- "4"
sovi$BoroCode[which(sovi$COUNTY == "Richmond")] <- "5"

sovi$boroct <-
  paste(sovi$BoroCode, substr(sovi$FIPS, 6, 12), sep = "")

# Load census tract boundaries from Bytes of the Big Apple (2010 boundaries) and so some light-weight manipulation for consistency
ct <-
  st_read(
    "https://services5.arcgis.com/GfwWNkhOj9bNBqoJ/arcgis/rest/services/NYC_Census_Tracts_for_2010_US_Census/FeatureServer/0/query?where=1=1&outFields=*&outSR=4326&f=pgeojson"
  ) %>%
  st_transform(crs = 2263)
names(ct) <- tolower(names(ct))

# make single sf object with sovi data and boroct by merging the two datasets
censustract_sovi2018 <-
  merge(ct, (replace(sovi, sovi == -999, NA)), by.y = "boroct", by.x = "boroct2010")

# Exclude any unnecessary fields - the main one here is the State code from the US Census (36 for NY)
censustract_sovi2018 <-
  dplyr::select(censustract_sovi2018, -c("ï..ST")) # Note - if calling on a census tract dataset from the database, add "pgid" to this as well

# write data out to a temporary geojson, load data into database, and remove temporary file and the object in the workspace
# This can be by writing censustract_sovi2018 directly from R using the robjpoly2postgis function also (from the associated package sourced at the beginning of this script)
st_write(
  st_transform(censustract_sovi2018, crs = 4326),
  "D:/sovi2018_censustract2010.geojson"
)
system.time(
  vectorpathpoly2postgis(
    path = "D:/sovi2018_censustract2010.geojson",
    schema = "socioeconomic_health",
    lyrname = "sovi2018_censustract2010"
  )
)
unlink("D:/sovi2018_censustract2010.geojson")
rm(ct, censustract_sovi2018, sovi)
########


### Non-spatial data
## NYC NTA-Census Tract Lookup Table
# xlsx file is avaialble from Bytes of the Big Apple, but the file doesn't read into R at all using the xlsx pacakge.
# Original file is at https://www1.nyc.gov/assets/planning/download/office/data-maps/nyc-population/census2010/nyc2010census_tabulation_equiv.xlsx; data were downloaded, saved as another xlsx file, simplifying some column names, and used.

# Load the data
nta_census_lookup <-
  read_xlsx("D:/nyc2010census_tabulation_equiv_R_readable.xlsx") %>% data.frame()

# Create a field called "boroct2010" which is the concatenation of borocode and census tract from the nta census lookup table
nta_census_lookup$boroct2010 <-
  paste(nta_census_lookup$borocode,
        nta_census_lookup$censustract2010,
        sep = "")

# Write the result to the database
dbWriteTable(
  value = nta_census_lookup,
  conn = con,
  name = c("admin", "nta_censustract2010_lookup")
)
