Open Data related to the NYC Urban Forest -- Quick Reference Sheet
==================================================================

Developed by Michael Treglia, Alaina Van Slooten, and Natalia Piland of
The Nature Conservancy in New York, Cities Program for a [NYC Open Data
Week 2022
event](https://2022.open-data.nyc/event/understanding-the-urban-forest-in-nyc-through-open-data/).

Contact: Michael Treglia, Lead Scientist -- michael.treglia\@tnc.org

*Disclaimer: This material is provided by The Nature Conservancy as-is,
without warranty under a Creative Commons
Attribution-NonCommercial-ShareAlike License as set forth in our
Conservation Gateway Terms of Use (available at:
<http://conservationgateway.org/Pages/Terms-of-Use.aspx>)*

Table of Contents
--------

- [Overview](#overview)
- [Supplemental Files from *The State of the Urban Forest in New York City*](#supplemental-files-from-the-state-of-the-urban-forest-in-new-york-city)
- [Canopy Change Data](#canopy-change-data)
- [Street Tree Census Data](#street-tree-census-data)
- [Equity Data](#equity-data)


Overview
--------

The Nature Conservancy in New York's Cities Program recently released
[*The State of the Urban Forest in New York
City*](https://www.nature.org/content/dam/tnc/nature/en/photos/TheStateoftheNYCUrbanForest.pdf),
a report that provides a holistic, point-in-time understanding of the
urban forest citywide. The report built primarily on a wealth of Open
Data and published research to characterize trees and their canopy
across NYC, and the physical and social infrastructure that support
them, across public and private property.

As part of [NYC Open Data Week](https://2022.open-data.nyc/) 2022 we
developed a presentation and workshop focused on the report and key Open
Data sets related to the urban forest. This document is intended to
serve as a quick reference sheet for folks interested in NYC urban
forestry datasets to start working with them. In many cases, examples of
software that is available to open specific file formats is listed, with
options for proprietary and free and open source when possible.

Although data files of summarized results from the report were developed by The
Nature Conservancy, the other data discussed here were produced by and/or made
available by government agencies. The datasets presented here are
some of key ones that those interested in understanding NYC urban forestry data
should be aware of, although there may be others and this is not a exhaustive list.

While this document is intended to serve as a reference for users who may work
with data files for analysis and vizualization, a suite of results and
interpretations based on these and other data are presented in the report linked
above, as well as within a [StoryMap developed by the NYC Department of Parks
and
Recreation](https://storymaps.arcgis.com/stories/5353de3dea91420faaa7faff0b32206b).

Supplemental Files from *The State of the Urban Forest in New York City*
------------------------------------------------------------------------

As part of *The State of the Urban Forest in New York City*, The Nature
Conservancy released a set of supplementary data files, making a variety
of results of the data processing and analysis that went into the report
available for others to use (e.g., for visualization and analysis). The
files are available at <https://zenodo.org/record/5210261> (scroll down at that webpage
for download links).

The repository contains the following zipped folders with data.
| File Name | Description | Some Potential Uses
|-----------|-------------|---------------------------
***canopy\_jurisdiction\_landuse\_borough.zip*** | Zipped folder with comma separated values (.csv) file of land area and canopy area summaries by approximated general ownership type, land use categories, and natural/developed breakdown, with Data Dictionary files in .docx and .html formats. | The contained data can be used to gain a better understanding of how tree canopy and land area are distributed across different ownership types (e.g., City vs State vs Federal vs Private) and land uses (e.g., residential vs institutional or commercial), by borough.
***canopy\_streettree\_summaries.zip*** | Zipped folder containing GeoPackage (.gpkg), Esri File Geodatabase (.gdb), and comma separated values (.csv) files with canopy and street tree summary data at the scales of Neighborhood Tabulation Area, Community District, City Council District, and Borough, with Data Dictionary files in .docx and .html formats. | The contained data can be used to understand the distribution of tree canopy and street trees, and changes in these measures of the urban forest, across the city. For example, one could look at what areas in NYC have the most or least canopy, or have seen the greatest increases in recent years.
***equity\_data.zip*** | Zipped folder containing GeoPackage (.gpkg), Esri File Geodatabase (.gdb), and comma separated values (.csv) files with data used for equity analyses at the scale of Neighborhood Tabulation Area, with Data Dictionary files in .docx and .html formats. *Note - the column named \"relativecanopychange\_percent\" represents relative canopy change from 2010 to 2017 as proportions, not percentages. To convert these numbers to percentages, values can be multiplied by 100.* | The contained data can be used to analyze and visualize the relationship of the urban forest with socioeconomic, demographic, and vulnerability metrics across the city. For example, one can use the data to look into questions such as "how is tree canopy related to income across NYC at the scale of Neighborhood Tabulation Areas?"
***naturalareas\_canopy\_jurisdiction\_borough.zip*** | Zipped folder with comma separated values (.csv) file of summaries of natural area canopy data by approximated general ownership type and by borough, with Data Dictionary files in .docx and .html formats. | The data in this folder can help users understand how much of the urban forest, as measured by canopy, is in natural areas in different jurisdictions across NYC.

Some notes:

-   After downloading, the desired .zip files, users can unzip the
    folders using the utilities installed with their operating system or
    through software such as the free and open source software,
    [7-Zip](https://www.7-zip.org/).

    -   All of these folders contain respective *Data Dictionary* files
        (in both .html and .docx formats) which detail what the columns
        in each dataset represent, and in cases where multiple data
        files are included (e.g., different files for different
        geographic units), information about what data are in each file.
        You may want to have the Data Dictionary handy as you work with
        the data.

-   All folders contain data files in .csv ("Comma Separated Values")
    format

    -   These files can be opened using spreadsheet software (e.g.,
        [LibreOffice Calc](https://www.libreoffice.org/discover/calc/),
        [Microsoft
        Excel](https://www.microsoft.com/en-us/microsoft-365/excel)),
        and using code-based tools such as
        [R](https://cran.r-project.org/) and
        [python](https://www.python.org/). (.csv files contain the data
        as plan text \[which can be seen by opening them in a text
        editor\], where data for different columns are separated by
        commas.)

-   In addition to .csv files, the folders of
    ***canopy\_streettree\_summaries.zip*** and ***equity\_data.zip***
    contain data in GIS formats as .gdb and .gpkg files

    -   These files can be opened using GIS software such as
        [QGIS](https://www.qgis.org) and
        [ArcGIS](https://www.esri.com/en-us/arcgis/about-arcgis/overview),
        or suitable libraries in R, Python, or other languages (e.g.,
        the [sf package for
        R](https://cran.r-project.org/web/packages/sf/index.html) and
        the [GeoPandas python library](https://geopandas.org/)).

        -   For ArcGIS you may need to create a connection to the folder
            where you have the data stored. The .gdb file is expected to
            work better in that software.

        -   In QGIS there are a variety of ways to open data. Dragging
            from your file manager (e.g., Windows Explorer) into the
            main QGIS window will start the import process.

            -   Some other options include using the "Data Source Manager" in
                QGIS or browse for the desired files and layers in the
                "Browser" pane. Either .gdb or .gpkg files should work
                fine with QGIS.

            -   Depending on the version of QGIS you are using, you may
                see a prompt about what "transformation" to use.
                Clicking "Okay" to use the default setting is suitable
                for these data and the region this applies to.

    -   Note -- the boundaries included for the spatial data (Borough
        Boundaries, Neighborhood Tabulation Areas, City Council
        Districts, and Community Districts) were originally downloaded
        from the [NYC Department of City Planning Open Data
        website](https://www1.nyc.gov/site/planning/data-maps/open-data.page)
        in the fall of 2020.

        -   These datasets are sometimes updated, and users may see
            (generally) very slight differences with newer versions of
            these data.

        -   Given the timing of the report, the data for Neighborhood
            Tabulation Areas reflect the 2010 version (boundaries are
            updated based on decennial census data). Updated
            Neighborhood Tabulation Area boundaries have been delineated
            based on 2020 census data and are available at
            <https://www1.nyc.gov/site/planning/data-maps/open-data/census-download-metadata.page>.
            Overlay of canopy data with these boundaries could be
            re-done in GIS. (See documentation for these types of
            overlays at
            <https://github.com/tnc-ny-science/NYC_StateOfUrbanForest_Docs#analysis-of-canopy-distribution-and-canopy-change-chapter-2>)

Canopy Change Data
------------------

Data on Tree Canopy Change from 2010 to 2017 are available from the NYC Open
Data Portal at
<https://data.cityofnewyork.us/Environment/Tree-Canopy-Change-2010-2017-/by9k-vhck>.
This is a spatial dataset stored as an Esri File Geodatabase (.gdb file), with
polygons representing whether tree canopy was gained during 2010-2017, lost, or
present in both years, across the entirety of New York City (including both
public and private property). In development of the data, vegetation had to be
at least 8' above the ground to be considered tree canopy. It was developed
based on remote sensing analysis with some manual refinement, and more
information about this and related datasets is available from a [StoryMap
available from the NYC Department of Technology and
Telecommunications](https://maps.nyc.gov/lidar/2017/) (in particular see the
"Derived Datasets" tab).

Some notes for users interested in these data:

-   Users should unzip the download the dataset and then it can be
    loaded into GIS software such as [QGIS](https://www.qgis.org) and
    [ArcGIS](https://www.esri.com/en-us/arcgis/about-arcgis/overview),
    or opened using suitable libraries in R, Python, and other
    code-based tools (e.g., using the [sf package for
    R](https://cran.r-project.org/web/packages/sf/index.html) and the
    [GeoPandas python library](https://geopandas.org/)).

-   The column "Class" has the values of whether canopy was gained,
    lost, or no change (with values of *Gain*, *Loss*, or *No Change*,
    respectively).

    -   The canopy as of 2010 can be seen as all polygons with Class
        values of *Loss* or *No Change.*

    -   The canopy as of 2017 can be seen as all polygons with Class
        values of *Gain* or *No Change.*

-   These data are derived from high-resolution land cover
    data from 2010 and 2017, although some additional processing was
    conducted for improved accuracy. The land cover data is available in a raster GIS data
    format, where each pixel of the data represents 6" x 6" on the
    ground. Both datasets have land cover classes of (1) tree
    canopy, (2) grass/shrub, (3) bare earth/soil, (4) water, (5)
    buildings, (6) roads, and (7) other paved surfaces. The 2017 data
    also have an 8th class, representing railroads.

    -   2010 raster data are available at
        <https://data.cityofnewyork.us/Environment/Landcover-Raster-Data-2010-6in-Resolution/sknu-4f6s>.

    -   2017 raster data are available at
        <https://data.cityofnewyork.us/Environment/Land-Cover-Raster-Data-2017-6in-Resolution/he6d-2qns>

Street Tree Census Data
-----------------------

Street trees are those planted in public rights of way along streets, sidewalks,
and medians of surface roads (generally excluding rights of way along highways).
These are under the jurisdiction of NYC Parks, and the agency has led decennial
censuses of them since 1995 (involving both staff and volunteers to collect
data). These censuses provide an incredible snapshot in time of this part of the
NYC urban forest, with information such as size, species, and location. Although
work on these trees is tracked on an ongoing basis, it is only through these
censuses that we can truly get a time-stamped snapshot, as all of these street
trees are documented within a short period of time (within two years). The
spatial accuracy and precision has been improved through time, thus the
individual trees cannot reliably be compared, point for point (e.g., 1995 and
2005 Street Tree Censuses have spatial points recorded based on the street
address trees were closest to, and points show up within the roadways, though
the 2015 Street Tree Census has very precise and accurate location information).
However, aggregated information by a broader area (e.g., Community District) can
generally be compared. Below is information on the actual data. Some general
conclusions and information about this portion of the urban forest is available
in *The State of the Urban Forest in New York City*, and those interesed should
also look through the
[NYC Parks website dedicated to results from the most recent street tree census](http://media.nycgovparks.org/images/web/TreesCount/Index.html).

Street tree census data is available, with some key details for usage,
as follows:

-   1995 Street Tree Census Data are available at:
    <https://data.cityofnewyork.us/Environment/1995-Street-Tree-Census/kyad-zm4j>

    -   Click on the link under "Attachments" for the full metadata
        file, and read the "Columns in this Dataset" section of the
        webpage.

    -   The data can be exported by clicking the "Export" button on the
        webpage and selecting the desired format. Users can select the
        desired format (CSV format is often a suitable option).

        -   Note -- this dataset is large, with over 500,000 rows! CSV
            files can generally be opened in spreadsheet software such
            as [LibreOffice
            Calc](https://www.libreoffice.org/discover/calc/) or
            [Microsoft
            Excel](https://www.microsoft.com/en-us/microsoft-365/excel)
            although users may hit limits in being able to open the
            files and users may need to explore other tools.

            -   For those inclined to use code-based data analysis
                tools, software such as R or Python can be a powerful
                option if hitting limits with spreadsheet software.

    -   For the 1995 Street Tree Census, data are not available on NYC
        Open Data in spatial data formats that can directly be read into
        GIS software, although CSV data files can be imported into GIS
        and used with coordinates, generally available in these data.

        -   X/Y coordinates are in the data in columns called "X" and
            "Y" which are based on the [New York State Plane Projection
            -- Long Island Zone, with North American Datum of 1983
            (EPSG 2263)](https://spatialreference.org/ref/epsg/nad83-new-york-long-island-ftus/)

        -   Latitude/Longitude coordinates in columns named
            respectively.

        -   Note -- some rows are missing spatial data, thus for
            aggregations of data by political, administrative, or other
            geographies, it is best to use the respective columns from the
            data file table.

-   The 2005 Street Tree Census Data are available at:
    <https://data.cityofnewyork.us/Environment/2005-Street-Tree-Census/29bw-z7pj>.
    The information for the 1995 data generally apply to the 2005
    dataset, although the data spatial in the .csv file are arranged in
    columns of "x\_sp," "y\_sp," "latitude," and "longitude."

    -   A spatial data file (for use in GIS software) for the 2005
        street tree census can be downloaded from:
        <https://data.cityofnewyork.us/Environment/2005-Street-Tree-Census/ye4j-rp7z>

        -   There is an "Export" button near the top of the screen and
            users will see options for downloading the data in different
            formats. "Original" downloads as a shapefile in this case.

        -   As with the 1995 street tree census data, not all rows of
            data have spatial data, thus for aggregations it by
            political, administrative, or other geographies, it is best
            practice to use the data from the table.

    -   Note -- the field "boroname" in this dataset has Staten Island
        represented as *5* rather than *Staten Island*. (In some data
        the City uses numbers in addition to or instead of a borough
        name, and 5 is the numeric identifier used for Staten Island).
        Depending on the use case of the data, users may opt to replace
        the values in that field appropriately.

-   The 2015 Street Tree Census Data are available at
    <https://data.cityofnewyork.us/Environment/2015-Street-Tree-Census-Tree-Data/pi5s-9p35>

    -   The data can be downloaded in spatial or non-spatial (e.g., .csv
        file) formats using the "Export" button towards the top of the
        data webpage.

    -   To find the full Metadata, users can click on the "About" button
        towards the top of the webpage, and click on the link under the
        "Attachments."

    -   The spatial data of the trees are very accurate and precise, and
        can be used to overlay other datasets such as different types of
        boundary datasets.

Equity-Related Data
-------------------

In analyzing data related to equity for *The State of the Urban Forest in New
York City* we primarily relied on the [Social Vulnerability
Index](https://www.atsdr.cdc.gov/placeandhealth/svi/index.html) for 2018 and
underlying data from the U.S. Census American Community Survey, distributed
together by the U.S. Centers for Disease Control and Prevention Agency for Toxic
Substances and Disease Registry, and the [Heat Vulnerability Index for New York
City](https://a816-dohbesp.nyc.gov/IndicatorPublic/HeatHub/hvi.html) (for 2018),
developed by the NYC Department of Health and Mental Hygiene. Information on
these data sources is below, and users can work with them in various ways to
ovarlay them with more explicit urban forestry data.

-   The Social Vulnerability Index data (and underlying data) are
    available for download at
    <https://www.atsdr.cdc.gov/placeandhealth/svi/data_documentation_download.html>.

    -   Users can download a spatial data file (shapefile) by Census
        Tract or County, either for the entire country or for entire
        states. They can then filter, from the downloaded data, for the
        desired counties (the county names for the five boroughs are:
        New York \[for Manhattan\], Bronx, Kings \[for Brooklyn\],
        Queens, and Richmond \[for Staten Island\]).

-   The Heat Vulnerability Index data for NYC can be downloaded for the
    scale of Neighborhood Tabulation Areas (the 2010 version) at
    <https://a816-dohbesp.nyc.gov/IndicatorPublic/VisualizationData.aspx?id=2411,719b87,107,Map,Score,2018>

    -   Near the top of that webpage, there is an "Export" button which
        will initiate the download of a .zip file.

        -   When unzipped, users will find .json and .csv files of the
            data.

            -   The .csv file will generally open in spreadsheet
                software. Note, the first 15 rows are metadata, and
                depending on the tool users are working with (e.g., in
                R), they may need to exclude those rows on importing the
                data for analysis, or create a copy of this file with
                all of the rows before the column names deleted.

            -   The .json file actually contains spatial data. To make
                it more immediately readable by GIS software, the
                extension can be changed to ".geojson" which is more
                generally recognized as a spatial data format by
                appropriate software.

        -   Note that with the spatial data, there will be areas with no
            information -- these are unpopulated areas that inherently
            do not have a Heat Vulnerability Index score.

    -   The Heat Vulnerability Index for Community Districts is also
        available for download, at
        <https://a816-dohbesp.nyc.gov/IndicatorPublic/VisualizationData.aspx?id=2191,719b87,107,Map,Score,2018>
