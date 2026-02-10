import pandas.io.sql as sql
from sqlalchemy import create_engine, text as sql_text
import os
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
print(BASE_DIR)

#camps8_18-03-2025-sansNAniOUTLIERS
FILE_PATH = os.path.join(BASE_DIR, r"camps8_06022026_Maison.csv")

def load_data():
    try:
        QueryTous = """select unique_id, nom_unique, 
        doublon,  bdd_source, localisation_qualite, 
        camp_latitude, camp_longitude, "URL_maps",
        iso3, pays, pays_population , pays_surfacekm2,
        derniere_date_info , actif_dernieres_infos,
        "ouverture/premiere_date", fermeture_date, 
        camp_adresse, camp_code_postal, camp_commune, 
        type_camp, 
        capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
        coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) as capacite,
        prison, 
        degurba, 
        horsdburba, 
        ville_proche_nom ,  "ville_proche_code postal",
        ville_proche_population , distance_ville_proche, 
        eurostat_computed_fua_code, eurostat_computed_gisco_id, eurostat_name_ascii_2016, eurostat_pop_2019, camps_commune_surfacekm2,
        infrastructure_norm,	infrastructure_avant_conversion,	infrastructure_solidite,	infrastructure_confort,
        climat,   
        mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, 
        medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
        ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
        clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, clc_majoritaire_13_mixte,
        distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, distance_121_zi_zac,
        distanceschengenkm, eloignementschengen , classificationWeb, membersClus3 , membersClus4, 
        geom
        from camps.camps8 c 
        where  true
        and point3857 is not null and doublon='Non' 
        order by pays ; """
        
        print("-------------------- Connecting to database -----------------------")
        print("postgresql://camps_reader:Camps_2026@localhost:5432/camps")
        
        #engine = create_engine('postgresql://postgres:postgres@localhost:5432/camps_europe')
        engine = create_engine('postgresql://camps_reader:Camps_2026@localhost:5432/camps')
        ORM_conn=engine.connect()
        ORM_conn
        print(ORM_conn)
        
        df = pd.read_sql_query(con=ORM_conn, sql=sql_text(QueryTous))
        ORM_conn.close()

        df['derniere_date_info'] = pd.to_numeric(df['derniere_date_info'], errors='coerce').astype('Int64')

        print('Data loaded from database')
        print(df.shape)
        #df = pd.read_csv(FILE_PATH, sep=None, engine='python', encoding='utf-8', on_bad_lines='skip')
    except Exception as e:
        print(f"Error connecting to database or executing query: {e}")
        print('reading CSV file')
        try:
            df = pd.read_csv(FILE_PATH, sep=';', encoding='utf-8', on_bad_lines='skip')
        except:
            df = pd.read_csv(FILE_PATH, sep=';', encoding='latin1', on_bad_lines='skip')
    df.columns = df.columns.str.strip()
    return df


main_df = load_data()

