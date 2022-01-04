## The below code was used for the analyses presented in Chapter 4 of The State
## of the Urban Forest in New York City. This workflow imports datasets from a
## PostGIS database into R and then entails preprocessing and analysis.
## 
## Running this code as-is would require  either setting up a comparable 
## database with the appropriate data, or working with the raw datasets and adjusting 
## code as appropriate. However, some of the code included here illustrates key parts 
## of workflows, such as aggregating data from the Social Vulnerability Index dataset
## to the scale of Neighborhood Tabulation Areas, which can support similar analyses.
## 
## Users can also download the summarized data on canopy and relative change in
## canopy, street tree stocking rates, Social Vulnerability, and Heat Vulnerability
## Index, as used in the correlation analyses from the Zenodo repository where
## supplemental data are available: https://zenodo.org/record/5210261.
## In that case, see line 99.
##
## Code for correlation analyses between urban forest and socioeconomic
## variables goes run through line 227; for code related to analysis of canopy
## around Schools & Hospitals compared to broader NTAs, see from line 229 onward.
##
## Code developed by Mike Treglia, The Nature Conservancy (michael.treglia@tnc.org)

# Load Packages
library(sf)
library(dplyr)
library(Hmisc)
library(RPostgres)

### Load RPostgres package and connect to database. Note - users may need to
### adjust or add information for the connection based on their system and settings
### (e.g., users may adjust the database name and user name, add password
### information [which should not be stored within code as good practice], and the
### port)
con <- dbConnect(RPostgres::Postgres(), user='postgres', host='localhost', dbname="nyc_urbanforest")

######### Begin code related to correlations of urban forest and socioeconomic variables #########

# Load Social Vulnerability Data
# Note - for details on loading these data into the PostGIS Database, or into R more generally
# see the section of "dataloadingexamples.R" starting at line 315. 
# Note - NTA Code (and name) are integrated into the social vulnerability data loaded, as it was joined 
# to the NYC Census Tracts, which has NTA information, before the data were added to the database.
sovi2018 <- st_read(con, Id(schema="socioeconomic_health", table="sovi2018_censustract2010"))
st_geometry(sovi2018) <- NULL # Drop the geometry column

# Select only necessary/desired columns
sovi2018 <- select(sovi2018, boroname, borocode, boroct2010, fips, 
                   ntaname, ntacode, e_totpop, e_pci, ep_pov, ep_age65,ep_age17,
                   ep_limeng, ep_minrty, ep_crowd, ep_noveh, spl_theme1, spl_theme2, spl_theme3, spl_theme4, spl_themes)


# For the Social Vulnerability variables, aggregate the data from census tracts to neighborhood
# tabulation areas by averaging, weighted by the population estimate.
nta_sovi2018 <- group_by(sovi2018, ntacode, boroname) %>% 
  summarise(
            pci_wtdavg = weighted.mean(e_pci, e_totpop, na.rm = TRUE),
            povrate_wtdavg = weighted.mean(ep_pov, e_totpop, na.rm = TRUE),
            gte65rate_wtdavg = weighted.mean(ep_age65, e_totpop, na.rm = TRUE),
            lte17rate_wtdavg = weighted.mean(ep_age17, e_totpop, na.rm = TRUE),
            limengrate_wtdavg = weighted.mean(ep_limeng, e_totpop, na.rm = TRUE),
            minorityrate_wtdavg = weighted.mean(ep_minrty, e_totpop, na.rm = TRUE),
            crowding_wtdavg = weighted.mean(ep_crowd, e_totpop, na.rm = TRUE),
            noveh_wtdavg = weighted.mean(ep_noveh, e_totpop, na.rm = TRUE),
            spl_theme1_wtdavg = weighted.mean(spl_theme1, e_totpop, na.rm = TRUE),
            spl_theme2_wtdavg = weighted.mean(spl_theme2, e_totpop, na.rm = TRUE),
            spl_theme3_wtdavg = weighted.mean(spl_theme3, e_totpop, na.rm = TRUE),
            spl_theme4_wtdavg = weighted.mean(spl_theme4, e_totpop, na.rm = TRUE),
            spl_themes_wtdavg = weighted.mean(spl_themes, e_totpop, na.rm=TRUE)) %>% as.data.frame()

# Load data on canopy cover and canopy change by NTA (NTAs for this analysis were buffered by 1/4 mile, clipped to borough boundary land area)
# For example of doing that analysis in SQL given canopy change data and administrative boundaries
# see Example 2 in ./SQL/CanopyCoverOverlay.sql.
nta.canopy <- st_read(con, Id(schema="results_utc_landcover", table="canopyvector_nycnta_qtr_mi_buff"))

# join the canpy data with the Social Vulnerability data based on common nta code
nta_canopy_sovi <- merge(nta.canopy, nta_sovi2018, by="ntacode")

# Create non-spatial version to reduce size and complexity.
nta_canopy_sovi.ns <- nta_canopy_sovi
st_geometry(nta_canopy_sovi.ns) <- NULL

# Load Heat Vulnerability Index. Can be exported from a NYC Department of Health
# and Mental Hygiene website at
# https://a816-dohbesp.nyc.gov/IndicatorPublic/VisualizationData.aspx?id=2411,719b87,107,Map,Score,2018
hvi_nta <- st_read(con, Id(schema="socioeconomic_health", table="hvi_rank_nta_2018"))
st_geometry(hvi_nta) <- NULL

# Load in data on Street Trees (for Street Tree Stocking Rate)
# Note - the queries used to calculate the street tree stocking rate are
# in ./SQL/StreetTrees_Queries.sql
stockingrate_nta <- st_read(con, Id(schema="results_streetrees", table="treecensus_summaries_nta_final"))

# Select the appropriate variables to keep
stockingrate_nta <- select(stockingrate_nta, ntacode, stockingrate=stockingrate_2015_living)
st_geometry(stockingrate_nta) <- NULL

# Join the multiple datasets together
nta_canopy_sovi_streettrees <- merge(nta_canopy_sovi.ns, hvi_nta, by="ntacode") %>%  merge(stockingrate_nta, by="ntacode") %>% select(ntacode, boroname, unit_ft2, canopy_2017_pct, canopy_17min10_pct, canopy_17min10_div10, pci_wtdavg, povrate_wtdavg, gte65rate_wtdavg, lte17rate_wtdavg, limengrate_wtdavg, minorityrate_wtdavg, crowding_wtdavg, noveh_wtdavg, hvi_rank, spl_theme1_wtdavg, spl_theme2_wtdavg, spl_theme3_wtdavg, spl_theme4_wtdavg, spl_themes_wtdavg, stockingrate)

# Remove unpopulated areas - some have census data very strangely (w/ very small populations) like Central Park
nta_canopy_sovi_streettrees <- nta_canopy_sovi_streettrees[which(nta_canopy_sovi_streettrees$ntacode %nin% c("SI99", "QN99", "QN98", "MN99", "BX99", "BX98",  "BK99")),]

############
#NOTE: Users can also load the equity data available on Zenodo and start here
# After importing that dataset the variable in that dataset called 'relativecanopychange_percent' 
# should be renamed to canopy_17min10_div10. Sample R code for that: 
#     names(nta_canopy_sovi)[names(nta_canopy_sovi)=="relativecanopychange_percent"] <- "canopy_17min10_div10"

# Correlations between canopy % in 2017 and socioeconomic data at the scale of NTAs by borough
nta_canopy_sovi_streettrees %>% 
  filter(!is.na(spl_themes_wtdavg)) %>%
  group_by(boroname) %>%
  summarise(cor_canopy_pci=cor(canopy_2017_pct,pci_wtdavg, use="complete.obs", method = "kendall"), pval1=cor.test(canopy_2017_pct,pci_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_povrate=cor(canopy_2017_pct,povrate_wtdavg, use="complete.obs", method = "kendall"), pval2=cor.test(canopy_2017_pct,povrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_gte65=cor(canopy_2017_pct,gte65rate_wtdavg, use="complete.obs", method = "kendall"), pval3=cor.test(canopy_2017_pct,gte65rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_lte17=cor(canopy_2017_pct,lte17rate_wtdavg, use="complete.obs", method = "kendall"), pval_lte17=cor.test(canopy_2017_pct,lte17rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_limeng=cor(canopy_2017_pct,limengrate_wtdavg, use="complete.obs", method = "kendall"), pval4=cor.test(canopy_2017_pct,limengrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_minorityrate=cor(canopy_2017_pct,minorityrate_wtdavg, use="complete.obs", method = "kendall"), pval5=cor.test(canopy_2017_pct,minorityrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_crowding=cor(canopy_2017_pct,crowding_wtdavg, use="complete.obs", method = "kendall"), pval6=cor.test(canopy_2017_pct,crowding_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_noveh=cor(canopy_2017_pct,noveh_wtdavg, use="complete.obs", method = "kendall"), pval7=cor.test(canopy_2017_pct,noveh_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_hvirank=cor(canopy_2017_pct,hvi_rank, use="complete.obs", method = "kendall"), pval8=cor.test(canopy_2017_pct,hvi_rank, use="complete.obs", method="kendall")$p.value,
            cor_canopy_spltheme1=cor(canopy_2017_pct,spl_theme1_wtdavg, use="complete.obs", method = "kendall"), pval9=cor.test(canopy_2017_pct,spl_theme1_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_spltheme2=cor(canopy_2017_pct,spl_theme2_wtdavg, use="complete.obs", method = "kendall"), pval10=cor.test(canopy_2017_pct,spl_theme2_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_spltheme3=cor(canopy_2017_pct,spl_theme3_wtdavg, use="complete.obs", method = "kendall"), pval11=cor.test(canopy_2017_pct,spl_theme3_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_spltheme4=cor(canopy_2017_pct,spl_theme4_wtdavg, use="complete.obs", method = "kendall"), pval12=cor.test(canopy_2017_pct,spl_theme4_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_splthemes=cor(canopy_2017_pct,spl_themes_wtdavg, use="complete.obs", method = "kendall"), pval13=cor.test(canopy_2017_pct,spl_themes_wtdavg, use="complete.obs", method="kendall")$p.value,
  )


# Correlations between relative canopy change and socioeconomic data at the scale of NTAs by borough
nta_canopy_sovi_streettrees %>% 
  filter(!is.na(spl_themes_wtdavg)) %>%
  group_by(boroname) %>%
  summarise(cor_relcanchange_pci=cor(canopy_17min10_div10,pci_wtdavg, use="complete.obs", method = "kendall"), pval1=cor.test(canopy_17min10_div10,pci_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_povrate=cor(canopy_17min10_div10,povrate_wtdavg, use="complete.obs", method = "kendall"), pval2=cor.test(canopy_17min10_div10,povrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_gte65=cor(canopy_17min10_div10,gte65rate_wtdavg, use="complete.obs", method = "kendall"), pval3=cor.test(canopy_17min10_div10,gte65rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relchange_lte17=cor(canopy_17min10_div10,lte17rate_wtdavg, use="complete.obs", method = "kendall"), pval_lte17=cor.test(canopy_17min10_div10,lte17rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_limeng=cor(canopy_17min10_div10,limengrate_wtdavg, use="complete.obs", method = "kendall"), pval4=cor.test(canopy_17min10_div10,limengrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_minorityrate=cor(canopy_17min10_div10,minorityrate_wtdavg, use="complete.obs", method = "kendall"), pval5=cor.test(canopy_17min10_div10,minorityrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_crowding=cor(canopy_17min10_div10,crowding_wtdavg, use="complete.obs", method = "kendall"), pval6=cor.test(canopy_17min10_div10,crowding_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_noveh=cor(canopy_17min10_div10,noveh_wtdavg, use="complete.obs", method = "kendall"), pval7=cor.test(canopy_17min10_div10,noveh_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_hvirank=cor(canopy_17min10_div10,hvi_rank, use="complete.obs", method = "kendall"), pval8=cor.test(canopy_17min10_div10,hvi_rank, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_spltheme1=cor(canopy_17min10_div10,spl_theme1_wtdavg, use="complete.obs", method = "kendall"), pval9=cor.test(canopy_17min10_div10,spl_theme1_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_spltheme2=cor(canopy_17min10_div10,spl_theme2_wtdavg, use="complete.obs", method = "kendall"), pval10=cor.test(canopy_17min10_div10,spl_theme2_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_spltheme3=cor(canopy_17min10_div10,spl_theme3_wtdavg, use="complete.obs", method = "kendall"), pval11=cor.test(canopy_17min10_div10,spl_theme3_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_spltheme4=cor(canopy_17min10_div10,spl_theme4_wtdavg, use="complete.obs", method = "kendall"), pval12=cor.test(canopy_17min10_div10,spl_theme4_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_splthemes=cor(canopy_17min10_div10,spl_themes_wtdavg, use="complete.obs", method = "kendall"), pval13=cor.test(canopy_17min10_div10,spl_themes_wtdavg, use="complete.obs", method="kendall")$p.value
  )


# Correlations between street tree stocking rate and socioeconomic data at the scale of NTAs by borough
nta_canopy_sovi_streettrees %>% 
  filter(!is.na(spl_themes_wtdavg)) %>%
  group_by(boroname) %>%
  summarise(cor_stkngrate_pci=cor(stockingrate,pci_wtdavg, use="complete.obs", method = "kendall"), pval1=cor.test(stockingrate,pci_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_povrate=cor(stockingrate,povrate_wtdavg, use="complete.obs", method = "kendall"), pval2=cor.test(stockingrate,povrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_gte65=cor(stockingrate,gte65rate_wtdavg, use="complete.obs", method = "kendall"), pval3=cor.test(stockingrate,gte65rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_lte17=cor(stockingrate,lte17rate_wtdavg, use="complete.obs", method = "kendall"), pval_lte17=cor.test(stockingrate,lte17rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_limeng=cor(stockingrate,limengrate_wtdavg, use="complete.obs", method = "kendall"), pval4=cor.test(stockingrate,limengrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_minorityrate=cor(stockingrate,minorityrate_wtdavg, use="complete.obs", method = "kendall"), pval5=cor.test(stockingrate,minorityrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_crowding=cor(stockingrate,crowding_wtdavg, use="complete.obs", method = "kendall"), pval6=cor.test(stockingrate,crowding_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_noveh=cor(stockingrate,noveh_wtdavg, use="complete.obs", method = "kendall"), pval7=cor.test(stockingrate,noveh_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_hvirank=cor(stockingrate,hvi_rank, use="complete.obs", method = "kendall"), pval8=cor.test(stockingrate,hvi_rank, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_spltheme1=cor(stockingrate,spl_theme1_wtdavg, use="complete.obs", method = "kendall"), pval9=cor.test(stockingrate,spl_theme1_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_spltheme2=cor(stockingrate,spl_theme2_wtdavg, use="complete.obs", method = "kendall"), pval10=cor.test(stockingrate,spl_theme2_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_spltheme3=cor(stockingrate,spl_theme3_wtdavg, use="complete.obs", method = "kendall"), pval11=cor.test(stockingrate,spl_theme3_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_spltheme4=cor(stockingrate,spl_theme4_wtdavg, use="complete.obs", method = "kendall"), pval12=cor.test(stockingrate,spl_theme4_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_splthemes=cor(stockingrate,spl_themes_wtdavg, use="complete.obs", method = "kendall"), pval13=cor.test(stockingrate,spl_themes_wtdavg, use="complete.obs", method="kendall")$p.value
  )


# Correlations between canopy % in 2017 and socioeconomic data at the scale of NTAs, citywide
nta_canopy_sovi_streettrees %>% 
  filter(!is.na(spl_themes_wtdavg)) %>%
  summarise(cor_canopy_pci=cor(canopy_2017_pct,pci_wtdavg, use="complete.obs", method = "kendall"), pval1=cor.test(canopy_2017_pct,pci_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_povrate=cor(canopy_2017_pct,povrate_wtdavg, use="complete.obs", method = "kendall"), pval2=cor.test(canopy_2017_pct,povrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_gte65=cor(canopy_2017_pct,gte65rate_wtdavg, use="complete.obs", method = "kendall"), pval3=cor.test(canopy_2017_pct,gte65rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_lte17=cor(canopy_2017_pct,lte17rate_wtdavg, use="complete.obs", method = "kendall"), pval_lte17=cor.test(canopy_2017_pct,lte17rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_limeng=cor(canopy_2017_pct,limengrate_wtdavg, use="complete.obs", method = "kendall"), pval4=cor.test(canopy_2017_pct,limengrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_minorityrate=cor(canopy_2017_pct,minorityrate_wtdavg, use="complete.obs", method = "kendall"), pval5=cor.test(canopy_2017_pct,minorityrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_crowding=cor(canopy_2017_pct,crowding_wtdavg, use="complete.obs", method = "kendall"), pval6=cor.test(canopy_2017_pct,crowding_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_noveh=cor(canopy_2017_pct,noveh_wtdavg, use="complete.obs", method = "kendall"), pval7=cor.test(canopy_2017_pct,noveh_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_hvirank=cor(canopy_2017_pct,hvi_rank, use="complete.obs", method = "kendall"), pval8=cor.test(canopy_2017_pct,hvi_rank, use="complete.obs", method="kendall")$p.value,
            cor_canopy_spltheme1=cor(canopy_2017_pct,spl_theme1_wtdavg, use="complete.obs", method = "kendall"), pval9=cor.test(canopy_2017_pct,spl_theme1_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_spltheme2=cor(canopy_2017_pct,spl_theme2_wtdavg, use="complete.obs", method = "kendall"), pval10=cor.test(canopy_2017_pct,spl_theme2_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_spltheme3=cor(canopy_2017_pct,spl_theme3_wtdavg, use="complete.obs", method = "kendall"), pval11=cor.test(canopy_2017_pct,spl_theme3_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_spltheme4=cor(canopy_2017_pct,spl_theme4_wtdavg, use="complete.obs", method = "kendall"), pval12=cor.test(canopy_2017_pct,spl_theme4_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_canopy_splthemes=cor(canopy_2017_pct,spl_themes_wtdavg, use="complete.obs", method = "kendall"), pval13=cor.test(canopy_2017_pct,spl_themes_wtdavg, use="complete.obs", method="kendall")$p.value,
  )


# Correlations between relative canopy change and socioeconomic data at the scale of NTAs, citywide
nta_canopy_sovi_streettrees %>% 
  filter(!is.na(spl_themes_wtdavg)) %>%
  summarise(cor_relcanchange_pci=cor(canopy_17min10_div10,pci_wtdavg, use="complete.obs", method = "kendall"), pval1=cor.test(canopy_17min10_div10,pci_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_povrate=cor(canopy_17min10_div10,povrate_wtdavg, use="complete.obs", method = "kendall"), pval2=cor.test(canopy_17min10_div10,povrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_gte65=cor(canopy_17min10_div10,gte65rate_wtdavg, use="complete.obs", method = "kendall"), pval3=cor.test(canopy_17min10_div10,gte65rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relchange_lte17=cor(canopy_17min10_div10,lte17rate_wtdavg, use="complete.obs", method = "kendall"), pval_lte17=cor.test(canopy_17min10_div10,lte17rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_limeng=cor(canopy_17min10_div10,limengrate_wtdavg, use="complete.obs", method = "kendall"), pval4=cor.test(canopy_17min10_div10,limengrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_minorityrate=cor(canopy_17min10_div10,minorityrate_wtdavg, use="complete.obs", method = "kendall"), pval5=cor.test(canopy_17min10_div10,minorityrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_crowding=cor(canopy_17min10_div10,crowding_wtdavg, use="complete.obs", method = "kendall"), pval6=cor.test(canopy_17min10_div10,crowding_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_noveh=cor(canopy_17min10_div10,noveh_wtdavg, use="complete.obs", method = "kendall"), pval7=cor.test(canopy_17min10_div10,noveh_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_hvirank=cor(canopy_17min10_div10,hvi_rank, use="complete.obs", method = "kendall"), pval8=cor.test(canopy_17min10_div10,hvi_rank, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_spltheme1=cor(canopy_17min10_div10,spl_theme1_wtdavg, use="complete.obs", method = "kendall"), pval9=cor.test(canopy_17min10_div10,spl_theme1_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_spltheme2=cor(canopy_17min10_div10,spl_theme2_wtdavg, use="complete.obs", method = "kendall"), pval10=cor.test(canopy_17min10_div10,spl_theme2_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_spltheme3=cor(canopy_17min10_div10,spl_theme3_wtdavg, use="complete.obs", method = "kendall"), pval11=cor.test(canopy_17min10_div10,spl_theme3_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_spltheme4=cor(canopy_17min10_div10,spl_theme4_wtdavg, use="complete.obs", method = "kendall"), pval12=cor.test(canopy_17min10_div10,spl_theme4_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_relcanchange_splthemes=cor(canopy_17min10_div10,spl_themes_wtdavg, use="complete.obs", method = "kendall"), pval13=cor.test(canopy_17min10_div10,spl_themes_wtdavg, use="complete.obs", method="kendall")$p.value
  )


# Correlations between street tree stocking rate and socioeconomic data at the scale of NTAs, citywide
nta_canopy_sovi_streettrees %>% 
  filter(!is.na(spl_themes_wtdavg)) %>%
  summarise(cor_stkngrate_pci=cor(stockingrate,pci_wtdavg, use="complete.obs", method = "kendall"), pval1=cor.test(stockingrate,pci_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_povrate=cor(stockingrate,povrate_wtdavg, use="complete.obs", method = "kendall"), pval2=cor.test(stockingrate,povrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_gte65=cor(stockingrate,gte65rate_wtdavg, use="complete.obs", method = "kendall"), pval3=cor.test(stockingrate,gte65rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_lte17=cor(stockingrate,lte17rate_wtdavg, use="complete.obs", method = "kendall"), pval_lte17=cor.test(stockingrate,lte17rate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_limeng=cor(stockingrate,limengrate_wtdavg, use="complete.obs", method = "kendall"), pval4=cor.test(stockingrate,limengrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_minorityrate=cor(stockingrate,minorityrate_wtdavg, use="complete.obs", method = "kendall"), pval5=cor.test(stockingrate,minorityrate_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_crowding=cor(stockingrate,crowding_wtdavg, use="complete.obs", method = "kendall"), pval6=cor.test(stockingrate,crowding_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_noveh=cor(stockingrate,noveh_wtdavg, use="complete.obs", method = "kendall"), pval7=cor.test(stockingrate,noveh_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_hvirank=cor(stockingrate,hvi_rank, use="complete.obs", method = "kendall"), pval8=cor.test(stockingrate,hvi_rank, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_spltheme1=cor(stockingrate,spl_theme1_wtdavg, use="complete.obs", method = "kendall"), pval9=cor.test(stockingrate,spl_theme1_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_spltheme2=cor(stockingrate,spl_theme2_wtdavg, use="complete.obs", method = "kendall"), pval10=cor.test(stockingrate,spl_theme2_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_spltheme3=cor(stockingrate,spl_theme3_wtdavg, use="complete.obs", method = "kendall"), pval11=cor.test(stockingrate,spl_theme3_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_spltheme4=cor(stockingrate,spl_theme4_wtdavg, use="complete.obs", method = "kendall"), pval12=cor.test(stockingrate,spl_theme4_wtdavg, use="complete.obs", method="kendall")$p.value,
            cor_stkngrate_splthemes=cor(stockingrate,spl_themes_wtdavg, use="complete.obs", method = "kendall"), pval13=cor.test(stockingrate,spl_themes_wtdavg, use="complete.obs", method="kendall")$p.value
  )

###### End Code for Correlations between Urban Forest and Socioeconomic Data #######

###### Begin code for analysis of canopy around schools & hospitals #######