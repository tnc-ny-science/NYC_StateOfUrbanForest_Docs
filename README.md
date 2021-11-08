## README

[Click here to jump to the Table of Contents](#table-of-contents)

This repository is intended to document analyses conducted in development of
*The State of the Urban Forest in New York City*. This is seeen as an expanded
version of **Appendix 1** in the report; the same methods are summarized, but
supported with relevant code and in cases additional details. The report is
available online at
[https://doi.org/10.5281/zenodo.5532876](https://doi.org/10.5281/zenodo.5532876)
and supplemental results files are available at
[https://doi.org/10.5281/zenodo.5210261](https://doi.org/10.5281/zenodo.5210261).

*Note, this repository is undergoing completion, along with some updates for formatting, readabiilty,
and organization. Thanks for your patience!*

This work is Copyright The Nature Conservancy, and all materials are provided
as-is, without warranty. The [License](./License.md) file applies to code in
this repository. All other materials are made available under a Creative Commons
Attribution-NonCommercial-ShareAlike License as set forth in our Conservation
Gateway Terms of Use (available at:
http://conservationgateway.org/Pages/Terms-of-Use.aspx)

If using these materials, please reference the report (per this recommended
citation): 
Treglia, M.L., Acosta-Morel, M., Crabtree, D., Galbo, K., Lin-Moges,
T., Van Slooten, A., and Maxwell, E.N. (2021). *The State of the Urban Forest in
New York City*. The Nature Conservancy. doi: 10.5281/zenodo.5532876

Navigate this page by scrolling, or using the Table of Contents, below.

## Table of Contents
  * [README](#readme)
- [The State of the Urban Forest in New York City: Online Methods Supplement](#the-state-of-the-urban-forest-in-new-york-city--online-methods-supplement)
  * [General Notes and Data Used in Analyses](#general-notes-and-data-used-in-analyses)
  * [Breakdown of Site Types](#breakdown-of-site-types)
    + [Land Ownership and Jurisdiction](#land-ownership-and-jurisdiction)
    + [Land Use](#land-use)
      - [Colleges/Universities, Schools, and Hospitals](#colleges-universities--schools--and-hospitals)
      - [Select Special Purpose Districts](#select-special-purpose-districts)
    + [Delineation of Natural Areas](#delineation-of-natural-areas)
  * [Analysis of Canopy Distribution and Canopy Change (Chapter 2)](#analysis-of-canopy-distribution-and-canopy-change--chapter-2-)
  * [Analysis of Street Trees (Chapter 2)](#analysis-of-street-trees--chapter-2-)
    + [Distribution, Size, and Common Species by Geography](#distribution--size--and-common-species-by-geography)
    + [Stocking Rate and Density per Road Mile](#stocking-rate-and-density-per-road-mile)
  * [Analysis of Landscaped Park Trees in City Parkland (Chapter 2)](#analysis-of-landscaped-park-trees-in-city-parkland--chapter-2-)
  * [Analysis of Equity of the NYC Urban Forest (Chapter 4)](#analysis-of-equity-of-the-nyc-urban-forest--chapter-4-)
    + [Urban Forest and Socioeconomic Metrics](#urban-forest-and-socioeconomic-metrics)
    + [Canopy around Schools and Hospitals](#canopy-around-schools-and-hospitals)
    + [Canopy and HOLC Grades (Redlining)](#canopy-and-holc-grades--redlining-)
  * [Additional Notes about Information Presented in This Report](#additional-notes-about-information-presented-in-this-report)
    + [Other Available Data on Canopy and Vegetation in NYC](#other-available-data-on-canopy-and-vegetation-in-nyc)
    + [Notes about the Economic Valuation of Benefits Presented](#notes-about-the-economic-valuation-of-benefits-presented)
  * [References](#references)



The State of the Urban Forest in New York City: Online Methods Supplement
=========================================


General Notes and Data Used in Analyses
---------------------------------------

For analysis, we accessioned all data into a
[PostgreSQL](https://www.postgresql.org/) (version 13.1) database with the
[PostGIS](https://postgis.net/) (version 3.1.1) extension installed that enabled
spatial queries (i.e., functionality of desktop GIS software implemented
directly within the database). Additional data processing and analysis were
conducted in the database (using SQL queries) and in
[R](https://cran.r-project.org/) (versions 3.5.2 and 4.0.3). In general, data
were loaded into Postgres through R code (see sample
[functions](R/dataloadingfunctions.R) and [examples](R/dataloadingexamples.R))
that can help facilitate that.

All spatial analysis was conducted with data projected in the NY State
Plane - Long Island Zone coordinate system (datum NAD83), EPSG code
2263. This coordinate reference system uses feet as the units. For
presentation of results in the report we converted units to acres (1
acre = 43,560 ft<sup>2</sup>)

Datasets used in analyses are listed below (**Table 1**). When
referencing specific attributes of individual datasets by name, for
concision we follow a convention of DatasetName.FieldName, where
"DatasetName" refers to the dataset, and the "FieldName" refers to the
column or field. We used the data that were most recent and that we
considered most appropriate for this work at the time of analysis. Thus,
for example, some older datasets that were not comparable to newer ones
were not leveraged for this report, and we may not have been able to
leverage more recent datasets if released during the later stages of
this report.

***Table Table 1. Data Sources used in Analysis in this Report.***
  
  |**Dataset\***                                                                                       |**Source\***|
  |----------------------------------------------------------------------------------------------------| -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  |MapPLUTO - version 20v6 (Tax lot boundaries)                                                        |NYC Department of City Planning; <https://www1.nyc.gov/site/planning/data-maps/open-data/dwn-pluto-mappluto.page>|
  |Borough Boundaries (Clipped to Shoreline)                                                           |NYC Department of City Planning; <https://www1.nyc.gov/site/planning/data-maps/open-data/districts-download-metadata.page>|
  |City Council Districts (Water Areas Included)                                                       |NYC Department of City Planning; <https://www1.nyc.gov/site/planning/data-maps/open-data/districts-download-metadata.page>|
  |Community District Boundaries (Water Areas Included)                                                |NYC Department of City Planning; <https://www1.nyc.gov/site/planning/data-maps/open-data/districts-download-metadata.page>|
  |Neighborhood Tabulation Areas - 2010                                                                |NYC Department of City Planning; <https://www1.nyc.gov/site/planning/data-maps/open-data/census-download-metadata.page>|
  |NYC Special Purpose Districts (Zoning)                                                              |NYC Department of City Planning; <https://www1.nyc.gov/site/planning/data-maps/open-data/dwn-gis-zoning.page>|
  |LION - version 16a (Linear Features for NYC)                                                        |NYC Department of City Planning; <https://www1.nyc.gov/site/planning/data-maps/open-data.page#lion>|
  |IPIS (Integrated Property Information System)                                                       |NYC OpenData; Dataset is no longer available from NYC OpenData but archived version is available from QRI at <https://qri.cloud/nyc-open-data-archive/ipis-integrated-property-information-system>|
  |FacDB (Facilities Database)                                                                         |NYC Department of City Planning; <https://www1.nyc.gov/site/planning/data-maps/open-data/dwn-selfac.page>|
  |Heat Vulnerability Index for NYC - 2018                                                             |NYC Department of Health and Mental Hygiene; data available at <https://a816-dohbesp.nyc.gov/IndicatorPublic/VisualizationData.aspx?id=2411,719b87,107,Map,Score,2018>|
  |NYC Parks Forever Wild Area Boundaries                                                              |NYC Open Data; https://data.cityofnewyork.us/Environment/NYC-Parks-Forever-Wild/48va-85tp |
  |Street Tree Census - 1995-1996                                                                      |NYC OpenData; <https://data.cityofnewyork.us/Environment/1995-Street-Tree-Census/tn4g-ski5>|
  |Street Tree Census - 2005-2006                                                                      |NYC OpenData; <https://data.cityofnewyork.us/Environment/2005-Street-Tree-Census/29bw-z7pj>|
  |Street Tree Census - 2015-2016                                                                      |NYC OpenData; <https://data.cityofnewyork.us/Environment/2015-Street-Tree-Census-Tree-Data/pi5s-9p35>|
  |Tree Canopy Change -- 2010-2017                                                                     |NYC OpenData; <https://data.cityofnewyork.us/Environment/Tree-Canopy-Change-2010-2017-/by9k-vhck>|
  |NYC Parks Dominant Type Dataset                                                                     |NYC Department of Parks and Recreation; Dominant Type, 2020|
  |NYC Parks Golf Course Boundaries                                                                    |NYC Department of Parks and Recreation; Golf Courses, 2020|
  |NYC Parks Park Tree Inventory for Landscaped Park Areas of City Parkland                            |NYC Department of Parks and Recreation; Park Tree Inventory, 2018|
  |Street Tree Capacity Estimates                                                                      |NYC Department of Parks and Recreation; Street Tree Capacity, 2017|
  |Social Vulnerability Index - 2018                                                                   |Centers for Disease Control and Prevention/ Agency for Toxic Substances and Disease Registry/ Geospatial Research, Analysis, and Services Program. CDC/ATSDR Social Vulnerability Index, 2018 Database, New York. <https://www.atsdr.cdc.gov/placeandhealth/svi/data_documentation_download.html.>|
  |HOLC (Home Owners' Loan Corporation) Boundaries and Grades                                          |University of Richmond, Digital Scholarship Lab; Nelson, R.K., Winling, L., Marciano, R., Connolly, N. et al. Mapping inequality. American Panorama, ed. Nelson, R.K., and Ayers, E.L. Available:  https://dsl.richmond.edu/panorama/redlining/ |
  |Gateway National Recreation Area Boundaries                                                         |National Park Service|
  |ECM (Ecological Covertype Map)                                                                      |The Natural Areas Conservancy|
  |NYC Housing Authority Properties                                                                    |NYC Housing Authority|
  |NYS State-Owned Parcels                                                                             |NYS GIS Clearinghouse; <http://gis.ny.gov/gisdata/inventories/details.cfm?DSID=1300>|
  |NYS Department of Environmental Conservation Lands (DEC Lands)                                      |NYS GIS Clearinghouse; <https://gis.ny.gov/gisdata/inventories/details.cfm?DSID=1114>|
  |NYS Historic Sites and Park Boundary (NYS Office of Parks, Recreation, and Historic Preservation)   |NYS GIS Clearinghouse; <https://gis.ny.gov/gisdata/inventories/details.cfm?DSID=430>|
  ---------------------------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
\* Where available, specific versions of datasets are indicated, and
data were generally accessed in October 2020.

\*\* In cases where no URL is indicated, datasets were shared by the
respective entities and used with permission.

Breakdown of Site Types
-----------------------

We developed a holistic data layer that encompassed a broad suite of
datasets representing land ownership and jurisdiction, zoning, land use,
administrative and political boundaries, and biophysical data such as
Natural Area types into a single data layer (referred to as the
"mashup"). This was done in coordination with staff from the NYC
Department of Parks and Recreation (NYC Parks) Division of Forestry,
Horticulture, and Natural Resources for consistency in data used across
similar efforts, and with contracted support from the geospatial
technology company, Azavea. Some of the input data are not publicly
available and were used with permission or under data-sharing
agreements. This mashup ultimately enabled us to describe the urban
forest across site types, described in the report, based on ownership or
jurisdiction and land use characteristics, as well as other specific
breakdowns such as select Special Purpose Districts.

We restricted all analyses to the land area of NYC, based on the dataset of
"Borough Boundaries (Clipped to Shoreline)" from the NYC Department of City
Planning (DCP). Given that different datasets representing the land area of NYC are
sometimes used or created by different City agencies (among others), whenever
possible, we leveraged datasets that were not restricted to land area, but only
considered areas within those borough boundaries for consistency. For example,
the version of the Parcels dataset for NYC (MapPLUTO) that is clipped to the
shoreline sometimes differs in the representation of the shoreline, thus we used
the "unclipped" version of that dataset (in which some parcels extend into New York
Harbor) in the mashup, but only considered portions of the parcels within the
DCP Borough Boundaries (Clipped to Shoreline) dataset for all analysis and
numbers presented in the report. For analysis, area of every polygon in the
mashup was calculated and areas were aggregated based on appropriate grouping
(e.g., by site type, administrative or political unit).

### Land Ownership and Jurisdiction

While some data (e.g., administrative and political boundaries) were leveraged
in the mashup as provided, we processed other datasets to fit our specific
purposes or to overcome known limits, to the extent
possible. This was particularly the case for ownership and jurisdiction. The
best available, single dataset that represents spatial boundaries, ownership,
and land use (among other attributes) of parcels (i.e., tax lots or properties)
is MapPLUTO, publicly available from DCP, developed from a suite of datasets
available from City agencies. While it is an invaluable dataset, and there are ongoing
efforts to improve it,[^1] MapPLUTO has limits. For example, in some
cases MapPLUTO offers limited resolution for the OwnerType field, not
specifically delimiting State, Federal, or private, tax-exempt entities.
Furthermore, our understanding for publicly owned properties, on which taxes are
not collected, is that the ownership or jurisdictional information is not
reliably updated. Thus, in some cases ownership information for public
properties is outdated. To improve, and simplify characterizations of ownership,
particularly for public entities, we developed holistic approximations of
ownership based on generalizations we drew from inspecting MapPLUTO data in
conjunction with the MapPLUTO data dictionary,[^2] and by leveraging additional
data as described below. Our re-classifications of the ownership or
jurisdictional information are imperfect due to nature of the data, but they
enabled a clearer breakdown that was sufficient for our intents and purposes. In
many cases we are not able to accurately discern granular ownership or
jurisdiction such as those of most individual government agencies. These results
were primarily leveraged for Chapter 2 of the report, but many are referenced
throughout. R code used to accomplish this re-coding is available in
[ownership_landuse_recoding.R](./ownership_landuse_recoding.R) (lines 59-217).

-   For properties where MapPLUTO.OwnerType was recorded as either City ("C" in MapPLUTO)
    or Mixed ("M" in MapPLUTO; mixed City and private ownership), we classified these as City-owned.

-   For properties where MapPLUTO.OwnerType was recorded as either Other
    ("O" in MapPLUTO; owned by a public authority or the State or Federal government) we
    classified these as State-owned.

-   For properties where MapPLUTO.OwnerType was blank, or was recorded as
    Private ("P" in MapPLUTO) or as a "fully tax exempt" ("X" in MapPLUTO) entity, we classified these as 
    privately-owned.

-   For a suite of properties where owner name was listed in MapPLUTO as
    federal entities (e.g., U.S. Post Office), we classified these
    properties as Federally-owned).

-   We leveraged other datasets to supplement MapPLUTO. Where these
    overlapped MapPLUTO, they were given priority over MapPLUTO as they
    were generally seen as more reliable. In cases where multiple
    datasets overlapped, the ownership delineation earlier in the list
    was given precedence:

    -   NYC Parks' Dominant Type dataset represents properties
        designated and managed as City Parkland, under the jurisdiction
        of NYC Parks. This dataset delineates each area as "Natural" or
        "Developed." In some cases, mapped but unbuilt roads adjacent to
        or within formal properties are included, though these are
        managed as City Parkland. All land captured in this dataset was
        assumed to be City-owned, and more specifically within NYC
        Parks' jurisdiction. Notably, some areas within these datasets
        are not designated as tax lots but are mapped as City Parkland
        and were treated as such for all analysis.

    -   Based on information within the boundaries dataset for Gateway National
        Recreation Area, we designated areas as Federal land, and as
        appropriate, specifically National Park Service - Gateway property.

    -   All NYC Housing Authority (NYCHA) Properties were considered State-owned,
        and those that were not delineated as part of Rental
        Asssistance Demonstration/Permanent Affordability Commitment Together (RAD/PACT)
        programs (which focus on leveraging private and non-profit partnerships)
        were specifically considered within the jurisdiction of NYCHA.

    -   Properties in the NYS-owned, NYS Office of Parks, Recreation and
        Historic Preservation (NYS OPRHP), and NYS Department of Environmental
        Conservation (NYS DEC) properties datasets were considered State-owned.
        Properties in the latter two datasets were assumed to be in the
        jurisdiction of those agencies, respectively.

    -   We incorporated data from the Integrated Property Information System
        (IPIS), based on the parcel identifier (borough, block, and lot number),
        reflecting whether properties are owned or leased by the City of New
        York. When the IPIS data indicated that properties were owned by the City
        (owned_leased field coded as "O"), we considered them City-owned in the
        mashup. For properties with multiple, conflicting entries (i.e., some
        entries for one property indicated City-ownership, while others
        indicated City-leased), we assumed the properties were City-owned.

    -   Lands that were not within any of the aforementioned datasets were
        considered rights of way. A specific data layer representing this had
        been developed separately and incorporated into the mashup. In the data
        processing to develop the mashup, extremely small gaps (<0.004" wide in
        most cases) between some layers appeared between jurisdictional layers
        such as MapPLUTO and the layer representing rights of way. In these
        cases, when no other ownership or jurisdictional information was
        associated with these spaces, we assumed them to within rights of way.

### Land Use

To distill how land is used, we leveraged some of the aforementioned
information as well as specific information from MapPLUTO related to
land use (MapPLUTO.LandUse) and building class (MapPLUTO.BldgClass), as
follows. Rules that applied to all lands within certain categories
superseded earlier rules (e.g., NYC Parks properties were considered
Parkland, regardless of designations in MapPLUTO). We used information
from MapPLUTO as provided, with the following exceptions:

-   Properties with MapPLUTO.LandUse coded as Multi-Family Walk-Up ("02"),
    Multi-Family Elevator ("03"), and Mixed Residential & Commercial Buildings ("05")
    were classified as Multifamily Residential.

-   Properties with MapPLUTO.LandUse coded as Commercial & Office ("05"),
    Industrial & Manufacturing ("06"), Transportation & Utility ("07"), and Parking 
    Facilities ("10"), were classified as Non-Residential Developed. A small
    percentage (0.34%) of tax lots did not have land use information in
    MapPLUTO. After on spot-checking some of those sites with aerial
    imagery, we grouped them in this category.

-   While cemeteries generally have MapPLUTO.LandUse coded as Open Space
    and Outdoor Recreation ("09"), we specifically considered them as
    cemeteries based on the building class code (MapPLUTO.BldgClass of
    "Z8").

-   For all properties associated with NYC Parks, Gateway National
    Recreation Area, NYCHA, NYS DEC, and NYS OPRHP, we classified the land use to be aligned with the
    owning or managing entity (e.g., NYC Parks properties were all
    considered City Parkland).

Relevant R code used to accomplish this re-coding of land use information, as
well to delineate classes listed below (Colleges/Universities, Schools,
Hospitals, and Natural vs Developed areas) is available in
[ownership_landuse_recoding.R](./ownership_landuse_recoding.R) (starting at Line 220).

#### Colleges/Universities, Schools, and Hospitals

For select analyses or reporting numbers in the report (found in Chapter 7), we
also noted Colleges and Universities specifically based on the building class
information in MapPLUTO (MapPLUTO.BldgClass coded as either "W5" or "W6"). We
also identified Public Schools in NYC, leveraging the Facilities Database (FacDB)
developed by DCP (leveraged in Equity Analyses for Chapter 4). We considered
public schools to be any properties for which the Facility Subgroup
(FacDB.FACSUBGRP) was coded as "PUBLIC K-12 SCHOOLS" and joined these data to
the mashup based on the borough, block, and lot number (BBL). Similarly, we
identified hospitals (for analysis in Chapter 4) in NYC based on the Facilities
Database, where FacDB.FACTYPE was coded as "Hospital" again, joining the data to
the mashup based on the BBL.

#### Select Special Purpose Districts

To report the canopy and land area of applicable properties within Special
Purpose Districts in the context of zoning regulations (found in Chapter 5), we
leveraged the Special Purpose Districts dataset from DCP. We specifically
examined land that was within tax lots (i.e., not rights of way) and excluded
land considered City Parkland, per the above. Special Purpose Districts of
interest were identified based on the "sdname" field. Specifically, we queried
for those areas with sdname being "Special Fort Totten Natural Area District,"
"Special Hillsides Preservation District," "Special Natural Area District," and
"Special South Richmond Development District."

### Delineation of Natural Areas

To delineate natural areas from the rest of the landscape (primarily
discussed in Chapter 2), we leveraged both the Dominant Type dataset
from NYC Parks for City Parkland and the Ecological Covertype Map (ECM; level 2 data)
from the Natural Areas Conservancy for other portions of the NYC
landscape. For City Parkland, Natural Areas were any areas considered
"Natural" in the Dominant Type dataset (as opposed to "Developed"); we
also captured whether lands were designated as ForeverWild areas based
on the respective dataset shared by NYC Parks. For the rest of the
landscape, we considered natural areas as those classified in the ECM as
"Forested Wetland," "Freshwater Aquatic Vegetation," "Freshwater
Wetland," "Inland Water," "Maritime Forest," "Off-shore Water,"
"Saltwater Aquatic Vegetation," "Tidal Wetland," "Upland Forest," or
"Upland Grass/Shrub." For purposes of this report, we considered
forested natural areas as those that had canopy according to the Tree
Canopy Change dataset.

A small portion of the area of NYC near the edges of the borough
boundaries (3.5 acres total) had not been classified at all in the ECM,
likely due to slight changes in available data layers representing
borough boundaries since the time the ECM was created. These areas
generally fell in suburban areas in far Queens (along the boundary with
Nassau County) and the Bronx (along the boundary with Westchester
County). Based on our observations of the data, considered these areas
as non-natural areas in analyses and aggregations of data.

Analysis of Canopy Distribution and Canopy Change (Chapter 2)
-------------------------------------------------------------

We calculated the area and percentage of tree canopy across NYC in 2010
and 2017, as well as change in canopy, across different geographies and
site types by overlaying the tree canopy change dataset data with the
mashup. Every polygon in the tree canopy change dataset is classified as
"Gain," "Loss," or "No Change." Gain polygons reflect canopy present in
2017 but not 2010; Loss polygons reflect canopy present in 2010 but not
2017; No Change polygons reflect canopy present in both years.
Calculations could therefore be conducted based on the following
relationships:

-   Canopy Area 2010 = \[Area of "Loss" Polygons\] + \[Area of "No
    Change" Polygons\]

-   Canopy Area 2017 = \[Area of "Gain" Polygons\] + \[Area of "No
    Change" Polygons\]

-   Canopy Area Change 2010-2017 = \[Canopy Area 2017\] - \[Canopy Area
    2010\]

The version of the tree canopy change data we used had minor corrections to
remove rare instances of overlaps among polygons. The total area of overlaps in
the original dataset was 48.84 ft<sup>2</sup>, so there would have been no
measurable difference in results had we used the data from NYC
Open Data.

The spatial overlay analysis split every polygon in the tree canopy
change dataset by every polygon boundary in the mashup. Based on that
result, we summed area of Gain, Loss, and No Change by geographic unit,
jurisdiction, and land use categories, and from there calculated the
area of canopy in 2010 and 2017.

Every polygon in the mashup has its own area, calculated from the
spatial data, thus, for analyses in which we considered total area of
geographic units (e.g., boroughs, Community Districts, etc.) and site
type categories (based on ownership and land use), we aggregated area of
polygons accordingly. Canopy percentage by area was calculated as:

-   Canopy % \[Year\]<sub>*i*</sub> = \[Canopy Area \[Year\]<sub>*i*</sub>\] / \[Total
    Area<sub>*i*</sub>]

*Canopy Area \[Year\]* refers to *Canopy Area 2010* or *Canopy Area
2017*, and the *Total Area* refers to the sum of the of all polygons for
the areas of interest (e.g., the focal geography, ownership, or land use
categories). The subscripted *i* refers to the focal geography (e.g.,
each individual, borough, Community District, etc.), or site type
category.

Percentage changes in canopy can be calculated as:

-   Net Canopy Change (%)<sub>*i*</sub> = \[Canopy % 2017<sub>*i*</sub>\] -- \[Canopy %
    2010<sub>*i*</sub>\]

-   Relative Canopy Change (%)<sub>*i*</sub> = 100 \* (\[Canopy % 2017<sub>*i*</sub>\] --
    \[Canopy % 2010<sub>*i*</sub>\])/\[Canopy % 2010<sub>*i*</sub>\]

A template of code used for doing the overlay and associated calculations PostGIS code can be found in [./SQL/CanopyCoverOverlay.sql](./SQL/CanopyCoverOverlay.sql).

Note - for select analysis intended to estimate how much canopy was roughly attributable to new tree planting vs. expansion of existing trees we derived a dataset from the original canopy change polygon data, in which only polygons that did not touch other polygons were considered. PostGIS code for that operation is available in [./SQL/CanopyCover_NonTouchingPolygons.sql](./SQL/CanopyCover_NonTouchingPolygons.sql).

Analysis of Street Trees (Chapter 2)
------------------------------------

Analysis of street trees was primarily based on the data from the 1995-1996,
2005-2006, and 2015-2016 street tree census datasets. Analysis of street tree
stocking rates was based on estimated street tree capacity data, developed by
NYC Parks. Unless otherwise noted, code used for these analyses is available in
[./SQL/StreetTrees_Queries.sql](./SQL/StreetTrees_Queries.sql).

### Distribution, Size, and Common Species by Geography

For street trees, analysis focused on data from the most recent street
tree census, although older datasets were used for estimated numbers of
street trees in the respective time periods. Living trees were
delineated based on StreetTreeCensus2015.Status being recorded as
'Alive.' For 1995-1996, living trees were counted as those for which
StreetTreeCensus1995.Condition was not recorded as "Dead," "Planting
Space," "Shaft," or "Stump," and for 2005-2006, living trees were
counted as those for which StreetTreeCensus2005.Status was not recorded
as "Dead."

To understand the distribution of street trees across NYC as of the most
recent street tree census, we leveraged the spatial data with each tree
point, conducting overlay analyses to identify which trees were in each
focal unit (borough, Community District, City Council District, and
Neighborhood Tabulation Area). Though this information was already
associated with the data, for consistency in our work, we conducted this
analysis using the data available. For the previous street tree
censuses, some points did not have spatial data, thus we leveraged the
information on borough, Community District, City Council District, and
Neighborhood Tabulation Area that was associated with the tree data as
available.

We leveraged the most recent street tree census data to represent
information about size of the trees, both generally and by geography. We
calculated median and mean diameter at breast height (DBH) for living trees
(based on StreetTreeCensus2015.tree\_dbh), as well as the number and
percentage of trees less than 6" DBH and greater than 30" DBH. We also
processed data to identify the most common entry on
StreetTreeCensus2015.spc\_common field for living trees by geography to
understand the most common species in each unit.

### Stocking Rate and Density per Road Mile

In the report, we present information on stocking rate of trees, which we
calculated as the number of existing (living) street trees, per the 2015
street tree census, out of the total estimated capacity. Capacity was
estimated by NYC Parks following the street tree census, at the scale of
block-faces (the linear spaces along streets and sidewalks that could
theoretically contain tree beds). In some instances, block faces span
multiple geographic or administrative units (e.g., a Neighborhood
Tabulation Area boundary may be in the middle of a block). In such cases
we split the block-face lines based on the respective boundaries and
assigned the capacity to each new line based on the relative length from
the original block face. For example, if a block face was split by a
Community District boundary, such that 60% of the original length fell
in one Community District and 40% fell in the other, 60% of the original
capacity for that full block face was assigned to the Community District
with the 60% of the line. Numbers were rounded to the nearest whole number.
Stocking rates were then calculated as the number of living street trees
divided by the total capacity within the respective geographic unit.

Tables in Appendix 2 have information on living street trees per road
mile (trees per road mile) by geographic unit. The patterns we observed
across NYC were generally similar between stocking rates and trees per
mile, thus, for concision, we only presented stocking rate data in the
body of the report. To calculate the mileage of relevant roads within
each geographic unit, we leveraged the LION dataset for NYC, which
represents a variety of linear features such as streets and sidewalks.
We used version 16A which captures the landscape of as of early 2016, as
an approximation of the landscape during the 2015-2016 street tree
census. We only considered line features in LION coded as "streets"
(LION.RW\_TYPE = 1) and excluded those that were coded as private
(LION.FeatureTyp = 6). Furthermore, we only considered those identified
as either a roadbed, an undivided street, or a roadbed segment
(LION.SegmentTyp = U, B, or R), and excluded those coded as inaccessible
to pedestrian usage (as street trees are generally along sidewalks;
LION.NonPed = D). After selecting the appropriate features in LION, we
split them based on geographic boundaries and calculated the total
length of road features within each unit. Trees per road mile were then
derived as the total number of living street trees within each area,
divided by the total mileage of roads within that area.

Analysis of Landscaped Park Trees in City Parkland (Chapter 2)
--------------------------------------------------------------

For analyses of trees in landscaped portions of City Parkland, we
leveraged two key datasets: a recent inventory of these trees (the
Park Tree Inventory) from NYC Parks, and the Dominant Type dataset for
City Parkland. We leveraged the borough associations of the trees after
spot-checking for data for consistency with boundaries, only considering
trees presumed to be alive (i.e., those for which
ParkTreeInventory.Condition was not coded as "Dead"). We derived the
area of landscaped portions of City Parkland from the mashup, only
considering the areas within the land boundaries of NYC and those where
the area was indicated as "Developed," rather than "Natural"). Density
of trees in landscaped portions of City Parkland was calculated as the
number of these living trees divided by the area.

Analysis of relative abundance of the different kinds of trees in these
spaces was based on unique field that captured the kinds of trees.
Analysis of size was based on a field representing the DBH.

Analysis of Equity of the NYC Urban Forest (Chapter 4) 
-------------------------------------------------------
*Note: R Code associated with this section is available in [R/equity_analyses.R](R/equity_analyses.R).*

### Urban Forest and Socioeconomic Metrics

In considering equity of the urban forest, we examined correlations
between three variables representing attributes of the urban forest of
NYC and a suite of socioeconomic variables. We used Neighborhood
Tabulation Areas (NTAs) as the units of analysis. For the canopy metrics
(canopy cover and relative change in canopy), we calculated variables
for each NTA buffered by one-quarter mile (clipped to land area), as a
way to help capture access to the urban forest and its benefits present
in adjacent areas. Natural areas and large parks or cemeteries, such as
Central Park, would otherwise be excluded from analysis, based on the
boundaries of NTAs.

Urban forest metrics were computed following the same overall methods 
described in previous sections, and included:

-   Canopy cover as of 2017 (%) for each NTA (+0.25 mile buffer);

-   Relative change in canopy (+0.25 mile buffer); and

-   Street tree stocking rate.

Below are the socioeconomic variables we included in the analysis. Most
were based on data from the 2018 Social Vulnerability Index, developed
by the U.S. Centers for Disease Control and Prevention (CDC). These are
indicated with a parenthetical remark, indicating the original variable
name from the Social Vulnerability Index data ("SVI variable \[variable
name\]"). Those variables were ultimately sourced or derived by the CDC
from U.S. Census 2014-2018 American Community Survey estimates, at the
scale of census tracts. We aggregated the data to the scale of NTAs the
based on standardized data from DCP.[^3] For these aggregations, we
averaged values, weighted by estimates of total population within each
census tract (included within the original Social Vulnerability Data).
The Heat Vulnerability Index (HVI) was sourced from the NYC Department of
Health and Mental Hygiene for the scale of NTAs, representing
approximately 2018.

-   Per Capita Income (SVI variable EP\_PCI)

-   Percent of People Below the Federal Poverty Level (SVI variable
    EP\_POV)

-   Percent of People Aged 65 or Older (SVI Variable EP\_AGE65)

-   Percent of People Aged 17 or Younger (SVI Variable EP\_AGE17)

-   Percent of People with Limited English (SVI variable EP\_LIMENG)

-   Percent of People of Color (SVI variable EP\_MINRTY)

-   Percent of Housing Units with More People than Rooms (SVI variable
    EP\_CROWD)

-   Percent of Households with No Vehicle (SVI variable EP\_NOVEH)

-   Socioeconomic SVI Theme (SVI variable SPL\_THEME1)

-   Household Composition SVI Theme (SVI variable SPL\_THEME2)

-   Minority Status/Language SVI Theme (SVI variable SPL\_THEME3).

-   Housing Type/ Transportation SVI Theme-(SVI variable SPL\_THEME4)

-   Combination SVI Theme (SVI variable SPL\_THEMES)

-   Heat Vulnerability Index

We analyzed correlations between each urban forest metric and each
socioeconomic metric based on Kendall's tau correlation. We did this
with all data together and with data grouped by borough. SoVI Theme
variables were leveraged as-is for analysis, given the correlation
metric we used is based on ranks; for display purposes those data were
rescaled to a range of 0-1.

### Canopy around Schools and Hospitals

We examined whether canopy around hospitals and public schools was
related to the canopy in the respective NTAs (plus the quarter mile
buffer) the respective institutions were located within to understand
whether these were representative of the broader trends or unique in
terms of canopy cover. We considered canopy cover (%) within a 500 ft
buffer of these properties, restricted to land area (see earlier section
on *Colleges/Universities, Schools, and Hospitals* for how these were
identified). We calculated Kendall's tau correlation coefficient and the
associated p-value between the canopy cover within each NTA plus the
quarter mile buffer (per the previous section) and the canopy within the
500 ft buffer of school and hospitals, separately.

### Canopy and HOLC Grades (Redlining)

We examined the relationship between current canopy cover and grades
historically assigned to geographic areas by the Home Owners' Loan
Corporation (HOLC) as an initial exploration into potential legacy
effects of redlining on the distribution of the urban forest of NYC. We
calculated canopy cover (%) as of 2017, constrained to land area, for
each area that had a HOLC grade, using data from the *Mapping
Inequality* project at the University of Richmond's Digital Scholarship
Lab. We conducted correlation analyses considering the HOLC grade as an
ordinal variable, as they are ordered (A \[highest\] to D \[lowest\]),
and used Kendall's tau correlation.


Additional Notes about Information Presented in This Report
-----------------------------------------------------------

### Other Available Data on Canopy and Vegetation in NYC

In addition to the work leveraged in this report, other analyses of
vegetation and tree canopy in NYC have been conducted through the years.
We did not include them in our analysis because they were not comparable with
the most recent data, or generally to each other. Particular works that
may interest readers include: analysis for a 2006 report about
existing and potential canopy in NYC that leveraged aerial imagery[1];
research on estimating vegetation abundance and change based on spectral
mixture analysis leveraging Landsat imagery[2,3]; and analysis of
vegetation change based on spectral mixture analysis leveraging Landsat
magery[4].

### Notes about the Economic Valuation of Benefits Presented

We drew on a variety of studies related to benefits of the urban forest
in NYC, with two specific efforts to offer estimates of economic
valuation of those benefits. We recognize, as with all modeled
estimates, there are limits, and included information from both,
recognizing they capture different aspects or different benefits of the
urban forest. The two efforts we leveraged were: an analysis of samples
of the urban forest throughout NYC (stratified by borough)[5] that
leveraged i-Tree Eco[6]; and an analysis of street tree data by NYC
Parks[7], following the most recent street tree census that leveraged
i-Tree Streets[8]. The distinct input data and the different tools
likely contributed to different results presented in these works[9].

In discussing specific economic benefits of trees in NYC, we primarily
used the former analysis[5] as it attempted to estimate benefits for the entire
urban forest of NYC, and i-Tree Eco is undergoing regular updates. We
used the results from NYC Parks to supplement information about different
benefits presented, such as, relating to on aesthetics and air pollution
removal.

References
----------

\[1\]. Grove JM, O'Neil-Dunne J, Pelletier K, Nowak D, Walton J. A report on
New York City's present and possible urban tree canopy. United States
Department of Agriculture, Forest Service, Northeastern Area, South
Burlington, Vermont. 2006;

\[2\]. Small C. Estimation of urban vegetation abundance by spectral mixture
analysis. International journal of remote sensing. 2001;22(7):1305--34.

\[3\]. Small C, Lu JWT. Estimation and vicarious validation of urban
vegetation abundance by spectral mixture analysis. Remote sensing of the
environment 2006;100(4):441--56.

\[4\]. Locke DH, King KL, Svendsen ES, Campbell LK, Small C, Sonti NF, et
al. Urban environmental stewardship and changes in vegetative cover and
building footprint in New York City neighborhoods (2000--2010). Journal
of Environmental Studies and Sciences. 2014 Jul 1;4(3):250--62.

\[5\]. Nowak DJ, Bodine AR, Hoehn RE, Ellis A, Hirabayashi S, Coville R, et
al. The urban forest of New York City. Newtown Square, PA: USDA Forest
Service, Northern Research Station; 2018 Sep p. 1--82. Report No.:
NRS-117.

\[6\]. i-Tree. i-Tree Eco. 2020. Available from:
<https://www.itreetools.org/tools/i-tree-eco>

\[7\]. NYC Department of Parks and Recreation \[Internet\]. 2015 Street Tree
Census Report. 2017. Available from:
<http://media.nycgovparks.org/images/web/TreesCount/Index.html#portfolio>

\[8\]. i-Tree. i-Tree Streets. 2019. Available from:
<https://www.itreetools.org/tools/i-tree-streets>

\[9\]. Kuehler EA. Technical notes - comparison of i-Tree Eco and i-Tree
Streets carbon storage and sequestration values. Athens, Georgia: Urban
Forestry South; 2010. Available from:
<https://urbanforestrysouth.org/resources/library/ttresources/technical-notes-comparison-of-i-tree-eco-and-i-tree-streets-carbon-storage-and-sequestration-values>

[^1]: Changes are captured in the code base underlying this product,
    available on GitHub at <https://github.com/NYCPlanning/db-pluto>, as
    well as in the Read Me files associated with each release. The Read
    Me document for the version used in this report is available at
    <https://www1.nyc.gov/assets/planning/download/pdf/data-maps/open-data/pluto-readme.pdf?r=20v6>.

[^2]: Version used for this report available at
    <https://www1.nyc.gov/assets/planning/download/pdf/data-maps/open-data/pluto_datadictionary.pdf?r=20v6>.

[^3]: We leveraged the "2010 Census Tract to 2010 Neighborhood
    Tabulation Area Equivalency" data table, available from DCP to
    associate individual census tracts with NTAs. Data table available
    at:
    <https://www1.nyc.gov/site/planning/data-maps/open-data/dwn-nynta.page>
