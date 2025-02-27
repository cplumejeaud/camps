set search_path = public, camps, demographie;

GRANT USAGE ON schema public, camps, clc, natura2000  TO qgis_reader; 
GRANT select ON ALL SEQUENCES  IN SCHEMA public, camps, clc, natura2000 TO qgis_reader;
GRANT select ON ALL TABLES  IN SCHEMA public, camps, clc, natura2000 TO qgis_reader;

create extension dblink ;

---------------------------------------------------
-- Import des camps 
---------------------------------------------------

-- l'import par shapefile raccourci le nom des champs à 8 caratères. 

create schema camps

set PGCLIENTENCODING=latin1
ogr2ogr -f "PostgreSQL" PG:"host=localhost port=5432 user=postgres dbname=camps_europe password=aqua_77 schemas=camps" /home/plumegeo/camps_migrants/BDD_carto_camps_20220217.shp -a_srs EPSG:4326 -nln camps.camps  -overwrite -lco precision=NO


-- Il vaut mieux passer par l'import de la couche générée par le fichier Excel directement

-- Import des camps en date du 26 septembre 2022 depuis le fichier Excel
-- reste à faire la géomatrie
select c3.unique_id , c3.id , c3.nom, c4.unique_id , c4.id , c4.nom  
from  camps.camps3 c3, camps.lfernier_carto_bdd c4
where c3.unique_id = c4.unique_id 
-- 660

select count(*) from camps.camps3 c3;
--662
select count(*) from camps.lfernier_carto_bdd c4;
-- 867


select * from camps.lfernier_carto_bdd c4
where unique_id = 665;

create table camps.camps4 as (select * from camps.lfernier_carto_bdd where nom is not null) ;
update camps.camps4 c4 set vetements_adaptes = null, distance_41_zones_humides_interieures = null
where unique_id = 665;
update camps.camps4 c4 set doublon = 'unique_id_665'  
where unique_id = 595;
update camps.camps4 c4 set doublon = 'unique_id_47'  
where unique_id = 48;
update camps.camps4 c4 set doublon = 'unique_id_54'  
where unique_id = 55;
update camps.camps4 c4 set doublon = 'unique_id_47'  
where unique_id = 46;

-- ne garder pour l'analyse finale que les camps non doublons
select count(*) from camps.camps4 c4
where doublon is null; --703
-- les doublons 
select count(*) from camps.camps4 c4
where doublon like 'unique_id_%'; --52

-- rajouter la colonne geom
alter table camps.camps4 add column geom geometry;
select *
-- replace(camp_longitude, ',', '.')::float , replace(camp_latitude, ',', '.')::float 
from  camps.camps4 where camp_latitude like 'pas%';
update camps.camps4 set camp_longitude = null, camp_latitude = null where unique_id in (737, 738);
select * from camps.camps4 where doublon like 'unique_id_738%';

update camps.camps4 c4 set geom = st_setsrid(st_makepoint(replace(camp_longitude, ',', '.')::float, replace(camp_latitude, ',', '.')::float), 4326);

alter table camps.camps4 add column point3857 geometry;
update camps.camps4 c4 set point3857 = st_setsrid(st_transform(geom, 3857), 3857);

alter table camps.camps4 add column point3035 geometry;
update camps.camps4 c4 set point3035 = st_setsrid(st_transform(geom, 3035), 3035);

--------------------------------------------------
-- Données osm 
-- exemple sur Bruxelles
-------------------------------------------------
planet_osm_point

select * from planet_osm_point 


select distinct amenity  from planet_osm_point order by amenity
-- pharmacy / townhall / clinic / hospital / doctors / post_office / police / taxi / water_point
-- bureau_de_change  / community_centre / social_centre / internet_cafe  / post_box / post_office
-- school / college / kindergarten / language_school / nursery / nursing_home
select distinct military  from planet_osm_point order by military; 
-- bunker

select distinct "natural" from planet_osm_point order by "natural"
-- peak, beach, ...

select distinct landuse  from planet_osm_point order by landuse
-- null 
select distinct landuse  from planet_osm_polygon order by landuse
-- industrial / military / railway / residential / highway /forest /greenfield /grass / farmland / depot

select distinct aerialway  from planet_osm_point order by aerialway
-- null
select * from planet_osm_polygon where population  is not null
-- admin_level, boundary, name, population, shop, waterway, man_made
select distinct public_transport  from planet_osm_point order by public_transport
-- platform / station / stop_position
select distinct railway  from planet_osm_point order by railway
-- station / stop
 

select osm_id, amenity, name, way, * from planet_osm_point where amenity in ('pharmacy', 'townhall', 'clinic', 'hospital')
order by amenity


select osm_id, landuse, name, way_area, way  from planet_osm_polygon where landuse in ('industrial', 'highway', 'depot', 'railway')
order by landuse

select osm_id, public_transport, name, way from planet_osm_point where public_transport in ('station', 'platform', 'stop_position')
order by public_transport

select * from planet_osm_roads where population  is not null

drop table planet_osm_polygon cascade;
drop table planet_osm_line cascade;
drop table planet_osm_point cascade;
drop table planet_osm_roads cascade;

-- liste des clés intéressantes
-- sur les points
amenity, public_transport, office, railway,highway, power, man_made, landuse, railway, aeroway, leisure, military
-- sur les polygones
landuse,  man_made, industrial, admin_level, boundary, name, population, shop, waterway,

-- total
-- amenity, public_transport, office, railway,highway, power, man_made, landuse, railway, aeroway, leisure, military, admin_level, boundary, name, population, shop, waterway

select * from planet_osm_line


-----
-- Import OSM
-------

cd /data/osm
wget https://download.geofabrik.de/europe/belgium-latest.osm.pbf

osmium extract -b 4.29,50.815,4.47,50.90 /data/osm/belgium-latest.osm.pbf  -o brussels.osm.pbf

sudo -u postgres createdb   brussels      
sudo -u postgres psql -d  brussels -c "create extension postgis"
sudo -u postgres psql -d  brussels  -c "CREATE EXTENSION hstore;"



osm2pgsql -d brussels -U postgres -W -c brussels.osm.pbf
sudo -u postgres psql -d brussels -c "create schema brussels; alter table xx set schema yyy;"

export PGPASSWORD="aqua_77"
sudo -u postgres psql -d brussels -c "create schema brussels; "
sudo -u postgres psql -d brussels -c "alter table planet_osm_line set schema brussels;"
sudo -u postgres psql -d brussels -c " alter table planet_osm_point set schema brussels;"
sudo -u postgres psql -d brussels -c " alter table planet_osm_polygon set schema brussels;"
sudo -u postgres psql -d brussels -c " alter table planet_osm_roads set schema brussels;"

sudo -u postgres psql -d brussels -c "alter database  brussels rename to osm;"

ALTER DATABASE brussels RENAME TO osm;

osm2pgsql -d osm -U postgres -W -c -s --drop --flat-nodes /data/osm/flat_nodes.cache -j brussels.osm.pbf
bosnia-herzegovina-latest.osm.pbf

-- tests avec hstore : https://www.paulnorman.ca/blog/2014/03/osm2pgsql-and-hstore/
-- pas très utile
osm2pgsql -d osm -U postgres -W -c -s --drop  brussels.osm.pbf

-- Import de la bosnia-herzegovina
export PGPASSWORD="aqua_77"
nohup osm2pgsql -d osm -U postgres -c -s --drop  bosnia-herzegovina-latest.osm.pbf > out.txt &
-- 90 s

create schema bosnie
alter table planet_osm_point set schema bosnie;
alter table planet_osm_line set schema bosnie;
alter table planet_osm_polygon set schema bosnie;
alter table planet_osm_roads set schema bosnie;

-- Import du danemark
export PGPASSWORD="aqua_77"
nohup osm2pgsql -d osm -U postgres -c -s --drop  denmark-latest.osm.pbf > out.txt &
-- 308 s 

create schema denmark;
alter table planet_osm_point set schema denmark;
alter table planet_osm_line set schema denmark;
alter table planet_osm_polygon set schema denmark;
alter table planet_osm_roads set schema denmark;

-- Import de la belgique
export PGPASSWORD="******"
nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/belgium-latest.osm.pbf > out.txt &
-- 308 s 

create schema denmark;
alter table planet_osm_point set schema denmark;
alter table planet_osm_line set schema denmark;
alter table planet_osm_polygon set schema denmark;
alter table planet_osm_roads set schema denmark;

-- use dblink to query osm.bosnie puis osm.denmark

amenity is not null or public_transport is not null or office is not null OR railway is not null or highway is not null or power is not null or man_made is not null or landuse is not null or railway is not null or aeroway is not null or leisure is not null or military is not null
create VIEW  public.osm_point_denmark AS
            SELECT osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=aqua_77 options=-csearch_path=',
                        'select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.denmark.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building=''train_station''
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medial_supply'')
									or waterway=''water_point''
									or population is not null 
									
				')
            AS t1(osm_id int8, way geometry, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

drop VIEW  public.osm_point_denmark;           
select * from public.osm_point_denmark;




-- landuse,  man_made, industrial, admin_level, boundary, name, population, shop, waterway,

create VIEW  public.osm_polygon_denmark AS
            SELECT osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=aqua_77 options=-csearch_path=',
                        'select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.denmark.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building=''train_station''
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medial_supply'')
									or waterway=''water_point''
									or population is not null 
				')
            AS t1(osm_id int8, way geometry, name text, admin_level int, population int8, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

drop VIEW  public.osm_polygon           
select * from public.osm_polygon_denmark;

select osm_id, way, name, population, admin_level  from public.osm_polygon
where boundary = 'administrative';

select admin_level, sum(population), count(osm_id)  from public.osm_polygon
where boundary = 'administrative' 
group by admin_level
order by admin_level

/*
 * 2		2 -- Pays
4	83516	19
5	171033	13
6	1351509	29
7	617537	144
8	7213	121
9	395780	1239
10		3
*/
-- 3 301 000,0 : pop total estimée du pays
 */

 select row_number() over () as id,  osm_id, name, admin_level, population, way from public.osm_polygon
where boundary = 'administrative' 
and admin_level = 7

--  Bosnie_OSM_n7_3857
 


------------------------------------------------------
-- vérifications de localisation
---------------------------------------------------------

--- Les camps dans l'eau le 15 mars 2022
select * from camps.camps2 where unique_id not in (
select c.unique_id from camps.camps2 c, camps.countries w
where st_contains(w.geom, c.geom)
) and geom is not null-- , w.admin

--- Les camps dans l'eau le 17 mars 2022
select * from camps.camps3 where unique_id not in (
select c.unique_id from camps.camps2 c, camps.countries w
where st_contains(w.geom, c.geom)
) and geom is not null-- , w.admin

-- Pour les étiquettes de camps3 dans QGIS
concat(id, concat(' - ', concat(concat(concat(concat("nom", '\n'),  "camp_adresse" ),  ' / '),"camp_commune" )))


--- Les camps dans l'eau le 26 sept 2022
select * from camps.camps4 where unique_id not in (
select c.unique_id from camps.camps4 c, camps.countries w
where st_contains(w.geom, c.geom)
) and geom is not null-- , w.admin
-- 21 dont un doublon à Myattoe (208 doublon avec le bon 203), 8 doutes et 4 imprecises

--------------------------------------------
-- les effectifs des camps RENSEIGNES
--------------------------------------------

select unique_id, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021 , effectif_total_2022  from camps.camps3

select annee, count as effectif_total from (
select count(*), 2017 as annee from  camps.camps3 where effectif_2017 is not null
union
(
select count(*), 2018 as annee from  camps.camps3 where effectif_2018 is not null
) union
(
select count(*), 2019 as annee from  camps.camps3 where effectif_2019 is not null
) union
(
select count(*), 2020 as annee from  camps.camps3 where effectif_2020 is not null
) union
(
select count(*), 2021 as annee from  camps.camps3 where effectif_2021 is not null
) union
(
select count(*), 2022 as annee from  camps.camps3 where effectif_total_2022 is not null
)
) as k 
order by annee

create extension postgis;

/*
SELECT has_table_privilege('"geometry_columns"', 'SELECT'), 
has_table_privilege('"geometry_columns"', 'INSERT'),
  has_table_privilege('"geometry_columns"', 'UPDATE'), has_table_privilege('"geometry_columns"', 'DELETE')
*/

select effectif_2019, * from camps.camps3 where effectif_2019 ilike '%non pertinent%' or effectif_2019 = ' '
update camps.camps3 set effectif_2019 = null where effectif_2019 = ' ' --55

update camps.camps3 set remarques = coalesce(remarques, '; effectif_2019 ')||effectif_2019, effectif_2019=null 
where effectif_2019 ilike '%non pertinent%' or effectif_2019 ilike '%donnee%';

update camps.camps3 set remarques = coalesce(remarques, '; capacite_2017 ')||capacite_2017, capacite_2017=null 
where capacite_2017 ilike '%non pertinent%' or capacite_2017 ilike '%donnee%';

update camps.camps3 set remarques = coalesce(remarques, '; capacite_2018 ')||capacite_2018, capacite_2018=null 
where capacite_2018 ilike '%non pertinent%' or capacite_2018 ilike '%donnee%';

update camps.camps3 set remarques = coalesce(remarques, '; capacite_2019 ')||capacite_2019, capacite_2019=null 
where capacite_2019 ilike '%non pertinent%' or capacite_2019 ilike '%donnee%';

update camps.camps3 set remarques = coalesce(remarques, '; capacite_2020 ')||capacite_2020, capacite_2020=null 
where capacite_2020 ilike '%non pertinent%' or capacite_2020 ilike '%donnee%';

update camps.camps3 set remarques = coalesce(remarques, '; capacite_2021 ')||capacite_2021, capacite_2021=null 
where capacite_2021 ilike '%non pertinent%'  or capacite_2021 ilike '%donnee%';;

update camps.camps3 set remarques = coalesce(remarques, '; effectif_2017 ')||effectif_2017, effectif_2017=null 
where effectif_2017 ilike '%non pertinent%'  or effectif_2017 ilike '%donnee%';

update camps.camps3 set remarques = coalesce(remarques, '; effectif_2018 ')||effectif_2018, effectif_2018=null 
where effectif_2018 ilike '%non pertinent%' or effectif_2018 ilike '%donnee%';

update camps.camps3 set remarques = coalesce(remarques, '; effectif_2020 ')||effectif_2020, effectif_2020=null 
where effectif_2020 ilike '%non pertinent%'  or effectif_2020 ilike '%donnee%';
update camps.camps3 set remarques = coalesce(remarques, '; effectif_2021 ')||effectif_2021, effectif_2021=null 
where effectif_2021 ilike '%non pertinent%'  or effectif_2021 ilike '%donnee%';
update camps.camps3 set remarques = coalesce(remarques, '; effectif_2020 ')||effectif_2020, effectif_2020=null 
where effectif_2020 ilike '%non pertinent%'  or effectif_2020 ilike '%donnee%';
update camps.camps3 set remarques = coalesce(remarques, '; effectif_total_2022 ')||effectif_total_2022, effectif_total_2022=null 
where effectif_total_2022 ilike '%non pertinent%' or effectif_total_2022 ilike '%donnee%';

-- 
alter table  camps.camps3 alter effectif_2019 type int using trim(effectif_2019)::int ;
alter table  camps.camps3 alter capacite_2019 type int using trim(capacite_2019)::int ;
update camps.camps3 set capacite_2019 = null where capacite_2019 = ' ' --55


select effectif_2019, * from camps.camps3 where effectif_2019 ilike '%donnee%' 

--------------------------------------------
-- démographie
--------------------------------------------

-- import des données
create schema demographie;
drop table demographie.population_monde 

CREATE TABLE demographie.population_monde (
	country_name varchar(64) NULL,
	country_code varchar(4) NULL,
	indicator_name varchar(32) NULL,
	indicator_code varchar(16) NULL,
	"1960" int8 NULL,
	"1961" int8 NULL,
	"1962" int8 NULL,
	"1963" int8 NULL,
	"1964" int8 NULL,
	"1965" int8 NULL,
	"1966" int8 NULL,
	"1967" int8 NULL,
	"1968" int8 NULL,
	"1969" int8 NULL,
	"1970" int8 NULL,
	"1971" int8 NULL,
	"1972" int8 NULL,
	"1973" int8 NULL,
	"1974" int8 NULL,
	"1975" int8 NULL,
	"1976" int8 NULL,
	"1977" int8 NULL,
	"1978" int8 NULL,
	"1979" int8 NULL,
	"1980" int8 NULL,
	"1981" int8 NULL,
	"1982" int8 NULL,
	"1983" int8 NULL,
	"1984" int8 NULL,
	"1985" int8 NULL,
	"1986" int8 NULL,
	"1987" int8 NULL,
	"1988" int8 NULL,
	"1989" int8 NULL,
	"1990" int8 NULL,
	"1991" int8 NULL,
	"1992" int8 NULL,
	"1993" int8 NULL,
	"1994" int8 NULL,
	"1995" int8 NULL,
	"1996" int8 NULL,
	"1997" int8 NULL,
	"1998" int8 NULL,
	"1999" int8 NULL,
	"2000" int8 NULL,
	"2001" int8 NULL,
	"2002" int8 NULL,
	"2003" int8 NULL,
	"2004" int8 NULL,
	"2005" int8 NULL,
	"2006" int8 NULL,
	"2007" int8 NULL,
	"2008" int8 NULL,
	"2009" int8 NULL,
	"2010" int8 NULL,
	"2011" int8 NULL,
	"2012" int8 NULL,
	"2013" int8 NULL,
	"2014" int8 NULL,
	"2015" int8 NULL,
	"2016" int8 NULL,
	"2017" int8 NULL,
	"2018" int8 NULL,
	"2019" int8 NULL,
	"2020" int8 NULL
); -- banque mondiale


select pm.country_name , pm.country_code , pm."2020"  
from demographie.population_monde pm , demographie.ne_10m_admin_0_countries c
where c.adm0_a3  = pm.country_code 
-- 213

select count(*) from demographie.population_monde
-- 266
select count(*) from demographie.ne_10m_admin_0_countries
-- 258


select pm.country_name , pm.country_code , pm."2020" , c.id
from demographie.population_monde pm left outer join demographie.ne_10m_admin_0_countries c
on c.adm0_a3  = pm.country_code 
-- Kosovo	XKX 1775378
-- Cisjordanie et Gaza	PSE	4803269
-- Îles Anglo-Normandes	CHI	173859 : GGY et JEY
-- Soudan du Sud	SSD	11193729
-- Petits états	SST	41912623


-- 22 mars 2022
-- Import des communes d'Europe
--Télécharger les communes sur toute l'europe
--https://ec.europa.eu/eurostat/fr/web/gisco/geodata/reference-data/administrative-units-statistical-units/communes#communes16
--version 2016 (EPSG 3857  - UTF-8)
--

--Chez Eurostat, les LAU2, avec Grece, Turquie et Irlande seulement
--https://ec.europa.eu/eurostat/fr/web/nuts/local-administrative-units
-- Turquie : latin 1 , EPSG 4230
-- 
--l'UKRAINE : 4326
--http://worldmap.harvard.edu/data/geonode:ukraine_may_2014_administrative_units_9ob
--
--La Crimée : 4326
--- http://worldmap.harvard.edu/data/geonode:crimea_9sr

-- Importer le fond NON ESPON space (3857)
-- C:\Travail\ULR_owncloud\ANR_PORTIC\Data\ports\cartes\NUTS_2003\GEOM\map_template_1_(eurogeographics_20M)\non_espon_space_2003.shp

-- Importer les données de pop 2019 qui viennent de cette page
-- https://ec.europa.eu/eurostat/fr/web/nuts/local-administrative-units
-- https://ec.europa.eu/eurostat/documents/345175/501971/EU-28-LAU-2019-NUTS-2016.xlsx

alter table demographie.eu alter column "CHANGE (Y/N)" type varchar(8);
alter table demographie.eu alter column "DEG change compared to last year" type varchar(8);
alter table demographie.eu alter column "COAST change compared to last year" type varchar(8);
alter table demographie.eu alter column "CITY_ID change compared to last year" type varchar(8);
alter table demographie.eu alter column "FUA_ID change compared to last year" type varchar(8);
alter table demographie.eu alter column "country"  type varchar(8); 
alter table demographie.eu alter column "greater_city_id"  type varchar(8); 
alter table demographie.eu alter column "greater_city_name"  type text; 
alter table demographie.eu alter column "GREATER_CITY_ID change compared to last year"  type varchar(8); 

ALTER TABLE demographie.eu ALTER COLUMN "TOTAL AREA (m2)" TYPE text USING "TOTAL AREA (m2)"::text;
ALTER TABLE demographie.eu ALTER COLUMN city_name TYPE text USING city_name::text;
ALTER TABLE demographie.eu ALTER COLUMN fua_name TYPE text USING fua_name::text;

ALTER TABLE demographie.eu ALTER COLUMN "NUTS 3 CODE" TYPE text USING "NUTS 3 CODE"::text;
ALTER TABLE demographie.eu ALTER COLUMN "LAU CODE" TYPE text USING "LAU CODE"::text;
ALTER TABLE demographie.eu ALTER COLUMN "LAU NAME NATIONAL" TYPE text USING "LAU NAME NATIONAL"::text;
ALTER TABLE demographie.eu ALTER COLUMN "LAU NAME LATIN" TYPE text USING "LAU NAME LATIN"::text;
ALTER TABLE demographie.eu ALTER COLUMN "CHANGE (Y/N)" TYPE text USING "CHANGE (Y/N)"::text;
ALTER TABLE demographie.eu ALTER COLUMN "DEG change compared to last year" TYPE text USING "DEG change compared to last year"::text;
ALTER TABLE demographie.eu ALTER COLUMN "COASTAL AREA (yes/no)" TYPE text USING "COASTAL AREA (yes/no)"::text;
ALTER TABLE demographie.eu ALTER COLUMN "COAST change compared to last year" TYPE text USING "COAST change compared to last year"::text;
ALTER TABLE demographie.eu ALTER COLUMN city_id TYPE text USING city_id::text;
ALTER TABLE demographie.eu ALTER COLUMN "CITY_ID change compared to last year" TYPE text USING "CITY_ID change compared to last year"::text;
ALTER TABLE demographie.eu ALTER COLUMN greater_city_id TYPE text USING greater_city_id::text;
ALTER TABLE demographie.eu ALTER COLUMN "GREATER_CITY_ID change compared to last year" TYPE text USING "GREATER_CITY_ID change compared to last year"::text;
ALTER TABLE demographie.eu ALTER COLUMN fua_id TYPE text USING fua_id::text;
ALTER TABLE demographie.eu ALTER COLUMN "FUA_ID change compared to last year" TYPE text USING "FUA_ID change compared to last year"::text;
ALTER TABLE demographie.eu ALTER COLUMN country TYPE text USING country::text;
ALTER TABLE demographie.eu ALTER COLUMN gisco_id TYPE text USING gisco_id::text;

ALTER TABLE demographie.eu ALTER COLUMN population TYPE text ;
ALTER TABLE demographie.eu ALTER COLUMN degurba TYPE text USING degurba::text;

update demographie.eu set population = null where population = 'n.a.'; -- 615
update demographie.eu set population = REPLACE (population, ' ', '');--99140
ALTER TABLE demographie.eu ALTER COLUMN population TYPE int using population::int ;



select * from demographie.eu eu
where eu."LAU NAME LATIN"  = 'Deutschkreutz'

truncate table demographie.eu 


CREATE TABLE demographie.eu (
	"NUTS 3 CODE" text NULL,
	"LAU CODE" text NULL,
	"LAU NAME NATIONAL" text NULL,
	"LAU NAME LATIN" text NULL,
	"CHANGE (Y/N)" text NULL,
	population text NULL,
	"TOTAL AREA (m2)" text NULL,
	degurba text NULL,
	"DEG change compared to last year" text NULL,
	"COASTAL AREA (yes/no)" text NULL,
	"COAST change compared to last year" text NULL,
	city_id text NULL,
	"CITY_ID change compared to last year" text NULL,
	city_name text NULL,
	greater_city_id text NULL,
	"GREATER_CITY_ID change compared to last year" text NULL,
	greater_city_name text NULL,
	fua_id text NULL,
	"FUA_ID change compared to last year" text NULL,
	fua_name text NULL,
	country text NULL,
	gisco_id text NULL
); 
-- import de l'onglet Combined du fichier 2019 : C:\Travail\CNRS_poitiers\MIGRINTER\Labo\Louis_Fernier\demographie\EU-28-LAU-2019-NUTS-2016.xlsx

/*
LAU CODE	LAU NAME NATIONAL	LAU NAME LATIN	CHANGE (Y/N)	POPULATION	TOTAL AREA (m2)	DEGURBA	
DEG change compared to last year	COASTAL AREA (yes/no)	COAST change compared to last year	CITY_ID	CITY_ID change compared to last year
CITY_NAME	GREATER_CITY_ID	GREATER_CITY_ID change compared to last year	GREATER_CITY_NAME	
FUA_ID	FUA_ID change compared to last year	FUA_NAME
*/

CREATE TABLE demographie.fr (
	"LAU CODE" text NULL,
	"LAU NAME NATIONAL" text NULL,
	"LAU NAME LATIN" text NULL,
	"CHANGE (Y/N)" text NULL,
	population text NULL,
	"TOTAL AREA (m2)" text NULL,
	degurba text NULL,
	"DEG change compared to last year" text NULL,
	"COASTAL AREA (yes/no)" text NULL,
	"COAST change compared to last year" text NULL,
	city_id text NULL,
	"CITY_ID change compared to last year" text NULL,
	city_name text NULL,
	greater_city_id text NULL,
	"GREATER_CITY_ID change compared to last year" text NULL,
	greater_city_name text NULL,
	fua_id text NULL,
	"FUA_ID change compared to last year" text NULL,
	fua_name text NULL
);
-- import de l'onglet FR du fichier 2018 : C:\Travail\CNRS_poitiers\MIGRINTER\Labo\Louis_Fernier\demographie\EU-28-LAU-2018-NUTS-2016.xlsx


ALTER TABLE demographie.fr ALTER COLUMN population TYPE int using population::int ;
ALTER TABLE demographie.eu ADD COLUMN annee int default 2019;
ALTER TABLE demographie.fr ADD COLUMN annee int default 2018;

update demographie.eu set annee = 2018, population = fr.population 
from demographie.fr
where fr."LAU CODE" = eu."LAU CODE" and fr."NUTS 3 CODE" = eu."NUTS 3 CODE" ;
-- 34970


select fr."NUTS 3 CODE" , fr."LAU CODE" , fr."LAU NAME LATIN" , fr.population , fr.fua_id , eu.fua_id , eu.fua_name 
from demographie.fr, demographie.eu 
where fr."LAU CODE" = eu."LAU CODE" and fr."NUTS 3 CODE" = eu."NUTS 3 CODE" and fr.fua_id is not null
-- 10427 / 34970 -- FUASs / COMMUNES JOINTES


select count(*) from demographie.fr where fua_id is not null
-- 10499 / 35462 -- FUASs / COMMUNES TOTALES

select count(*) from demographie.eu where fua_id is not null and eu.country = 'FR'
-- 34970

select fr."NUTS 3 CODE" , fr."LAU CODE" , fr."LAU NAME LATIN" , fr.population , fr.fua_id , eu.fua_id , eu.fua_name 
from demographie.fr left outer join demographie.eu 
on fr."LAU CODE" = eu."LAU CODE" and fr."NUTS 3 CODE" = eu."NUTS 3 CODE"

-----
-- JOINTURES

select population, eu."LAU NAME LATIN" , g.comm_name , g.geom 
from  demographie.eu eu, "GISCO_LAU_eurostat" g
where g.nuts_code||g.nsi_code = eu."NUTS 3 CODE"||eu."LAU CODE" 
-- alignement au niveau des communes

select population,  g.id , g.urau_name , g.geom 
from  demographie.eu eu, aires_urbaines g 
where g.urau_code = eu.fua_id 
-- alignement au niveau des FUA

-- group by fua_id
select fua_id, sum(population) as pop_2019  
from  demographie.eu eu
where "NUTS 3 CODE" like 'FR%' and trim(fua_id)='FR004L2'
group by fua_id

IE001F	2029986
IE002F	465228
IE003F	261759
IE004F	279400
IE005F	84955

select distinct q.fua_id, q.pop_2019, eu.city_name from 
(
select fua_id,  sum(population) as pop_2019  
from  demographie.eu eu
where "NUTS 3 CODE" like 'IE%' 
group by fua_id
) as q , 
demographie.eu eu 
where eu.fua_id =q.fua_id and city_name is not null


select urau_code , urau_name , fid from aires_urbaines where urau_code like 'FR%'
select urau_code , urau_name , fid,* from aires_urbaines where urau_code like 'IE%'

FR004L2	FUA of Toulouse	FR004L2
FR076L2	FUA of Belfort	FR076L2

alter table aires_urbaines add  pop_2019 int ;

update aires_urbaines a set pop_2019 = k.pop_2019
from 
(select fua_id, sum(population) as pop_2019  
from  demographie.eu eu
group by fua_id
order by fua_id) as k 
where trim(k.fua_id) = trim(a.urau_code) 
-- 578



update aires_urbaines a set pop_2019 = k.pop_2019
from 
(
	select distinct q.fua_id, q.pop_2019, eu.city_name from 
	(
		select fua_id,  sum(population) as pop_2019  
		from  demographie.eu eu
		where "NUTS 3 CODE" like 'IE%' 
		group by fua_id
	) as q , 
	demographie.eu eu 
	where eu.fua_id =q.fua_id and city_name is not null
) as k 
where a.pop_2019 is null 
and trim(k.fua_id) != trim(a.urau_code) 
and a.urau_name=k.city_name
--10 (pour les urau_catg = C ou F, pour les 5 unités urbaines d'IE : Cork, Waterford, Limerick, Galway, Dublin)


update aires_urbaines a set pop_2019 = k.pop_2019
from 
(
	select distinct q.fua_id, q.pop_2019, eu.city_name from 
	(
		select fua_id,  sum(population) as pop_2019  
		from  demographie.eu eu
		--where "NUTS 3 CODE" like 'IE%' 
		group by fua_id
	) as q , 
	demographie.eu eu 
	where eu.fua_id =q.fua_id and city_name is not null
) as k --929
where a.pop_2019 is null 
and trim(k.fua_id) != trim(a.urau_code) 
and a.urau_name=k.city_name
-- 769

select * from aires_urbaines a where a.urau_catg ='C'

set search_path=demographie, camps, public;

select  cntr_code, count(*)  as c
from aires_urbaines a where a.pop_2019 is null and a.urau_catg ='F'
group by cntr_code
order by c desc;
-- UK, ES, HU, PL (PL002L -Łódź)
-- FR306C1	C	FR	City of Mantes-la-Jolie
 /*
PL	59 - 27 - 12
HU	19 - 6 - 4
EL	12 - 13 - 3
NO	6 - 6 - 3
CY	2 - 2 - 1
SI	1 - 1 - 1
BE 1

FR	73 - 0
UK	42 - 42 - 28 - 23 - 0
ES	8 - 8 - 8 - 0
SK	4 - 0
LT	3 - 0
CZ	3 - 0
LV	2 - 0
MT	1 - 0
*/

select  substring(urau_name from 8 for length(urau_name)), * 
from aires_urbaines a where a.pop_2019 is null and a.urau_catg ='F' and a.cntr_code ='PL'

/*
ES055L0	F	ES	FUA of Melilla
ES065L0	F	ES	FUA of Línea de la Concepción, La
ES062L0	F	ES	FUA of Sanlúcar de Barrameda
ES073L0	F	ES	FUA of Elda
ES074L0	F	ES	FUA of Santa Lucía de Tirajana
ES045L0	F	ES	FUA of Ceuta
ES037L0	F	ES	FUA of Puerto de Santa María, El
ES540L0	F	ES	FUA of Chiclana de la Frontera

ES640
ES612
*/
select "NUTS 3 CODE", eu."LAU NAME LATIN" , eu.city_name, gisco_id  from demographie.eu 
where "NUTS 3 CODE" like 'UK%'

update aires_urbaines a set pop_2019 = k.pop_2019
from 
(
	select distinct q.fua_id, q.pop_2019, eu.city_name from 
	(
		select fua_id,  sum(population) as pop_2019  
		from  demographie.eu eu
		--where "NUTS 3 CODE" like 'IE%' 
		group by fua_id
	) as q , 
	demographie.eu eu 
	where eu.fua_id =q.fua_id and city_name is not null
) as k --929
where a.pop_2019 is null 
--and trim(k.fua_id) != trim(a.urau_code) 
and lower(trim(substring(a.urau_name from 8 for length(a.urau_name))))=lower(trim(k.city_name))
-- 2+104

update aires_urbaines a set pop_2019 = k.pop_2019
from 
(
		select eu.city_name ,  sum(population) as pop_2019  
		from  demographie.eu eu
		where fua_id is null
		group by eu.city_name 
) as k --929
where a.pop_2019 is null 
--and trim(k.fua_id) != trim(a.urau_code) 
and lower(trim(substring(a.urau_name from 8 for length(a.urau_name))))=lower(trim(k.city_name))
-- 13 -- Note : si la city_name est seulement sur une des communes de la FUA, c'est la merde

create extension pg_trgm

select eu.city_name , eu."LAU NAME LATIN" , a.urau_name 
from demographie.eu , aires_urbaines a
where a.pop_2019 is null and eu.country = 'ES'
and eu.city_name % a.urau_name 
and lower(trim(substring(a.urau_name from 8 for length(a.urau_name))))=lower(trim(eu.city_name))



update aires_urbaines a set pop_2019 = k.pop_2019
from 
(
		select eu.city_name ,  sum(population) as pop_2019  
		from  demographie.eu eu
		where fua_id is null
		group by eu.city_name 
) as k --929
where a.pop_2019 is null 
--and trim(k.fua_id) != trim(a.urau_code) 
and lower(trim(a.urau_name))=lower(trim(k.city_name))
-- 54 -- Note : si la city_name est seulement sur une des communes de la FUA, c'est la merde


/*
PL511L	F	PL	Wałbrzych	N			PL517
PL030L	F	PL	Jastrzębie-Zdrój	N			PL227
PL020L	F	PL	Nowy Sącz	N			PL218
PL517L	F	PL	Grudziądz	N			PL616
PL011L	F	PL	Białystok	N			PL841
PL035L	F	PL	Inowrocław	N			PL617
PL036L	F	PL	Ostrowiec Świętokrzyski	N			PL721
PL040L	F	PL	Przemyśl	N			PL822
PL513L	F	PL	Włocławek	N			PL619
PL506L	F	PL	Bielsko-Biała	N			PL225
PL024L	F	PL	Częstochowa	N			PL224
PL049L	F	PL	Świdnica	N			PL517
*/

select "NUTS 3 CODE", eu."LAU NAME LATIN" , eu.city_name, gisco_id  from demographie.eu 
where "NUTS 3 CODE" like 'PL517%'
-- encodage merdique de city_name 

select * from aires_urbaines au where au.urau_code = 'BE005L3'
-- Note : si la city_name est seulement sur une des communes de la FUA, c'est la merde

-- faire la jointure avce GISCO_LAU_eurostat 
-- entre eu et GISCO_LAU_eurostat 
-- puis calculer les communes dans l'emprise des aires_urbaines

-- Reprise le 23 mars 2022


select count(*) from 
aires_urbaines au, "GISCO_LAU_eurostat" c 
where urau_catg = 'F' and st_contains(au.geom, st_centroid(c.geom))
-- C ou F
-- 6224 si C
-- 36123 si F

alter table demographie."GISCO_LAU_eurostat" add column computed_city_code text;
alter table demographie."GISCO_LAU_eurostat" add column computed_fua_code text;

update demographie."GISCO_LAU_eurostat" c set computed_city_code = au.urau_code 
from aires_urbaines au
where urau_catg = 'C' and st_contains(au.geom, st_centroid(c.geom))

update demographie."GISCO_LAU_eurostat" c set computed_fua_code = au.urau_code 
from aires_urbaines au
where urau_catg = 'F' and st_contains(au.geom, st_centroid(c.geom))

select population, eu."LAU NAME LATIN" , g.comm_name , g.geom 
from  demographie.eu eu, "GISCO_LAU_eurostat" g
where g.nuts_code||g.nsi_code = eu."NUTS 3 CODE"||eu."LAU CODE" 
-- alignement au niveau des communes / 114553 lignes

select count(*) from demographie.eu
-- 99140
select count(*) from "GISCO_LAU_eurostat"
-- 122750

alter table demographie.eu add column computed_city_code text;
alter table demographie.eu add column computed_fua_code text;

update demographie.eu eu set computed_city_code = g.computed_city_code
from "GISCO_LAU_eurostat" g
where g.nuts_code||g.nsi_code = eu."NUTS 3 CODE"||eu."LAU CODE"
-- 91489

select * from demographie.eu where eu."NUTS 3 CODE" = 'HU110'
update demographie.eu set computed_city_code = 'HU001C1' where eu."NUTS 3 CODE" = 'HU110'
update demographie.eu set computed_fua_code = 'HU001L2' where eu."NUTS 3 CODE" = 'HU110'


--HU110	13578 / HU001C1
select * from demographie."GISCO_LAU_eurostat" g where g.nuts_code = 'HU110'

update demographie.eu eu set computed_fua_code = g.computed_fua_code
from "GISCO_LAU_eurostat" g
where g.nuts_code||g.nsi_code = eu."NUTS 3 CODE"||eu."LAU CODE"
-- là il a des trous dans la raquette car certains nuts_code et nsi_code sont à null dans GISCO_LAU_eurostat 

alter table aires_urbaines add column fua_pop2019 text;

set search_path = public, camps, demographie;

update aires_urbaines a set fua_pop2019 = k.pop_2019
from 
(select computed_fua_code, sum(population) as pop_2019  
from  demographie.eu eu
group by computed_fua_code
) as k 
where k.computed_fua_code = a.urau_code;
-- 686 
alter table aires_urbaines add column city_pop2019 text;

update aires_urbaines a set city_pop2019 = k.pop_2019
from 
(select computed_city_code, sum(population) as pop_2019  
from  demographie.eu eu
group by computed_city_code
) as k 
where k.computed_city_code = a.urau_code;
-- 887

select * from aires_urbaines where cntr_code = 'IE' 
-- IE005C1	C	IE	Waterford			IE005L1	IE052
select * from demographie.eu where eu."NUTS 3 CODE" = 'IE052' 
-- IE052	1390402	PILTOWN	PILTOWN	yes	21343	428365000	1	yes	yes		IE004F			IE	IE_1390402	2019

select * from "GISCO_LAU_eurostat" gle where fid like 'IE%' and nuts_code = 'IE052' and comm_name ilike 'PILTOWN%'
select * from "GISCO_LAU_eurostat" gle where fid like 'IE%' and nuts_code = 'IE052' and comm_name ilike 'Jerpoint West%'
select * from "GISCO_LAU_eurostat" gle where fid like 'IE%' and nuts_code = 'IE052' and comm_name ilike 'Listerlin%'

07035	Jerpoint West
07036	Listerlin

select city_id, fua_id, *  from demographie.eu where eu."NUTS 3 CODE" in ('UKM50' , 'IE052')
select * from "GISCO_LAU_eurostat" gle where fid like 'GB%' --and comm_name ilike 'Aberd%'
select * from "GISCO_LAU_eurostat" gle where fid like 'GBS13002761' --and comm_name ilike 'Aberd%'
-- pas de nuts_code ni de nsi_code en Ecosse
-- fid = GB | LAU_code
UK016C1	UK016L1	UKM50	S30000026	Aberdeen City
		UK016L1	UKM50	S30000027	Aberdeenshire
	
Tweeddale West GBS13002761

Avondale and Stonehouse GBS13002791
and Glasgow, UK004L1, UKM95, aire de 3 373 270 411,80333

select city_id, fua_id, 'GB'||eu."LAU CODE"  from demographie.eu where eu."NUTS 3 CODE" = 'UKM95'
select *  from demographie."GISCO_LAU_eurostat" where fid like 'GB%' and nuts_code is null
-- 353
select *  from demographie."GISCO_LAU_eurostat" where fid like 'GB%' and nuts_code is null
and fid in (select 'GB'||eu."LAU CODE"  from demographie.eu where eu.country = 'UK')

GBE07000036
GBE06000001

select *  from demographie."GISCO_LAU_eurostat" g where 
 g.comm_name ilike '%Paisley North West%'


select 'GB'||eu."LAU CODE"  from demographie.eu where eu.country = 'UK' and eu."LAU NAME LATIN" ilike '%Glasgow%'
-- UKM82	S30000019	Glasgow City
-- UKM50	S30000026	Aberdeen City

select 'GB'||eu."LAU CODE" , eu."LAU NAME NATIONAL"  from demographie.eu where eu.country = 'UK' and eu."LAU NAME NATIONAL" ilike '%Glasgow%'
-- GBS30000019


select * from demographie.eu

CREATE TABLE demographie.lau2_reference_dates_pop (
	cntr_code varchar(2) NULL,
	cntr_lau_code varchar(16) NULL,
	lau_label text NULL,
	pop_1961 varchar(16) NULL,
	pop_1971 varchar(16) NULL,
	pop_1981 varchar(16) NULL,
	pop_1991 varchar(16) NULL,
	pop_2001 varchar(16) NULL,
	pop_2011 varchar(16) NULL)
truncate lau2_reference_dates_pop 
alter table demographie.lau2_reference_dates_pop alter column cntr_lau_code type varchar(16);

-- completer avec les données de population 2011 les LAU d'ecosse par exemple 

select count(distinct gisco_id) from demographie.eu where gisco_id is not null 
-- 99140

alter table demographie."GISCO_LAU_eurostat" add column computed_gisco_id text;

update demographie."GISCO_LAU_eurostat" g set computed_gisco_id = eu.gisco_id
from demographie.eu eu 
where g.nuts_code||g.nsi_code = eu."NUTS 3 CODE"||eu."LAU CODE"
-- 114553


select  cntr_code, count(*) as c  from demographie."GISCO_LAU_eurostat" 
where computed_gisco_id is null
group by cntr_code 
order by c desc

/*
 * IE	3441
MD	982
UK	815
UA	682
FR	577
NO	426
EL	326
EE	217
RS	169
IT	96
CH	82
ES	80
AL	73
DE	55
NL	45
XK	37
FO	29
HU	23
MK	13
AT	8
GL	5
IS	3
LU	3
LT	2
SM	1
BL	1
VA	1
AD	1
FK	1
	1
MC	1
GI	1
*/

select  name_asci   from demographie."GISCO_LAU_eurostat" 
where computed_gisco_id is null
and cntr_code = 'IE'

select g.name_asci   , p.*
from demographie."GISCO_LAU_eurostat" g, demographie.lau2_reference_dates_pop p
where g.computed_gisco_id is null and g.cntr_code = 'IE'
and p.cntr_code = 'IE' and p.lau_label = g.name_asci 


alter table demographie."GISCO_LAU_eurostat" add column pop_2019 int8;
alter table demographie."GISCO_LAU_eurostat" add column pop_2011 int8;
alter table demographie."GISCO_LAU_eurostat" add column pop_2018 int8;

update demographie."GISCO_LAU_eurostat" set pop_2019 = eu.population 
from demographie.eu 
where computed_gisco_id = eu.gisco_id 

update demographie."GISCO_LAU_eurostat" g set pop_2018 = fr.population 
from demographie.fr 
where g.nuts_code||g.nsi_code = fr."NUTS 3 CODE"||fr."LAU CODE" 

select '#'||pop_2011||'#', * from demographie.lau2_reference_dates_pop where pop_2011  = ' -   ' like '%-%' # -   #
update demographie.lau2_reference_dates_pop set pop_2011 = null where pop_2011  = ' -   ' --86
alter table  demographie.lau2_reference_dates_pop alter column pop_2011 type int using replace(pop_2011, ' ', '')::int;


update demographie."GISCO_LAU_eurostat" g set pop_2011 = k.somme
from (
select g.name_asci   , sum(p.pop_2011) as somme
from demographie."GISCO_LAU_eurostat" g, demographie.lau2_reference_dates_pop p
where g.computed_gisco_id is null 
and  p.lau_label = g.name_asci
group by g.name_asci
) as k 
where g.name_asci = k.name_asci 
-- 5654 

-- Analyse possible basée sur ces chiffres
select * from demographie."GISCO_LAU_eurostat" where coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1))) = -1

Candroma#Ceann Droma

select * from demographie.lau2_reference_dates_pop where lau_label = 'Ceann Droma'


update demographie."GISCO_LAU_eurostat" g set pop_2011 = k.somme
from (
select p.lau_label   , sum(p.pop_2011) as somme
from demographie."GISCO_LAU_eurostat" g, demographie.lau2_reference_dates_pop p
where g.computed_gisco_id is null and g.pop_2011 is null
and  p.lau_label = substring(g.name_asci from position('#' in g.name_asci)+1)
group by p.lau_label
) as k 
where substring(g.name_asci from position('#' in g.name_asci)+1) = k.lau_label 
-- complete pour l'Irlande (IE)

select g.name_asci, substring(g.name_asci from position('#' in g.name_asci)+1)  ,p.pop_2011, p.*
from demographie."GISCO_LAU_eurostat" g, demographie.lau2_reference_dates_pop p
where g.computed_gisco_id is null and g.pop_2011 is null
and  p.lau_label = substring(g.name_asci from position('#' in g.name_asci)+1)

/* 5 unités couvrent Leitrim par exemple
 * IE31077	Leitrim
IE28024	Leitrim
IE27125	Leitrim
IE19115	Leitrim
IE18142	Leitrim
*/




-- EL513	01020108	Τοπική Κοινότητα Δοκού	Local Commune of Dokos
select * from demographie.eu where "NUTS 3 CODE" = 'EL513'
select 'GR'||"LAU CODE"||'#'  from demographie.eu where "NUTS 3 CODE" = 'EL513'
select 'GR'||"LAU CODE"||'#', *  from demographie.eu where "NUTS 3 CODE" = 'EL511'

select substring("LAU NAME LATIN" from position('of' in "LAU NAME LATIN")+3) , 'GR'||substring("LAU CODE" from 5 for 4)||'#'||substring("LAU CODE" from 0 for 5), 
*  from demographie.eu where "NUTS 3 CODE" = 'EL511'
select 'GR'||substring("LAU CODE" from 5 for 4)||'#'||substring("LAU CODE" from 0 for 5), *  from demographie.eu where "NUTS 3 CODE" = 'EL513'

-- GR03020101#	EL511	03020101	???????? ????????? ????????????	Municipal Commune of Didymoticho

-- La Grèce
update demographie."GISCO_LAU_eurostat" g set computed_gisco_id = null
where  g.cntr_code = 'EL' 


update demographie."GISCO_LAU_eurostat" g set computed_gisco_id = eu.gisco_id
from demographie.eu eu 
where eu.country = 'EL' and g.cntr_code = 'EL' and g.comm_id  = 'GR'||eu."LAU CODE"
-- 13 pas sur 

update demographie."GISCO_LAU_eurostat" g set computed_gisco_id = eu.gisco_id
from demographie.eu eu 
where eu.country = 'EL' and g.cntr_code = 'EL' and g.comm_id  = 'GR'||substring("LAU CODE" from 5 for 4)||substring("LAU CODE" from 0 for 5)
-- 103 NON


update demographie."GISCO_LAU_eurostat" g set computed_gisco_id = eu.gisco_id
from demographie.eu eu 
where eu.country = 'EL' and g.cntr_code = 'EL' and substring("LAU NAME LATIN" from position('of' in "LAU NAME LATIN")+3) = g.name_asci
--5 NON 

select round(st_area(g.geom)), eu."TOTAL AREA (m2)", g.name_asci, g.comm_id, g.computed_gisco_id, eu."LAU NAME LATIN" , eu."LAU NAME NATIONAL" , eu."NUTS 3 CODE" , eu."LAU CODE" , eu.gisco_id 
from demographie."GISCO_LAU_eurostat" g, demographie.eu eu 
where eu.country = 'EL' and g.cntr_code = 'EL'  
and substring("LAU NAME LATIN" from position('of' in "LAU NAME LATIN")+3) % g.name_asci
-- and eu."TOTAL AREA (m2)"  % st_area(g.geom)

select * from demographie."GISCO_LAU_eurostat" g where g.cntr_code = 'EL' and g.name_asci not in (
select g.name_asci--,  string_agg(eu.gisco_id, ',') 
from demographie."GISCO_LAU_eurostat" g, demographie.eu eu 
where eu.country = 'EL' and g.cntr_code = 'EL'  and substring("LAU NAME LATIN" from position('of' in "LAU NAME LATIN")+3) % g.name_asci
group by g.name_asci)

-- , 'GR'||substring("LAU CODE" from 5 for 4)||'#'||substring("LAU CODE" from 0 for 5), 
select *  from demographie.eu where "LAU NAME LATIN" = 'Local Commune of Platania'
50825556
9901394
11332160
18831189
13585286

GR 07137406

EL421	69010705
EL433	73030211
EL514	02040204
EL531	14020113
EL653	44060309

--select * from demographie."GISCO_LAU_eurostat" g  where g.cntr_code = 'EL' and comm_id like '%01030302%'
select * from demographie."GISCO_LAU_eurostat" g  where g.cntr_code = 'EL' and comm_id like '%01030%'
GR01010302 Didymoteichou
GR 0101 0301	EL	EL	Αλεξανδρούπολης	Alexandroupolis 
GR 0302 0101 Didymoteichou


select g.name_asci, g.comm_id, g.computed_gisco_id, eu."LAU NAME LATIN" , eu."NUTS 3 CODE" , eu."LAU CODE" , eu.gisco_id 
from demographie."GISCO_LAU_eurostat" g, demographie.eu eu 
where eu.country = 'EL' and g.cntr_code = 'EL'  and substring("LAU NAME LATIN" from position('of' in "LAU NAME LATIN")+3) % g.name_asci



select  cntr_code, count(*)  as c
from demographie."GISCO_LAU_eurostat" 
where coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1))) = -1
group by cntr_code
order by c desc

code nb	missing1	nom
MD	978 2019	Moldavie
UA	682 		Ukraine
CY	613 2019	Chypre
EL	323			Grece
RS	163	2019	Serbie
NO	129 2019 	Norvège
UK	126			Grande Bretagne
IE	117			Irlande
AL	73			Albanie
EE	66			Estonie
MK	40			Macedoine du Nord
XK	36 2019		KOSOVO


ES	80			Espagne
FR	53 2018		France
CH	46			Suisse
FO	29			Iles Feroés*
DE	17			Allemagne
GL	5			Groenland
IS	3			Islande
AT	3			Autriche
LT	2			Lituanie
NL	2			Netherlands (Pays-Bas)
SM	1			San Marino*
GI	1			Gibraltar*
FK	1			Iles Falkland*
VA	1			Vatican*
BL	1			Saint Barthelemy
MC	1			Monaco
	1
IT	1			Italie


select * from demographie."GISCO_LAU_eurostat"  where cntr_code = 'IE' or cntr_code = 'UK'
-- Dooega#Dumha Éige	Dooega#Dumha Eige IE1303157074
select * from demographie.lau2_reference_dates_pop  where cntr_code = 'IE' and lau_label ilike '%Dumha%'

select g.name_asci, substring(g.name_asci from position('#' in g.name_asci)+1)  ,p.pop_2011, p.*
from demographie."GISCO_LAU_eurostat" g, demographie.lau2_reference_dates_pop p
where g.computed_gisco_id is null and g.pop_2011 is null
and  p.lau_label % substring(g.name_asci from position('#' in g.name_asci)+1)


select * from aires_urbaines au where fua_pop2019 is null
IE002L1	IE053

select * from "GISCO_LAU_eurostat" g where g.cntr_code = 'IE' and computed_fua_code nd 

---------------------------------------------
-- demographie des pays 
-- pays_population
---------------------------------------------

select distinct c.iso3 , c.pays , pm.country_name , pm.country_code , pm."2019"
from camps.camps3 c , demographie.population_monde pm 
where c.iso3 = pm.country_code 

select distinct iso3, pays from camps.camps3 c
where iso3 not in (select distinct country_code from demographie.population_monde)
-- UNK : Kosovo

-- Cas du Kosovo : on prend les données de natural Earth

select distinct c.iso3 , c.pays , w.adm0_a3_fr , w.name_fr , w.pop_year, w.pop_est,  pm."2019"
from 
camps.camps3 c left outer join demographie.ne_10m_admin_0_countries w on w.name_fr=c.pays or w.adm0_a3_fr=c.iso3
left join demographie.population_monde pm  on c.iso3 = pm.country_code 
where c.iso3 is not null
order by pays
-- where w.adm0_a3_fr=c.iso3 and c.iso3 = pm.country_code 

update  camps.camps3 c set pays_population = pm."2019"
from demographie.population_monde pm 
where c.iso3 = pm.country_code 
-- 651 

update  camps.camps3 c set pays_population = w.pop_est 
from demographie.ne_10m_admin_0_countries w 
where pays_population is null and (w.name_fr=c.pays or w.adm0_a3_fr=c.iso3)
-- 1 (kosovo)


update  camps.camps4 c set pays_population = pm."2019"
from demographie.population_monde pm 
where c.iso3 = pm.country_code 
-- 753 

update  camps.camps4 c set pays_population = w.pop_est 
from demographie.ne_10m_admin_0_countries w 
where pays_population is null and (w.name_fr=c.pays or w.adm0_a3_fr=c.iso3)
-- 1 (kosovo)

---------------------------
-- renseigner des iso3 et pays manquants dans la base : pas possible, ce sont des camps non  localisés.
---------------------------
select name, iso_n3, un_a3, adm0_a3_fr , name_fr from ne_10m_admin_0_countries

select w.adm0_a3_fr , w.name_fr, c.nom
from demographie.ne_10m_admin_0_countries w, camps.camps3 c
where c.iso3 is null and st_contains(w.geom, c.geom)
-- and st_intersects(w.geom, st_buffer(c.geom, 1000))
-- and st_contains(w.geom, c.geom)
-- marche pas car ces camps ne sont pas localisés.

select c.unique_id, w.adm0_a3_fr , w.name_fr, c.nom, c.iso3, c.pays, c.unique_id 
from demographie.ne_10m_admin_0_countries w, camps.camps3 c
where c.iso3 is not null and st_contains(w.geom, c.geom) and  w.adm0_a3_fr<>c.iso3

-- faire vérifier à Louis la position de ces camps en frontière
/*
 * ESB	Dhekelia	Xilofagou Police Station	CYP	Cyprus	67
ESB	Dhekelia	Xilotimpou Police Station	CYP	Cyprus	68
MAF	Saint-Martin	Saint-Martin	FRA	France	210
BLR	Biélorussie	PADVARIONI? BORDER GUARD STATION - TEMPORARY TENT CAMP	LTU	Lithuania	624
BLR	Biélorussie	ven?ioni? Border Guard Station - Temporary Tent Camp	LTU	Lithuania	625
BLR	Biélorussie	Tvere?iaus Border Guard Station - Temporary Tent Camp	LTU	Lithuania	627
FIN	Finlande	Tallin (North Police Station)	EST	Estonia	92
KOS	Kosovo	Magura/Lipjan/Lipljan, Reception Center for Foreigners	UNK	Kosovo	372
POL	Pologne	Gorlitz - JVA Gorlitz	DEU	Germany	224
ITA	Italie	Chiasso centro di registrazione	CHE	Switzerland	478
HRV	Croatie	PRINCIPOVAC TRC	SRB	Serbia	433
NCL	Nouvelle-Calédonie	Nouméa (Aéroport de - Nouvelle Calédonie)	FRA	France	196
*/
set search_path = demographie, camps, clc, natura2000, public;

select c.unique_id , c.nom, w.adm0_a3_fr as NaturalEarth_adm0 , w.name_fr as NaturalEarth_country, c.iso3, c.pays,  c.localisation_qualite , c.doublon 
from demographie.ne_10m_admin_0_countries w, camps.camps4 c
where c.iso3 is not null and st_contains(w.geom, c.geom) and  w.adm0_a3_fr<>c.iso3

select * from camps.camps4 c
where c.pays_population is  null

-------------------------------------------------------
-- Renseigner les communes (lorsque non renseignée)
-- camp_commune 
-------------------------------------------------------

alter table camps.camps3 add column point3857 geometry ;
update camps.camps3 set point3857 = st_setsrid(st_transform(geom, 3857),3857) where geom is not null;
-- 617

alter table camps.camps3 add column eurostat_computed_gisco_id text ;
alter table camps.camps3 add column eurostat_computed_city_code text ;
alter table camps.camps3 add column eurostat_computed_fua_code text ;
alter table camps.camps3 add column eurostat_nuts_code_2016 text ;
alter table camps.camps3 add column eurostat_nsi_code_2016 text ;
alter table camps.camps3 add column eurostat_name_ascii_2016 text ;
alter table camps.camps3 add column eurostat_pop_2019 text ;

select g.name_asci , g.nsi_code , g.nuts_code , c.pays , c.camp_commune , c.camp_code_postal , 
g.computed_gisco_id , g.computed_city_code , g.computed_fua_code , 
coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1))) as eurostat_pop_2019
from camps.camps3 c, "GISCO_LAU_eurostat" g 
where st_contains(g.geom, c.point3857)

update camps.camps3 c set 
eurostat_computed_gisco_id = g.nsi_code,
eurostat_computed_city_code = g.computed_city_code,
eurostat_computed_fua_code = g.computed_fua_code,
eurostat_nuts_code_2016 = g.nuts_code,
eurostat_nsi_code_2016 = g.nsi_code,
eurostat_name_ascii_2016 = g.name_asci,
eurostat_pop_2019 = coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))
from  "GISCO_LAU_eurostat" g 
where st_contains(g.geom, c.point3857)
-- 567

select  pays, count(*) as c from camps.camps3 
where eurostat_name_ascii_2016 is null and geom is not null
group by pays
order by c desc
-- 95

/*
Turkey	27
Bosnia and Herzegovina	8
Azerbaijan	2
Belarus	2
Georgia	1
France	1
Montenegro	1
 */

update camps.camps3 c set 
eurostat_computed_gisco_id = g.nsi_code,
eurostat_computed_city_code = g.computed_city_code,
eurostat_computed_fua_code = g.computed_fua_code,
eurostat_nuts_code_2016 = g.nuts_code,
eurostat_nsi_code_2016 = g.nsi_code,
eurostat_name_ascii_2016 = g.name_asci,
eurostat_pop_2019 = coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))
from  "GISCO_LAU_eurostat" g 
where eurostat_name_ascii_2016 is null and st_intersects(g.geom, st_buffer(c.point3857, 1000))  


select * from camps.camps3 
where eurostat_name_ascii_2016 is null and geom is not null
and pays = 'France'
-- Nouméa (Aéroport de - Nouvelle Calédonie) pour n° 196

select count(*) from camps.camps3 
where camp_commune is null and geom is not null
-- 289 
update camps.camps3 set camp_commune = eurostat_name_ascii_2016 where camp_commune is null and eurostat_name_ascii_2016 is not null
-- 266
comment on column camps.camps3.camp_commune is 'camp_commune a été complété avec la valeur de eurostat_name_ascii_2016 quand elle n''était pas renseignée par Louis, le 17 mars 2022';

-------------------------------------------------------
-- Renseigner ville_proche_nom : prendre le nom de la city ou fua sinon
-- Renseigner ville_proche_population : prendre la population de la city ou de la fua si celle-ci est renseignée
-------------------------------------------------------

alter table camps.camps3 add column distance_ville_proche float ;
-- 0 si dans la grande ville (catégorie C des aires_urbaines)
-- km sinon du camps au coeur de la city la plus proche

select c.nom, camp_commune , au.urau_name, au.city_pop2019 ,
case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end
from camps.camps3 c, demographie.aires_urbaines au 
where au.urau_catg = 'C' and eurostat_computed_city_code is not null and eurostat_computed_city_code = au.urau_code
 
update camps.camps3 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population = au.city_pop2019,
distance_ville_proche = 0
from demographie.aires_urbaines au 
where au.urau_catg = 'C' and eurostat_computed_city_code is not null and eurostat_computed_city_code = au.urau_code
-- 172


select c.nom, camp_commune , au.urau_name, au.fua_pop2019 ,
case when position('FUA of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 8) end
from camps.camps3 c, demographie.aires_urbaines au 
where c.distance_ville_proche is null and au.urau_catg = 'F' and eurostat_computed_fua_code is not null and eurostat_computed_fua_code = au.urau_code
 
-- FUA of the Greater City of Paris
update camps.camps3 c 
set ville_proche_nom = case when position('FUA of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 8) end,
ville_proche_population = au.fua_pop2019
from demographie.aires_urbaines au 
where ville_proche_population is null and au.urau_catg = 'F' and eurostat_computed_fua_code is not null and eurostat_computed_fua_code = au.urau_code
-- 135 / 73


select  c.unique_id , c.nom, camp_commune , au.urau_code, au.urau_name, au.urau_catg, nuts3_2016, nuts3_2021, round(st_distance(c.point3857, au.geom)/1000) as d
from camps.camps3 c , demographie.centres_aires_urbaines au ,
(select  c.unique_id , min(st_distance(c.point3857, au.geom)) as dmin
from camps.camps3 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C'
group by c.unique_id) as k 
where st_distance(c.point3857, au.geom) = k.dmin and c.unique_id = k.unique_id
-- 617

select  c.unique_id , min(st_distance(c.point3857, au.geom))
from camps.camps3 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C'
group by c.unique_id
-- 662

alter table camps.camps3 add column eurostat_nuts_code_2016_level3 text ;
alter table camps.camps3 add column eurostat_nuts_code_2021_level3 text ;

update camps.camps3 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
distance_ville_proche = round(st_distance(c.point3857, au.geom)/1000),
eurostat_nuts_code_2016_level3 = au.nuts3_2016 ,
eurostat_nuts_code_2021_level3 = au.nuts3_2021
from 
 demographie.centres_aires_urbaines au ,
(select  c.unique_id , min(st_distance(c.point3857, au.geom)) as dmin
from camps.camps3 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C'
group by c.unique_id) as k 
where st_distance(c.point3857, au.geom) = k.dmin and c.unique_id = k.unique_id
-- 617


select * from  camps.camps3 
where ville_proche_nom is not null and ville_proche_population is null
and pays = 'Italy'

/*
-- il faut renseigner la pop avec la population du NUTS3 associé à la ville la plus proche
-- eurostat_nuts_code_2016_level3 
-- exemple : Lampedusa - Contrada Imbriacola (Agrigento)  est à 215 km de milan (MT001)
select  c.unique_id , min(st_distance(c.point3857, au.geom))
from camps.camps3 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C' and ville_proche_nom is null 
group by c.unique_id
*/
-- Non finalement, on remplace par la population de la commune quand le camp n'est ni dans une FUA ni une City 
update camps.camps3 c set ville_proche_population = eurostat_pop_2019 
where eurostat_computed_city_code is null and eurostat_computed_fua_code is  null and eurostat_pop_2019::int <> -1

select unique_id, pays, camp_commune, eurostat_computed_gisco_id , eurostat_name_ascii_2016 , eurostat_pop_2019 , distance_ville_proche, ville_proche_nom, ville_proche_population, eurostat_computed_city_code, eurostat_computed_fua_code
from  camps.camps3 
where ville_proche_nom is not null and ville_proche_population is null and eurostat_computed_gisco_id is not null 
and eurostat_pop_2019::int <> -1
-- 132 entités
except (
select unique_id, pays, camp_commune, eurostat_computed_gisco_id , eurostat_name_ascii_2016 , eurostat_pop_2019 , distance_ville_proche, ville_proche_nom, ville_proche_population, eurostat_computed_city_code, eurostat_computed_fua_code
from  camps.camps3 
where  eurostat_computed_city_code is null and eurostat_computed_fua_code is  null and eurostat_pop_2019::int <> -1)
-- 128 entités


select * from demographie.aires_urbaines au 
where au.urau_code in ('HU001C1','FR030L1', 'FR028L1', 'FR030L1', 'HU001L2', 'IE001L1', 'IE002L1', 'IE001L1', 'IE001L1', 'IE001L1', 'IE003L1', 'NO001L1')

/*
HU001L2 1245672
HU001C1 
FR028C1	FR028L1
FR028L1
FR521L1
FR521L1
FR030L1
NO001L1
FR030L1
*/

/*
set ville_proche_nom = case when position('FUA of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 8) end,
ville_proche_population = au.fua_pop2019
from camps.camps3 c, "GISCO_LAU_eurostat" is
where c.eurostat_computed_gisco_id 
*/

alter table camps.camps3 alter column eurostat_pop_2019 type int using eurostat_pop_2019::int;
update camps.camps3 set eurostat_pop_2019 = null where eurostat_pop_2019= -1

---------------------------------
-- renseigner zone (ZR, ZU, ZIC, B)
-- Utiliser la base degurba d'Eurostat
----------------------------------

select  zone, count(*) from camps.camps3 group by zone
ZR	32
B	11
ZU	6
ZIC	12
	601
	
alter table camps.camps3 add column degurba int;

update camps.camps3 c set degurba = g.dgurba 
from "DGURBA_2018_01M" g
where st_contains(g.geom, st_setsrid(st_transform(c.geom, 4258), 4258));
-- 541

/*
update camps.camps3 c set degurba = g.dgurba 
from "DGURBA_2018_01M" g
where degurba is null and st_intersects(g.geom, st_buffer(st_setsrid(st_transform(c.geom, 4258), 4258), 1000));
 */

select k.degurba, count(*) 
from 
(select pays, degurba, zone, case when zone='ZR' then 3 else case when zone='B' or zone='ZIC' then 2 else 1 end end as test 
from camps.camps3 where zone is not null) as k 
where degurba is not null  and k.degurba<>k.test 
group by degurba


select pays, * from camps3
where degurba is null and geom is not null
order by pays

comment on table  "DGURBA_2018_01M" is 'Degré d''urbanisation des unités LAU : 1 -ville) - 2 (banlieue) - 3 (rural)';
comment on column camps.camps3.degurba is 'Degré d''urbanisation des unités LAU : 1 -ville) - 2 (banlieue) - 3 (rural) - croisement avec la base Eurostat degurba EPSG 4258';

-------------------------------
-- rétablir l'id de unique_id 
-------------------------------

select c2.id, c2.unique_id, c3.unique_id , c2.nom , c3.nom
from camps2 c2 , camps3 c3
where c2.unique_id = c3.unique_id;

alter table camps3 alter column id type text;

update camps3 c3 set id = c2.id
from camps2 c2
where c2.unique_id = c3.unique_id;
-- 662

-------------------------------
-- croiser avec CLC
-------------------------------

select * from clc.u2018_clc2018_v2020_20u1 ucvu limit 6


alter table camps3 add column point3035 geometry;
update camps3 set point3035 = st_setsrid(st_transform(geom, 3035), 3035);
CREATE INDEX sidx_camps3_point3035 ON camps.camps3 USING gist (point3035);

alter table camps3 add column CLC_majoritaire_3 varchar(3);
alter table camps3 add column distance_124_aeroport float;
alter table camps3 add column distance_13_mines_decharges_chantiers float;
alter table camps3 add column distance_123_zones_portuaires float;
alter table camps3 add column distance_122_reseaux_routiers float;
alter table camps3 add column distance_24_zones_agricoles_heterogenes float;
alter table camps3 add column distance_41_zones_humides_interieures float;

/*
CLC_majoritaire_1	catégorie CLC de niveau 1
CLC_majoritaire_2	catégorie CLC de niveau 2
CLC_majoritaire_3	catégorie CLC de niveau 3
distance_124_aéroport	nombre
distance_13_mines_décharges_chantiers	nombre
distance_123_zones_portuaires	nombre
distance_122_réseaux_routiers	nombre
distance_24_zones_agricoles_hétérogènes	nombre
distance_41_zones_humides_intérieures	nombre
*/

select * from camps3 c, clc.u2018_clc2018_v2020_20u1 clc
where st_contains(clc.shape, c.point3035)

update camps.camps3 c set CLC_majoritaire_3 = clc.code_18
from clc.u2018_clc2018_v2020_20u1 clc
where st_contains(clc.shape, c.point3035)
-- 569

select * from camps.camps3 
where CLC_majoritaire_3 is null and geom is not null 
 
update camps.camps3  c set distance_124_aeroport = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps3 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 = '124'
group by c.unique_id
) as k where k.unique_id = c.unique_id
-- 662

update camps.camps3  c set distance_13_mines_decharges_chantiers = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps3 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '13%'
group by c.unique_id
) as k where k.unique_id = c.unique_id
-- 39 s

update camps.camps3  c set distance_123_zones_portuaires = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps3 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '123'
group by c.unique_id
) as k where k.unique_id = c.unique_id
-- 5s

update camps.camps3  c set distance_122_reseaux_routiers = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps3 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '122'
group by c.unique_id
) as k where k.unique_id = c.unique_id
-- 24 s

update camps.camps3  c set distance_24_zones_agricoles_heterogenes = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps3 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '24%'
group by c.unique_id
) as k where k.unique_id = c.unique_id
-- 26 min

update camps.camps3  c set distance_41_zones_humides_interieures = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps3 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '41%'
group by c.unique_id
) as k where k.unique_id = c.unique_id
-- 3 min

update camps3 set camp_adresse = 'Aéroport de Dinart Pleurtuit - Saint Malo - Locaux des Douanes (Nuit: Hôtel Europe, 11 bd de la République 35400 Saint Malo)'
where unique_id = 154
-- 1

select unique_id, regexp_replace(sources, '\n', ' - ') from camps3 where unique_id = 435
select unique_id, regexp_replace(sources, '\n', ' - ') from camps3 where unique_id = 583
select unique_id, sources from camps3 where unique_id = 583
 -- https://www.infomigrants.net/en/post/34401/no-one-will-answer-our-questions--migrants-in-lithuanian-camps-wait-in-uncertainty - Plat?kyt?, D. « Migrants kept in inhuman and degrading conditions in Lithuania, says watchdog », Lithuanian Radio and Television, 07 october 2021, https://www.lrt.lt/en/news-in-english/19/1515856/migrants-kept-in-inhuman-and-degrading-conditions-in-lithuania-says-watchdog - News Front, Illegal migrants in Lithuania complain of hunger and dampness in refugee camps, 30/08/2021, https://en.news-front.info/2021/08/30/illegal-migrants-in-lithuania-complain-of-hunger-and-dampness-in-refugee-camps/

-- http://bosnian.iom.acsitefactory.com/situation-reports - https://help.unhcr.org/bosniaandherzegovina/where-to-seek-help/reception-centres/ - https://bih.iom.int/sites/g/files/tmzbdl1076/files/inline-files/LIPAoctober20.pdf

update camps3 set sources = regexp_replace(sources, '\n', ' - ', 'g');

-- https://asylumineurope.org/reports/country/serbia/reception-conditions/housing/types-accommodation/
-- https://kirs.gov.rs/eng/asylum/asylum-and-reception-centers

-- https://asylumineurope.org/reports/country/serbia/reception-conditions/housing/types-accommodation/ - https://kirs.gov.rs/eng/asylum/asylum-and-reception-centers

---------------------------------------------------------
-- Calculer et renseigner les distances aux aménités que l'on trouve dans OSM
-- Analyse sur le Danemark uniquement
---------------------------------------------------------

-- ADMINISTRATIF
select count(*) from public.osm_point_denmark where amenity='townhall'; --24
select count(*) from public.osm_point_denmark where office='lawyer'; --46


-- SANTE
select count(*) from public.osm_point_denmark where amenity='hospital'; --81
select count(*) from public.osm_point_denmark where amenity='pharmacy'; --481
select count(*) from public.osm_point_denmark where shop='chemist'; --379
select count(*) from public.osm_point_denmark where shop='medical_supply'; --0
select count(*) from public.osm_point_denmark where amenity='clinic'; --164
select count(*) from public.osm_point_denmark where amenity='doctors'; --154
select count(*) from public.osm_point_denmark where amenity='dentist'; --133

-- TRANSPORTS
select count(*) from public.osm_point_denmark where amenity='atm'; --544
select count(*) from public.osm_point_denmark where highway='bus_stop'; --13650
select count(*) from public.osm_point_denmark where public_transport='platform'; --11683
select count(*) from public.osm_point_denmark where amenity='bus_station'; --142
select count(*) from public.osm_point_denmark where railway='platform'; --0
-- train
select count(*) from public.osm_point_denmark where railway='station' or railway='halt'; --341 + 253
select count(*) from public.osm_point_denmark where building='train_station' ; --0
select count(*) from public.osm_point_denmark where public_transport='station' ; --746

-- EAU
select count(*) from public.osm_point_denmark where amenity='water_point' ; --48
select count(*) from public.osm_point_denmark where waterway='water_point' ; --0
select count(*) from public.osm_point_denmark where amenity='drinking_water' ; --803
select count(*) from public.osm_point_denmark where man_made='water_tap' ; --14


-- healthcare=hospital	
-- 	healthcare=dentist

--mairie_distance

select unique_id , nom , iso3, distance_ville_proche, mairie_distance, atm_distance, hopital_distance,pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, avocat_hors_camp_distance_km --, replace(mairie_distance, ',', '.') 
from camps.camps4 c 
where  geom is not null and iso3 in ('ITA', 'GRC', 'DNK', 'BIH')
order by iso3;
-- and mairie_distance is not null;
-- where mairie_distance is not null;
-- where hopital_distance is not null;

alter table camps.camps4 alter column mairie_distance type float using replace(mairie_distance, ',', '.')::double precision;
update camps.camps4  c set mairie_distance = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point_denmark osm , camps.camps4  c
where amenity='townhall' and c.iso3 = 'DNK' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id;

-- Bosnie
update camps.camps4  c set mairie_distance = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps4  c
where amenity='townhall' and c.iso3 = 'BIH' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id and c.mairie_distance is null;

update camps.camps4 c set mairie_distance = replace(lcb.mairie_distance, ',', '.')::double precision
from lfernier_carto_bdd lcb
where lcb.unique_id = c.unique_id and c.iso3 = 'BIH';

-- atm
alter table camps.camps4 alter column atm_distance type float using replace(atm_distance, ',', '.')::double precision;
update camps.camps4  c set atm_distance = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point_denmark osm , camps.camps4  c
where amenity='atm' and c.iso3 = 'DNK' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id;

-- Bosnie
update camps.camps4  c set atm_distance = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps4  c
where amenity='atm' and c.iso3 = 'BIH' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id and atm_distance is null ;

-- hopital_distance
alter table camps.camps4 alter column hopital_distance type float using replace(hopital_distance, ',', '.')::double precision;
update camps.camps4  c set hopital_distance = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point_denmark osm , camps.camps4  c
where amenity='hospital' and c.iso3 = 'DNK' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id;

-- Bosnie
update camps.camps4  c set hopital_distance = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps4  c
where amenity='hospital' and c.iso3 = 'BIH' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id and hopital_distance is null ;

-- pharmacie_distance
alter table camps.camps4 alter column pharmacie_distance type float using replace(pharmacie_distance, ',', '.')::double precision;
update camps.camps4  c set pharmacie_distance = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point_denmark osm , camps.camps4  c
where (amenity='pharmacy' or shop in ('chemist', 'medical_supply') ) and c.iso3 = 'DNK' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id;

select nom , iso3, pharmacie_distance from lfernier_carto_bdd lcb where pharmacie_distance is not null;
update camps.camps4 c set pharmacie_distance = replace(lcb.pharmacie_distance, ',', '.')::double precision
from lfernier_carto_bdd lcb
where lcb.unique_id = c.unique_id ;
select nom , iso3, pharmacie_distance from camps.camps4 c where pharmacie_distance is not null;


-- Bosnie
update camps.camps4  c set pharmacie_distance = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps4  c
where (amenity='pharmacy' or shop in ('chemist', 'medical_supply') ) and c.iso3 = 'BIH' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id and pharmacie_distance is null ;

-- arret_bus_distance_km
alter table camps.camps4 alter column arret_bus_distance_km type float using replace(arret_bus_distance_km, ',', '.')::double precision;
update camps.camps4  c set arret_bus_distance_km = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point_denmark osm , camps.camps4  c
where (amenity='bus_station' or highway='bus_stop' or public_transport='platform' or  railway='platform' ) and c.iso3 = 'DNK' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id;


-- Bosnie
update camps.camps4  c set arret_bus_distance_km = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps4  c
where (amenity='bus_station' or highway='bus_stop' or public_transport='platform' or  railway='platform' )  and c.iso3 = 'BIH' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id and arret_bus_distance_km is null ;

-- gare_distance_km
alter table camps.camps4 alter column gare_distance_km type float using replace(gare_distance_km, ',', '.')::double precision;
update camps.camps4  c set gare_distance_km = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point_denmark osm , camps.camps4  c
where (railway='station' or railway='halt' or building='train_station' or  public_transport='station' ) and c.iso3 = 'DNK' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id;

-- Bosnie
update camps.camps4  c set gare_distance_km = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps4  c
where (railway='station' or railway='halt' or building='train_station' or  public_transport='station' )  and c.iso3 = 'BIH' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id and gare_distance_km is null ;


-- medecin_clinique_hors_camp_distance_km
alter table camps.camps4 alter column medecin_clinique_hors_camp_distance_km type float using replace(medecin_clinique_hors_camp_distance_km, ',', '.')::double precision;
update camps.camps4  c set medecin_clinique_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point_denmark osm , camps.camps4  c
where (amenity in ('clinic', 'doctors') ) and c.iso3 = 'DNK' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id;

-- Bosnie
update camps.camps4  c set medecin_clinique_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps4  c
where (amenity in ('clinic', 'doctors') )  and c.iso3 = 'BIH' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id and medecin_clinique_hors_camp_distance_km is null ;

-- dentiste_hors_camp_distance_km
alter table camps.camps4 alter column dentiste_hors_camp_distance_km type float using replace(dentiste_hors_camp_distance_km, ',', '.')::double precision;
update camps.camps4  c set dentiste_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point_denmark osm , camps.camps4  c
where (amenity = 'dentist' ) and c.iso3 = 'DNK' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id;

-- Bosnie
update camps.camps4  c set dentiste_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps4  c
where (amenity = 'dentist' )  and c.iso3 = 'BIH' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id and dentiste_hors_camp_distance_km is null ;

-- avocat_hors_camp_distance_km
alter table camps.camps4 alter column avocat_hors_camp_distance_km type float using replace(avocat_hors_camp_distance_km, ',', '.')::double precision;
update camps.camps4  c set avocat_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point_denmark osm , camps.camps4  c
where (office = 'lawyer' ) and c.iso3 = 'DNK' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id;

-- Bosnie
update camps.camps4  c set avocat_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps4  c
where (office = 'lawyer' )  and c.iso3 = 'BIH' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id and avocat_hors_camp_distance_km is null ;

------------------------------------------------------------------------------------------------------------
---- A finir pour le 9 nov 2022
-- Analyse croisée avec OSM
------------------------------------------------------------------------------------------------------------

/*
Pour poste : post_box / post_office
Pour école : school / college
Centres sociaux : community_centre / social_centre
Ensemble (garde de petits) : kindergarten / nursery / nursing_home
''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'',  ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe''
Le reste à part pour chaque item : 
- bureau_de_change 
- internet_cafe  
- language_school 

Si cela est trop chronophage, je dirais que les moins prioritaires (à enlever si besoin) sont : 
- Ensemble (garde de petits) : kindergarten / nursery / nursing_home
- internet_cafe  
*/

select distinct building from osm.denmark.planet_osm_polygon;
-- hospital;yes, healthcare, hospital, clinic
-- townhall
-- school, college, kindergarten, childcare
-- ''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare''

select distinct amenity from osm.denmark.planet_osm_polygon where  amenity like '%townhall%';
--townhall ok
--school, college, childcare, kindergarten
--post_office
--internet_cafe
--clinic, hospital ok
-- ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe''

-- Import de la belgique
export PGPASSWORD="xxxxxxx"
nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/belgium-latest.osm.pbf > out.txt &
-- 308 s 

create schema belgium;
alter table planet_osm_point set schema belgium;
alter table planet_osm_line set schema belgium;
alter table planet_osm_polygon set schema belgium;
alter table planet_osm_roads set schema belgium;


create schema belgium;
alter table planet_osm_point set schema belgium;
alter table planet_osm_line set schema belgium;
alter table planet_osm_polygon set schema belgium;
alter table planet_osm_roads set schema belgium;

-- Import des pays bas
export PGPASSWORD="xxxxxxx"
nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/netherlands-latest.osm.pbf > out.txt &
-- 1473 s 

create schema netherlands;
alter table planet_osm_point set schema netherlands;
alter table planet_osm_line set schema netherlands;
alter table planet_osm_polygon set schema netherlands;
alter table planet_osm_roads set schema netherlands;

-- use dblink to query osm.bosnie puis osm.denmark

-- amenity is not null or public_transport is not null or office is not null OR railway is not null or highway is not null or power is not null or man_made is not null or landuse is not null or railway is not null or aeroway is not null or leisure is not null or military is not null
create or replace VIEW  public.osm_point AS
            SELECT osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.denmark.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.belgium.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )			
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.bosnie.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.netherlands.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.france.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
				')
            AS t1(osm_id int8, way geometry, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

drop VIEW  public.osm_point;     

select count(osm_id) from public.osm_point;
-- 200 787 en 2022 sans la France
-- 724 739 en 2024 avec la France

select count(*) from public.osm_point where amenity='townhall' or building = 'townhall';--17288

select c.unique_id , c.nom , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps5  c
where c.unique_id = 129 and (amenity='townhall' or building = 'townhall')  and c.point3857 is not null
group by c.unique_id , c.nom;
-- 129	Palaiseau	525.3589981989759

select c.unique_id , c.nom , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_polygon osm , camps.camps5  c
where c.unique_id = 129 and (amenity='townhall' or building = 'townhall')  and c.point3857 is not null
group by c.unique_id , c.nom;
-- SQL Error [22P02]: ERREUR: syntaxe en entrée invalide pour l'entier : « 3 629 »
select count(name) from public.osm_polygon;
select count(osm_id) from public.osm_polygon where amenity='townhall' or building = 'townhall';--771
select * from public.osm_polygon where osm_id > 3629;
select * from public.osm_polygon where osm_id='3629 ';
-- syntaxe en entrée invalide pour l'entier : « 3 629

-- landuse,  man_made, industrial, admin_level, boundary, name, population, shop, waterway,
drop VIEW  public.osm_polygon;     

create or replace VIEW  public.osm_polygon AS
            SELECT osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.denmark.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
						UNION (
							select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.bosnie.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.belgium.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.netherlands.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.france.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						
				')
            AS t1(osm_id int8, way geometry, name text, admin_level int, population int8, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

drop VIEW  public.osm_polygon           
select * from public.osm_polygon;
select count(osm_id) from public.osm_polygon;
-- 64 584 en 2022 sans la France
-- 285 927 en 2024 avec la France

/*
drop view public.osm_polygon_france
create or replace VIEW  public.osm_polygon_france AS
            SELECT osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
							'select new_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.france.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
			')
            AS t1(osm_id int8, way geometry, name text, admin_level int, population int8, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 


select count(osm_id) from public.osm_polygon_france;

-- select count(new_id)  --221 452
select  new_id, population , way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
from france.planet_osm_polygon a 
where amenity in ('atm','bus_station','clinic','dentist','doctors','drinking_water','hospital','pharmacy','recycling','townhall','water_point', 'post_box', 'post_office', 'school', 'childcare', 'kindergarten', 'college', 'community_centre',  'post_office', 'clinic',  'internet_cafe')
									or boundary in ('administrative','hazard','national_park','protected_area')
									or aeroway='aerodrome'
									or building in ('train_station','healthcare', 'hospital', 'clinic', 'townhall', 'school', 'college', 'kindergarten', 'childcare')
									or landuse='quarry'
									or highway in ('bus_stop','motorway','trunk')
									or leisure in ('nature_reserve', 'shooting_ground')
									or man_made in ('wastewater_plant', 'man_made=water_tap')
									or military='danger_area'
									or office='lawyer'
									or power='line'
									or public_transport in ('platform', 'station')
									or railway in ('halt','platform','rail','station')
									or shop in ('chemist', 'medical_supply')
									or waterway='water_point'
									or population is not null and population like '3 629%'; --221 452
-- 221 452 environ
select  new_id, replace(population, ' ', '') , way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
from france.planet_osm_polygon a 
where population is not null and population  like '3 629%';									
--mairie_distance
-- La Bazoge 3 629 / new_id = 35430648
*/

select unique_id , nom , iso3, distance_ville_proche, mairie_distance, atm_distance, hopital_distance,pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, avocat_hors_camp_distance_km --, replace(mairie_distance, ',', '.') 
from camps.camps4 c 
where  geom is not null and iso3 in ('ITA', 'GRC', 'DNK', 'BIH')
order by iso3;
-- and mairie_distance is not null;
-- where mairie_distance is not null;
-- where hopital_distance is not null;

alter table camps.camps4 alter column mairie_distance type float using replace(mairie_distance, ',', '.')::double precision;


update camps.camps4  c set mairie_distance = round((dkm/ 1000.0)::numeric, 1)
from
(select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_point osm , camps.camps4  c
where amenity='townhall' and c.iso3 = 'BIH' and c.point3857 is not null
group by c.unique_id) as k 
where k.unique_id = c.unique_id and c.mairie_distance is null;

alter table camps.camps4 add column mairie_distance_new float;
update camps.camps4  c set mairie_distance_new = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (amenity='townhall' or building = 'townhall') and c.iso3 = 'BIH' and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (amenity='townhall' or building = 'townhall' ) and c.iso3 = 'BIH' and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and c.mairie_distance_new is null;

select c.unique_id ,c.nom, mairie_distance, mairie_distance_new from camps.camps4 c where c.iso3 = 'BIH' and c.point3857 is not null
/*
 * 34	1680.7705515059683
589	28777.420969710747
611	9953.920696310492
612	16362.630776132479
613	1675.3484585417316
614	5731.913836365251
615	4176.957014701969
616	1409.0611511039147
734	10707.877856709321
759	6726.791715786358*/
 */
 
-- validé par mail par Louis le 14/11/2022

alter table camps.camps4 drop column mairie_distance_new;

update camps.camps4  c set mairie_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (amenity='townhall' or building = 'townhall') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (amenity='townhall' or building = 'townhall' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and c.mairie_distance is null;
-- 39

update camps.camps4 c set mairie_distance = replace(lcb.mairie_distance, ',', '.')::double precision
from camps.lfernier_carto_bdd lcb
where lcb.unique_id = c.unique_id and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and lcb.mairie_distance is not null; --11

-- atm
alter table camps.camps4 alter column atm_distance type float using replace(atm_distance, ',', '.')::double precision;

update camps.camps4  c set atm_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (amenity='atm') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (amenity='atm' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 44



-- hopital_distance
alter table camps.camps4 alter column hopital_distance type float using replace(hopital_distance, ',', '.')::double precision;

update camps.camps4  c set hopital_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (amenity in ('hospital', 'clinic') or building in ('hospital', 'clinic')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (amenity in ('hospital', 'clinic') or building in ('hospital', 'clinic')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 44

-- pharmacie_distance
alter table camps.camps4 alter column pharmacie_distance type float using replace(pharmacie_distance, ',', '.')::double precision;

update camps.camps4  c set pharmacie_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (amenity in ('pharmacy') or shop in ('chemist', 'medical_supply')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (amenity in ('pharmacy') or shop in ('chemist', 'medical_supply')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 44


select nom , iso3, pharmacie_distance from lfernier_carto_bdd lcb where pharmacie_distance is not null;
update camps.camps4 c set pharmacie_distance = replace(lcb.pharmacie_distance, ',', '.')::double precision
from lfernier_carto_bdd lcb
where lcb.unique_id = c.unique_id and lcb.pharmacie_distance is not null;

select nom , iso3, pharmacie_distance from camps.camps4 c where pharmacie_distance is not null;


-- arret_bus_distance_km
alter table camps.camps4 alter column arret_bus_distance_km type float using replace(arret_bus_distance_km, ',', '.')::double precision;


update camps.camps4  c set arret_bus_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (amenity in ('bus_station') or highway='bus_stop' or public_transport='platform' or  railway='platform') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (amenity in ('bus_station') or highway='bus_stop' or public_transport='platform' or  railway='platform') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
--44


-- gare_distance_km
alter table camps.camps4 alter column gare_distance_km type float using replace(gare_distance_km, ',', '.')::double precision;

update camps.camps4  c set gare_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (railway='station' or railway='halt' or building='train_station' or  public_transport='station' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (railway='station' or railway='halt' or building='train_station' or  public_transport='station' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
--44

-- medecin_clinique_hors_camp_distance_km
alter table camps.camps4 alter column medecin_clinique_hors_camp_distance_km type float using replace(medecin_clinique_hors_camp_distance_km, ',', '.')::double precision;

update camps.camps4  c set medecin_clinique_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (amenity in ('clinic', 'doctors') or building in ('clinic', 'healthcare')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (amenity in ('clinic', 'doctors') or building in ('clinic', 'healthcare')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;


-- dentiste_hors_camp_distance_km
alter table camps.camps4 alter column dentiste_hors_camp_distance_km type float using replace(dentiste_hors_camp_distance_km, ',', '.')::double precision;
update camps.camps4  c set dentiste_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (amenity in ('dentist') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (amenity in ('dentist') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;


-- avocat_hors_camp_distance_km
alter table camps.camps4 alter column avocat_hors_camp_distance_km type float using replace(avocat_hors_camp_distance_km, ',', '.')::double precision;

update camps.camps4  c set avocat_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (office = 'lawyer' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (office = 'lawyer') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 44

-- poste_hors_camp_distance_km
-- Pour poste : post_box / post_office
alter table camps.camps4 add column poste_hors_camp_distance_km float;

update camps.camps4  c set poste_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (amenity in ('post_box', 'post_office') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (amenity in ('post_box', 'post_office')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;

-- Pour école : school / college
alter table camps.camps4 add column ecole_hors_camp_distance_km float;
update camps.camps4  c set ecole_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps4  c
	where (amenity in ('school', 'college') or building in ('school', 'college') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps4  c
	where (amenity in ('school', 'college') or building in ('school', 'college')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 44

select c.unique_id , c.nom, c.ecole_hors_camp_distance_km, poste_hors_camp_distance_km, avocat_hors_camp_distance_km, dentiste_hors_camp_distance_km, medecin_clinique_hors_camp_distance_km, gare_distance_km, arret_bus_distance_km , atm_distance , pharmacie_distance, hopital_distance , mairie_distance 
from camps.camps4  c
where  c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL') and c.point3857 is not null;
-- Pour école : school / college
-- Centres sociaux : community_centre / social_centre
-- Ensemble (garde de petits) : kindergarten / nursery / nursing_home


---------------------------------------------------------------------------------------------
-- ajout France
-- le 26/02/2024
---------------------------------------------------------------------------------------------
Reste 89G
df -H
	Sys. de fichiers                 Taille Utilisé Dispo Uti% Monté sur
	udev                                17G       0   17G   0% /dev
	tmpfs                              3,4G    840k  3,4G   1% /run
	/dev/mapper/cchumvmtmp1--vg-root    94G     59G   32G  66% /
	tmpfs                               17G    1,2M   17G   1% /dev/shm
	tmpfs                              5,3M    4,1k  5,3M   1% /run/lock
	tmpfs                               17G       0   17G   0% /sys/fs/cgroup
	/dev/vda1                          518M    127M  365M  26% /boot
	/dev/mapper/externe-data           633G    513G   89G  86% /data
	tmpfs                              3,4G       0  3,4G   0% /run/user/41412
	tmpfs                              3,4G       0  3,4G   0% /run/user/1005

http://download.geofabrik.de/europe/france/
Toutes les régions (22 en métropole + 5 DOM): -240225.osm.pbf
alsace
aquitaine
...



cd /data/osm
wget http://download.geofabrik.de/europe/france-240225.osm.pbf
(4.2G)



osm2pgsql -d osm -U postgres -W -c france-240225.osm.pbf
-- a faire
sudo -u postgres psql -d osm -c "create schema france; alter table xx set schema yyy;"

export PGPASSWORD="******" --ne marche plus depuis postgres 11
sudo -u postgres psql -d osm -c "create schema france; "
-- après l'import, move les données de public vers le schema france
sudo -u postgres psql -d osm -c "alter table planet_osm_line set schema france;"
sudo -u postgres psql -d osm -c " alter table planet_osm_point set schema france;"
sudo -u postgres psql -d osm -c " alter table planet_osm_polygon set schema france;"
sudo -u postgres psql -d osm -c " alter table planet_osm_roads set schema france;"


export PGPASSWORD="******"
nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/france-240225.osm.pbf > out.txt &

plumegeo@cchum-kvm-mapuce:~$ sudo pg_lsclusters
[sudo] Mot de passe de plumegeo :
Ver Cluster Port Status Owner    Data directory              Log file
11  main    5432 online postgres /data/postgres/11/data      /var/log/postgresql/postgresql-11-main.log
14  main    5433 online postgres /data/postgres/14/data      /var/log/postgresql/postgresql-14-main.log
15  main    5434 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

-- utiliser le fichier pgpass (connecté en tant que plumegeo)
-- https://docs.postgresql.fr/10/libpq-pgpass.html
-- edition dans le répertoire home de plumegeo
chmod 0600 ~/.pgpass
vi ~/.pgpass
localhost:5432:osm:postgres:******

sudo -u postgres psql -d osm -c "select count(*) from nantes.planet_osm_roads; "
-- demande encore le mot de passe (car pas de réperoire /home/postgres)

 psql -U postgres -d osm -c "select count(*) from nantes.planet_osm_roads; "
 -- marche
 
nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/france-240225.osm.pbf > out.txt &
-- lancé le 26 février 2024 à 12h35
--  ps -ef | grep osm2pgsql

-- taille de la france
plumegeo@cchum-kvm-mapuce:/data/osm$ du -sk *
4426464 france-240225.osm.pbf


--- out.txt
/*Processing: Node(480458k 658.2k/s) Way(67843k 18.90k/s) Relation(921230 327.61/s
)  parse time: 7132s
Node stats: total(480458045), max(11663763935) in 730s
Way stats: total(67843406), max(1254707509) in 3590s
Relation stats: total(921745), max(17268501) in 2812s
Committing transaction for planet_osm_point
Committing transaction for planet_osm_line
Committing transaction for planet_osm_polygon
Committing transaction for planet_osm_roads

Creating geometry index on planet_osm_roads
Creating indexes on planet_osm_roads finished
All indexes on planet_osm_roads created in 48s
Completed planet_osm_roads
Copying planet_osm_point to cluster by geometry finished
Creating geometry index on planet_osm_point
Copying planet_osm_line to cluster by geometry finished
Creating geometry index on planet_osm_line
Creating indexes on planet_osm_point finished
All indexes on planet_osm_point created in 339s
Completed planet_osm_point
Creating indexes on planet_osm_line finished
All indexes on planet_osm_line created in 379s
Completed planet_osm_line
Copying planet_osm_polygon to cluster by geometry finished
Creating geometry index on planet_osm_polygon
Creating indexes on planet_osm_polygon finished
All indexes on planet_osm_polygon created in 1807s
Completed planet_osm_polygon
node cache: stored: 64342623(13.39%), storage efficiency: 61.36% (dense blocks: 4906, sparse nodes: 32333825), hit rate: 19.02
%

Osm2pgsql took 12612 s overall

*
*
**/
--- 

-- après l'import, move les données de public vers le schema france
psql -U postgres -d osm -c "alter table planet_osm_line set schema france;"
psql -U postgres -d osm -c " alter table planet_osm_point set schema france;"
psql -U postgres -d osm -c " alter table planet_osm_polygon set schema france;"
psql -U postgres -d osm -c " alter table planet_osm_roads set schema france;"


pg_dump -U postgres  -t france.planet_osm_point osm > france_point_osm.sql
