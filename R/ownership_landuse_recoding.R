## The below code takes a dataset that was developed for The State of the Urban
## Forest in New York City, the "analytical mashup" and attempts to better capture
## ownership and land use based on the suite of datasets that went into the
## analytical mashup, as well as ancillary data, and occasionally separate
## datasets. The analytical mashup is not publicly available, as some component
## data are not publicly available, but the code below references a number of
## publicly available datasets, described in the README.md file of this repository.
## The starting point ultimately calls on a PostGIS database to load the data into
## R, all manipulation is based on R code. Column names from original data were
## maintained (or slighlty modified to avoid duplicates or confusion) in the
## anlytical mashup and used below.
##
## Code developed by Mike Treglia, The Nature Conservancy (michael.treglia@tnc.org)


# Load packages
library(sf)
library(RPostgres)
library(tidyquery)
library(dplyr)

# Establish Connection to Database
con <-
  dbConnect(
    dbDriver("Postgres"),
    user = 'postgres',
    host = 'localhost',
    dbname = "nyc_urbanforest"
  )

# Load the "analytical mashup" which had fields from various input datasets into R
# The mashup is not publicly available, but contained fields from various other datasets that were overlaid
# Column names
system.time(ownership_canopy <-
              st_read(con, Id(schema = "mashup_results", table = "mashup_result")))

# Load the Facilities Database layer
system.time(facdb.sch <-
              st_read(con, Id(schema = "admin", table = "facilities_db20210105")))
# Remove geometry field given it was not need and otherwise causes challenges with the merge, below
st_geometry(facdb.sch) <- NULL
# Select public schools from fac.db - only maintain bbl and facsubgrp
facdb.sch <-
  query(
    "select  distinct(bbl) as bbl, facsubgrp from facdb.sch where facsubgrp like 'PUBLIC K-12 SCHOOLS' and bbl is not NULL"
  )
# Join the facilities database data for schools
system.time(
  ownership_canopy <-
    merge(
      ownership_canopy,
      facdb.sch,
      by.x = "bbl",
      by.y = "bbl",
      all.x = TRUE
    )
)

##################
# Ownership Information

# Create  column for Assumed Owner Type
ownership_canopy <-
  cbind(ownership_canopy, assumed_owner_type = as.character(rep(NA, nrow(ownership_canopy))))
ownership_canopy$assumed_owner_type <-
  as.character(ownership_canopy$assumed_owner_type)

# Delineate City owned based on PLUTO (Mixed tends to be City)
ownership_canopy[which(ownership_canopy$ownertype == "C" |
                         ownership_canopy$ownertype == "M"), "assumed_owner_type"] <-
  "City"

# Delineate Rights of way based on Assumed ROW layer derived from MapPLUTO, NYC Parks boundaries, NPS boundaries.
ownership_canopy[which(ownership_canopy$assumed_row == 1), "assumed_owner_type"] <-
  "Assumed PROW"

# Delineate Other Govt in PLUTO as NYS (generalization based on inspection of data)
ownership_canopy[which(ownership_canopy$ownertype == "O"), "assumed_owner_type"] <-
  "NYS"

# Delineate Private based on PLUTO (X (based on inspection of the data) and no
#ownertype (based on PLUTO metadata) listed tend to be under private ownership)
ownership_canopy[which(ownership_canopy$ownertype == "P" |
                         ownership_canopy$ownertype == "X"), "assumed_owner_type"] <-
  "Private"
ownership_canopy[which(is.na(ownership_canopy$ownertype) &
                         !is.na(ownership_canopy$bbl)), "assumed_owner_type"] <- "Private"

#  Delineate owners as federal when names are as follows
ownership_canopy[which(
  ownership_canopy$ownername %in% c(
    'THE UNITED STATES OF',
    'POST OFFICE',
    'U S AMERICA',
    'U S GOV',
    'U S GOVERNMENT',
    'U S GOVERNMENT OWNED',
    'U S GOVT INTERIOR',
    'U S GOVT LAND & BLDGS',
    'U S GOVT POST OFFIC',
    'U S GOVT POST OFFICE',
    'U S OF AMERICA',
    'U S POST OFFICE',
    'U S POSTAL SER',
    'U S POSTAL SERVICE',
    'U S POSTAL SVCE',
    'U.S. CUSTOMS AND BORD',
    'U.S. DEPARTMENT OF H.',
    'U.S. DEPARTMENT OF HU',
    'U.S. DEPARTMENT OF TR',
    'UNITED STATE AVA',
    'UNITED STATE OF AMERI',
    'UNITED STATES A- VA' ,
    'UNITED STATES A-HUD',
    'UNITED STATES A-V A',
    'UNITED STATES A-VA',
    'UNITED STATES A HUD',
    'UNITED STATES A OF VA',
    'UNITED STATES A VA',
    'UNITED STATES AMERICA',
    'UNITED STATES ARMY',
    'UNITED STATES MARSHAL',
    'UNITED STATES OF AMER',
    'UNITED STATES OF AMFB',
    'UNITED STATES POST OF',
    'UNITED STATES POSTAL',
    'UNITED STATES POSTALE',
    'UNITED STATES POSTALS',
    'UNITED STATES POSTLSR',
    'US COAST GUARD',
    'US DEPARTMENT OF TRAN',
    'US DEPT OF HOUSING &',
    'US DEPT OF HUD-MF/REO',
    'US GENERAL SERVICES A',
    'US GOV',
    'US GOVERNMENT',
    'US GOVERNMENT GEN SER',
    'US GOVT POST OFFICE',
    'US MARSHAL SERVICE, S',
    'US POSTAL SERV',
    'USPS',
    'US TREASURY'
  ),
  "assumed_owner_type"] <- "FED"

# Also delineate City owned based on IPIS Owned (should capture anything city-owned not with a C)
ownership_canopy[which(ownership_canopy$ipis_city_own_lease == "O"), "assumed_owner_type"] <-
  "City"

# Delineate NYS Owned based on the specific datasets of state-owned land.
# Overrides the City-owned according to IPIS as there are ~4K acres of conflict w/
# PANYNJ alone which should go to NYS
ownership_canopy[which((ownership_canopy$state_owne == 1) |
                         (ownership_canopy$nysoprhp_2 == 1) |
                         (ownership_canopy$declands == 1)
), "assumed_owner_type"] <- "NYS"

# Make sure NYCHA properties not part of RAD/PACT are definitively called NYS owned
# This is a pulls everything that is not null for nycha_deve and everything
# that is not RAD/PACT for nycha_mana (including nulls)
ownership_canopy[(!is.na(ownership_canopy$nycha_deve) &
                    ((
                      is.na(ownership_canopy$nycha_mana) |
                        (ownership_canopy$nycha_mana != "RAD/PACT")
                    ))), "assumed_owner_type"] <- "NYS"

# Delineate Rights of way based as anything else at this point with no assumed owner type
# (this was very rare, but occured in the results of the spatial processing)
ownership_canopy[which(is.na(ownership_canopy$assumed_owner_type)), "assumed_owner_type"] <-
  "Assumed PROW"

# Delineate Federal, in addition to the above names, where ownership data from
# National Park Service/Gateway boundaries are listed as FED or OTFED
ownership_canopy[which((ownership_canopy$nps == 'FED') |
                         (ownership_canopy$nps == 'OTFED')), "assumed_owner_type"] <- "FED"

# Delineate City based on Functional Parkland
ownership_canopy[which(!is.na(ownership_canopy$dprfunctio)), "assumed_owner_type"] <-
  "City"
ownership_canopy[which(!is.na(ownership_canopy$dprparkdom)), "assumed_owner_type"] <-
  "City"
#########

#########
# Refine Owner Name details when we can do so

# Create column for this
ownership_canopy$ownername_refined <- ownership_canopy$ownername

## NYS Owners with definitive datasets
# NYS OPRHP
ownership_canopy[which(ownership_canopy$nysoprhp_2 == 1 &
                         ownership_canopy$assumed_owner_type == "NYS"), "ownername_refined"] <-
  "NYS OPRHP Definitive"
# NYS DEC
ownership_canopy[which(ownership_canopy$declands == 1 &
                         ownership_canopy$assumed_owner_type == "NYS"), "ownername_refined"] <-
  "NYS DEC Definitive"

# NYCHA - Non RAD/PACT
# Pulls everything that is not null for nycha_deve and everything
# that is not RAD/PACT for nycha_mana (including nulls)
ownership_canopy[(!is.na(ownership_canopy$nycha_deve) &
                    ((
                      is.na(ownership_canopy$nycha_mana) |
                        (ownership_canopy$nycha_mana != "RAD/PACT")
                    ))), "ownername_refined"] <- "NYCHA non RAD/PACT"
##

# NPS
ownership_canopy[which(ownership_canopy$nps == 'FED'), "ownername_refined"] <-
  "NATIONAL PARK SERVICE Gateway"

# NYC PARKS
ownership_canopy[which(!is.na(ownership_canopy$dprparkdom)), "ownername_refined"] <-
  "NYC PARKS Definitive"
##################


##################
# LAND USE
ownership_canopy$landuse_description <-
  as.character(rep(NA, nrow(ownership_canopy)))

# Delineate Residential based on PLUTO
ownership_canopy[which(ownership_canopy$pluto_landuse == "01"), "landuse_description"] <-
  "Res 1 and 2 Family"
ownership_canopy[which(
  ownership_canopy$pluto_landuse == "02" | #Res Multifam Walkup
    ownership_canopy$pluto_landuse == "03" |
    #Res Multifam Elevator
    ownership_canopy$pluto_landuse == "04"
), #Res/Commercial
"landuse_description"] <- "Res MultiFam"

# Delineate nonresidential developed based on PLUTO
# Areas with no landuse description at this point are also added to this category at this point;
# Properties with other landuse types caputred in PLUTO get corrected further on in this code,
# as do property types that are assumed rights of way, and within specific City, State, and Federal
# jurisdictions for which we have clearer data.
ownership_canopy[which(
  ownership_canopy$pluto_landuse == "05" | #Commercial/Office
    ownership_canopy$pluto_landuse == "06" |
    #Industrial/Manufacturing
    ownership_canopy$pluto_landuse == "10" |
    #Parking
    ownership_canopy$pluto_landuse == "07"
), #Transit & Utility
"landuse_description"] <-
  "NonResidential Developed"

ownership_canopy[which(is.na(ownership_canopy$landuse_description)), "landuse_description"] <-
  "NonResidential Developed"

# Delineate Public Faciities & Institutions
ownership_canopy[which(ownership_canopy$pluto_landuse == "08"), "landuse_description"] <-
  "Public Facilities and  Institutions"

# Delineate Vacant Land
ownership_canopy[which(ownership_canopy$pluto_landuse == "11"), "landuse_description"] <-
  "Vacant Land"


## Delineate Parks and Rec in a few contexts baesd on PLUTO land use,
## buildingclass, and ancillary ownership information

# Based on PLUTO (PLUTO Class 09 is "Open Space & Outdoor Recreation")
ownership_canopy[which(ownership_canopy$pluto_landuse == "09"), "landuse_description"] <-
  "Parks and Rec"

# Delineate cemeteries uniquely based on PLUTO building class, as they are
# considered a form of Open Space and Outdoor Recreation in PLUTO
ownership_canopy[which(ownership_canopy$pluto_landuse == "09" &
                         ownership_canopy$pluto_bldgclass == "Z8"), "landuse_description"] <-
  "Cemeteries"

# Delineate land use for NYS Office of Parks, Recreation, and Historic Preservation as such
ownership_canopy[which(ownership_canopy$ownername_refined == "NYS OPRHP Definitive"), "landuse_description"] <-
  "NYS OPRHP Definitive"

# Delineate land use for NYS Department of Environmental Conservation as such
ownership_canopy[which(ownership_canopy$ownername_refined == "NYS DEC Definitive"), "landuse_description"] <-
  "NYS DEC Definitive"

# Delineate National Park Service - Gateway National Recreation Area as such.
ownership_canopy[which(ownership_canopy$ownername_refined == "NATIONAL PARK SERVICE Gateway"), "landuse_description"] <-
  "NATIONAL PARK SERVICE Gateway"

# Delineate NYC Parks lands as such
ownership_canopy[which(!is.na(ownership_canopy$dprparkdom)), "landuse_description"] <-
  "NYC Parks"
##

# Delineate land use Non-RAD/PACT NYCHA properties as such
ownership_canopy[which(ownership_canopy$ownername_refined == "NYCHA non RAD/PACT"), "landuse_description"] <-
  "NYCHA non RAD/PACT"

# Delineate Public Rights of Way
ownership_canopy[which(ownership_canopy$assumed_owner_type == "Assumed PROW"), "landuse_description"] <-
  "Assumed PROW"

## Create column for the landuse description that calls out schools, collesges,
## universities based on PLUTO building Class (Colleges and Universities) and the
## Facilities Database (Public K-12 schools)
## There are potential conflicts with other fields, but this is
## intended to get a sense of the areas and canopies for public schools and
## colleges/universities as reported in the report.
ownership_canopy$landuse_description_schools <-
  ownership_canopy$landuse_descrption

# Colleges and Universities
ownership_canopy[which(ownership_canopy$pluto_bldgclass %in% c("W5", "W6")), "landuse_description_schools"] <-
  "Colleges and Universities"
# Colleges and Universities
ownership_canopy[which(ownership_canopy$facsubgrp == "PUBLIC K-12 SCHOOLS"), "landuse_description_schools"] <-
  "Public K-12 Schools"
##
##################

##################
## Natural vs Developed Lands
# Create new column for this
ownership_canopy$natural_developed <-
  as.character(rep(NA, nrow(ownership_canopy)))

# Delineate NYC Parks as Natural or Developed based on the Dominant Type dataset
ownership_canopy[which(ownership_canopy$dprparkdom == "Developed"), "natural_developed"] <-
  "Developed"
ownership_canopy[which(ownership_canopy$dprparkdom == "Natural"), "natural_developed"] <-
  "Natural"

# Developed all other lands as Natural or Developed based on ECM Level 2 data from
# the Natural Areas Conservancy. Note - before this, the multiple classes were
# grouped in to this dichotomy of "Natural" or "Developed"
ownership_canopy[which(
  is.na(ownership_canopy$dprparkdom) &
    ownership_canopy$ecml2_dev_natural == "Developed"
),
"natural_developed"] <- "Developed"
ownership_canopy[which(
  is.na(ownership_canopy$dprparkdom) &
    ownership_canopy$ecml2_dev_natural == "Natural"
),
"natural_developed"] <- "Natural"

##################