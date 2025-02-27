---------------------------------------------
-- Script de mise à jour des infos sur les camps, version février 2024 de L. Fernier (base du 10.10.2023)
-- Auteur : Christine PLUMEJEAUD-PERREAU, UMR 7301 MIGRINTER
-- Date de creation : 26/02/2024
-- Date de mise à jour : 26/02
-- Base de données camps_europe sur mapuce (TGIR humanum)
---------------------------------------------

-- camps 5

ALTER TABLE camps.lfernier_bdd_10oct2023 alter column remarques type text ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column bdd_source type text ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column sources type text ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column camp_adresse type text ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column url_maps type text ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column camp_commune type text ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column effectif_total_2022 type varchar(50) ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column capacite_2022 type varchar(50) ;

ALTER TABLE camps.lfernier_bdd_10oct2023 alter column nom type varchar(250) ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column nom_court type varchar(250) ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column doublon type varchar(150) ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column pays type varchar(150) ;


ALTER TABLE camps.lfernier_bdd_10oct2023 alter column eurostat_computed_gisco_id type varchar(50) ;
ALTER TABLE camps.lfernier_bdd_10oct2023 alter column eurostat_nsi_code_2016 type varchar(50) ;


-- import du fichier CSV (UFT8 avec ; comme sép) depuis DBeaver
-- truncate TABLE camps.lfernier_bdd_10oct2023;

select column_name,data_type 
from information_schema.columns 
where table_name = 'lfernier_bdd_10oct2023' and data_type='integer' 
-- and data_type!='character varying';



-- Ok

select c4.unique_id , c4.id , c4.nom, c5.unique_id , c5.id , c5.nom  
from  camps.camps4 c4, camps.lfernier_bdd_10oct2023 c5
where c4.unique_id = c5.unique_id 
-- 757 avant

select  c5.unique_id , c5.id , c5.nom 
from   camps.lfernier_bdd_10oct2023 c5
where c5.unique_id not in (select c4.unique_id from camps.camps4 c4) and c5.nom is not null and nom != '';
-- 784 nouveaux

select count(*) from camps.lfernier_carto_bdd c4 where nom is not null; --755
select count(*) from camps.lfernier_bdd_10oct2023 c4 where nom is not null; --1705
select count(distinct unique_id) from camps.lfernier_bdd_10oct2023 c4 where nom is not null; --1548
-- il y a des doublons
select count(*) from camps.lfernier_bdd_10oct2023 c4 where nom is not null and doublon is not null; --1705

select * from camps.lfernier_bdd_10oct2023 where nom = '';--166
select 1705 - 166 --1539
select 757+784 -- 1541

drop table camps.camps5;
create table camps.camps5 as (select * from camps.lfernier_bdd_10oct2023 where nom is not null and nom != '') ;--1705

-- trouver les doublons
select count(*) from camps.camps5 c5
where doublon like 'unique_id_%';--64

-- trouver les localisations non renseignées (pas de géométrie)
select count(*) from camps.camps5 c5
where camp_latitude like '' and doublon = '';--8


-- rajouter la colonne geom
alter table camps.camps5 add column geom geometry;

select unique_id, doublon, nom, pays, camp_latitude , camp_longitude , localisation_qualite, bdd_source, sources    
-- replace(camp_longitude, ',', '.')::float , replace(camp_latitude, ',', '.')::float 
from  camps.camps5 where camp_latitude like '' and doublon = '' ;

/*
202		Païta (Nouvelle-Calédonie)	France
592		Laviro (Grèce)	Greece
587		camp / squat de Selam Palace (Rome Italie)	Italy
859		Roccella Jonica structure	Italy
860		Friuli Hotspot	Italy
861		Pantelleria Hotspot	Italy
598		Miksaliste TC	Serbia
593		Douvres (Angleterre)	United Kingdom of Great Britain and Northern Ireland
 */

update camps.camps5 c4 set geom = st_setsrid(st_makepoint(replace(camp_longitude, ',', '.')::float, replace(camp_latitude, ',', '.')::float), 4326)
where camp_latitude !=''; --1527

alter table camps.camps5 drop column point3857 ;
alter table camps.camps5 drop column point3035 ;

alter table camps.camps5 add column point3857 geometry;
update camps.camps5 c4 set point3857 = st_setsrid(st_transform(geom, 3857), 3857);

alter table camps.camps5 add column point3035 geometry;
update camps.camps5 c4 set point3035 = st_setsrid(st_transform(geom, 3035), 3035);

-----------------------------------------------------------------------------------------------------------------
-- effectifs des camps
-----------------------------------------------------------------------------------------------------------------
-- TODO

-----------------------------
-- pop des villes proches 
-----------------------------
select  c.nom , c.pays ,c.unique_id , c.doublon , c.camp_adresse ,
 g.nsi_code,
 g.computed_city_code,
g.computed_fua_code,
g.nuts_code,
 g.nsi_code,
 g.name_asci,
coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))
from  demographie."GISCO_LAU_eurostat"  g , camps.camps5 c 
where st_contains(g.geom, c.point3857) and c.eurostat_name_ascii_2016  = ''
order by pays, nom;
--772 nouveaux

select  c.nom , c.pays ,c.unique_id , c.camp_adresse ,
 g.nsi_code, c.eurostat_computed_gisco_id ,
 g.computed_city_code, c.eurostat_computed_city_code ,
g.computed_fua_code, c.eurostat_computed_fua_code ,
g.nuts_code, c.eurostat_nuts_code_2016 ,
 g.nsi_code, c.eurostat_nsi_code_2016 ,
 g.name_asci,  c.eurostat_name_ascii_2016, 
 c.eurostat_pop_2019 ,
coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1))) as compte_pop
from  demographie."GISCO_LAU_eurostat"  g , camps.camps5 c 
where st_contains(g.geom, c.point3857) and c.eurostat_name_ascii_2016  != '' 
and coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))!=eurostat_pop_2019
order by pays, nom;

-- je constate une correction sur 4 camps pour la ville la plus proche
-- est-ce les erreurs dont Louis m'avait fait part ?

-- Ostroleka Deportation Arrest	Poland	712
-- Porto	Portugal	421
-- Giurgiu Regional Center for Procedures and Accommodation for Asylum Seekers	Romania	424
-- Kosice (international airport)	Slovakia	441

update camps.camps5 c set 
eurostat_computed_gisco_id = g.nsi_code,
eurostat_computed_city_code = g.computed_city_code,
eurostat_computed_fua_code = g.computed_fua_code,
eurostat_nuts_code_2016 = g.nuts_code,
eurostat_nsi_code_2016 = g.nsi_code,
eurostat_name_ascii_2016 = g.name_asci,
eurostat_pop_2019 = coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))
from  demographie."GISCO_LAU_eurostat" g 
where st_contains(g.geom, c.point3857) and c.eurostat_name_ascii_2016  = '';
-- 772 / 784 nouvelles entités sont mises à jour

select  pays, count(*) as c from camps.camps5 
where eurostat_name_ascii_2016 = '' and geom is not null
group by pays
order by c desc

-- a renseigner : Netherlands et France
--Turkey	46
--Bosnia and Herzegovina	12
--Belarus	4
--Azerbaijan	2
--Georgia	1
--Montenegro	1
--Netherlands	1
--France	1

select * from camps.camps5  where eurostat_name_ascii_2016 = '' and  geom is not null
and pays  in ('Netherlands', 'France', 'Montenegro');
-- ok, 196 Nouméa ou 865 Curaçao (hors europe)
-- reste 387 montenegro ?

---------------------------------
-- renseigner zone (ZR, ZU, ZIC, B)
-- Utiliser la base degurba d'Eurostat
----------------------------------
update camps.camps5 set zone = null where zone = '';
update camps.camps5 set degurba = null where degurba = '';

select  zone, count(*) from camps.camps5 group by zone;
ZR	32
B	11
ZU	6
ZIC	12
	1478

alter table camps.camps5 add column point4258 geometry;
update camps.camps5  set point4258 = st_setsrid(st_transform(geom, 4258), 4258);
CREATE INDEX sidx_camps5_point4258 ON camps.camps5 USING gist (point4258);
vacuum analyse camps.camps5;

select  st_srid(g.geom) from demographie."DGURBA_2018_01M" g;

select c.nom, g.dgurba , c.degurba 
from demographie."DGURBA_2018_01M" g, camps.camps5 c
where st_contains(g.geom, point4258) and degurba is null;

update camps.camps5 c set degurba = g.dgurba 
from demographie."DGURBA_2018_01M" g
where st_contains(g.geom, point4258) and degurba is null;
-- 773

/*
update camps.camps5 c set degurba = g.dgurba 
from demographie."DGURBA_2018_01M" g
where degurba is null and st_intersects(g.geom, st_buffer(st_setsrid(st_transform(c.geom, 4258), 4258), 1000));
 */

-- décompte des potentielles erreurs de classification (divergence) de Louis sur zone
select k.degurba, count(*) 
from 
(select pays, degurba, zone, case when zone='ZR' then 3 else case when zone='B' or zone='ZIC' then 2 else 1 end end as test 
from camps.camps5 where zone is not null) as k 
where degurba is not null  and k.degurba<>k.test 
group by degurba


select pays, unique_id, nom, doublon, localisation_qualite  from camps.camps5
where degurba is null and geom is not null
order by pays;

update camps.camps5 set degurba=3 where unique_id = 189;
-- Netherlands	865		verifiee
update camps.camps5 set degurba=2 where unique_id = 306;
update camps.camps5 set degurba=2 where unique_id in (280, 281, 279, 282);

select * from camps.camps5 where unique_id in (280, 281, 279, 282);
update camps.camps5 set doublon='unique_id_282' where unique_id in (280, 281, 279);
	

comment on table  "DGURBA_2018_01M" is 'Degré d''urbanisation des unités LAU : 1 -ville) - 2 (banlieue) - 3 (rural)';
comment on column camps.camps5.degurba is 'Degré d''urbanisation des unités LAU : 1 -ville) - 2 (banlieue) - 3 (rural) - croisement avec la base Eurostat degurba EPSG 4258';

-- missing data dans DGURBA_2018_01M pour Bosnia and Herzegovina, Azerbaijan, Belarus, Moldova, Georgia,  Turkey, Ukraine

----------------------------------------------------------------------------------------
-- Traitement OSM
-- creation d'une vue combinant les données (bosnie, belgium, denmark, netherlands, france)

CREATE INDEX sidx_camps5_point3857 ON camps.camps5 USING gist (point3857);


--mairie_distance
select unique_id , nom , iso3, distance_ville_proche, mairie_distance, atm_distance, hopital_distance,pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, avocat_hors_camp_distance_km --, replace(mairie_distance, ',', '.') 
from camps.camps5 c 
where  geom is not null and iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA')
order by iso3;
-- 816
-- reprise du script C:\Travail\MIGRINTER\Labo\Louis_Fernier\osm_extract.sql ligne 2235

update camps.camps5 set mairie_distance = null where mairie_distance = '';
alter table camps.camps5 alter column mairie_distance type float using replace(mairie_distance, ',', '.')::double precision;


update camps.camps5  c set mairie_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (amenity='townhall' or building = 'townhall') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (amenity='townhall' or building = 'townhall' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and c.mairie_distance is null;
-- 657

/*
select c.unique_id , c.nom ,st_distance(osm.way, c.point3857) as dkm, osm.*
from public.osm_point osm , camps.camps5  c
where c.unique_id = 129 and (amenity='townhall' or building = 'townhall')  and c.point3857 is not null;
-- -- 129	Palaiseau	525.3589981989759

select c.unique_id , c.nom , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_polygon osm , camps.camps5  c
where c.unique_id = 129 and (amenity='townhall' or building = 'townhall')  and c.point3857 is not null
group by c.unique_id , c.nom;

alter table france.planet_osm_polygon add column new_id serial;
-- 20 min
select count(*) from france.planet_osm_polygon -- 54517680
*/

-- vérification que les vues sur OSM fonctionnent bien

select count(*) from public.osm_point where amenity='townhall' or building = 'townhall';--754 (avant France) à 17288 (avec France)
select count(*) from public.osm_polygon where amenity='townhall' or building = 'townhall';--771 (avant France) à 21699 (avec France)

select count(*) from france.planet_osm_point where amenity='townhall' or building = 'townhall';--16537
select count(*) from france.planet_osm_point where amenity='townhall' or building = 'townhall';--16537


select mairie_distance from camps.lfernier_bdd_10oct2023  lcb where lcb.mairie_distance !='' 
-- and lcb.iso3  in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA');
-- 36 lignes mais pas dans ('BIH', 'DNK', 'NLD', 'BEL', 'FRA');


update camps.camps5 c set mairie_distance = replace(lcb.mairie_distance, ',', '.')::double precision
from camps.lfernier_bdd_10oct2023  lcb
where lcb.unique_id = c.unique_id  and lcb.mairie_distance != ''; --36


-- atm
update camps.camps5 set atm_distance = null where atm_distance = '';
alter table camps.camps5 alter column atm_distance type float using replace(atm_distance, ',', '.')::double precision;

update camps.camps5  c set atm_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (amenity='atm') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (amenity='atm' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
--  819 

update camps.camps5 c set atm_distance = replace(lcb.atm_distance, ',', '.')::double precision
from camps.lfernier_bdd_10oct2023  lcb
where lcb.unique_id = c.unique_id  and lcb.atm_distance != '';--0

-- hopital_distance
update camps.camps5 set hopital_distance = null where hopital_distance = '';
alter table camps.camps5 alter column hopital_distance type float using replace(hopital_distance, ',', '.')::double precision;

update camps.camps5  c set hopital_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (amenity in ('hospital', 'clinic') or building in ('hospital', 'clinic')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (amenity in ('hospital', 'clinic') or building in ('hospital', 'clinic')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 819 

select hopital_distance from camps.lfernier_bdd_10oct2023  lcb where lcb.hopital_distance !='' and lcb.iso3 not in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA');

update camps.camps5 c set hopital_distance = replace(lcb.hopital_distance, ',', '.')::double precision
from camps.lfernier_bdd_10oct2023  lcb
where lcb.unique_id = c.unique_id  and lcb.hopital_distance != '';--36

-- pharmacie_distance
update camps.camps5 set pharmacie_distance = null where pharmacie_distance = '';
alter table camps.camps5 alter column pharmacie_distance type float using replace(pharmacie_distance, ',', '.')::double precision;

update camps.camps5  c set pharmacie_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (amenity in ('pharmacy') or shop in ('chemist', 'medical_supply')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (amenity in ('pharmacy') or shop in ('chemist', 'medical_supply')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 819

select pharmacie_distance from camps.lfernier_bdd_10oct2023  lcb where lcb.pharmacie_distance !='' and lcb.iso3  in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA');



-- arret_bus_distance_km
update camps.camps5 set arret_bus_distance_km = null where arret_bus_distance_km = '';

alter table camps.camps5 alter column arret_bus_distance_km type float using replace(arret_bus_distance_km, ',', '.')::double precision;


update camps.camps5  c set arret_bus_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (amenity in ('bus_station') or highway='bus_stop' or public_transport='platform' or  railway='platform') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (amenity in ('bus_station') or highway='bus_stop' or public_transport='platform' or  railway='platform') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
--819


-- gare_distance_km
update camps.camps5 set gare_distance_km = null where gare_distance_km = '';
alter table camps.camps5 alter column gare_distance_km type float using replace(gare_distance_km, ',', '.')::double precision;

update camps.camps5  c set gare_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (railway='station' or railway='halt' or building='train_station' or  public_transport='station' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (railway='station' or railway='halt' or building='train_station' or  public_transport='station' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 819


-- medecin_clinique_hors_camp_distance_km
update camps.camps5 set medecin_clinique_hors_camp_distance_km = null where medecin_clinique_hors_camp_distance_km = '';
alter table camps.camps5 alter column medecin_clinique_hors_camp_distance_km type float using replace(medecin_clinique_hors_camp_distance_km, ',', '.')::double precision;

update camps.camps5  c set medecin_clinique_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (amenity in ('clinic', 'doctors') or building in ('clinic', 'healthcare')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (amenity in ('clinic', 'doctors') or building in ('clinic', 'healthcare')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 816

select iso3, medecin_clinique_hors_camp_distance_km 
from camps.camps5  c
where c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
order by iso3;

-- dentiste_hors_camp_distance_km
update camps.camps5 set dentiste_hors_camp_distance_km = null where dentiste_hors_camp_distance_km = '';
alter table camps.camps5 alter column dentiste_hors_camp_distance_km type float using replace(dentiste_hors_camp_distance_km, ',', '.')::double precision;
update camps.camps5  c set dentiste_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (amenity in ('dentist') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (amenity in ('dentist') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 819


-- avocat_hors_camp_distance_km
update camps.camps5 set avocat_hors_camp_distance_km = null where avocat_hors_camp_distance_km = '';
alter table camps.camps5 alter column avocat_hors_camp_distance_km type float using replace(avocat_hors_camp_distance_km, ',', '.')::double precision;

update camps.camps5  c set avocat_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (office = 'lawyer' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (office = 'lawyer') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 819




-- poste_hors_camp_distance_km
-- Pour poste : post_box / post_office
update camps.camps5 set poste_hors_camp_distance_km = null where poste_hors_camp_distance_km = '';

alter table camps.camps5 add column poste_hors_camp_distance_km float;

update camps.camps5  c set poste_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (amenity in ('post_box', 'post_office') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (amenity in ('post_box', 'post_office')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 819 , 2 min 15 s


select column_name, data_type 
from information_schema.columns 
where table_name = 'lfernier_bdd_10oct2023' and column_name like '%distance%' ;

-- UPDATED
--mairie_distance	character varying
-- ecole_hors_camp_distance_km
--atm_distance	character varying
--hopital_distance	character varying
--pharmacie_distance	character varying
--medecin_clinique_hors_camp_distance_km	character varying
--dentiste_hors_camp_distance_km	character varying
--arret_bus_distance_km	character varying
--gare_distance_km	character varying
--avocat_hors_camp_distance_km	character varying
-- poste_hors_camp_distance_km

-- UNDONE
/*
installation_electrique_distance_km	character varying
station_epuration_distance_km	character varying
dechetterie_distance_km	character varying
carriere_distance_km	character varying
voie_ferree_distance_km	character varying
usine_chimique_distance_km	character varying
usine_chimique_zone_contaminee_distance_km	character varying
danger_zone_distance_km	character varying
aeroport_distance_km	character varying
autoroute_distance_km	character varying
voie_rapide_distance_km	character varying
pesticides_distance_km	character varying
seveso_distance_km	character varying
natura_2000_distance_km	character varying
nucléaire_zone_radioactive_distance_km	character varying
zone_minee_distance_km	character varying
champ_de_tir_distance_km	character varying
munitions_non_explosees_distance_km	character varying
*/






-- Pour école : school / college
alter table camps.camps5 add column ecole_hors_camp_distance_km numeric;

update camps.camps5  c set ecole_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps5  c
	where (amenity in ('school', 'college') or building in ('school', 'college') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps5  c
	where (amenity in ('school', 'college') or building in ('school', 'college')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;
-- 819






----------------------------------------------------------------------------------------
-- CLC
-- voir C:\Travail\MIGRINTER\Labo\Louis_Fernier\Analyse_campSeptembre2022\camps4.sql
-- ligne 453
----------------------------------------------------------------------------------------

-- TODO
/*
distance_ville_proche	character varying
distance_13_mines_decharges_chantiers	integer
distance_124_aeroport	integer
distance_123_zones_portuaires	integer
distance_122_reseaux_routiers	integer
distance_24_zones_agricoles_heterogenes	integer
distance_41_zones_humides_interieures	integer
distancesc	integer
*/

-- c.clc_majoritaire_4 est vide : pourquoi ?
-- maintenant clc_majoritaire_3 est un entier (avant un code text sur 3 characters) 
select c.iso3 , c.nom, c.clc_majoritaire_3, c.clc_majoritaire_4, clc.code_18 
from camps.camps5 c, clc.u2018_clc2018_v2020_20u1 clc
where st_contains(clc.shape, c.point3035) and c.iso3 = 'FRA';


update camps.camps5 c set CLC_majoritaire_3 = clc.code_18::int
from clc.u2018_clc2018_v2020_20u1 clc
where st_contains(clc.shape, c.point3035); --1474




update camps.camps5  c set distance_124_aeroport = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 = '124'
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 1539 - 27 s



update camps.camps5  c set distance_13_mines_decharges_chantiers = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '13%'
group by c.unique_id
) as k where k.unique_id = c.unique_id
-- 1.21 min 



update camps.camps5  c set distance_123_zones_portuaires = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '123'
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 1539 5s 


update camps.camps5  c set distance_122_reseaux_routiers = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '122'
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 1539 44 s 


CREATE INDEX sidx_camps5_point3035 ON camps.camps4 USING gist (point3035);
-- DONE


update camps.camps5  c set distance_41_zones_humides_interieures = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '41%'
group by c.unique_id
) as k where k.unique_id = c.unique_id ;
-- 1539, 8 min 02 DONE

-------------------
-- STOP vraiment trop long
-- fait uniquement sur FRA, BEL, NLD, BIH et BEL

update camps.camps5  c set distance_24_zones_agricoles_heterogenes = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '24%'
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 32 min 

-- procéder pays par pays, en limitant les CLC à celles dont l'emprise est dans le pays
select count(clc.objectid )
from camps.countries c, clc.u2018_clc2018_v2020_20u1 clc
where c.id = 22 and (clc.shape && box2D(c.geom))  and clc.code_18 like '24%';

select st_setsrid(st_transform(st_setsrid(box2D(c.geom), 4126), 3035), 3035), c.*
from camps.countries c
where c.id = 22 ;

select count(clc.objectid )
from camps.countries c, clc.u2018_clc2018_v2020_20u1 clc
where c.id = 22 and (clc.shape && st_setsrid(st_transform(st_setsrid(box2D(c.geom), 4126), 3035), 3035))  
and clc.code_18 like '24%';
-- 429 533 en 6 s

update camps.camps5  c set distance_24_zones_agricoles_heterogenes = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, camps.countries pays, clc.u2018_clc2018_v2020_20u1 clc
where c.iso3 = 'FRA' and pays.id=22 and  clc.code_18 like '24%' and
( (clc.shape && st_setsrid(st_transform(st_setsrid(box2D(pays.geom), 4126), 3035), 3035)) )
group by c.unique_id
) as k where k.unique_id = c.unique_id;--62
-- corrigé, mais reste très très long.

create table camps.temps_distance as
(select 'FRA' as country, c.unique_id, st_distance(c.point3035, clc.shape) as distance_clc_24
from camps.camps5 c, camps.countries pays, clc.u2018_clc2018_v2020_20u1 clc
where c.iso3 = 'FRA' and pays.id=22 and  clc.code_18 like '24%' and
( (clc.shape && st_setsrid(st_transform(st_setsrid(box2D(pays.geom), 4126), 3035), 3035)) )
);
-- 31 min, 2 261 639 028 lignes
update camps.camps5  c set distance_24_zones_agricoles_heterogenes = round(k.min_d/1000)
from (
select c.unique_id, min(distance_clc_24) as min_d
from camps.temps_distance c
group by c.unique_id) as k -- 1.28 min
where k.unique_id = c.unique_id; --516 en 40s


update camps.camps5  c set distance_24_zones_agricoles_heterogenes = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, camps.countries pays, clc.u2018_clc2018_v2020_20u1 clc
where c.iso3 = 'BIH' and pays.id=132 and  clc.code_18 like '24%' and
( (clc.shape && st_setsrid(st_transform(st_setsrid(box2D(pays.geom), 4126), 3035), 3035)) )
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 13 

update camps.camps5  c set distance_24_zones_agricoles_heterogenes = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, camps.countries pays, clc.u2018_clc2018_v2020_20u1 clc
where c.iso3 = 'BEL' and pays.id=60 and  clc.code_18 like '24%' and
( (clc.shape && st_setsrid(st_transform(st_setsrid(box2D(pays.geom), 4126), 3035), 3035)) )
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 92

update camps.camps5  c set distance_24_zones_agricoles_heterogenes = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, camps.countries pays, clc.u2018_clc2018_v2020_20u1 clc
where c.iso3 = 'DNK' and pays.id in (178,71) and  clc.code_18 like '24%' and
( (clc.shape && st_setsrid(st_transform(st_setsrid(box2D(pays.geom), 4126), 3035), 3035)) )
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 26

update camps.camps5  c set distance_24_zones_agricoles_heterogenes = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, camps.countries pays, clc.u2018_clc2018_v2020_20u1 clc
where c.iso3 = 'NLD' and pays.id = 94 and  clc.code_18 like '24%' and
( (clc.shape && st_setsrid(st_transform(st_setsrid(box2D(pays.geom), 4126), 3035), 3035)) )
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 176 en 4 min


select count(*) from camps.camps5 c where c.iso3 = 'NLD' ;


/*
update camps.camps5  c set distance_24_zones_agricoles_heterogenes = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps.camps5 c, clc.u2018_clc2018_v2020_20u1 clc
where c.iso3 = 'FRA' 
and clc.objectid in (
	select count(clc.objectid) from camps.countries pays, clc.u2018_clc2018_v2020_20u1 clc 
	where pays.id=22 and clc.code_18 like '24%' and 
	(clc.shape::box2D && st_setsrid(st_transform(st_setsrid(box2D(pays.geom), 4126), 3035), 3035)) 
	) 
group by c.unique_id
) as k where k.unique_id = c.unique_id;--62

select count(*) from camps.camps5 c where c.iso3 = 'FRA' 
*/


select count(*) from camps.camps5 c  where distance_24_zones_agricoles_heterogenes is not null;

select iso3, count(unique_id), min(distance_24_zones_agricoles_heterogenes), 
avg(distance_24_zones_agricoles_heterogenes), max(distance_24_zones_agricoles_heterogenes) 
from camps.camps5 c  
where distance_24_zones_agricoles_heterogenes < 3000
group by iso3 ;
-- FRA	497	0	1.6096579476861167	8
--where distance_24_zones_agricoles_heterogenes is not null;

----------------------------------
-- Distance de Schengen
-- distancesc


select  distancesc from camps5; 
alter table camps5 add column  distanceSchengenkm float default 0;
comment on column camps.camps5.distanceSchengenkm is 'Distance en km aux frontières de l''espace de Schengen sur la base du fond natural Earth 10 000eme.';

update camps.camps5  c set distanceSchengenkm = round(k.min_d/1000)
from (
	select c.unique_id, min(st_distance(c.point3857, ne.poly3857)) as min_d
	from camps5 c, demographie.ne_10m_admin_0_countries ne
	where ne.Espace_Schengen is true 
	and iso3 not in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC' )
	group by c.unique_id
) as k where k.unique_id = c.unique_id ;
-- 250

select  unique_id, nom, distancesc, distanceSchengenkm 
from camps5
where iso3 not in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC' ) and distancesc!=distanceSchengenkm;

/* unique_id, nom, distancesc, distanceSchengenkm
424	Giurgiu Regional Center for Procedures and Accommodation for Asylum Seekers	335	325.0
427	Otopeni Centre for Accommodation of Foreigners Taken into Public Custody	429	430.0
520	Hatay	904	886.0
514	Istanbul (aéroport int. Ataturk)	248	249.0
542	Lutsk Temporary Holding Facility	133	134.0
544	Lviv Temporary Holding Facility	89	91.0
547	Donetsk Temporary Holding Facility	1584	1575.0
756	Ankara airport	728	727.0
538	Chernigiv Temporary Holding Facility	786	721.0
577	Cambridge. Oakington IRC	300	302.0
571	Doncaster. South Yorkshire. Lindholme IRC	564	560.0
543	Mostys'ka Temporary Holding Facility	21	20.0
553	Kyiv	707	706.0
*/
select * from camps.camps5 where distanceSchengenkm is null;


-----------------------------------------------
-- le 04 mars 2024 : extraction 
select unique_id, nom, type_camp , ville_proche_nom , pays, gare_distance_km , arret_bus_distance_km , pharmacie_distance , hopital_distance , atm_distance , mairie_distance , clc_majoritaire_3   
from camps.camps4 where geom is not null and pays in ('Bosnia and Herzegovina', 'Denmark');


select column_name, data_type 
from information_schema.columns 
where table_name = 'camps5';

select "pays_community health workers (per 1,000 people)" from camps.camps5 c where "pays_community health workers (per 1,000 people)" != '';
select "pays_hospital beds (per 1,000 people)" from camps.camps5 c where "pays_hospital beds (per 1,000 people)" != '';
select "camps_community health workers (per 1,000 people)" from camps.camps5 c where "camps_community health workers (per 1,000 people)" != '';

select column_name 
from  information_schema.columns 
where table_name = 'camps5' and column_name like 'pays_%' ;


select string_agg(column_name, ', ') 
from  information_schema.columns 
where table_name = 'camps5' and column_name not like 'field_%' and column_name not like 'point%';

update camps.camps5 set sources = regexp_replace(sources, '\n', ' - ', 'g');


select unique_id, id, nom, nom_court, doublon, remarques, bdd_source, sources, iso3, pays, pays_population, "ouverture/premiere_date", fermeture_date, derniere_date_info, actif_dernieres_infos, localisation_qualite, camp_latitude, camp_longitude, url_maps, camp_adresse, camp_code_postal, camp_commune, 
ville_proche_nom, "ville_proche_code postal", ville_proche_population, 
prison, type_camp, infrastructure, climat, zone, occupation_du_sol, capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
mairie_distance, mairie_temps_pied, atm_distance, atm_temps_pied, hopital_distance, hopital_temps_voiture, pharmacie_distance, pharmacie_temps_pied, medecin_presence, transports_publics_camp_regularite, transports_publics_ville_proche_regularite, arret_bus_distance_km, arret_bus_temps, gare_distance_km, gare_temps, medecin_clinique_hors_camp_distance_km, medecin_clinique_hors_camp_temps, dentiste_hors_camp_distance_km, dentiste_hors_camp_temps, 
eau_accès, collecte_dechets, electricite, energie_autre, toilettes, douche, sanitaires_separation, travail_non, travail_oui, education_publique, education_associations, avocat_camp_presence, risque_environnemental, 
avocat_hors_camp, avocat_hors_camp_distance_km, installation_electrique, installation_electrique_distance_km, station_epuration, station_epuration_distance_km, dechetterie, dechetterie_distance_km, carriere, carriere_distance_km, voie_ferree, voie_ferree_distance_km, usine_chimique, usine_chimique_distance_km, usine_chimique_zone_contaminee, usine_chimique_zone_contaminee_distance_km, danger_zone, danger_zone_distance_km, aeroport, aeroport_distance_km, autoroute, autoroute_distance_km, voie_rapide, voie_rapide_distance_km, pesticides, pesticides_distance_km, seveso, seveso_distance_km, natura_2000, natura_2000_distance_km, nucléaire_zone_radioactive, nucléaire_zone_radioactive_distance_km, zone_minee, zone_minee_distance_km, champ_de_tir, champ_de_tir_distance_km, munitions_non_explosees, munitions_non_explosees_distance_km, 
"pays_community health workers (per 1,000 people)", "camps_community health workers (per 1,000 people)", "pays_hospital beds (per 1,000 people)", "pays_mortality rate attributed to household and ambient air pol", "camp_mortality rate attributed to household and ambient air pol", "pays_suicide mortality rate (per 100,000 population)", "camp_suicide mortality rate", "pays_mortality rate attributed to unsafe water, unsafe sanitati", "camp_mortality rate attributed to unsafe water, unsafe sanitati", 
pays_nombre_undernourished_people, camp_nombre_undernourished_people, pays_pourcentage_undernourished_people, camp_pourcentage_undernourished_people, "pays_people using at least basic drinking water services (% of", "camp_people using at least basic drinking water services (% of", "pays_hypertension_adultes_pourcentage", camp_hypertension_adultes_pourcentage, pays_traitement_hypertension_adultes_pourcentage, camp_traitement_hypertension_adultes_pourcentage, "pays_death_by_communicable_diseases (% of total)", 
camp_maladies_infectieuses, pays_maladies_infectieuses, ville_proche_maladies_infectieuses, camp_maladies_mentales, pays_maladies_mentales, ville_proche_maladies_mentales, malnutrition, "camp_death_by_communicable_diseases (% of total)", "pays_death_by_non_communicable_diseases (% of total)", "camp_death_by_non_communicable_diseases (% of total)", 
chauffage_ventilation, mouvement_de_terrain, intemperies, tempetes, orages_et_foudres, grele, tornade_et_trombe, incendies, inondations_et_coulees_de_boue, marecages, seismes, froid_neige_pluies_verglacantes, secheresses, canicules, tensions_population_locale, raison_encampement, surveillance_qui, surveillance_nombre, surveillance_mission, surveillance_comportement, turnover_encampes, modification_cadre_de_vie, organisations_nombre, organisations_reunions_annuelles_nombre, environnement_plan_global, manifestaions_possibles, 
tentes_places, rubhall_places, containers_places, prefabriques_places, dur_places, hebergement_choix_possible, hebergement_changement_possible, herbergement_modification_possible, 
aide_financière, alimentation_distributions, alimentation_cuisine, vetements_distribution, vetements_adaptes, 
eurostat_computed_gisco_id, eurostat_computed_city_code, eurostat_computed_fua_code, eurostat_nuts_code_2016, eurostat_nsi_code_2016, eurostat_name_ascii_2016, eurostat_pop_2019, distance_ville_proche, eurostat_nuts_code_2016_level3, eurostat_nuts_code_2021_level3, degurba, 
clc_majoritaire_3, clc_majoritaire_4, distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, distancesc, gestionnaire_principal, 
ecole_hors_camp_distance_km, poste_hors_camp_distance_km, distanceschengenkm, 
geom
from camps.camps5 c ;
-- export complet

select unique_id, id, nom, doublon,  iso3, 
localisation_qualite, camp_latitude, camp_longitude,
-- url_maps, camp_adresse, camp_code_postal, camp_commune, 
ville_proche_nom, "ville_proche_code postal", ville_proche_population, 
--prison, type_camp, infrastructure, climat, zone, occupation_du_sol, capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
--mairie_temps_pied, atm_temps_pied, , hopital_temps_voiture, pharmacie_temps_pied, medecin_presence, transports_publics_camp_regularite, 
--transports_publics_ville_proche_regularite, arret_bus_temps, gare_temps, medecin_clinique_hors_camp_temps, dentiste_hors_camp_temps, 
eurostat_computed_gisco_id, eurostat_computed_city_code, eurostat_computed_fua_code, eurostat_nuts_code_2016, eurostat_nsi_code_2016, eurostat_name_ascii_2016, eurostat_pop_2019, distance_ville_proche, eurostat_nuts_code_2016_level3, eurostat_nuts_code_2021_level3, degurba, 
clc_majoritaire_3, clc_majoritaire_4, distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distancesc, distanceschengenkm 
geom
from camps.camps5 c ;