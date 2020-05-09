IMPORTANT!
Database after creation has to be set as spatial database:
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

#1
setup_grid.sh
Load european LAEA 500m grid into database

#2
setup_heat_wave.sh
Generate final tables for land use procesed cities data

#3
setup_pluvial_flood.sh
Generate final tables for streams and basins procesed cities data
Also insert into database original tables for european basins and streams.

#4
city.sh
Analysis of Urban Atlas, European Settlement Maps and Street Tree Layer data sources currently in the system (also check cities with mortality data) and find
which cities are available for processing.
As well it generates table where all found cities are stored with its boundaries geometry and flags to know if a city has been processed for pluvial floods or heat waves.

#5
mortality.sh --> it needs city.sh to be run previously!
import mortality data for cities into clarity database from Heinrich csv file obtained from eurostat web site
