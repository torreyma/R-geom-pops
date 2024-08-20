# hex-grid-population-count.R
# Last modified: 2024-08-19 17:03
## This R code generates a hex grid vector object, and then uses raster population data to calculate the popualtion of each grid element.
## NYC is used for this example, but the code can be easily modified for any city.


library(sf) # tools for dataframes with geometries
library(terra) # tools for geo raster


##### Creating the hex grid

# Read NYC borough boundaries file:
nybb.sf <- sf::st_read("~/DOHMH-local/public-project-data/GMCgeos/nybb_gen/wholecityboundary.shp", stringsAsFactors = F, quiet=T)
# check projection:
#st_crs(nybb.sf) # Should be NAD83 NY/LI Feet

# Set the size of the hexbin you want here (remember, the raster data is limited to 100m, so you want a grid of at least a few hundred meters):
  #hexbin_size <- 1320 # quarter mile, in feet
  hexbin_size <- 2640 # half mile, in feet

# Create hex grid the size of NYC
nyc_grid <- st_make_grid(nybb.sf,
  hexbin_size,
  crs = st_crs(nybb.sf),
  what = "polygons",
  square = FALSE) # false means make hexagons

# st_make_grid creates the grid across the rectangular bounding box. But I just just want the hexes that intersect with the nyc features:
nyc_grid <- nyc_grid[nybb.sf]
# Convert sfc object to sf object; necessary for the st_join later, also create a base layer, which we may use later for empty hexes:
nyc_grid_base.sf <- nyc_grid.sf <- st_as_sf(nyc_grid)
# trim off the edges of the hexes that fall outside the Bronx:
nyc_grid_base.sf <- nyc_grid.sf <- st_intersection(nyc_grid.sf, nybb.sf)
# rm grid object we're done with:
rm(nyc_grid)
# Add a column to act as an index:
nyc_grid.sf$poly.id <- 1:nrow(nyc_grid.sf)

# Load worldpop raster data:
poprast <- rast("~/DOHMH-local/public-project-data/NYC-extracted_ppp_2020_constrained.tif")
# Get sum for pop of hex geos from raster (round for whole number):
# (This will warn that nyc_grid.sf is in a different projection, since it's in NYLI and poprast is in WGS84, but it works fine)
extracted_pop <- round(extract(poprast, nyc_grid.sf, fun='sum', na.rm = TRUE))
# add the pop column back to NYC_grid.sf:
nyc_grid.sf$RASTR_POP <- extracted_pop$"NYC-extracted_ppp_2020_constrained"
# Done with this:
rm(extracted_pop)




