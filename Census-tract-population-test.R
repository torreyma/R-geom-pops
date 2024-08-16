# Census-tract-population-test.R
# Last modified: 2024-08-16 14:11
## This R code uses a raster of population information to calculate populations of Census tract 
## -- check against Census tract populations as listed by the Census. NYC is used for example.
## NOTE: This code has already been run for NYC and the results saved in the git repo data/ folder. 
## You only need to modify and run this code if you want to run it for a region other than NYC.
## You may also want to modify and run the raster section of this code if you want to do a hexgrid/custom geography of a different region.
## As such, this code is really intended to be run line-by-line with modifications as necessary.


library(sf) # tools for dataframes with geometries
library(terra) # tools for geo raster

########## Census tracts geography
## In this section you download the Census tracts geography for New York State, and the code extracts just the Census tracts for NYC. 

## First, in your web broswer, download Census tracts geography files for your state from the Census. 
## We will use the 2020 Census tracts because that is the year our population raster data will be:
	# https://www.census.gov/cgi-bin/geo/shapefiles/index.php?year=2020&layergroup=Census+Tracts
	# Save the downloaded file somwhere that makes sense.

## Unzip the downloaded file:
unzip("~/Downloads/tl_2020_36_tract.zip", exdir = "~/Downloads")

# Load the shape file with the sf library. This file includes Census tracts for all of New York State:
NYS_ct.sf <- sf::st_read("~/Downloads/tl_2020_36_tract.shp", stringsAsFactors = F, quiet=T)

# This shapefile includes county ids, so we can use that to extract NYC.
# Subset just the NYC counties. You can look up the NYC countyfp ids here:
	# https://www2.census.gov/geo/docs/reference/codes2020/cou/st36_ny_cou2020.txt
# We need Kings 047, New York County 061, Queens 081, Bronx 005, and Richmond (SI) 085:
NYC_ct.sf <- NYS_ct.sf[NYS_ct.sf$"COUNTYFP" == "047" |
		       NYS_ct.sf$"COUNTYFP" == "061" |
		       NYS_ct.sf$"COUNTYFP" == "081" |
		       NYS_ct.sf$"COUNTYFP" == "005" |
		       NYS_ct.sf$"COUNTYFP" == "085", ]

# Let's also remove any tracts that are only water (that is, area of land = 0):
NYC_ct.sf <- NYC_ct.sf[NYC_ct.sf$"ALAND" != 0, ]


# Let's keep just the fields that might be useful to us:
NYC_ct.sf <- NYC_ct.sf[, c("COUNTYFP",
                           "TRACTCE",
                           "GEOID",
                           "NAMELSAD",
                           "geometry")]

# Write out the NYC counties shapefile:
st_write(NYC_ct.sf, "./data/NYC_ct.shp")
	# (./data/ assumes you ran this file from the github repo directory)
	# (Expect this to throw an error if the layer already exists)

# Clean up:
rm(NYS_ct.sf)
rm(NYC_ct.sf)


########## Census tracts population data
## In this section you download the Census population data, and the code attaches it to our NYC Census tracts.

## First, in your web browser, download Census population data for the year 2020 for Kings, Queens, Bronx, New York, and Richmond counties. 
## This will be table S0101 from the 2020 ACS 5-year estimates:
	# https://data.census.gov/table?g=050XX00US36005$1400000,36047$1400000,36061$1400000,36081$1400000,36085$1400000&y=2020

## Unzip the downloaded file:
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

# merge pop data and MOE to geometry data frame:
NYC_ct.sf <- merge(NYC_ct.sf, NYC_ct_pop, by.x = "GEOID", by.y = "GEOID2")

# Convert Cenus pop and MOE columnts to numeric:
NYC_ct.sf$CTPOP <- as.numeric(NYC_ct.sf$CTPOP)
NYC_ct.sf$CTPOPMOE <- as.numeric(NYC_ct.sf$CTPOPMOE)

## Write out the NYC counties shapefile, now with Census pop and MOE:
st_write(NYC_ct.sf, "./data/NYC_ct.shp")
	# (./data/ assumes you ran this file from the github repo directory)
	# (Expect this to throw an error if the layer already exists)


########## WorldPop raster population data
## In this section you download the raster population data from WorldPop. 
## That file is large (500mb), so the code here will crop it with the NYC geography and save that much-smaller just-NYC area of the raster. 
## NOTE: You need this raster file to run the hexgrid/custom geography analysis.

## First, in your web browser, download the 100m United States Constrained 2020 population raster data set:
	# https://hub.worldpop.org/geodata/summary?id=49727

# Load the full US pop raster data (geotiff):
US_rast_pop <- rast("~/Downloads/usa_ppp_2020_constrained.tif")

# Load our Census tract geometry data:
NYC_ct.sf <- sf::st_read("./data/NYC_ct.shp", stringsAsFactors = F, quiet=T)

# Crop the US pop raster with the NYC geography (using the terra package's crop):
NYC_rast_pop <- crop(US_rast_pop, NYC_ct.sf)

# Write NYC raster to the git repo data/ dir with terra's writeRaster:
writeRaster(NYC_rast_pop, "./data/NYC_ppp_2020_constrained.tif")


########## Calculate population for Census tracts from raster data
## This section is the main work everthing else in the code has been prep for.
## It uses the raster file we cropped above to calculat and add a population row to our Census tracts file.

# Load worldpop raster data:
NYC_rast_pop <- rast("./data/NYC_ppp_2020_constrained.tif")

# Load our Census tract geometry data:
NYC_ct.sf <- sf::st_read("./data/NYC_ct.shp", stringsAsFactors = F, quiet=T)

# Calculate the population using terra package's extract() function:
extracted_pop <- round(extract(NYC_rast_pop, NYC_ct.sf, fun='sum', na.rm = TRUE))

# add the pop column back to NYC_grid.sf:
# (This will warn that nyc_grid.sf is in a different CRS than the raster, but it works fine)
NYC_ct.sf$RASTRPOP <- extracted_pop$"usa_ppp_2020_constrained"

## Write out the NYC counties shapefile, now with raster pop:
st_write(NYC_ct.sf, "./data/NYC_ct.shp")
	# (./data/ assumes you ran this file from the github repo directory)
	# (Expect this to throw an error if the layer already exists)

########## Compare raster-based population to population from Census
## This section checks our work by comparing the raster-derived population with the Census 
## population to see if it is within the Census' margin of error.

# Load our Census tract geometry data:
NYC_ct.sf <- sf::st_read("./data/NYC_ct.shp", stringsAsFactors = F, quiet=T)

# Calculate boolean column showing if raster pop is within the MOE of the Census pop:
NYC_ct.sf$WITHINMOE <- ifelse((((NYC_ct.sf$CTPOP + NYC_ct.sf$CTPOPMOE) >= NYC_ct.sf$RASTRPOP)  & 
			       ((NYC_ct.sf$CTPOP - NYC_ct.sf$CTPOPMOE) <= NYC_ct.sf$RASTRPOP))
			      , TRUE, FALSE)

# Show the percentange rows that are TRUE for having a raster-calculated population within the MOE of the Census population:
round(sum(NYC_ct.sf$WITHINMOE) / (nrow(NYC_ct.sf)) * 100)


