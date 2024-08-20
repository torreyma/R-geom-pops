# hex-grid-population-count.R
# Last modified: 2024-08-20 17:09
## This R code generates a hex grid vector object, and then uses raster population data to calculate the popualtion of each grid element.
## NYC is used for this example, but the code can be easily modified for any city.


library(sf) # tools for dataframes with geometries
library(terra) # tools for geo raster


##### Creating the hex grid

# Read NYC Census tract geography (generated in Census-tract-population-test.R file):
NYC_ct.sf <- sf::st_read(file.path("data", "NYC_ct.shp"), stringsAsFactors = F, quiet=T)
# Reproject into NAD83 NY/LI, Feet:
NYC_ct.sf <- st_transform(NYC_ct.sf, 2263)
# Combine all the Census tract features into one, since we just need the NYC shape to stamp out the hex grid later:
NYC_ct.sf <- st_combine(NYC_ct.sf)

# Set the size of the hexbin you want here (remember, the raster data is limited to 100m, so you want a grid of at least a few hundred meters):
  #hexbin_size <- 1320 # quarter mile, in feet
  hexbin_size <- 2640 # half mile, in feet

# Create hex grid the size of NYC
nyc_grid <- st_make_grid(NYC_ct.sf,
  hexbin_size,
  crs = st_crs(NYC_ct.sf),
  what = "polygons",
  square = FALSE) # false means make hexagons

# st_make_grid creates the grid across the rectangular bounding box. But I just just want the hexes that intersect with the nyc features:
nyc_grid <- nyc_grid[NYC_ct.sf]
# Convert sfc object to sf object; necessary for the st_join later, also create a base layer, which we may use later for empty hexes:
nyc_grid.sf <- st_as_sf(nyc_grid)
# trim off the edges of the hexes that fall outside the Bronx:
nyc_grid.sf <- st_intersection(nyc_grid.sf, NYC_ct.sf)
# rm grid object we're done with:
rm(nyc_grid)
# Add a column to act as an index:
nyc_grid.sf$poly.id <- 1:nrow(nyc_grid.sf)

# Load worldpop raster data:
NYCpop.rast <- rast(file.path("data", "NYC_ppp_2020_constrained.tif"))
# Get sum for pop of hex geos from raster (round for whole number):
# (This will warn that nyc_grid.sf is in a different projection, since it's in NYLI and poprast is in WGS84, but it works fine)
extracted_pop <- round(extract(NYCpop.rast, nyc_grid.sf, fun='sum', na.rm = TRUE))
# add the pop column back to NYC_grid.sf:
nyc_grid.sf$RASTR_POP <- extracted_pop$"usa_ppp_2020_constrained"

# Write out grid shapefile:
st_write(nyc_grid.sf, file.path("data", "NYC_grid.shp"))
	# (./data/ assumes you ran this file from the github repo directory)
	# (Expect this to throw an error if the layer already exists)



