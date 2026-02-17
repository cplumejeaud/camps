# ============================================
# Code_projet_V4.py – Version finale avec radar adaptatif + bouton vider
# ============================================

from flask import Flask, render_template, render_template_string, request, redirect, url_for, jsonify, session, g
import pandas as pd
import folium
import plotly.graph_objects as go
import numpy as np
import geopandas as gpd
import os
import random
from folium.plugins import VectorGridProtobuf
from flask_cors import CORS, cross_origin
# import error handling file from where you have defined it
import error

import pandas.io.sql as sql
from sqlalchemy import create_engine, text as sql_text
from datetime import datetime


# ============================================
# CONFIGURATION
# ============================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
#print(BASE_DIR)
#FILE_PATH = r"C:\Travail\Enseignement\Cours_M2_python\2025\Projet_CAMPS\camps8_18-03-2025-sansNAniOUTLIERS.csv"
#SHAPEFILE_PATH = r"C:\Travail\Enseignement\Cours_M2_python\2025\Projet_CAMPS\Espace_Schengen_ligne\Espace_Schengen_ligne.shp"

#camps8_18-03-2025-sansNAniOUTLIERS
FILE_PATH = os.path.join(BASE_DIR, r"camps8_06022026_Maison.csv")
SHAPEFILE_PATH = os.path.join(BASE_DIR, r"Espace_Schengen_ligne")
SHAPEFILE_PATH = os.path.join(SHAPEFILE_PATH, r"Espace_Schengen_ligne.shp")

DEGURBA_PATH = os.path.join(BASE_DIR, r"DGURBA-2018-01M-SH\DGURBA_2018_01M.shp")
COUNTRIES_PATH = os.path.join(BASE_DIR, r"ne_10m_countries_2021")
COUNTRIES_PATH = os.path.join(COUNTRIES_PATH, r"ne_10m_admin_0_countries.shp")


TEMPLATE_PATH = os.path.join(BASE_DIR, 'templates/')
STATIC_PATH = os.path.join(BASE_DIR, 'static/')

CSVFILE_PATH = os.path.join(BASE_DIR, r"new_camps.csv")

CONFIGFILE_PATH = os.path.join(BASE_DIR, r"config_webapp.xlsx")

# ============================================
# INIT the app
# ============================================

#Blocage d’une requête multiorigines (Cross-Origin Request) : la politique « Same Origin » ne permet pas de consulter la ressource distante située sur http://vtiles.plumegeo.fr/10/531/363.pbf. Raison : l’en-tête CORS « Access-Control-Allow-Origin » est manquant. Code d’état : 404
#https://stackoverflow.com/questions/25594893/how-to-enable-cors-in-flask

app = Flask(__name__, template_folder = TEMPLATE_PATH)
app.secret_key = 'your-secret-key-here-change-in-production'  # Required for session
CORS(app) # This will enable CORS for all routes
error.init_handler(app) # initialise error handling 

#CORS(app, resources={r"/*": {"origins": "*"}})
#CORS(app, origins=['http://localhost:5000', 'http://vtiles.plumegeo.fr/*'])
#app.config['CORS_HEADERS'] = 'Content-Type'
#https://www.alsacreations.com/article/lire/1938-La-notion-d-origine-web-et-CORS.html

# https://stackoverflow.com/questions/26980713/solve-cross-origin-resource-sharing-with-flask
#cors = CORS(app, resources={r"/": {"origins": "*"}})
#app.config['CORS_HEADERS'] = 'Content-Type'



# ============================================
# CHARGEMENT DES DONNÉES
# ============================================
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
        #print("postgresql://camps_reader:Camps_2026@localhost:5432/camps")
        #engine = create_engine('postgresql://camps_reader:Camps_2026@localhost:5432/camps')
        engine = create_engine('postgresql://postgres:postgres@localhost:5432/camps_europe')
        
        ORM_conn=engine.connect()
        ORM_conn
        #print(ORM_conn)
        
        df = pd.read_sql_query(con=ORM_conn, sql=sql_text(QueryTous))

        print('Data loaded from database')
        print(df.shape)
        
        ORM_conn.close()

    except Exception as e:
        print(f"Error connecting to database or executing query: {e}")
        print('reading CSV file')
        try:
            df = pd.read_csv(FILE_PATH, sep=';', encoding='utf-8', on_bad_lines='skip')
            #df = pd.read_csv(FILE_PATH, sep=None, engine='python', encoding='utf-8', on_bad_lines='skip')
        except:
            df = pd.read_csv(FILE_PATH, sep=';', encoding='latin1', on_bad_lines='skip')
    df.columns = df.columns.str.strip()

    #df['derniere_date_info'] = pd.to_numeric(df['derniere_date_info'], errors='coerce').astype('Int64')
    df['derniere_date_info'] = pd.to_datetime(df['derniere_date_info'], errors='coerce', format='%Y')
    
    return df

def load_shapefile(filepath):
    gdf = gpd.read_file(filepath)
    if gdf.crs != "EPSG:4326":
        gdf = gdf.to_crs(epsg=4326)
    return gdf



config_notes  = pd.read_excel(CONFIGFILE_PATH, sheet_name='2024-11-25_indices_isolement', skiprows=1)
config_translations  = pd.read_excel(CONFIGFILE_PATH, sheet_name='traductions')
config_countries = pd.read_excel(CONFIGFILE_PATH, sheet_name='codes_iso3166_2024-06-19', skiprows=1)
#print(config_countries.shape)

TRANSLATIONS = dict()
for _, col in config_translations.columns.to_series().items():
    if (col.strip() != 'keys') :
        TRANSLATIONS[col.strip()] = dict()
        for _, row in config_translations.iterrows():
            TRANSLATIONS[col.strip()][row['keys']] = row[col.strip()]

#print(TRANSLATIONS)

camps = load_data()
#print(camps.columns)

    
## Formulaire 
formColumns = ['nom_unique', 'camp_latitude', 'camp_longitude', 'camp_adresse', 'pays', 'type_camp', 
               'ouverture/premiere_date', 'fermeture_date', 'actif_dernieres_infos', 'derniere_date_info', 
               'capacite', 'infrastructure_norm', 'infrastructure_avant_conversion', 'infrastructure_autre',
               'hommes', 'femmes', 'mineurs', 
               'type_source_observation', 'type_source_journalism', 'type_source_Web', 'bdd_source', 'mail_contributeur', 'comment']

## DataFrame pour les nouveaux camps ajoutés via le formulaire
## Si le serveur est redémarré, les données seront perdues, mais on peut les sauvegarder dans un csv pour garder une trace (optionnel)
## Lire les données existantes dans le csv au démarrage du serveur pour les réintégrer dans la carte
if os.path.exists(CSVFILE_PATH) :
    new_camps = pd.read_csv(CSVFILE_PATH, sep=";") 
    #new_camps['derniere_date_info'] = pd.to_datetime(new_camps['derniere_date_info'], errors='coerce', format='%Y-%m-%d')
else :
    new_camps = pd.DataFrame(columns=formColumns)  # DataFrame pour les nouveaux camps ajoutés 
new_camps['derniere_date_info'] = pd.to_datetime(new_camps['derniere_date_info'], errors='coerce', format='%Y-%m-%d')

#new_camps = pd.DataFrame(columns=formColumns)  # DataFrame pour les nouveaux camps ajoutés 
gdf_schengen = load_shapefile(SHAPEFILE_PATH)
gdf_countries = load_shapefile(COUNTRIES_PATH)
#https://python-visualization.github.io/folium/latest/user_guide/plugins/vector_tiles.html


# ===========================================
# INTERNATIONALISATION
# ===========================================

def get_locale():
    global TRANSLATIONS
    # 1. Via URL param ?lang=fr/en
    lang = request.args.get('lang')
    if lang in TRANSLATIONS:
        session['lang'] = lang
        return lang
    # 2. Via session
    if 'lang' in session and session['lang'] in TRANSLATIONS:
        return session['lang']
    # 3. Via browser headers
    accept = request.headers.get('Accept-Language', '')
    for l in accept.split(','):
        code = l.split('-')[0].strip()
        if code in TRANSLATIONS:
            return code
    # 4. Default
    return 'en'

def _(key, **kwargs):
    global TRANSLATIONS
    #lang = get_locale()
    lang='en' #en mode débug pour forcer l'anglais et éviter les problèmes de traduction pendant le développement
    txt = TRANSLATIONS[lang].get(key, key)
    return txt.format(**kwargs) if kwargs else txt

# ============================================
# CONSTANTES & MAPPINGS
# ============================================
DEGURBA_MAPPING = {
    'ville': 'ville', 'urban': 'ville', 'urbain': 'ville', 'city': 'ville',
    'banlieue': 'banlieue', 'périphérie': 'banlieue', 'suburban': 'banlieue', 'peri-urban': 'banlieue',
    'rural': 'rural', 'countryside': 'rural', 'campagne': 'rural', 'non vérifié': 'non vérifié'
}

ZONE_COLORS = {
    'ville': '#dc2626',
    'banlieue': '#f59e0b',
    'rural': '#059669',
    'non classifié': '#6b7280',
    'non vérifié': "#000000"
}


        
INFRASTRUCTURES = {
    'Hôpital': 'hopital_distance',
    'Pharmacie': 'pharmacie_distance',
    'Médecin': 'medecin_clinique_hors_camp_distance_km',
    'École': 'ecole_hors_camp_distance_km',
    'Mairie': 'mairie_distance',
    'Bus': 'arret_bus_distance_km',
    'Gare': 'gare_distance_km',
    'Automate bancaire': 'atm_distance'
}



# ============================================
# UTILITAIRES
# ============================================

def get_country_from_coordinates(lat, lng):
    point = gpd.points_from_xy([lng], [lat], crs="EPSG:4326")
    for idx, row in gdf_countries.iterrows():
        if row['geometry'].contains(point[0]):
            return row['ADM0_A3']  # ou 'name' selon ce que vous voulez retourner
    return None

def normalize_zone(classificationweb):
    if not classificationweb or pd.isna(classificationweb):
        return 'non classifié'
    return DEGURBA_MAPPING.get(str(classificationweb).lower().strip(), 'non classifié')

""" def safe_float(value, default=0.0):
    try:
        return float(value) if pd.notna(value) else default
    except:
        return default """

def safe_float(value, default=0.0):
    if isinstance(value, (list, np.ndarray, pd.Series)):
        value = value.iloc[0] if hasattr(value, 'iloc') else value[0]
    try:
        return float(value) if pd.notna(value) else default
    except:
        print(f"Warning: could not convert '{value}' to float. Returning default value {default}.")
        return default
    
def distance_to_note(distance, infra, config_notes):
    """
    Convertit une distance en note (1-5) selon la table config_notes pour une infrastructure donnée.
    - distance : valeur numérique de la distance
    - infra : nom de l'infrastructure (ex: 'Hôpital') / Critère
    - config_notes : DataFrame de correspondance
    """
    if isinstance(distance, (list, np.ndarray, pd.Series)):
        distance = distance.iloc[0] if hasattr(distance, 'iloc') else distance[0]
        
    # Filtrer la table pour l'infrastructure concernée
    table = config_notes[config_notes['Critère'] == infra]
    #print(f"Calculating note for distance {distance} and infrastructure '{infra}'")
    index = 0
    for i, row in table.iterrows():
        try:
            min_val = float(row['Constat'])
            if (index + 1) < len(table) : 
                max_val = float(table.iloc[index + 1]['Constat'])  
            else :
                max_val = float('inf')
            #print(f"""{min_val}  - {max_val} : {int(row['Note'])}""")
            if min_val <= distance < max_val:
                return int(row['Note'])
        except Exception as e:
            print(f"Error processing row {index} for infrastructure '{infra}': {e}")
            continue
        index = index+1
    return None  # ou une note par défaut


def  get_zone_shape(type_camp, classificationweb, color, actif) : 
    # &#9658; https://www.w3schools.com/charsets/ref_utf_geometric.asp drapeau sur fond blanc
    if (classificationweb=='non classifié') : 
        #print("point")
        #point  ok
        icon = f"""<div style="width:7px;height:7px;border-radius:50%;background:#222;display:inline-block;margin-right: 8px;"></div>"""
        
        if (not actif) : 
            # point avec cible autour pour inactifs
            icon = f"""<div style="width:16px;height:16px;border-radius:50%;border:1px solid {color};background:transparent;display:flex;align-items:center;justify-content:center;margin-right: 8px;">
                <div style="width:7px;height:7px;border-radius:50%;background:{color};border:1px solid {color};display:inline-block;"></div>
            </div>"""
    elif  (classificationweb=='non vérifié') :
        #print("triangle")
        #triangle ok
        icon = f"""<div style="width:0;height:0;
                border-left:6px solid transparent;
                border-right:6px solid transparent;
                border-bottom:12px solid {color};
                border-bottom-color:{color};
                margin-right: 8px;
                position:relative;
            ">
            </div>
            """
        if (not actif) : 
            # triangle hâchuré pour inactifs
            icon = f"""
                <div style="
                    width:0;height:0;
                    border-left:6px solid transparent;
                    border-right:6px solid transparent;
                    border-bottom:12px solid {color};
                    position:relative;
                    margin-right: 8px;
                ">
                <div style="
                    position:absolute;
                    left:-6px; top:0;
                    width:12px; height:12px;
                    clip-path:polygon(50% 0%,0% 100%,100% 100%);
                    background: repeating-linear-gradient(45deg, #fff 0 2px, transparent 2px 4px);
                    opacity:0.7;
                    pointer-events:none;
                "></div>
            </div>
            """
    elif (type_camp == 'ouvert') : 
        #rond  plein pour actifs
        icon = f"""
            <div style="width:12px;height:12px;border-radius:50%;
            background:{color};border:0.75px solid white;
            box-shadow:0 2px 4px rgba(0,0,0,0.3);
            margin-right: 8px;"></div>
        """
        if (not actif) : 
            # rond hâchuré pour inactifs
            icon = f"""
            <div style="
                width:12px;height:12px;border-radius:50%;
                background: repeating-linear-gradient(
                    45deg, {color}, {color} 2px, #fff 2px, #fff 4px
                );
                border:2px solid {color};
                box-shadow:0 2px 4px rgba(0,0,0,0.3);
                margin-right: 8px;
            "></div>
            """
    elif (type_camp == 'fermé') : 
        #carré ok
        icon = f"""
        <div style="width:11px;height:11px;background:{color};
            border:0.75px solid white;
            box-shadow:0 2px 4px rgba(0,0,0,0.3);
            margin-right: 8px;"></div>
        """
        if (not actif) : 
            # carré hâchuré pour inactifs
            icon = f"""
            <div style="
                width:11px;height:11px;
                background: repeating-linear-gradient(
                    45deg, {color}, {color} 2px, #fff 2px, #fff 4px
                );
                border:2px solid {color};
                box-shadow:0 2px 4px rgba(0,0,0,0.3);
                margin-right: 8px;
            "></div>
            """
    elif (type_camp == 'doute' or type_camp == 'semi-ouvert') : 
        #losange ok
        icon = f"""
        <div style="width:12px;height:12px;background:{color};transform:rotate(45deg);
                    border:0.75px solid white;
                    box-shadow:0 2px 4px rgba(0,0,0,0.3) transform:rotate(30deg);
                    margin-right: 8px;"></div>
        """
        if (not actif) : 
            # losange hâchuré pour inactifs
            icon = f"""
            <div style="
                width:12px;height:12px;transform:rotate(45deg);
                background: repeating-linear-gradient(
                    45deg, {color}, {color} 2px, #fff 2px, #fff 4px
                );
                border:2px solid {color};
                box-shadow:0 2px 4px rgba(0,0,0,0.3)  transform:rotate(45deg);
                margin-right: 8px;
            "></div>
            """
    return icon

# ============================================
# CARTE FOLIUM
# ============================================
def create_camps_map(dataframe, newcamps):
         
    center_lat = dataframe['camp_latitude'].mean()
    center_lon = dataframe['camp_longitude'].mean()

    m = folium.Map(location=[center_lat, center_lon], zoom_start=5, max_bounds=True)

    folium.TileLayer('CartoDB positron', name=_('map_background')).add_to(m)

    # Deux couches de camps, les actifs et les inactifs
    camps_actifs_layer = folium.FeatureGroup(name=_('map_layer_actifs'), show=True)
    camps_inactifs_layer = folium.FeatureGroup(name=_('map_layer_inactifs'), show=False)


    for idx, row in dataframe.iterrows():
        #print(f"Processing camp {idx} - {row.get('nom_unique', 'N/A')}")
        date_objet = row.get('derniere_date_info', None) if  not pd.isnull(row.get('derniere_date_info', None)) else datetime.strptime('2000', '%Y')
        #print(date_objet)
        annee_derniere_date_info = int(date_objet.year) 
        #print(annee_derniere_date_info)
        
        actif = row.get('actif_dernieres_infos', 'non') == 'oui' and (annee_derniere_date_info >= 2018)
        
        # Attention, classificationweb est précalculé en base de données à partir d'une CAH sur AFCM 
        # pour tous les camps couverts par les CLC et de qualité de localisation satisfaisante
        zone = normalize_zone(row.get('classificationweb'))
        color = ZONE_COLORS.get(zone, ZONE_COLORS['non classifié'])

        #TRACE type_camps, classificationweb, color
        #if row.get('unique_id') == '154' or row.get('unique_id')== '165':
        #    print(f"""type_camp: {row.get('type_camp')}, classificationweb: {zone}, color: {color}, actif: {actif}""")
        icon_html = get_zone_shape(row.get('type_camp'), zone, color, actif)

        icon = folium.DivIcon(html=icon_html, icon_size=(14,14), icon_anchor=(7,7))

        camp_name = row.get('nom_unique', 'Camp inconnu').replace("'", "\\'")

        popup_html = f"""
        <div style="font-family:Arial,sans-serif;min-width:200px;">
            <b style="font-size:14px;">{row.get('nom_unique', 'N/A')}</b><br>
            <span style="color:#666;">{_('camp_type')} : {row.get('type_camp', 'N/A')}</span><br>
            <span style="color:#666;">{_('camp_actif')} : {actif}</span><br>
            <span style="color:#666;">{_('camp_classification')} : {zone}</span><br>
            <button onclick="window.parent.toggleRadarForCamp({idx}, '{camp_name}')"
                    style="margin-top:10px;padding:8px 16px;background:#16a34a;color:white;
                           border:none;border-radius:4px;cursor:pointer;font-weight:600;">
                {_('add_or_remove_radar')}
            </button>
            
        </div>
        """
        marker = folium.Marker(
                location=[row['camp_latitude'], row['camp_longitude']],
                popup=folium.Popup(popup_html, max_width=300),
                tooltip=row.get('nom_unique', 'Camp'),
                icon=icon
            )
        
        if( actif):
            marker.add_to(camps_actifs_layer)
        else:
            marker.add_to(camps_inactifs_layer)

    camps_actifs_layer.add_to(m)
    camps_inactifs_layer.add_to(m)
    folium.GeoJson(gdf_schengen, name=_('map_layer_schengen'),
                   style_function=lambda x: {'fillColor':'none', 'color':'blue', 'weight':2}).add_to(m)

    folium.GeoJson(gdf_countries, name=_('map_layer_countries'),
                   style_function=lambda x: {'fillColor':'none', 'color':'black', 'weight':1}, show=False).add_to(m)
    
    styles = {
        "cities": {
            "fill": True,
            "weight": 1,
            "fillColor": "#cc068a",
            "color": "#cc068a",
            "fillOpacity": 0.2,
            "opacity": 0.4
        },
        "degurba01": {
            "fill": True,
            "weight": 1,
            "fillColor": "#ea0a0e",
            "color": "#ea0a0e00",
            "fillOpacity": 0.2,
            "opacity": 0.4
        },
        "degurba02": {
            "fill": True,
            "weight": 0.1,
            "fillColor": "#eafb01",
            "color": "#eafb0100",
            "fillOpacity": 0.2,
            "opacity": 0.4
        },
        "degurba03": {
            "fill": True,
            "weight": 0.1,
            "fillColor": "#13df68",
            "color": "#13df6800",
            "fillOpacity": 0.2,
            "opacity": 0.4
        },}
    vectorTileLayerStyles = {}
    vectorTileLayerStyles["cities"] = styles["cities"]
    url = "http://vtiles.plumegeo.fr/fua/{z}/{x}/{y}.pbf"
    options = {
        "vectorTileLayerStyles": vectorTileLayerStyles
    }

    VectorGridProtobuf(url, _('map_layer_cities'), options, show=False).add_to(m)

    vectorTileLayerStyles2 = {}
    vectorTileLayerStyles2["degurba01"] = styles["degurba01"]
    vectorTileLayerStyles2["degurba02"] = styles["degurba02"]
    vectorTileLayerStyles2["degurba03"] = styles["degurba03"]
    #print(vectorTileLayerStyles2)
    url = "http://vtiles.plumegeo.fr/degurba/{z}/{x}/{y}.pbf"
    options = {
        "vectorTileLayerStyles": vectorTileLayerStyles2
    }

    VectorGridProtobuf(url, _('map_layer_degurba') , options, show=False).add_to(m)

    # Nouveaux camps ajoutés via le formulaire
    #print("Nouveaux camps ajoutés via le formulaire")
    newcamps_clean = newcamps.dropna(subset=['camp_latitude', 'camp_longitude']).copy().reset_index(drop=True)
    if not newcamps_clean.empty:
        #print(newcamps_clean.shape)
        #print(newcamps_clean.columns)
        for idx, row in newcamps_clean.iterrows():
            zone = 'non vérifié'
            color = ZONE_COLORS[zone]
            
            #print(f"Processing new camp {idx} - {row.get('nom_unique', 'Camp inconnu')} - {row.get('derniere_date_info', 'N/A')}")
            date_objet = row.get('derniere_date_info', None) if  not pd.isnull(row.get('derniere_date_info', None)) else datetime.strptime('2000', '%Y')
            annee_derniere_date_info = date_objet.year         
            #print(annee_derniere_date_info)  
            actif = row.get('actif_dernieres_infos', 'non') == 'oui' and (annee_derniere_date_info >= 2018)
            #icon_html = f"""<div style="width:0;height:0;border-left:6px solid transparent;border-right:6px solid transparent;border-bottom:12px solid {color};border-bottom-color:{color};"></div>"""
            icon_html = get_zone_shape(row.get('type_camp'), zone, color, actif)
            icon = folium.DivIcon(html=icon_html, icon_size=(10,10), icon_anchor=(7,7))

            
            camp_name = row.get('nom_unique', 'Camp inconnu').replace("'", "\\'")

            popup_html = f"""
                <div style="font-family:Arial,sans-serif;min-width:200px;">
                    <b style="font-size:14px;">{row.get('nom_unique', 'N/A')}</b><br>
                    <span style="color:#666;">{_('camp_type')} : {row.get('type_camp', 'N/A')}</span><br>
                    <span style="color:#666;">{_('camp_actif')} : {actif}</span><br>
                    <span style="color:#666;">{_('camp_classification')} : {zone}</span><br>
                </div>
                """
            folium.Marker(
                location=[row['camp_latitude'], row['camp_longitude']],
                popup=folium.Popup(popup_html, max_width=300),
                tooltip=row.get('nom_unique', 'Camp non vérifié'),
                icon=icon
            ).add_to(m)

    folium.LayerControl().add_to(m)
    m.get_root().html.add_child(folium.Element(create_legend_html()))

    # Add double-click functionality to open add_camp form
    double_click_script = """
    <script>
    // Function to handle double-click on map
    function onMapDoubleClick(e) {
        var lat = e.latlng.lat.toFixed(6);
        var lng = e.latlng.lng.toFixed(6);
        window.open('/create_camp?lat=' + lat + '&lng=' + lng, '_blank');
    }

    // Add the event listener after map loads
    document.addEventListener('DOMContentLoaded', function() {
        // Find all Folium maps
        var maps = document.querySelectorAll('.folium-map');
        maps.forEach(function(mapDiv) {
            // Get the map ID from the div
            var mapId = mapDiv.id;
            if (window[mapId]) {
                window[mapId].on('dblclick', onMapDoubleClick);
            }
        });
    });
    </script>
    """
    
    # Inject the double-click script into the map's HTML
    m.get_root().html.add_child(folium.Element(double_click_script))

    
    #return m._repr_html_()
    return m

def create_legend_html():
    #icon_html_rond = get_zone_shape('ouvert', '', 'grey', True)
    #icon_html_carre = get_zone_shape('fermé', '', 'grey', True)
    #icon_html_losange = get_zone_shape('semi-ouvert', '', 'grey', True)
    #icon_html_point = get_zone_shape('', 'non classifié', 'grey', True)
    #icon_html_triangle = get_zone_shape('', 'non vérifié', 'black', True)


    """Crée le HTML de la légende"""
    return f"""
    <div style="
        position: fixed;
        bottom: 20px;
        left: 20px;
        z-index: 9999;
        background-color: white;
        border: 2px solid rgba(0,0,0,0.2);
        border-radius: 8px;
        padding: 12px 15px;
        font-family: Arial, sans-serif;
        box-shadow: 0 2px 10px rgba(0,0,0,0.2);
    ">
        <b style="font-size: 14px; display: block; margin-bottom: 10px;">{_('active_camps')}</b>
        
        <table
            style="border-collapse: collapse; margin-bottom: 10px; width: 100%;">
            <tr>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">{_('camp_type')}</span>
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">{_('city')}</span>
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">{_('suburb')}</span>
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">{_('rural')}</span>
                </td>
            </tr>
            <tr>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">{_('type_camp_open')}</span>
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    {get_zone_shape('ouvert', '', ZONE_COLORS['ville'], True)}
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    {get_zone_shape('ouvert', '', ZONE_COLORS['banlieue'], True)}
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    {get_zone_shape('ouvert', '', ZONE_COLORS['rural'], True)}
                </td>
            </tr>
            <tr>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">{_('type_camp_closed')}</span>
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    {get_zone_shape('fermé', '', ZONE_COLORS['ville'], True)}
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    {get_zone_shape('fermé', '', ZONE_COLORS['banlieue'], True)}
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    {get_zone_shape('fermé', '', ZONE_COLORS['rural'], True)}
                </td>
            </tr>
            <tr>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">{_('type_camp_clopen')}</span>
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    {get_zone_shape('semi-ouvert', '', ZONE_COLORS['ville'], True)}
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    {get_zone_shape('semi-ouvert', '', ZONE_COLORS['banlieue'], True)}
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    {get_zone_shape('semi-ouvert', '', ZONE_COLORS['rural'], True)}
                </td>
            </tr>
        </table>
        
        <div style="display: flex; align-items: center; margin-bottom: 8px;">
            {get_zone_shape('', 'non classifié', 'grey', True)}
            <span style="font-size: 12px;">{_('not_classified')}</span>
        </div>

        <div style="display: flex; align-items: center; margin-bottom: 8px;">
            {get_zone_shape('', 'non vérifié', 'black', True)}
            <span style="font-size: 12px;">{_('not_verified')}</span>
        </div>

        <div style=" margin-top: 10px; padding-top: 8px; border-top: 1px solid #e0e0e0;">
        
            <b style="font-size: 14px; display: block; margin-bottom: 10px;">{_('inactive_camps')}</b>
        
            <table
                style="border-collapse: collapse; margin-bottom: 10px; width: 100%;">
                <tr>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">{_('camp_type')}</span>
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">{_('city')}</span>
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">{_('suburb')}</span>
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">{_('rural')}</span>
                    </td>
                </tr>
                <tr>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">{_('type_camp_open')}</span>
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        {get_zone_shape('ouvert', '', ZONE_COLORS['ville'], False)}
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        {get_zone_shape('ouvert', '', ZONE_COLORS['banlieue'], False)}
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        {get_zone_shape('ouvert', '', ZONE_COLORS['rural'], False)}
                    </td>
                </tr>
                <tr>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">{_('type_camp_closed')}</span>
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        {get_zone_shape('fermé', '', ZONE_COLORS['ville'], False)}
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        {get_zone_shape('fermé', '', ZONE_COLORS['banlieue'], False)}
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        {get_zone_shape('fermé', '', ZONE_COLORS['rural'], False)}
                    </td>
                </tr>
                <tr>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">{_('type_camp_clopen')}</span>
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        {get_zone_shape('semi-ouvert', '', ZONE_COLORS['ville'], False)}
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        {get_zone_shape('semi-ouvert', '', ZONE_COLORS['banlieue'], False)}
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        {get_zone_shape('semi-ouvert', '', ZONE_COLORS['rural'], False)}
                    </td>
                </tr>
            </table>
        
            <div style="display: flex; align-items: center; margin-bottom: 8px;">
                {get_zone_shape('', 'non classifié', 'grey', False)}
                <span style="font-size: 12px;"> {_('not_classified')}</span>
            </div>

            <div style="display: flex; align-items: center; margin-bottom: 8px;">
                {get_zone_shape('', 'non vérifié', 'black', False)}
                <span style="font-size: 12px;">{_('not_verified')}</span>
            </div>
        
        </div>
        
        <div style="display: flex; align-items: center; margin-top: 10px; padding-top: 8px; border-top: 1px solid #e0e0e0;">
            <div style="
                width: 20px;
                height: 2px;
                background-color: blue;
                margin-right: 8px;
            "></div>
            <span style="font-size: 12px;">{_('map_layer_schengen')}</span>
        </div>
    </div>
    """


# ============================================
# RADAR GLOBAL + ADAPTATIF
# ============================================
def create_global_radar_chart(dataframe):
    categories = list(INFRASTRUCTURES.keys())
    means = [np.mean(dataframe[col].apply(safe_float).dropna()) for col in INFRASTRUCTURES.values()]
    medians = [np.median(dataframe[col].apply(safe_float).dropna()) for col in INFRASTRUCTURES.values()]

    # On garde toujours moyenne/médiane comme base
    means += [means[0]]
    medians += [medians[0]]

    fig = go.Figure()

    fig.add_trace(go.Scatterpolar(
        r=means,
        theta=categories + [categories[0]],
        mode='lines',
        name='Moyenne',
        line=dict(color='black', width=1),
    ))

    fig.add_trace(go.Scatterpolar(
        r=medians,
        theta=categories + [categories[0]],
        mode='lines',
        name='Médiane',
        line=dict(color='black', width=1, dash='dash'),
    ))

    fig.update_layout(
        polar=dict(
            radialaxis=dict(
                visible=True,
                range=[0, 5],
                ticksuffix=' km',
                gridcolor='#e5e7eb',
                angle=90,  # Mettre les valeurs verticalement
            ),
            angularaxis=dict(
                rotation=90,  # Rotation pour meilleure lisibilité
                direction='clockwise'
            )
        ),
        showlegend=True,
        height=400,
        margin=dict(l=40, r=40, t=40, b=40),
        font=dict(size=11),
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=-0.4,
            xanchor="center",
            x=0.5
        ),
        uirevision='constant'  # Maintenir l'état du graphique lors des mises à jour
    )
    
    return fig.to_html(full_html=False, include_plotlyjs='cdn', div_id='radarChart')


# === 1. Créer une fonction pour le second radar chart avec les notes===
def create_secondary_radar_chart(dataframe):
    # Exemple : radar sur la médiane des notes (au lieu des distances)
    categories = list(INFRASTRUCTURES.keys())
    # On utilise la fonction distance_to_note pour chaque camp et chaque infra
    notes_matrix = []
    for _, row in dataframe.iterrows():
        notes = [distance_to_note(row.get(col, 0), col, config_notes) or 0 for col in INFRASTRUCTURES.values()]
        notes_matrix.append(notes)
    notes_matrix = np.array(notes_matrix)
    medians = np.median(notes_matrix, axis=0)
    medians = list(medians) + [medians[0]]

    fig = go.Figure()
    fig.add_trace(go.Scatterpolar(
        r=medians,
        theta=categories + [categories[0]],
        mode='lines+markers',
        name='Médiane des notes',
        line=dict(color='purple', width=2),
    ))
    fig.update_layout(
        polar=dict(
            radialaxis=dict(visible=True, range=[0, 5], gridcolor='#e5e7eb'),
            angularaxis=dict(rotation=90, direction='clockwise')
        ),
        showlegend=True,
        height=400,
        margin=dict(l=40, r=40, t=40, b=40),
        font=dict(size=11),
        legend=dict(orientation="h", yanchor="bottom", y=-0.4, xanchor="center", x=0.5),
        uirevision='constant'
    )
    return fig.to_html(full_html=False, include_plotlyjs='cdn', div_id='radarChart2')



# ============================================
# ROUTES
# ============================================

@app.before_request
def before_request():
    g.lang = get_locale()
    
@app.route("/")
def index():
    map = create_camps_map(camps, new_camps)

    # map.get_root().render()
    # mapheader = map.get_root().header.render()
    # mapbody_html = map.get_root().html.render()
    # mapscript = map.get_root().script.render()
    map_html = map._repr_html_()

    radar_html = create_global_radar_chart(camps) # Radar pour les distances
    radar2_html = create_secondary_radar_chart(camps)  #Radar pour les notes

    info_message = session.pop('info_message', None)

    return render_template("index.html", map_html=map_html, radar_html=radar_html, radar2_html=radar2_html, info_message=info_message, _=_, lang=get_locale())

@app.route("/get_camp_data/<int:camp_id>")
def get_camp_data(camp_id):
    try:
        camp = camps.iloc[camp_id]
        distances = [safe_float(camp.get(col, 0)) for col in INFRASTRUCTURES.values()]
        global config_notes
        notes = [distance_to_note(camp.get(col, 0),col, config_notes) for col in INFRASTRUCTURES.values()]

        #Si toutes les distances sont nulles ou invalides, on peut choisir de ne pas afficher le radar pour ce camp
        if all((d is None or d == 0) for d in distances):
            return jsonify({
                'error': 'Aucune donnée de distance disponible pour ce camp.',
                'info': "Les distances aux aménités socio-environnementales des camps de ce pays n'ont pas (encore) été calculées."
                }), 400
        return jsonify({
            'nom': str(camp.get('nom_unique', 'Inconnu')),
            'type': str(camp.get('type_camp', 'N/A')),
            'zone': normalize_zone(camp.get('classificationweb')),
            'actif': camp.get('actif_dernieres_infos', 'non') == 'oui' and (not pd.isnull(camp.get('derniere_date_info', None)) and int(camp.get('derniere_date_info').year) >= 2018),
            'distances': distances,
            'notes': notes,
            'categories': list(INFRASTRUCTURES.keys())
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 404


# --- Formulaire pour ajouter un nouveau camp ---
@app.route("/create_camp", methods=["GET"])
def create_camp():
    """ - Nom du camp _[texte]_
        - Type de camp ("ouvert" / "fermé" / "clo-pen") _[liste / radio bouton]_
        - actif_dernieres_infos (si le camp est encore actif ou si les dernières informations disponibles indiquent qu'il l'était) _[case à cocher]_
        - Date de la dernière information _[date]_

        - Coordonnées GPS (latitude / longitude) _[texte]_
        - Adresse précise _[texte]_
        - Pays _[liste]_

        - Date d'ouverture (si connue) _[date]_
        - Date de fermeture (si camp désormais inactif) _[date]_
        - Capacité du camp _[int]_
        - Infrastructure réemployée _[liste + texte si "autre"]_
        - Personnes encampées (si information disponible : hommes / femmes / enfants) _[case à cocher]_

        - Mail de la personne qui contribue _[texte]_
        - Source (observation personnelle / article journalistique / lien internet) _[case à cocher + texte]_
        - Champ de texte libre _[texte]_ 
        """

    ## liste des parameètres du template
    g.lang = get_locale()
    submit_url = url_for('submit_camp')
    index_url = url_for('index')

                                       
    # Generate captcha
    num1 = random.randint(1, 10)
    num2 = random.randint(1, 10)
    captcha_question = _('captcha_question').format(num1=num1, num2=num2)
    session['captcha_answer'] = str(num1 + num2)
    
    # Get coordinates from query parameters
    lat = request.args.get('lat', '')
    lng = request.args.get('lng', '')
    

    
    ## Crer une liste des pays avec autocompletion qui renseigne avec le code ISO3
    #URL : https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes/blob/master/all/all.csv
    global config_countries
    config_countries.rename(columns={'alpha-3': 'alpha3'}, inplace=True)  # Renommer pour éviter les problèmes de tirets dans les noms de champs   
    ##Calculer le pays à partir des coordonnées si possible pour pré-remplir le champ pays et éviter les erreurs de saisie
    computed_country_name = ""
    if lat and lng:
        computed_country_code = get_country_from_coordinates(lat, lng)
        if computed_country_code:
            computed_country_name = config_countries.loc[config_countries['alpha3'] == computed_country_code, 'name'].values[0]
    options_countries = ""
    #Sélectionner le pays calculé à partir de la lat/lng si possible
    for index, row  in config_countries.iterrows() :
        options_countries += f'<option value="{row["alpha3"]}" required>{row["name"]}</option>'
    #print(options)
    if computed_country_name:
        options_countries = f'<option value="{computed_country_code}" selected>{computed_country_name}</option>' + options_countries
    
    ## Liste des infrastructures pour le champ "infrastructure_norm" avec gestion des valeurs manquantes et tri
    liste_infrastructure = pd.unique(camps.infrastructure_norm.fillna('Autre'))  # Assurer que les valeurs manquantes sont traitées comme "Autre"
    liste_infrastructure = sorted(liste_infrastructure, key=lambda x: str(x).lower())  # Tri lexicographique insensible à la casse
    options_infra = ""
    for infra in liste_infrastructure:
        options_infra += f'<option value="{infra}">{infra}</option>'
    
    #print(submit_url)  # Debug: afficher l'url de soumission
    info_message = session.pop('info_message', None)

    return render_template("add_template.html", _=_, submit_url=submit_url, index_url=index_url, captcha_question=captcha_question, options_countries=options_countries, options_infra=options_infra, lat_value=lat, lng_value=lng, lang=get_locale(), info_message=info_message)


# --- Traitement des données saisies ---
@app.route("/submit_camp", methods=["POST"])
def submit_camp():
    # Verify captcha
    user_captcha = request.form.get('captcha')
    correct_captcha = session.get('captcha_answer')
    
    if not user_captcha or user_captcha != correct_captcha:
        # Invalid captcha, redirect back to form
        session['info_message'] = _('error_captcha') 
        #"Erreur de vérification : la réponse au captcha est incorrecte."
        return redirect(url_for('create_camp'))
    
    # Verify mandatory fields (e.g., nom_unique, type_camp)
    nom_unique = request.form.get('nom_unique')
    type_camp = request.form.get('type_camp')   
    actif_dernieres_infos = request.form.get('actif_dernieres_infos')  
    #print(f"le camps soumis est actif ? {actif_dernieres_infos}") 
    derniere_date_info = request.form.get('derniere_date_info')   
    latitude = request.form.get('camp_latitude')
    longitude = request.form.get('camp_longitude')  
    if not nom_unique or not type_camp or not actif_dernieres_infos or not derniere_date_info or not latitude or not longitude:
        session['info_message'] = _('error_mandatory') 
        #"Erreur : veuillez remplir tous les champs obligatoires (nom unique, type de camp, actif ou non, date de la dernière information, et les coordonnées géographiques du camp)."
        return redirect(url_for('create_camp')) 
    
    # Contrôle des bornes latitude/longitude
    try:
        lat_f = float(latitude)
        lng_f = float(longitude)
        if not (-90 <= lat_f <= 90) or not (-180 <= lng_f <= 180):
            print("Latitude or longitude out of range")
            session['info_message'] = _('error_latlng_range')
            return redirect(url_for('create_camp'))
    except Exception as e:
        print(f"Error parsing latitude/longitude: {e}")
        session['info_message'] = _('error_latlng_format')
        return redirect(url_for('create_camp'))
    
    global new_camps
    new_data = {col: request.form.get(col) for col in new_camps.columns}
    #Tester que les données ne contiennent pas de point-virgule (car sinon ça casse le csv)
    for key, value in new_data.items():
        if value and ';' in value:
            #print(f"Invalid input for {key}: contains semicolon")  
            #On indique quel champ est concerné dans le message d'erreur   
            session['info_message'] = _('error_semicolon').format(key=key) 
            #f"Erreur : le champ '{key}' contient un point-virgule, ce qui n'est pas autorisé."
            return redirect(url_for('create_camp'))
    try:
        new_camps = pd.concat([new_camps, pd.DataFrame([new_data])], ignore_index=True)
        new_camps['derniere_date_info'] = pd.to_datetime(new_camps['derniere_date_info'], errors='coerce', format='%Y-%m-%d')

        #print("Data added successfully")
        #Sauver le camps dans un csv pour garder une trace (optionnel)
        new_camps.to_csv(CSVFILE_PATH, index=False, mode='w', sep=';')
        session['info_message'] = _('success_add')
    except Exception as e:
        session['info_message'] = _('failure_add').format(e=e) 
        # f"Erreur lors de l'ajout du camp : {e}"
        print(f"Error adding data: {e}")
    return redirect(url_for('index'))


if __name__ == "__main__":
    app.run(debug=True,  port=5000) #use_reloader=False,