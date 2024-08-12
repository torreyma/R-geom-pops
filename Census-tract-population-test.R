# Census-tract-population-test.R
# Last modified: 2024-08-12 17:44
# Use a raster of population information to calculate populations of Census tract -- check against Census tract populations as listed by the Census. NYC is used for example.


library(sf)

########## Census tracts geography
## This section downloads the Census tracts geography for New York State and extracts just the Census tracts for NYC. You can skip this section if you are working in NYC, since the extracted tracts are included in the data/ folder of the git repo. Uncomment if you need it though.

# First, in your web broswer, download Census tracts geography files for your state from the Census. We will use the 2020 Census tracts because that is the year our population raster data will be:
	# https://www.census.gov/cgi-bin/geo/shapefiles/index.php?year=2020&layergroup=Census+Tracts
	# Save the downloaded file somwhere that makes sense.

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


