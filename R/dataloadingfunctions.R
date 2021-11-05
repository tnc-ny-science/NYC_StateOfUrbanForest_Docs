## The below code defines functions in R for importing spatial data from various formats into a PostGIS database. 
## The functions rely on the packages sf and RPostgres
## Warning - error handling is not well developed - users should inspect results
## and browse throuh R terminal for any errors as they use these functions.
##
## The coordinate reference system for all data imported via this code is gets defined as EPSG 2263 before import
## into the database, regardless of the source data. 
##
## Things these functions do: 1) Load data into R; 2) ensure data are projected to EPSG 2263; 3) lowercase column names [makes sql queries easier]
## 4) defines geometry colun name to 'geom_2263'; 5) writes data to database; 6) defines geometry type for the column in postgres; 
## 7) adds primary key; 8) creates spatial index.
##
## The functions can be modified to accommodate different types of formats.
##
## Code developed by Mike Treglia, The Nature Conservancy (michael.treglia@tnc.org)


library(sf)
library(RPostgres)
# Function to load polygon data into PostGIS from vector path (e.g., shapefile, geojson)
vectorpathpoly2postgis <- function(path, schema, lyrname){
  x <- st_read(paste(path)) %>% st_transform(crs=2263) 
  names(x) <- tolower(names(x))
  names(x)[which(names(x)=="geometry")] = "geom_2263"
  st_geometry(x) <- "geom_2263"  
  st_write(x, dsn=con, Id(schema=schema,table=lyrname))
  dbSendQuery(con, paste("ALTER TABLE ",  schema, ".", lyrname, 
                        " ALTER COLUMN geom_2263 TYPE geometry(MultiPolygon,2263) 
                        USING ST_SetSRID(geom_2263,2263);", 
                        sep=""))
  dbSendQuery(con, paste("ALTER TABLE ", schema, ".", lyrname,
                        " ADD pgid serial PRIMARY KEY;"
                        ,sep=""))
  dbSendQuery(con, paste("CREATE INDEX ", lyrname, "geom_idx",
                        " ON ", schema, ".", lyrname,
                        " USING GIST (geom_2263);"
                        , sep=""))
  print("layer successfully written")
}


# Function to load point data into PostGIS from vector path (e.g., shapefile, geojson)
vectorpathpnt2postgis <- function(path, schema, lyrname){
  x <- st_read(paste(path)) %>% st_transform(crs=2263) 
  names(x) <- tolower(names(x))
  names(x)[which(names(x)=="geometry")] = "geom_2263"
  st_geometry(x) <- "geom_2263"  
  st_write(x, dsn=con, Id(schema=schema,table=lyrname))
  dbSendQuery(con, paste("ALTER TABLE ",  schema, ".", lyrname, 
                        " ALTER COLUMN geom_2263 TYPE geometry(MultiPoint,2263) 
                        USING ST_Multi(geom_2263);"
                        ,sep=""))
  dbSendQuery(con, paste("ALTER TABLE ", schema, ".", lyrname,
                        " ADD pgid serial PRIMARY KEY;",
                        sep=""))
  dbSendQuery(con, paste("CREATE INDEX ", lyrname, "geom_idx",
                        " ON ", schema, ".", lyrname,
                        " USING GIST (geom_2263);"
                        , sep=""))
  print("layer successfully written")
  }

# Function to load line data into PostGIS from vector path (e.g., shapefile, geojson)
vectorpathlines2postgis <- function(path, schema, lyrname){
  x <- st_read(paste(path)) %>% st_transform(crs=2263) 
  names(x) <- tolower(names(x))
  names(x)[which(names(x)=="geometry")] = "geom_2263"
  st_geometry(x) <- "geom_2263"  
  st_write(x, dsn=con, Id(schema=schema,table=lyrname))
  dbSendQuery(con, paste("ALTER TABLE ",  schema, ".", lyrname, 
                         " ALTER COLUMN geom_2263 TYPE geometry(MULTILINESTRING,2263) 
                        USING ST_SetSRID(geom_2263,2263);", 
                         sep=""))
  dbSendQuery(con, paste("ALTER TABLE ", schema, ".", lyrname,
                        " ADD pgid serial PRIMARY KEY;"
                        , sep=""))
  dbSendQuery(con, paste("CREATE INDEX ", lyrname, "geom_idx",
                        " ON ", schema, ".", lyrname,
                        " USING GIST (geom_2263);"
                        , sep=""))
  print("layer successfully written")
}

# Function to load line data into PostGIS from an Esri file geodatabase
gdbpathlines2postgis <- function(path, layer, schema, lyrname){
  x <- st_read(paste(path), paste(layer)) %>% st_transform(crs=2263) 
  names(x) <- tolower(names(x))
  names(x)[which(names(x)=="shape")] = "geom_2263"
  st_geometry(x) <- "geom_2263"  
  st_write(x, dsn=con, Id(schema=schema,table=lyrname))
  dbSendQuery(con, paste("ALTER TABLE ",  schema, ".", lyrname, 
                        " ALTER COLUMN geom_2263 TYPE geometry(MULTILINESTRING,2263) 
                        USING ST_SetSRID(geom_2263,2263);"
                        , sep=""))
  dbSendQuery(con, paste("ALTER TABLE ", schema, ".", lyrname,
                        " ADD pgid serial PRIMARY KEY;"
                        ,sep=""))
  dbSendQuery(con, paste("CREATE INDEX ", lyrname, "geom_idx",
                        " ON ", schema, ".", lyrname,
                        " USING GIST (geom_2263);"
                        , sep=""))
  print("layer successfully written")
}

# Function to load polygon data into PostGIS from geopackage
gpkgpathpoly2postgis <- function(path, layer, schema, lyrname){
  x <- st_read(paste(path), paste(layer)) %>% st_transform(crs=2263) 
  names(x) <- tolower(names(x))
  names(x)[which(names(x)=="geom")] = "geom_2263"
  st_geometry(x) <- "geom_2263"  
  st_write(x, dsn=con, Id(schema=schema,table=lyrname))
  dbSendQuery(con, paste("ALTER TABLE ",  schema, ".", lyrname, 
                        " ALTER COLUMN geom_2263 TYPE geometry(MultiPolygon,2263) 
                        USING ST_SetSRID(geom_2263,2263);"
                        ,sep=""))
  dbSendQuery(con, paste("ALTER TABLE ", schema, ".", lyrname,
                        " ADD pgid serial PRIMARY KEY;"
                        ,sep=""))
  dbSendQuery(con, paste("CREATE INDEX ", lyrname, "geom_idx",
                        " ON ", schema, ".", lyrname,
                        " USING GIST (geom_2263);"
                        , sep=""))
  print("layer successfully written")
}

# Function to load point data from table with x/y coordinates (e.g., csv file) into PostGIS
xycsvpnt2postgis <- function(path, xcoord, ycoord, crs, schema, lyrname){
  x <- read.csv(path, stringsAsFactors = FALSE) %>% st_as_sf(., coords=c(xcoord,ycoord), crs=crs) %>% st_transform(crs=2263) 
  names(x) <- tolower(names(x))
  names(x)[which(names(x)=="geometry")] = "geom_2263"
  st_geometry(x) <- "geom_2263"  
  st_write(x, dsn=con, Id(schema=schema,table=lyrname))
  dbGetQuery(con, paste("ALTER TABLE ",  schema, ".", lyrname, 
                        " ALTER COLUMN geom_2263 TYPE geometry(MultiPoint,2263) 
                        USING ST_Multi(geom_2263);"
                        ,sep=""))
  dbSendQuery(con, paste("ALTER TABLE ", schema, ".", lyrname,
                        " ADD pgid serial PRIMARY KEY;"
                        ,sep=""))
  dbSendQuery(con, paste("CREATE INDEX ", lyrname, "geom_idx",
                        " ON ", schema, ".", lyrname,
                        " USING GIST (geom_2263);"
                        , sep=""))
  print("layer successfully written")
}