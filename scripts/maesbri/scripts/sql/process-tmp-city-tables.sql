UPDATE __urban_atlas SET geom=St_MakeValid(geom);
WITH deleted_geometries AS (DELETE FROM __urban_atlas WHERE NOT ST_Isvalid(geom) IS TRUE RETURNING *) SELECT count(*) FROM deleted_geometries;


INSERT INTO city (name, code, country_code, population, boundary, bbox)
        (SELECT c.name, c.code, c.country_code, c.population, c.wkb_geometry, ST_Envelope(c.wkb_geometry) FROM __city c WHERE c.code = :city_code);

--- define a temporary variable "city_grid" with the LAEA grid cells that intersect with the city boundary
DROP TABLE IF EXISTS __city_grid;
CREATE TEMPORARY TABLE __city_grid AS (SELECT g.fid, g.geom FROM city c, laea_etrs_500m g WHERE c.code = :city_code AND ST_Intersects(c.boundary, g.geom));

---LAYERS=("water" "roads" "railways" "trees" "vegetation" "agricultural_areas" "built_up" "built_open_spaces" "dense_urban_fabric" "medium_urban_fabric" "low_urban_fabric" "public_military_industrial")

--- WATER LAYER ---
--- save in the cityid variable the value assigned by the database in the "city" table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO __water (cityid, cellid, geom)
       (SELECT cityid.id,
               cg.fid,
               ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(ua.geom),0.0001)), cg.geom),3)) AS geom
               FROM cityid, __city_grid cg, __urban_atlas ua WHERE ua.featuretype_code IN ('50000') AND ST_Intersects(ua.geom, cg.geom) GROUP BY cg.geom,cg.fid,cityid.id);

UPDATE __water w SET fua_tunnel=get_parameter_value('fua_tunnel', 'dense_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11100', '11210') AND ST_Intersects(w.geom , ua.geom );
UPDATE __water w SET fua_tunnel=get_parameter_value('fua_tunnel', 'medium_urban_fabric') FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11220') AND ST_Intersects(w.geom , ua.geom );

UPDATE __water w SET building_shadow=0 FROM __urban_atlas ua WHERE ua.featuretype_code IN ('11100', '11210', '11220', '11230', '11240', '11300', '12100') AND ST_Intersects(w.geom , ua.geom );





-- Copy __water table information to water table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO water (cityid, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, fua_tunnel, building_shadow) 
        (SELECT cityid.id, cellid, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, fua_tunnel, building_shadow
        FROM cityid, __water);
