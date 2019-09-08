---------------------------------------------------------------------------------------------------------------
--- Obtain current city id from master 'city' table and prepare the LAEA grid according to its boundaries
---------------------------------------------------------------------------------------------------------------
--- Insert in the 'city' table the basic information of the current city being processed
INSERT INTO city (name, code, countrycode, population, boundary, bbox)
        (SELECT c.name, c.code, c.countrycode, c.population, c.wkb_geometry, ST_Envelope(c.wkb_geometry) FROM tmp_city c WHERE c.code = :citycode);

--- Drop 'tmp_city' table and recreate it again with the current city id in 'tmp_city' table given by the master 'city' table,
--- as we will be using it several times in the script
DROP TABLE IF EXISTS tmp_city;
CREATE TEMPORARY TABLE tmp_city AS (SELECT * FROM city c WHERE c.code = :citycode);

--- Define a temporary variable "tmp_city_grid" with the LAEA grid cells that intersect with the current city boundary
---DROP TABLE IF EXISTS tmp_city_grid;
INSERT INTO tmp_city_grid (fid, geom)
        (SELECT g.fid, g.geom FROM tmp_city c, laea_etrs_500m g WHERE ST_Intersects(c.boundary, g.geom));
--- Organize, group and optimize tmp_ua by feature type code
CLUSTER tmp_city_grid USING tmp_city_grid_geohash_idx;
VACUUM ANALYZE tmp_city_grid;
---CREATE TEMPORARY TABLE tmp_city_grid AS (SELECT g.fid, g.geom FROM tmp_city c, laea_etrs_500m g WHERE ST_Intersects(c.boundary, g.geom));

----------------------------------------------------------------------------------------------------------------
--- Verification of Urban Atlas geometries validity
----------------------------------------------------------------------------------------------------------------
--- Make sure that Urban Atlas geometries are valid, delete those that cannot not be made valid in order to prevent possible problems afterwards
UPDATE tmp_ua SET geom=St_MakeValid(geom);
WITH geometries AS (DELETE FROM tmp_ua WHERE NOT ST_Isvalid(geom) IS TRUE RETURNING *) SELECT count(*) FROM geometries;

--- Organize, group and optimize tmp_ua by feature type code
CLUSTER tmp_ua USING tmp_ua_ftcode_idx;
VACUUM ANALYZE tmp_ua;


----------------------------------------------------------------------------------------------------------------
--- Processing of the Urban Atlas layers
---
--- Layers MUST be processed in the following order (as there are interdependencies among them)
--- 1. Water (X)
--- 2. Roads (X)
--- 3. Railways (X)
--- 4. Trees (X)
--- 5. Vegetation
--- 6. Agricultural Areas
--- 7. Built Up
--- 8. Built Open Spaces
--- 9. Dense Urban Fabric
--- 10. Medium Urban Fabric
--- 11. Low Urban Fabric
--- 12. Public, Military and Industrial
----------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------
--- Define a list of Urban Atlas feature codes (related to layers numbered 9-12) that will be used commonly in 
--- several operations of this script.
----------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ua_codes;
CREATE TEMPORARY TABLE ua_codes (value VARCHAR(5) NOT NULL);
INSERT INTO ua_codes(value) VALUES ('11100'),('11210'), ('11220'), ('11230'), ('11240'), ('11300'), ('12100');


-------------------------------------------------------
--- 1. Water Layer
-------------------------------------------------------
INSERT INTO tmp_ua_gridded_water (cityid, cellid, geom)
       (SELECT c.id,
               cg.fid,
               ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(ua.geom),0.0001)), cg.geom),3)) AS geom
               FROM tmp_city c, tmp_city_grid cg, tmp_ua ua WHERE ua.ftcode IN ('50000') AND ST_Intersects(ua.geom, cg.geom) GROUP BY cg.geom,cg.fid,c.id);

--- Organize, group and optimize tmp_ua by feature type code
CLUSTER tmp_ua_gridded_water USING tmp_ua_gridded_water_st_geohash_idx;
VACUUM ANALYZE tmp_ua_gridded_water;

-- update fua_tunnel attribute, if it applies (by default the value for water is 1)
UPDATE tmp_ua_gridded_water x SET fua_tunnel=get_parameter_value('fua_tunnel', 'dense_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11100', '11210') AND ST_Intersects(x.geom, ua.geom);
UPDATE tmp_ua_gridded_water x SET fua_tunnel=get_parameter_value('fua_tunnel', 'medium_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11220') AND ST_Intersects(x.geom, ua.geom);

-- update building_shadow attribute, if it applies (by default the value for water is 1)
UPDATE tmp_ua_gridded_water x SET building_shadow=0 FROM tmp_ua ua WHERE ua.ftcode IN (SELECT * FROM ua_codes) AND ST_Intersects(x.geom, ua.geom);

-- copy tmp_ua__water table information to water table
INSERT INTO ua_gridded_water (cityid, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, runoff_coefficient, fua_tunnel, building_shadow) 
        (SELECT c.id, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, runoff_coefficient, fua_tunnel, building_shadow
        FROM tmp_city c, tmp_ua_gridded_water);


-------------------------------------------------------
--- 2. Roads Layer
-------------------------------------------------------
INSERT INTO tmp_ua_gridded_roads (cityid, cellid, geom)
       (SELECT c.id,
               cg.fid,
               ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(ua.geom),0.0001)), cg.geom),3)) AS geom
               FROM tmp_city c, tmp_city_grid cg, tmp_ua ua WHERE ua.ftcode IN ('12210', '12220') AND ST_Intersects(ua.geom, cg.geom) GROUP BY cg.geom,cg.fid,c.id);

--- Organize, group and optimize tmp_ua by feature type code
CLUSTER tmp_ua_gridded_roads USING tmp_ua_gridded_roads_st_geohash_idx;
VACUUM ANALYZE tmp_ua_gridded_roads;

-- update fua_tunnel attribute, if it applies (by default the value for roads is 1)
UPDATE tmp_ua_gridded_roads x SET fua_tunnel=get_parameter_value('fua_tunnel', 'dense_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11100', '11210') AND ST_Intersects(x.geom, ua.geom);
UPDATE tmp_ua_gridded_roads x SET fua_tunnel=get_parameter_value('fua_tunnel', 'medium_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11220') AND ST_Intersects(x.geom, ua.geom );

-- update building_shadow attribute, if it applies (by default the value for roads is 1)
UPDATE tmp_ua_gridded_roads x SET building_shadow=0 FROM tmp_ua ua WHERE ua.ftcode IN (SELECT * FROM ua_codes) AND ST_Intersects(x.geom, ua.geom);

-- update hillshade_building attribute, if it applies (by default the value for roads is 1):
-- * intersection with public_military_industrial (CODE=12100)
-- * intersection with low_urban_fabric (CODE=11230,11240,11300)
-- * intersection with medium_urban_fabric (CODE=11220)
-- * intersection with dense_urban_fabric (CODE=11210,11100)
UPDATE tmp_ua_gridded_roads x SET hillshade_building=get_parameter_value('hillshade_building', 'public_military_industrial') FROM tmp_ua ua WHERE ua.ftcode IN ('12100') AND ST_Intersects(x.geom, ua.geom);
UPDATE tmp_ua_gridded_roads x SET hillshade_building=get_parameter_value('hillshade_building', 'medium_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11230', '11240', '11300') AND ST_Intersects(x.geom, ua.geom);
UPDATE tmp_ua_gridded_roads x SET hillshade_building=get_parameter_value('hillshade_building', 'low_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11220') AND ST_Intersects(x.geom, ua.geom);
UPDATE tmp_ua_gridded_roads x SET hillshade_building=get_parameter_value('hillshade_building', 'dense_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11100', '11210') AND ST_Intersects(x.geom, ua.geom);


-- copy tmp_roads table information to roads table
INSERT INTO ua_gridded_roads (cityid, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, runoff_coefficient, fua_tunnel, building_shadow, hillshade_building) 
        (SELECT c.id, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, runoff_coefficient, fua_tunnel, building_shadow, hillshade_building
        FROM tmp_city c, tmp_ua_gridded_roads);


-------------------------------------------------------
--- 3. Railways Layer
-------------------------------------------------------
INSERT INTO tmp_ua_gridded_railways (cityid, cellid, geom)
       (SELECT c.id,
               cg.fid,
               ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(ua.geom),0.0001)), cg.geom),3)) AS geom
               FROM tmp_city c, tmp_city_grid cg, tmp_ua ua WHERE ua.ftcode IN ('12230') AND ST_Intersects(ua.geom, cg.geom) GROUP BY cg.geom,cg.fid,c.id);

--- Organize, group and optimize tmp_ua by feature type code
CLUSTER tmp_ua_gridded_railways USING tmp_ua_gridded_railways_st_geohash_idx;
VACUUM ANALYZE tmp_ua_gridded_railways;

-- update fua_tunnel attribute, if it applies (by default the value for railways is 1)
UPDATE tmp_ua_gridded_railways x SET fua_tunnel=get_parameter_value('fua_tunnel', 'dense_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11100', '11210') AND ST_Intersects(x.geom, ua.geom);
UPDATE tmp_ua_gridded_railways x SET fua_tunnel=get_parameter_value('fua_tunnel', 'medium_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11220') AND ST_Intersects(x.geom, ua.geom);

-- update building_shadow attribute, if it applies (by default the value for railways is 1)
UPDATE tmp_ua_gridded_railways x SET building_shadow=0 FROM tmp_ua ua WHERE ua.ftcode IN (SELECT * FROM ua_codes) AND ST_Intersects(x.geom, ua.geom);


-- copy tmp_railways table information to railways table
INSERT INTO ua_gridded_railways (cityid, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, runoff_coefficient, fua_tunnel, building_shadow) 
        (SELECT c.id, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, runoff_coefficient, fua_tunnel, building_shadow
        FROM tmp_city c, tmp_ua_gridded_railways);


-------------------------------------------------------
--- 4. Trees Layer
-------------------------------------------------------
INSERT INTO tmp_ua_gridded_trees (cityid, cellid, geom)
       (SELECT c.id,
               cg.fid,
               ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(ua.geom),0.0001)), cg.geom),3)) AS geom
               FROM tmp_city c, tmp_city_grid cg, tmp_ua ua WHERE ua.ftcode IN ('31000') AND ST_Intersects(ua.geom, cg.geom) GROUP BY cg.geom,cg.fid,c.id);

--- Organize, group and optimize tmp_ua by feature type code
CLUSTER tmp_ua_gridded_trees USING tmp_ua_gridded_trees_st_geohash_idx;
VACUUM ANALYZE tmp_ua_gridded_trees;

--- remove intersections with previous layers: tmp_ua__water, tmp_roads, tmp_railways
UPDATE tmp_ua_gridded_trees x SET geom=subq.geom FROM (SELECT t.id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(w.geom,0.0001))),3) ) as geom FROM tmp_ua_gridded_trees t, tmp_ua_gridded_water w WHERE w.cellid=t.cellid) as subq WHERE x.id=subq.id;
UPDATE tmp_ua_gridded_trees x SET geom=subq.geom FROM (SELECT t.id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM tmp_ua_gridded_trees t, tmp_ua_gridded_roads r WHERE r.cellid=t.cellid) as subq WHERE x.id=subq.id;
UPDATE tmp_ua_gridded_trees x SET geom=subq.geom FROM (SELECT t.id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM tmp_ua_gridded_trees t, tmp_ua_gridded_railways r WHERE r.cellid=t.cellid) as subq WHERE x.id=subq.id;

--- fix possible broken geometries
UPDATE tmp_ua_gridded_trees SET geom=St_MakeValid(geom);


-- update fua_tunnel attribute, if it applies (by default the value for trees is 1)
UPDATE tmp_ua_gridded_trees x SET fua_tunnel=get_parameter_value('fua_tunnel', 'dense_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11100', '11210') AND ST_Intersects(x.geom, ua.geom);
UPDATE tmp_ua_gridded_trees x SET fua_tunnel=get_parameter_value('fua_tunnel', 'medium_urban_fabric') FROM tmp_ua ua WHERE ua.ftcode IN ('11220') AND ST_Intersects(x.geom, ua.geom);

-- update building_shadow attribute, if it applies (by default the value for trees is 1)
UPDATE tmp_ua_gridded_trees x SET building_shadow=0 FROM tmp_ua ua WHERE ua.ftcode IN (SELECT * FROM ua_codes) AND ST_Intersects(x.geom, ua.geom);

-- hillshade is already set to 0.37 by default for trees, therefore, do nothing!

-- copy tmp_trees table information to trees table
INSERT INTO ua_gridded_trees (cityid, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, runoff_coefficient, fua_tunnel, building_shadow, hillshade_green_fraction) 
        (SELECT c.id, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, runoff_coefficient, fua_tunnel, building_shadow, hillshade_green_fraction
        FROM tmp_city c, tmp_ua_gridded_trees);



---------------------------------------------------------------------------------
--- Final cleaning
---------------------------------------------------------------------------------