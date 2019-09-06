--- Make sure that Urban Atlas geometries are valid, delete those that cannot not be made valid in order to prevent possible problems afterwards
UPDATE __urban_atlas SET geom=St_MakeValid(geom);
WITH invalid_geometries AS (DELETE FROM __urban_atlas WHERE NOT ST_Isvalid(geom) IS TRUE RETURNING *) SELECT count(*) FROM invalid_geometries;

--- Insert in the 'city' table the basic information
INSERT INTO city (name, code, country_code, population, boundary, bbox)
        (SELECT c.name, c.code, c.country_code, c.population, c.wkb_geometry, ST_Envelope(c.wkb_geometry) FROM __city c WHERE c.code = :city_code);

--- Define a temporary variable "city_grid" with the LAEA grid cells that intersects with the city boundary
DROP TABLE IF EXISTS __city_grid;
CREATE TEMPORARY TABLE __city_grid AS (SELECT g.fid, g.geom FROM city c, laea_etrs_500m g WHERE c.code = :city_code AND ST_Intersects(c.boundary, g.geom));

---LAYERS=("Xwater" "Xroads" "Xrailways" "trees" "vegetation" "agricultural_areas" "built_up" "built_open_spaces" "dense_urban_fabric" "medium_urban_fabric" "low_urban_fabric" "public_military_industrial")

-------------------
--- WATER LAYER ---
-------------------
--- save in the cityid variable the value assigned by the database in the "city" table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO __water (cityid, cellid, geom)
       (SELECT cityid.id,
               cg.fid,
               ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(ua.geom),0.0001)), cg.geom),3)) AS geom
               FROM cityid, __city_grid cg, __urban_atlas ua WHERE ua.featuretype_code IN ('50000') AND ST_Intersects(ua.geom, cg.geom) GROUP BY cg.geom,cg.fid,cityid.id);

-- update fua_tunnel attribute, if it applies (by default the value for water is 1)
UPDATE __water x SET fua_tunnel=get_parameter_value('fua_tunnel', 'dense_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11100', '11210') AND ST_Intersects(x.geom , ua.geom );
UPDATE __water x SET fua_tunnel=get_parameter_value('fua_tunnel', 'medium_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11220') AND ST_Intersects(x.geom , ua.geom );

-- update building_shadow attribute, if it applies (by default the value for water is 1)
UPDATE __water x SET building_shadow=0 FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11100', '11210', '11220', '11230', '11240', '11300', '12100') AND ST_Intersects(x.geom , ua.geom );

-- copy __water table information to water table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO water (cityid, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, fua_tunnel, building_shadow) 
        (SELECT cityid.id, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, fua_tunnel, building_shadow
        FROM cityid, __water);


-------------------
--- ROADS LAYER ---
-------------------
--- save in the cityid variable the value assigned by the database in the "city" table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO __roads (cityid, cellid, geom)
       (SELECT cityid.id,
               cg.fid,
               ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(ua.geom),0.0001)), cg.geom),3)) AS geom
               FROM cityid, __city_grid cg, __urban_atlas ua WHERE ua.featuretype_code IN ('12210', '12220') AND ST_Intersects(ua.geom, cg.geom) GROUP BY cg.geom,cg.fid,cityid.id);

-- update fua_tunnel attribute, if it applies (by default the value for roads is 1)
UPDATE __roads x SET fua_tunnel=get_parameter_value('fua_tunnel', 'dense_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11100', '11210') AND ST_Intersects(x.geom , ua.geom );
UPDATE __roads x SET fua_tunnel=get_parameter_value('fua_tunnel', 'medium_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11220') AND ST_Intersects(x.geom , ua.geom );

-- update building_shadow attribute, if it applies (by default the value for roads is 1)
UPDATE __roads x SET building_shadow=0 FROM __urban_atlas ua WHERE ST_Intersects(x.geom , ua.geom);

-- update hillshade_building attribute, if it applies (by default the value for roads is 1):
-- * intersection with public_military_industrial (CODE=12100)
-- * intersection with low_urban_fabric (CODE=11230,11240,11300)
-- * intersection with medium_urban_fabric (CODE=11220)
-- * intersection with dense_urban_fabric (CODE=11210,11100)
UPDATE __roads x SET hillshade_building=get_parameter_value('hillshade_building', 'public_military_industrial') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('12100') AND ST_Intersects(x.geom , ua.geom );
UPDATE __roads x SET hillshade_building=get_parameter_value('hillshade_building', 'medium_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11230', '11240', '11300') AND ST_Intersects(x.geom , ua.geom );
UPDATE __roads x SET hillshade_building=get_parameter_value('hillshade_building', 'low_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11220') AND ST_Intersects(x.geom , ua.geom );
UPDATE __roads x SET hillshade_building=get_parameter_value('hillshade_building', 'dense_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11100', '11210') AND ST_Intersects(x.geom , ua.geom );


-- copy __roads table information to roads table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO roads (cityid, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, fua_tunnel, building_shadow, hillshade_building) 
        (SELECT cityid.id, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, fua_tunnel, building_shadow, hillshade_building
        FROM cityid, __roads);


----------------------
--- RAILWAYS LAYER ---
----------------------
--- save in the cityid variable the value assigned by the database in the "city" table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO __railways (cityid, cellid, geom)
       (SELECT cityid.id,
               cg.fid,
               ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(ua.geom),0.0001)), cg.geom),3)) AS geom
               FROM cityid, __city_grid cg, __urban_atlas ua WHERE ua.featuretype_code IN ('12230') AND ST_Intersects(ua.geom, cg.geom) GROUP BY cg.geom,cg.fid,cityid.id);

-- update fua_tunnel attribute, if it applies (by default the value for railways is 1)
UPDATE __railways x SET fua_tunnel=get_parameter_value('fua_tunnel', 'dense_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11100', '11210') AND ST_Intersects(x.geom , ua.geom );
UPDATE __railways x SET fua_tunnel=get_parameter_value('fua_tunnel', 'medium_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11220') AND ST_Intersects(x.geom , ua.geom );

-- update building_shadow attribute, if it applies (by default the value for railways is 1)
-- BUG?: CHECK WITH MARIO ... SHOULDN'T THIS BE SIMILAR TO WATER LAYERS? (for instance, intersection can be with the railway itseld according to this query)
UPDATE __railways x SET building_shadow=0 FROM __urban_atlas ua WHERE ST_Intersects(x.geom , ua.geom);


-- copy __railways table information to railways table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO railways (cityid, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, fua_tunnel, building_shadow) 
        (SELECT cityid.id, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, fua_tunnel, building_shadow
        FROM cityid, __railways);


-------------------
--- TREES LAYER ---
-------------------
--- save in the cityid variable the value assigned by the database in the "city" table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO __trees (cityid, cellid, geom)
       (SELECT cityid.id,
               cg.fid,
               ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(ua.geom),0.0001)), cg.geom),3)) AS geom
               FROM cityid, __city_grid cg, __urban_atlas ua WHERE ua.featuretype_code IN ('31000') AND ST_Intersects(ua.geom, cg.geom) GROUP BY cg.geom,cg.fid,cityid.id);


--- remove intersections with previous layers: __water, __roads, __railways
UPDATE __trees x SET geom=subq.geom FROM (SELECT t.id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(w.geom,0.0001))),3) ) as geom FROM __trees t, __water w WHERE w.cellid=t.cellid) as subq WHERE x.id=subq.id;
UPDATE __trees x SET geom=subq.geom FROM (SELECT t.id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM __trees t, __roads r WHERE r.cellid=t.cellid) as subq WHERE x.id=subq.id;
UPDATE __trees x SET geom=subq.geom FROM (SELECT t.id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM __trees t, __railways r WHERE r.cellid=t.cellid) as subq WHERE x.id=subq.id;

--- fix possible broken geometries
UPDATE __trees SET geom=St_MakeValid(geom);


-- update fua_tunnel attribute, if it applies (by default the value for trees is 1)
UPDATE __trees x SET fua_tunnel=get_parameter_value('fua_tunnel', 'dense_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11100', '11210') AND ST_Intersects(x.geom , ua.geom );
UPDATE __trees x SET fua_tunnel=get_parameter_value('fua_tunnel', 'medium_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11220') AND ST_Intersects(x.geom , ua.geom );

-- update building_shadow attribute, if it applies (by default the value for trees is 1)
-- BUG?: CHECK WITH MARIO ... SHOULDN'T THIS BE SIMILAR TO WATER LAYERS? (for instance, intersection can be with the railway itseld according to this query)
UPDATE __trees x SET building_shadow=0 FROM __urban_atlas ua WHERE ST_Intersects(x.geom , ua.geom);

-- hillshade is already set to 0.37 by default for trees

-- copy __trees table information to trees table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO trees (cityid, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, fua_tunnel, building_shadow, hillshade_green_fraction) 
        (SELECT cityid.id, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, fua_tunnel, building_shadow, hillshade_green_fraction
        FROM cityid, __trees);