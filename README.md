# R-geom-pops
This repo contains demonstration R code for adding population data to an arbitrary geography. Say you have created a grid across your study area of a particular size that is meaningful to you. But you realize that the data you have should be normalized by population (that is, per-capita). So you need the population of each of your grids. You can find this by using publicly available population data in raster form. (At least down to a certain size.)

This code sample does this first with Census tracts, to test the method and show that it works. And then there is code for doing the same thing with a hex grid. Any geography could be used though.




## With ESRI tools:
You might want to do the same thing in ArcMap/ArcGIS rather than R. Without getting into details, here's the basic steps:
1. In Arcmap/arcgis, add your polygon geography layer. 
2. Add the worldpop raster population data layer.
3. Use "Zonal Statistics as Table" tool from toolbox. The only stat you need is Sum.
4. This creates a table, which you need to join back to your geography layer. 
5. Export your layer that now contains a population column to save it.



