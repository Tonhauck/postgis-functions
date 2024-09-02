CREATE OR REPLACE FUNCTION mvt(relation text, x integer, y integer, z integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    mvt_output text;
BEGIN
    WITH
    -- Définir les limites de la tuile en utilisant les coordonnées Z, X, Y fournies
    bounds AS (
        SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    -- Transformer les géométries d'EPSG:4326 à EPSG:3857 et les découper selon les limites de la tuile
    mvtgeom AS (
        SELECT
            -- inclure le nom uniquement à partir du zoom 10
            CASE
            
            WHEN z > 10 THEN accentcity
            ELSE NULL
            END AS
            -- On récupère ici le nb de caractères d'accentcity est on l'utilise 
            -- pour calculer le rayon du cercle à la volée
            LENGTH(accentCity) AS radius, 
            ST_AsMVTGeom(
                ST_Transform(wkt_geom, 3857), -- Transformer la géométrie en Web Mercator
                bounds.geom,
                4096, -- L'étendue de la tuile en pixels (généralement 256 ou 4096)
                0,    -- Tampon autour de la tuile en pixels
                true  -- Découper les géométries selon l'étendue de la tuile
            ) AS geom
        FROM
            world_cities, bounds
        WHERE
            ST_Intersects(ST_Transform(wkt_geom, 3857), bounds.geom)
    )
    -- Générer le MVT à partir des géométries découpées
    SELECT INTO mvt_output encode(ST_AsMVT(mvtgeom, 'world_cities', 4096, 'geom'),'base64')
    FROM mvtgeom;

    RETURN mvt_output;
END;
$$;
