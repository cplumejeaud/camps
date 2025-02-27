---------------------------------------------
-- Script de mise à jour des infos sur les camps, version septembre 2022 de L. Fernier
-- Auteur : Christine PLUMEJEAUD-PERREAU, UMR 7301 MIGRINTER
-- Date de creation : 26/09
-- Date de mise à jour : 26/09
-- Base de données camps_europe sur mapuce (TGIR humanum)
---------------------------------------------

set search_path = demographie, camps, clc, natura2000, public;

set role postgres;

GRANT USAGE ON schema public, camps, clc, natura2000, demographie  TO qgis_reader; 
GRANT select ON ALL SEQUENCES  IN SCHEMA public, camps, clc, natura2000, demographie TO qgis_reader;
GRANT select ON ALL TABLES  IN SCHEMA public, camps, clc, natura2000, demographie TO qgis_reader;


ALTER USER qgis_reader WITH PASSWORD 'BDmigr2022';


GRANT USAGE ON SCHEMA public TO public;
GRANT select ON ALL SEQUENCES  IN SCHEMA public TO public;
GRANT REFERENCES, SELECT on ALL TABLES  IN SCHEMA public, camps, clc, natura2000, demographie TO  public;


---------------------------------------------------
-- Import des camps 
---------------------------------------------------

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

select * from camps.camps4 where unique_id= 154;
update camps.camps4 c4 set localisation_qualite  = 'absent'  
where unique_id = 395;
update camps.camps4 c4 set localisation_qualite  = 'absent'  
where unique_id = 444;
update camps.camps4 c4 set localisation_qualite  = 'absent'  
where unique_id = 154;
update camps.camps4 c4 set localisation_qualite  = 'verifiee'  
where unique_id = 209;
select * from camps.camps4 where localisation_qualite = 'pas_de_donnees';
update camps.camps4 c4 set localisation_qualite  = 'absent'  
where unique_id = 250;

select * from camps.camps4 where unique_id = 209;
update camps.camps4 c4 set localisation_qualite  = 'verifiee'  
where unique_id = 187;

update camps.camps4 c4 set localisation_qualite  = 'imprecise'  
where unique_id = 587;
update camps.camps4 c4 set localisation_qualite  = 'verifiee'  
where unique_id = 214;-- GUYANE (CRA Matoury)

-- 593	734	Douvres (Angleterre)		Pas de présence sur internet / ni sur closethecamp ni sur globaldetentionproject
-- 598	748	Miksaliste TC		> N'est pas un camp mais un point d'info / enregistrement à Belgrade
update camps.camps4  c set localisation_qualite = 'absent' where distanceSchengenkm is null;

select * from camps.camps4 where localisation_qualite is null and doublon is null;

-------------------------------------------------------------
-- les valeurs d'effectif et de capacité totale
-------------------------------------------------------------


select annee, count as effectif_total from (
select count(*), 2017 as annee from  camps.camps4 where effectif_2017 is not null
union
(
select count(*), 2018 as annee from  camps.camps4 where effectif_2018 is not null
) union
(
select count(*), 2019 as annee from  camps.camps4 where effectif_2019 is not null
) union
(
select count(*), 2020 as annee from  camps.camps4 where effectif_2020 is not null
) union
(
select count(*), 2021 as annee from  camps.camps4 where effectif_2021 is not null
) union
(
select count(*), 2022 as annee from  camps.camps4 where effectif_total_2022 is not null
)
) as k 
order by annee

/*
2017	146
2018	147
2019	159
2020	133
2021	181
2022	126
*/
alter table camps.camps4 alter column remarques type text;

select effectif_2018, * from camps.camps4 
where effectif_2018 ilike '%non_pertinent%' or effectif_2018 ilike '%donnee%' or effectif_2018 = ' '
or effectif_2018 = 'voir_entretiens';

update camps.camps4 set remarques = coalesce(remarques,'')||'- effectif_2019 '||effectif_2019, effectif_2019=null 
where effectif_2019 ilike '%non_pertinent%' or effectif_2019 ilike '%donnee%';-- pas_de_donnees

update camps.camps4 set remarques = coalesce(remarques,'')||'- effectif_2019 '||effectif_2019, effectif_2019=null 
where effectif_2019 ilike '%voir_entretiens%' ;-- voir_entretiens
update camps.camps4 set remarques = coalesce(remarques,'')||'- effectif_2018 '||effectif_2018, effectif_2018=null 
where effectif_2018 = 'voir_entretiens';-- voir_entretiens
update camps.camps4 set remarques = coalesce(remarques,'')||'- capacite_2018 '||capacite_2018, capacite_2018=null 
where capacite_2018 = 'voir_entretiens';
update camps.camps4 set remarques = coalesce(remarques,'')||'- capacite_2019 '||capacite_2019, capacite_2019=null 
where capacite_2019 = 'voir_entretiens';

update camps.camps4 set remarques = coalesce(remarques, '')||'- capacite_2017 '||capacite_2017, capacite_2017=null 
where capacite_2017 ilike '%non_pertinent%' or capacite_2017 ilike '%donnee%';

update camps.camps4 set remarques = coalesce(remarques, '')||'- capacite_2018 '||capacite_2018, capacite_2018=null 
where capacite_2018 ilike '%non_pertinent%' or capacite_2018 ilike '%donnee%';

update camps.camps4 set remarques = coalesce(remarques, '')||'- capacite_2019 '||capacite_2019, capacite_2019=null 
where capacite_2019 ilike '%non_pertinent%' or capacite_2019 ilike '%donnee%';

update camps.camps4 set remarques = coalesce(remarques, '')||'- capacite_2020 '||capacite_2020, capacite_2020=null 
where capacite_2020 ilike '%non_pertinent%' or capacite_2020 ilike '%donnee%';

update camps.camps4 set remarques = coalesce(remarques,'')|| '- capacite_2021 '||capacite_2021, capacite_2021=null 
where capacite_2021 ilike '%non_pertinent%'  or capacite_2021 ilike '%donnee%';

update camps.camps4 set remarques = coalesce(remarques, '')||'- effectif_2017 '||effectif_2017, effectif_2017=null 
where effectif_2017 ilike '%non_pertinent%'  or effectif_2017 ilike '%donnee%';

update camps.camps4 set remarques = coalesce(remarques,'')|| '- effectif_2018 '||effectif_2018, effectif_2018=null 
where effectif_2018 ilike '%non_pertinent%' or effectif_2018 ilike '%donnee%';

update camps.camps4 set remarques = coalesce(remarques, '')||'- effectif_2020 '||effectif_2020, effectif_2020=null 
where effectif_2020 ilike '%non_pertinent%'  or effectif_2020 ilike '%donnee%';
update camps.camps4 set remarques = coalesce(remarques, '')||'- effectif_2021 '||effectif_2021, effectif_2021=null 
where effectif_2021 ilike '%non_pertinent%'  or effectif_2021 ilike '%donnee%';
update camps.camps4 set remarques = coalesce(remarques, '')||'- effectif_2020 '||effectif_2020, effectif_2020=null 
where effectif_2020 ilike '%non_pertinent%'  or effectif_2020 ilike '%donnee%';
update camps.camps4 set remarques = coalesce(remarques, '')||'- effectif_total_2022 '||effectif_total_2022, effectif_total_2022=null 
where effectif_total_2022 ilike '%non_pertinent%' or effectif_total_2022 ilike '%donnee%' or effectif_total_2022 = 'voir_entretiens';

-- 
alter table  camps.camps4 alter effectif_2019 type int using trim(effectif_2019)::int ;
update camps.camps4 set effectif_2019 = '2038' where effectif_2019 = '2 038' ;
select effectif_2019 from camps.camps4 where effectif_2019 is not null ;
-- laisse tomber - DIRE

alter table  camps.camps4 alter capacite_2019 type int using trim(capacite_2019)::int ;
update camps.camps4 set capacite_2019 = null where capacite_2019 = ' ' --55


select effectif_2019, * from camps.camps4 where effectif_2019 ilike '%donnee%' 

-----------------------------
-- pop des pays
-----------------------------

update  camps.camps4 c set pays_population = pm."2019"
from demographie.population_monde pm 
where c.iso3 = pm.country_code 
-- 753 

update  camps.camps4 c set pays_population = w.pop_est 
from demographie.ne_10m_admin_0_countries w 
where pays_population is null and (w.name_fr=c.pays or w.adm0_a3_fr=c.iso3)
-- 1 (kosovo)

select * from camps.camps4 where pays_population is null;

select c.unique_id , c.nom, w.adm0_a3_fr as NaturalEarth_adm0 , w.name_fr as NaturalEarth_country, c.iso3, c.pays,  c.localisation_qualite , c.doublon, c.pays_population 
from demographie.ne_10m_admin_0_countries w, camps.camps4 c
where c.iso3 is not null and st_contains(w.geom, c.geom) and  w.adm0_a3_fr<>c.iso3




alter table camps.camps4 add column eurostat_computed_gisco_id text ;
alter table camps.camps4 add column eurostat_computed_city_code text ;
alter table camps.camps4 add column eurostat_computed_fua_code text ;
alter table camps.camps4 add column eurostat_nuts_code_2016 text ;
alter table camps.camps4 add column eurostat_nsi_code_2016 text ;
alter table camps.camps4 add column eurostat_name_ascii_2016 text ;
alter table camps.camps4 add column eurostat_pop_2019 text ;


update camps.camps4 c set 
eurostat_computed_gisco_id = g.nsi_code,
eurostat_computed_city_code = g.computed_city_code,
eurostat_computed_fua_code = g.computed_fua_code,
eurostat_nuts_code_2016 = g.nuts_code,
eurostat_nsi_code_2016 = g.nsi_code,
eurostat_name_ascii_2016 = g.name_asci,
eurostat_pop_2019 = coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))
from  "GISCO_LAU_eurostat" g 
where st_contains(g.geom, c.point3857);
-- 678


select  pays, count(*) as c from camps.camps4 
where eurostat_name_ascii_2016 is null and geom is not null
group by pays
order by c desc
-- 95

/*
Turkey	33
Bosnia and Herzegovina	10
Belarus	4
Azerbaijan	2
Georgia	1
France	1
Montenegro	1
 */

update camps.camps4 c set 
eurostat_computed_gisco_id = g.nsi_code,
eurostat_computed_city_code = g.computed_city_code,
eurostat_computed_fua_code = g.computed_fua_code,
eurostat_nuts_code_2016 = g.nuts_code,
eurostat_nsi_code_2016 = g.nsi_code,
eurostat_name_ascii_2016 = g.name_asci,
eurostat_pop_2019 = coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))
from  "GISCO_LAU_eurostat" g 
where eurostat_name_ascii_2016 is null and st_intersects(g.geom, st_buffer(c.point3857, 1000))  ;


select * from camps.camps4 
where eurostat_name_ascii_2016 is null and geom is not null
and pays = 'France';
-- Nouméa (Aéroport de - Nouvelle Calédonie) pour n° 196

select count(*) from camps.camps4 
where camp_commune is null and geom is not null;
-- 82 / 24
update camps.camps4 set camp_commune = eurostat_name_ascii_2016 where camp_commune is null and eurostat_name_ascii_2016 is not null;
-- 58
comment on column camps.camps4.camp_commune is 'camp_commune a été complété avec la valeur de eurostat_name_ascii_2016 quand elle n''était pas renseignée par Louis, le 17 mars 2022';

-------------------------------------------------------
-- Renseigner ville_proche_nom : prendre le nom de la city ou fua sinon
-- Renseigner ville_proche_population : prendre la population de la city ou de la fua si celle-ci est renseignée
-- pas fait TODO
-------------------------------------------------------

alter table camps.camps4 add column distance_ville_proche float ;
-- 0 si dans la grande ville (catégorie C des aires_urbaines)
-- km sinon du camps au coeur de la city la plus proche

select c.nom, camp_commune , au.urau_name, au.city_pop2019 ,
case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end
from camps.camps4 c, demographie.aires_urbaines au 
where au.urau_catg = 'C' and eurostat_computed_city_code is not null and eurostat_computed_city_code = au.urau_code
 
update camps.camps4 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population = au.city_pop2019::int,
distance_ville_proche = 0
from demographie.aires_urbaines au 
where au.urau_catg = 'C' and eurostat_computed_city_code is not null and eurostat_computed_city_code = au.urau_code
-- 215


select c.nom, camp_commune , au.urau_name, au.fua_pop2019 ,
case when position('FUA of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 8) end
from camps.camps4 c, demographie.aires_urbaines au 
where c.distance_ville_proche is null and au.urau_catg = 'F' and eurostat_computed_fua_code is not null and eurostat_computed_fua_code = au.urau_code
 
-- FUA of the Greater City of Paris
update camps.camps4 c 
set ville_proche_nom = case when position('FUA of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 8) end,
ville_proche_population = au.fua_pop2019::int
from demographie.aires_urbaines au 
where ville_proche_population is null and au.urau_catg = 'F' and eurostat_computed_fua_code is not null and eurostat_computed_fua_code = au.urau_code
-- 101


select  c.unique_id , c.nom, camp_commune , au.urau_code, au.urau_name, au.urau_catg, nuts3_2016, nuts3_2021, round(st_distance(c.point3857, au.geom)/1000) as d
from camps.camps4 c , demographie.centres_aires_urbaines au ,
(select  c.unique_id , min(st_distance(c.point3857, au.geom)) as dmin
from camps.camps4 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C'
group by c.unique_id) as k 
where st_distance(c.point3857, au.geom) = k.dmin and c.unique_id = k.unique_id
-- 739

select  c.unique_id , min(st_distance(c.point3857, au.geom))
from camps.camps4 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C'
group by c.unique_id
-- 662

alter table camps.camps4 add column eurostat_nuts_code_2016_level3 text ;
alter table camps.camps4 add column eurostat_nuts_code_2021_level3 text ;

update camps.camps4 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
distance_ville_proche = round(st_distance(c.point3857, au.geom)/1000),
eurostat_nuts_code_2016_level3 = au.nuts3_2016 ,
eurostat_nuts_code_2021_level3 = au.nuts3_2021
from 
 demographie.centres_aires_urbaines au ,
(select  c.unique_id , min(st_distance(c.point3857, au.geom)) as dmin
from camps.camps4 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C'
group by c.unique_id) as k 
where st_distance(c.point3857, au.geom) = k.dmin and c.unique_id = k.unique_id;
-- 739


select * from  camps.camps4 
where ville_proche_nom is not null and ville_proche_population is null
and pays = 'Italy'

/*
-- il faut renseigner la pop avec la population du NUTS3 associé à la ville la plus proche
-- eurostat_nuts_code_2016_level3 
-- exemple : Lampedusa - Contrada Imbriacola (Agrigento)  est à 215 km de milan (MT001)
select  c.unique_id , min(st_distance(c.point3857, au.geom))
from camps.camps4 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C' and ville_proche_nom is null 
group by c.unique_id
*/
-- Non finalement, on remplace par la population de la commune quand le camp n'est ni dans une FUA ni une City 
update camps.camps4 c set ville_proche_population = eurostat_pop_2019 
where eurostat_computed_city_code is null and eurostat_computed_fua_code is  null and eurostat_pop_2019::int <> -1

select unique_id, pays, camp_commune, eurostat_computed_gisco_id , eurostat_name_ascii_2016 , eurostat_pop_2019 , distance_ville_proche, ville_proche_nom, ville_proche_population, eurostat_computed_city_code, eurostat_computed_fua_code
from  camps.camps4 
where ville_proche_nom is not null and ville_proche_population is null and eurostat_computed_gisco_id is not null 
and eurostat_pop_2019::int <> -1
-- 132 entités
except (
select unique_id, pays, camp_commune, eurostat_computed_gisco_id , eurostat_name_ascii_2016 , eurostat_pop_2019 , distance_ville_proche, ville_proche_nom, ville_proche_population, eurostat_computed_city_code, eurostat_computed_fua_code
from  camps.camps4 
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
from camps.camps4 c, "GISCO_LAU_eurostat" is
where c.eurostat_computed_gisco_id 
*/

alter table camps.camps4 alter column eurostat_pop_2019 type int using eurostat_pop_2019::int;
update camps.camps4 set eurostat_pop_2019 = null where eurostat_pop_2019= -1

---------------------------------
-- renseigner zone (ZR, ZU, ZIC, B)
-- Utiliser la base degurba d'Eurostat
----------------------------------

select  zone, count(*) from camps.camps4 group by zone
ZR	32
B	11
ZU	6
ZIC	12
	601
	
alter table camps.camps4 add column degurba int;

update camps.camps4 c set degurba = g.dgurba 
from "DGURBA_2018_01M" g
where st_contains(g.geom, st_setsrid(st_transform(c.geom, 4258), 4258));
-- 541

/*
update camps.camps4 c set degurba = g.dgurba 
from "DGURBA_2018_01M" g
where degurba is null and st_intersects(g.geom, st_buffer(st_setsrid(st_transform(c.geom, 4258), 4258), 1000));
 */

select k.degurba, count(*) 
from 
(select pays, degurba, zone, case when zone='ZR' then 3 else case when zone='B' or zone='ZIC' then 2 else 1 end end as test 
from camps.camps4 where zone is not null) as k 
where degurba is not null  and k.degurba<>k.test 
group by degurba


select pays, * from camps4
where degurba is null and geom is not null
order by pays

comment on table  "DGURBA_2018_01M" is 'Degré d''urbanisation des unités LAU : 1 -ville) - 2 (banlieue) - 3 (rural)';
comment on column camps.camps4.degurba is 'Degré d''urbanisation des unités LAU : 1 -ville) - 2 (banlieue) - 3 (rural) - croisement avec la base Eurostat degurba EPSG 4258';

-------------------------------
-- croiser avec CLC
-------------------------------

select * from clc.u2018_clc2018_v2020_20u1 ucvu limit 6


alter table camps4 add column point3035 geometry;
update camps4 set point3035 = st_setsrid(st_transform(geom, 3035), 3035);
CREATE INDEX sidx_camps4_point3035 ON camps.camps4 USING gist (point3035);

alter table camps4 add column CLC_majoritaire_3 varchar(3);
alter table camps4 add column distance_124_aeroport float;
alter table camps4 add column distance_13_mines_decharges_chantiers float;
alter table camps4 add column distance_123_zones_portuaires float;
alter table camps4 add column distance_122_reseaux_routiers float;
alter table camps4 add column distance_24_zones_agricoles_heterogenes float;
alter table camps4 add column distance_41_zones_humides_interieures float;

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

select * from camps4 c, clc.u2018_clc2018_v2020_20u1 clc
where st_contains(clc.shape, c.point3035)

alter table camps4 alter column CLC_majoritaire_3 type varchar(3) using CLC_majoritaire_3::text;

update camps.camps4 c set CLC_majoritaire_3 = clc.code_18
from clc.u2018_clc2018_v2020_20u1 clc
where st_contains(clc.shape, c.point3035);
-- 569

select * from camps.camps4 
where CLC_majoritaire_3 is null and geom is not null 
 
update camps.camps4  c set distance_124_aeroport = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps4 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 = '124'
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 662 DONE

update camps.camps4  c set distance_13_mines_decharges_chantiers = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps4 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '13%'
group by c.unique_id
) as k where k.unique_id = c.unique_id
-- 39 s DONE

update camps.camps4  c set distance_123_zones_portuaires = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps4 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '123'
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 5s DONE

update camps.camps4  c set distance_122_reseaux_routiers = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps4 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '122'
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 24 s DONE

update camps.camps4  c set distance_24_zones_agricoles_heterogenes = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps4 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '24%'
group by c.unique_id
) as k where k.unique_id = c.unique_id;
-- 32 min DONE

update camps.camps4  c set distance_41_zones_humides_interieures = round(k.min_d/1000)
from (
select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
from camps4 c, clc.u2018_clc2018_v2020_20u1 clc
where clc.code_18 like '41%'
group by c.unique_id
) as k where k.unique_id = c.unique_id ;
-- 4 min 37 DONE

---------------------------------------------
-- pour l'export
---------------------------------------------


update camps4 set sources = regexp_replace(sources, '\n', ' - ', 'g');

alter table demographie.ne_10m_admin_0_countries add column Espace_Schengen boolean;

update demographie.ne_10m_admin_0_countries set Espace_Schengen = false;
select * from demographie.ne_10m_admin_0_countries;

comment on column demographie.ne_10m_admin_0_countries.Espace_Schengen is 'Le Pays fait partie de l''Espace de Schengen en Europe';

update ne_10m_admin_0_countries set Espace_Schengen = true 
where adm0_a3 in ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC' );--23
/*
UNK	Kosovo
MDA	Moldova
CYP	Cyprus
MNE	Montenegro
HRV	Croatia
UKR	Ukraine
BGR	Bulgaria
LVA	Latvia
MKD	Macedonia
SRB	Serbia
GEO	Georgia
TUR	Turkey
ALB	Albania
ROU	Romania
AZE	Azerbaijan
IRL	Ireland
GBR	United Kingdom of Great Britain and Northern Ireland
BIH	Bosnia and Herzegovina
BLR	Belarus
*/
select distinct iso3, pays from  camps4 c demographie.ne_10m_admin_0_countries

alter table camps4 add column distanceSchengenkm float default 0;
comment on column camps.camps4.distanceSchengenkm is 'Distance en km aux frontières de l''espace de Schengen sur la base du fond natural Earth 10 000eme.';

alter table demographie.ne_10m_admin_0_countries  add column poly3857 geometry;
update demographie.ne_10m_admin_0_countries 
set poly3857 = st_setsrid(st_transform(geom, 3857), 3857)
where Espace_Schengen is true;


update camps.camps4  c set distanceSchengenkm = round(k.min_d/1000)
from (
	select c.unique_id, min(st_distance(c.point3857, ne.poly3857)) as min_d
	from camps4 c, demographie.ne_10m_admin_0_countries ne
	where ne.Espace_Schengen is true 
	and iso3 not in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC' )
	group by c.unique_id
) as k where k.unique_id = c.unique_id ;
-- 204

select * from camps.camps4 where distanceSchengenkm is null;
-- 593	734	Douvres (Angleterre)		Pas de présence sur internet / ni sur closethecamp ni sur globaldetentionproject
-- 598	748	Miksaliste TC		> N'est pas un camp mais un point d'info / enregistrement à Belgrade
update camps.camps4  c set localisation_qualite = 'absent' where distanceSchengenkm is null;

--------------------------------------
-- le 6 octobre : import des données ESRI comme fond de carte
--------------------------------------

export PGCLIENTENCODING=utf8
ogr2ogr -f "PostgreSQL" PG:"host=localhost port=5432 user=postgres dbname=camps_europe password=aqua_77 schemas=demographie" /home/plumegeo/camps_migrants/nuts0.shp -a_srs EPSG:4326 -nln esri_nuts0_2016 -nlt MULTIPOLYGON

drop table demographie.esri_nuts0_2016;
-- import depuis QGIS ok


-----------------------------------------------
-- le 04 nov 2022 : extraction et distance à la poste
select unique_id, nom, type_camp , ville_proche_nom , pays, gare_distance_km , arret_bus_distance_km , pharmacie_distance , hopital_distance , atm_distance , mairie_distance , clc_majoritaire_3   
from camps.camps4 where geom is not null and pays in ('Bosnia and Herzegovina', 'Denmark');

