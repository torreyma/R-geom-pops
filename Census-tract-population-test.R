# Census-tract-population-test.R
# Last modified: 2024-08-13 18:28
# Use a raster of population information to calculate populations of Census tract -- check against Census tract populations as listed by the Census. NYC is used for example.


library(sf) # tools for dataframes with geometries

########## Census tracts geography
## In this section you download the Census tracts geography for New York State, and the code extracts just the Census tracts for NYC. You can skip this section if you are working in NYC, since the extracted tracts are included in the data/ folder of the git repo. Uncomment if you need it for your region/state/city though.

## First, in your web broswer, download Census tracts geography files for your state from the Census. We will use the 2020 Census tracts because that is the year our population raster data will be:
	# https://www.census.gov/cgi-bin/geo/shapefiles/index.php?year=2020&layergroup=Census+Tracts
	# Save the downloaded file somwhere that makes sense.

## Uncomment first row from here down if you need this section:
## Unzip the downloaded file:
#unzip("~/Downloads/tl_2020_36_tract.zip", exdir = "~/Downloads")
#	
## Load the shape file with the sf library. This file includes Census tracts for all of New York State:
#NYS_ct.sf <- sf::st_read("~/Downloads/tl_2020_36_tract.shp", stringsAsFactors = F, quiet=T)
#
## This shapefile includes county ids, so we can use that to extract NYC.
## Subset just the NYC counties. You can look up the NYC countyfp ids here:
#	# https://www2.census.gov/geo/docs/reference/codes2020/cou/st36_ny_cou2020.txt
## We need Kings 047, New York County 061, Queens 081, Bronx 005, and Richmond (SI) 085:
#NYC_ct.sf <- NYS_ct.sf[NYS_ct.sf$"COUNTYFP" == "047" |
#		       NYS_ct.sf$"COUNTYFP" == "061" |
#		       NYS_ct.sf$"COUNTYFP" == "081" |
#		       NYS_ct.sf$"COUNTYFP" == "005" |
#		       NYS_ct.sf$"COUNTYFP" == "085", ]
#
## Let's also remove any tracts that are only water (that is, area of land = 0):
#NYC_ct.sf <- NYC_ct.sf[NYC_ct.sf$"ALAND" != 0, ] 
#
#
## Let's keep just the fields that might be useful to us:
#NYC_ct.sf <- NYC_ct.sf[, c("COUNTYFP", 
#                           "TRACTCE", 
#                           "GEOID", 
#                           "NAMELSAD", 
#                           "geometry")]
#
## Write out the NYC counties shapefile:
#st_write(NYC_ct.sf, "./data/NYC_ct.shp")
#	# (./data/ assumes you ran this file from the github repo directory)
#	# (Expect this to throw an error if the layer already exists)
#
## Clean up:
#rm(NYS_ct.sf)
#rm(NYC_ct.sf)


########## Census tracts population data
## In this section you download the Census population data, and the code attaches it to our NYC Census tracts.

## First, in your web browser, download Census population data for the year 2020 for Kings, Queens, Bronx, New York, and Richmond counties. This will be table S0101 from the 2020 ACS 5-year estimates:
	# https://data.census.gov/table?g=050XX00US36005$1400000,36047$1400000,36061$1400000,36081$1400000,36085$1400000&y=2020

## Uncomment first row from here down if you need this section:
# Unzip the downloaded file:
unzip("~/Downloads/ACSST5Y2020.S0101_2024-08-13T155613.zip", exdir = "~/Downloads")
# Read in the population data csv:
NYC_ct_pop <- read.csv("~/Downloads/ACSST5Y2020.S0101-Data.csv")

# We only need the total population column and it's MOE, so let's drop everything else:
NYC_ct_pop <- NYC_ct_pop[, c("GEO_ID", 
                           "NAME", 
                           "S0101_C01_001E", 
                           "S0101_C01_001M")]

# Let's rename the columns:
colnames(NYC_ct_pop) <- c("GEOID","NAME","CTPOP","CTPOPMOE")

# Let's also get rid of the row with detailed column names, since we won't use those:
message("Dropping this row with detailed column names: ", NYC_ct_pop[1, ])
NYC_ct_pop <- NYC_ct_pop[-1, ]

# Split the GEOID on the "US" into two separate columns:
NYC_ct_pop <- cbind(NYC_ct_pop, strcapture("(.*)US(.*)", as.character(NYC_ct_pop$GEOID), data.frame(GEOID1 = "", GEOID2 = "")))
# Remove GEOID columns we won't use anymore:
NYC_ct_pop <- subset(NYC_ct_pop, select = -c(GEOID, GEOID1))

# Load our Census tract geometry data:
NYC_ct.sf <- sf::st_read("./data/NYC_ct.shp", stringsAsFactors = F, quiet=T)



