[dense_urban_fabric] 1.2
[medium_urban_fabric] 1.1
[low_urban_fabric] 1
[public_military_industrial] 1



--- insert in the city table the basic information about the current city being processed
INSERT INTO city (name, code, country_code, bbox) 
       VALUES (UPPER(:city_name), :city_code, :country_code, ST_MakeEnvelope(:bbox_xmin,:bbox_ymin,:bbox_xmax,:bbox_ymax,3035));

--- define a temporary variable "city_grid" with the LAEA grid cells that intersect with the city bbox
DROP TABLE IF EXISTS __city_grid;
CREATE TEMPORARY TABLE __city_grid AS (SELECT g.fid, g.geom FROM city c, laea_etrs_500m g WHERE ST_Intersects(c.bbox, g.geom));

--- WATER LAYER ---
--- save in the cityid variable the value assigned by the database in the "city" table
WITH cityid AS (SELECT id FROM city c WHERE c.code = :city_code)
INSERT INTO __water (cityid, cellid, geom)
       (SELECT cityid.id,
               cg.fid,
               ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(ua.geom),0.0001)), cg.geom),3)) AS geom
               FROM cityid, __city_grid cg, __urban_atlas ua WHERE ua.featuretype_code = '50000' AND ST_Intersects(ua.geom, cg.geom) GROUP BY cg.geom,cg.fid,cityid.id);

FUA_TUNNEL=`grep -i -F ['dense_urban_fabric'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
UPDATE __water w SET fua_tunnel="$FUA_TUNNEL" FROM __urban_atlas ua WHERE ua.featuretype_code IN ['11100', '11210'] AND ST_Intersects(w.geom , ua.geom );"
FUA_TUNNEL=`grep -i -F ['medium_urban_fabric'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET fua_tunnel="$FUA_TUNNEL" FROM "$CITY"_layers9_12 l WHERE "$CODE"='11220' AND ST_Intersects( x.geom , l.geom );"


