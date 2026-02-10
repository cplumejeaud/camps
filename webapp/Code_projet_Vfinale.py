# ============================================
# Code_projet_V4.py – Version finale avec radar adaptatif + bouton vider
# ============================================

from flask import Flask, render_template_string, request, redirect, url_for, jsonify, session
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
        
        #engine = create_engine('postgresql://postgres:postgres@localhost:5432/camps_europe')
        print("-------------------- Connecting to database -----------------------")
        print("postgresql://camps_reader:Camps_2026@localhost:5432/camps")
        engine = create_engine('postgresql://camps_reader:Camps_2026@localhost:5432/camps')
        ORM_conn=engine.connect()
        ORM_conn
        print(ORM_conn)
        
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
    df['derniere_date_info'] = pd.to_numeric(df['derniere_date_info'], errors='coerce').astype('Int64')
    
    return df

def load_shapefile(filepath):
    gdf = gpd.read_file(filepath)
    if gdf.crs != "EPSG:4326":
        gdf = gdf.to_crs(epsg=4326)
    return gdf

camps = load_data()
#print(camps.columns)

    
## Formulaire 
formColumns = ['nom_unique', 'camp_latitude', 'camp_longitude', 'camp_adresse', 'pays', 'type_camp', 'ouverture/premiere_date', 'fermeture_date', 'actif_dernieres_infos', 'derniere_date_info', 'bdd_source', 'capacite', 'infrastructure_norm', 'infrastructure_avant_conversion', 'hommes', 'femmes', 'mineurs', 'mail_contributeur', 'comment']

## DataFrame pour les nouveaux camps ajoutés via le formulaire
## Si le serveur est redémarré, les données seront perdues, mais on peut les sauvegarder dans un csv pour garder une trace (optionnel)
## Lire les données existantes dans le csv au démarrage du serveur pour les réintégrer dans la carte
if os.path.exists(CSVFILE_PATH) :
    new_camps = pd.read_csv(CSVFILE_PATH, sep=";") 
else :
    new_camps = pd.DataFrame(columns=formColumns)  # DataFrame pour les nouveaux camps ajoutés 

#new_camps = pd.DataFrame(columns=formColumns)  # DataFrame pour les nouveaux camps ajoutés 
gdf_schengen = load_shapefile(SHAPEFILE_PATH)
gdf_countries = load_shapefile(COUNTRIES_PATH)
#https://python-visualization.github.io/folium/latest/user_guide/plugins/vector_tiles.html

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
    'ATM': 'atm_distance'
}



# ============================================
# UTILITAIRES
# ============================================
def normalize_zone(classificationweb):
    if not classificationweb or pd.isna(classificationweb):
        return 'non classifié'
    return DEGURBA_MAPPING.get(str(classificationweb).lower().strip(), 'non classifié')

def safe_float(value, default=0.0):
    try:
        return float(value) if pd.notna(value) else default
    except:
        return default

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

    folium.TileLayer('CartoDB positron', name='Positron').add_to(m)

    # Deux couches de camps, les actifs et les inactifs
    camps_actifs_layer = folium.FeatureGroup(name="Camps actifs", show=True)
    camps_inactifs_layer = folium.FeatureGroup(name="Camps désaffectés", show=False)

    for idx, row in dataframe.iterrows():
        actif = row.get('actif_dernieres_infos', 'non') == 'oui' and (int(row.get('derniere_date_info', 0)) >= 2018)
        
        #Attention, ce n'était pas degurba qu'il fallait cartographié (changer le fichier source)
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
            <span style="color:#666;">Type : {row.get('type_camp', 'N/A')}</span><br>
            <span style="color:#666;">Actif : {actif}</span><br>
            <span style="color:#666;">Classification : {zone}</span><br>
            <button onclick="window.parent.toggleRadarForCamp({idx}, '{camp_name}')"
                    style="margin-top:10px;padding:8px 16px;background:#16a34a;color:white;
                           border:none;border-radius:4px;cursor:pointer;font-weight:600;">
                Ajouter / Retirer dans le radar
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
    folium.GeoJson(gdf_schengen, name="Frontières Schengen",
                   style_function=lambda x: {'fillColor':'none', 'color':'blue', 'weight':2}).add_to(m)

    folium.GeoJson(gdf_countries, name="Countries (natural earth)",
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

    VectorGridProtobuf(url, "cities (FUA 2020)", options, show=False).add_to(m)

    vectorTileLayerStyles2 = {}
    vectorTileLayerStyles2["degurba01"] = styles["degurba01"]
    vectorTileLayerStyles2["degurba02"] = styles["degurba02"]
    vectorTileLayerStyles2["degurba03"] = styles["degurba03"]
    #print(vectorTileLayerStyles2)
    url = "http://vtiles.plumegeo.fr/degurba/{z}/{x}/{y}.pbf"
    options = {
        "vectorTileLayerStyles": vectorTileLayerStyles2
    }

    VectorGridProtobuf(url, "DEGURBA (Eurostat 2018)", options, show=False).add_to(m)

    # Nouveaux camps ajoutés via le formulaire
    newcamps_clean = newcamps.dropna(subset=['camp_latitude', 'camp_longitude']).copy().reset_index(drop=True)
    if not newcamps_clean.empty:
        print(newcamps_clean.shape)
        #print(newcamps_clean.columns)
        for idx, row in newcamps_clean.iterrows():
            zone = 'non vérifié'
            color = ZONE_COLORS[zone]
            actif = row.get('actif_dernieres_infos', 'non') == 'oui' and (int(row.get('derniere_date_info', 0)) >= 2018)
            #icon_html = f"""<div style="width:0;height:0;border-left:6px solid transparent;border-right:6px solid transparent;border-bottom:12px solid {color};border-bottom-color:{color};"></div>"""
            icon_html = get_zone_shape(row.get('type_camp'), zone, color, actif)
            icon = folium.DivIcon(html=icon_html, icon_size=(10,10), icon_anchor=(7,7))

        
            camp_name = row.get('nom_unique', 'Camp inconnu').replace("'", "\\'")

            popup_html = f"""
                <div style="font-family:Arial,sans-serif;min-width:200px;">
                    <b style="font-size:14px;">{row.get('nom_unique', 'N/A')}</b><br>
                    <span style="color:#666;">Type : {row.get('type_camp', 'N/A')}</span><br>
                    <span style="color:#666;">Actif : {actif}</span><br>
                    <span style="color:#666;">Classification : {zone}</span><br>
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
        window.open('/add_camp?lat=' + lat + '&lng=' + lng, '_blank');
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
    return f'''
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
        <b style="font-size: 14px; display: block; margin-bottom: 10px;">Camps actifs</b>
        
        <table
            style="border-collapse: collapse; margin-bottom: 10px; width: 100%;">
            <tr>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">Type de camp</span>
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">Ville</span>
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">Banlieue</span>
                </td>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">Rural</span>
                </td>
            </tr>
            <tr>
                <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                    <span style="font-size: 12px;">Ouvert</span>
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
                    <span style="font-size: 12px;">Fermé</span>
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
                    <span style="font-size: 12px;">Clopen</span>
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
            <span style="font-size: 12px;">Non classifié</span>
        </div>

        <div style="display: flex; align-items: center; margin-bottom: 8px;">
            {get_zone_shape('', 'non vérifié', 'black', True)}
            <span style="font-size: 12px;">Non vérifié</span>
        </div>

        <div style=" margin-top: 10px; padding-top: 8px; border-top: 1px solid #e0e0e0;">
        
            <b style="font-size: 14px; display: block; margin-bottom: 10px;">Camps désaffectés</b>
        
            <table
                style="border-collapse: collapse; margin-bottom: 10px; width: 100%;">
                <tr>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">Type de camp</span>
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">Ville</span>
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">Banlieue</span>
                    </td>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">Rural</span>
                    </td>
                </tr>
                <tr>
                    <td style="padding: 4px; border: 1px solid #e0e0e0; text-align: center; vertical-align: middle;">
                        <span style="font-size: 12px;">Ouvert</span>
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
                        <span style="font-size: 12px;">Fermé</span>
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
                        <span style="font-size: 12px;">Clopen</span>
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
                <span style="font-size: 12px;">Non classifié</span>
            </div>

            <div style="display: flex; align-items: center; margin-bottom: 8px;">
                {get_zone_shape('', 'non vérifié', 'black', False)}
                <span style="font-size: 12px;">Non vérifié</span>
            </div>
        
        </div>
        
        <div style="display: flex; align-items: center; margin-top: 10px; padding-top: 8px; border-top: 1px solid #e0e0e0;">
            <div style="
                width: 20px;
                height: 2px;
                background-color: blue;
                margin-right: 8px;
            "></div>
            <span style="font-size: 12px;">Frontières Schengen</span>
        </div>
    </div>
    '''


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



# ============================================
# ROUTES
# ============================================
@app.route("/")
def index():
    map = create_camps_map(camps, new_camps)

    # map.get_root().render()
    # mapheader = map.get_root().header.render()
    # mapbody_html = map.get_root().html.render()
    # mapscript = map.get_root().script.render()
    map_html = map._repr_html_()

    radar_html = create_global_radar_chart(camps)
    info_message = session.pop('info_message', None)
    
    template = """
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Analyse Géographique des Camps de Migrants en Europe</title>
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <script src="https://cdn.plot.ly/plotly-2.27.0.min.js"></script>
        <style>
            * { margin:0; padding:0; box-sizing:border-box; }
            body {font-family:'Segoe UI',sans-serif; background:linear-gradient(135deg,#667eea,#764ba2); min-height:100vh; padding:20px;}
            .container {max-width:1800px; margin:auto; background:white; border-radius:20px; box-shadow:0 20px 60px rgba(0,0,0,0.3); overflow:hidden;}
            .header {background:linear-gradient(135deg,#2d3748,#1a202c); color:white; padding:40px; text-align:center;}
            .header h1 {font-size:2.5em; margin-bottom:10px;}
            .content {display:grid; grid-template-columns:33.33% 66.67%; gap:30px; padding:40px;}
            .section {background:#f8f9fa; border-radius:15px; padding:15px; box-shadow:0 4px 15px rgba(0,0,0,0.08);}
            .section h2 {color:#2d3748; font-size:1.5em; margin-bottom:20px; display:flex; align-items:center; gap:10px;}
            .section h2::before {content:''; width:4px; height:24px; background:linear-gradient(#667eea,#764ba2); border-radius:2px;}
            .radar-section {grid-column:1; grid-row:1;}
            .button-section {grid-column:2; grid-row:2; display:flex; flex-direction:column; gap:20px;}
            .map-section {grid-column:2; grid-row:1; overflow: hidden;}
            #map {height:100%; min-height:500px; border-radius:10px;}
            #radarChart {height:420px; width:100%;}
            .btn-add, .btn-about, .btn-clear {padding:18px; background:linear-gradient(135deg,#1f77b4,#125b86); color:white; border-radius:12px;
                      text-align:center; text-decoration:none; font-weight:600; font-size:18px; box-shadow:0 4px 15px rgba(31,119,180,0.3); cursor:pointer;}
            .btn-clear {background:linear-gradient(135deg,#dc2626,#991b1b);}
            .btn-add:hover, .btn-about:hover, .btn-clear:hover {transform:translateY(-3px); box-shadow:0 8px 25px rgba(0,0,0,0.4);}
            .camp-info {background:#e3f2fd; padding:15px; border-radius:8px; margin-bottom:15px; border-left:4px solid #1f77b4;}
            .modal {display:none; position:fixed; z-index:1000; left:0; top:0; width:100%; height:100%; background-color:rgba(0,0,0,0.5);}
            .modal-content {background-color:white; margin:15% auto; padding:20px; border-radius:10px; width:80%; max-width:500px; position:relative;}
            .close {color:#aaa; float:right; font-size:28px; font-weight:bold; cursor:pointer;}
            .close:hover {color:black;}
            @media (max-width:1200px){
                .content {grid-template-columns:1fr;}
                .radar-section{grid-row:2;} .button-section{grid-row:3;} .map-section{grid-row:1;}
            }
        </style>
    </head>
    <body>
        {% if info_message %}
        <div style="background:#e0f7fa;color:#006064;padding:12px 20px;border-radius:8px;
                    margin:20px auto 0 auto;max-width:700px;text-align:center;font-size:1.1em;">
            {{ info_message }}
        </div>
        {% endif %}
        <div class="container">
            <div class="header">
                <h1>Analyse Géographique des Camps de Migrants en Europe</h1>
                <p>Cartographie interactive et analyse des distances aux infrastructures essentielles</p>
            </div>
            <div class="content">
                <div class="section radar-section">
                    <h2>Distances aux aménités socio-environnementales</h2>
                    <div class="camp-info" id="campInfo" style="display:none;">
                        <h3 id="campName"></h3>
                        <p id="campDetails"></p>
                    </div>
                    <div id="radarChart">{{ radar_html|safe }}</div>
                    <div style="text-align:center; margin-top:15px;">
                        <button class="btn-clear" onclick="clearAllIndividualCamps()">Vider le radar</button>
                    </div>
                </div>

                <div class="section button-section">
                    <h2>Actions</h2>
                    <a class="btn-add" href="{{ url_for('add_camp') }}">Ajouter un nouveau camp</a>
                    <button class="btn-about" onclick="showAboutModal()">À propos</button>
                </div>

                <div class="section map-section">
                    <h2>Carte des camps pour migrants en Europe et autour</h2>
                    <div id="map">{{ map_html|safe }} </div> 
                </div>
            </div>
        </div>

        <!-- Modal À propos -->
        <div id="aboutModal" class="modal">
            <div class="modal-content">
                <span class="close" onclick="closeAboutModal()">&times;</span>
                <h2>À propos</h2>
                
                <p>Cette application propose une visualisation interactive des camps en Europe, base de données complétée et qualifiée de mars 2025, en collaboration avec Louis Fernier, doctorant à Migrinter.
                <br>
                L'application a été développée dans le cadre du Master 2 SPE à La Rochelle, UE Data to Information, en décembre 2025, sous la responsabilité de Christine Plumejeaud-Perreau, enseignante de l'UE par des étudiants du Master 2 SPE :
                <ul><li>Damien Glo</li><li>Killian Lheote</li><li>Joseph Fournier.</li>    
                </ul>
                <br>
                C'est un prototype visant à démontrer les capacités d'exploration et visualisation des profils des camps avec Python (3.10). Il nécessite des améliorations pour une utilisation en production (en particulier pour le formulaire de saisie de nouveaux camps qui ne fonctionne pas). <br>
                </p>
                <p>Développé avec Flask, Folium, et Plotly, le code source est disponible sur le github de l'enseignante, sous licence Affero GPL v3.</p>
            </div>
        </div>

        <script>

            const visibleCamps = new Set();
            let originalMaxRange = 50; // Valeur par défaut, sera mise à jour au chargement

            // Attend que Plotly ait chargé le graphique initial
            document.addEventListener('DOMContentLoaded', function() {
                const radarDiv = document.getElementById('radarChart');
                
                // Récupérer la vraie échelle maximale utilisée au départ (moyenne/médiane)
                function updateOriginalScale() {
                    if (radarDiv.data && radarDiv.data.length >= 2) {
                        const means = radarDiv.data[0].r.slice(0, -1);
                        const medians = radarDiv.data[1].r.slice(0, -1);
                        const allValues = [...means, ...medians];
                        originalMaxRange = Math.max(...allValues) * 1.25;
                        if (originalMaxRange < 10) originalMaxRange = 50; // sécurité
                    }
                }

                // Observer les changements du graphique Plotly
                radarDiv.on('plotly_relayout', updateOriginalScale);
                radarDiv.on('plotly_afterplot', updateOriginalScale);

                // Au premier rendu
                setTimeout(updateOriginalScale, 500);
            });

            // Fonction pour recalculer la meilleure échelle selon les données visibles
            function updateRadarScale() {
                const div = document.getElementById('radarChart');
                if (!div.data || div.data.length === 0) return;

                let maxVal = 0;
                div.data.forEach(trace => {
                    if (trace.r && trace.visible !== 'legendonly') {
                        const traceMax = Math.max(...trace.r.slice(0, -1));
                        if (traceMax > maxVal) maxVal = traceMax;
                    }
                });

                const newRange = maxVal === 0 ? originalMaxRange : maxVal * 1.25;
                const finalRange = Math.max(newRange, 5); // jamais trop petit

                Plotly.relayout('radarChart', {
                    'polar.radialaxis.range': [0, finalRange]
                });
            }

            const colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf'];

            window.toggleRadarForCamp = function(campId, campName) {
                const radarDiv = document.getElementById('radarChart');
                if (!radarDiv.data) return;

                const traceIndex = radarDiv.data.findIndex(t => t.name === campName);

                if (traceIndex === -1) {
                    // === AJOUTER LE CAMP ===
                    fetch(`/get_camp_data/${campId}`)
                        .then(r => r.json())
                        .then(data => {
                            if (data.error && data.info) {
                                alert(data.info);
                                return;
                            }
                            const dist = [...data.distances, data.distances[0]];
                            const cat = [...data.categories, data.categories[0]];
                            const color = colors[visibleCamps.size % colors.length];

                            Plotly.addTraces('radarChart', [{
                                type: 'scatterpolar',
                                r: dist,
                                theta: cat,
                                fill: 'toself',
                                name: data.nom,
                                line: { color: color, width: 2 }, // Trait plus fin
                                //  fillcolor: color.replace(')', ', 0.2)').replace('rgb', 'rgba'), // Remplissage plus transparent
                                opacity: 0.6
                            }]);

                            visibleCamps.add(data.nom);
                            updateRadarScale();

                            // Info camp
                            document.getElementById('campName').textContent = data.nom;
                            document.getElementById('campDetails').textContent = `Type: ${data.type} | Zone: ${data.zone}`;
                            document.getElementById('campInfo').style.display = 'block';

                            // Changer le bouton en "Masquer"
                            setTimeout(() => {
                                const btn = document.querySelector(`button[onclick="window.parent.toggleRadarForCamp(${campId}, '${campName.replace(/'/g, "\\'")}')"]`);
                                if (btn) {
                                    btn.textContent = "Masquer du radar";
                                    btn.style.background = "#991b1b";
                                }
                            }, 100);
                        });
                } else {
                    // === SUPPRIMER LE CAMP ===
                    Plotly.deleteTraces('radarChart', traceIndex);
                    visibleCamps.delete(campName);
                    updateRadarScale();

                    // Remettre le bouton en "Voir"
                    setTimeout(() => {
                        const btn = document.querySelector(`button[onclick="window.parent.toggleRadarForCamp(${campId}, '${campName.replace(/'/g, "\\'")}')"]`);
                        if (btn) {
                            btn.textContent = "Voir dans le radar";
                            btn.style.background = "#16a34a";
                        }
                    }, 100);

                    // Cacher l'info si plus rien
                    if (visibleCamps.size === 0) {
                        document.getElementById('campInfo').style.display = 'none';
                    }
                }
            };

            // === BOUTON VIDER TOUT ===
            function clearAllIndividualCamps() {
                const radarDiv = document.getElementById('radarChart');
                if (!radarDiv.data || radarDiv.data.length <= 2) return;

                // Supprimer tous les tracés sauf les 2 premiers (moyenne + médiane)
                const tracesToRemove = [];
                for (let i = radarDiv.data.length - 1; i >= 2; i--) {
                    tracesToRemove.push(i);
                }

                Plotly.deleteTraces('radarChart', tracesToRemove);
                visibleCamps.clear();
                document.getElementById('campInfo').style.display = 'none';

                // Remettre l'échelle d'origine (calculée automatiquement)
                Plotly.relayout('radarChart', {
                    'polar.radialaxis.range': [0, 5]
                });

                // Réinitialiser tous les boutons
                document.querySelectorAll('button[onclick*="toggleRadarForCamp"]').forEach(btn => {
                    btn.textContent = "Voir dans le radar";
                    btn.style.background = "#16a34a";
                });
            }

            // Option bonus : mise à jour automatique toutes les 300ms après un changement (fluidité)
            let updateTimeout;
            document.getElementById('radarChart').on('plotly_restyle', () => {
                clearTimeout(updateTimeout);
                updateTimeout = setTimeout(updateRadarScale, 300);
            });

            // Modal functions
            function showAboutModal() {
                document.getElementById('aboutModal').style.display = 'block';
            }
            function closeAboutModal() {
                document.getElementById('aboutModal').style.display = 'none';
            }
            // Close modal when clicking outside
            window.onclick = function(event) {
                const modal = document.getElementById('aboutModal');
                if (event.target == modal) {
                    modal.style.display = 'none';
                }
            }
        </script>
    </body>
    </html>
    """
    #return render_template_string(template, mapheader=mapheader, mapbody_html=mapbody_html, mapscript=mapscript, radar_html=radar_html)
    return render_template_string(template, map_html=map_html, radar_html=radar_html, info_message=info_message)

@app.route("/get_camp_data/<int:camp_id>")
def get_camp_data(camp_id):
    try:
        camp = camps.iloc[camp_id]
        distances = [safe_float(camp.get(col, 0)) for col in INFRASTRUCTURES.values()]
        #Si toutes les distances sont nulles ou invalides, on peut choisir de ne pas afficher le radar pour ce camp
        if all((d is None or d == 0) for d in distances):
            return jsonify({
                'error': 'Aucune donnée de distance disponible pour ce camp.',
                'info': "Les distances aux aménités socio-environnementales des camps de ce pays n'ont pas (encore) été calculées."
                }), 400
        return jsonify({
            'nom': str(camp.get('nom_unique', 'Inconnu')),
            'type': str(camp.get('type_camp', 'N/A')),
            'zone': normalize_zone(camp.get('degurba')),
            'distances': distances,
            'categories': list(INFRASTRUCTURES.keys())
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 404


# --- Formulaire pour ajouter un nouveau camp ---
@app.route("/add_camp", methods=["GET"])
def add_camp():
    """ - Nom du camp _[texte]_

- Adresse précise _[texte]_

- Pays _[liste]_

- Type de camp ("ouvert" / "fermé" / "clo-pen") _[liste / radio bouton]_

- Date d'ouverture (si connue) _[date]_

- actif_dernieres_infos (si le camp est encore actif ou si les dernières informations disponibles indiquent qu'il l'était) _[case à cocher]_

- Date de fermeture (si camp désormais inactif) _[date]_

- Date de la dernière information _[date]_

- Source (observation personnelle / article journalistique / lien internet) _[case à cocher + texte]_

- Capacité du camp _[int]_

- Infrastructure réemployée _[liste + texte si "autre"]_

- Personnes encampées (si information disponible : hommes / femmes / enfants) _[case à cocher]_

- Mail de la personne qui contribue _[texte]_

- Champ de texte libre _[texte]_ """
    
    # Generate captcha
    num1 = random.randint(1, 10)
    num2 = random.randint(1, 10)
    captcha_question = f"Combien font {num1} + {num2} ?"
    session['captcha_answer'] = str(num1 + num2)
    
    # Get coordinates from query parameters
    lat = request.args.get('lat', '')
    lng = request.args.get('lng', '')
    
    champs = camps.columns.tolist()
    
    # Organiser les champs par catégorie
    categories = {
        'Informations générales': ['nom_unique', 'type_camp', 'capacite'],
        'Localisation': ['camp_latitude', 'camp_longitude', 'camp_adresse', 'pays'],
        'Détails': ['ouverture/premiere_date', 'fermeture_date', 'actif_dernieres_infos', 'derniere_date_info', 'infrastructure_norm', 'infrastructure_avant_conversion', 'hommes', 'femmes', 'mineurs'],
        'Métadonnées' : ['bdd_source', 'mail_contributeur', 'comment']
        #'Distances infrastructures': [col for col in champs if 'distance' in col.lower()],
        #'Autres': [col for col in champs if col not in ['nom_unique', 'type_camp', 'degurba', 'camp_latitude', 'camp_longitude', 'pays'] and 'distance' not in col.lower()]
    }
    
    form_fields = ""
    for cat_name, cols in categories.items():
        form_fields += f'<div class="form-category"><h3>{cat_name}</h3>'
        for col in cols:
            # Pre-fill latitude and longitude if provided
            value = ""
            if col == 'camp_latitude' and lat:
                value = lat
            elif col == 'camp_longitude' and lng:
                value = lng
            
            form_fields += f"""
            <div class="form-group">
                <label for="{col}">{col}</label>
                <input type="text" id="{col}" name="{col}" placeholder="Entrez {col}" value="{value}">
            </div>
            """
        form_fields += '</div>'
    
    # Add captcha field
    form_fields += f'''
    <div class="form-category">
        <h3>Vérification</h3>
        <div class="form-group">
            <label for="captcha">{captcha_question}</label>
            <input type="text" id="captcha" name="captcha" placeholder="Entrez la réponse" required>
        </div>
    </div>
    '''
    
    template = f"""
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Ajouter un camp</title>
        <style>
            * {{ margin: 0; padding: 0; box-sizing: border-box; }}
            body {{
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                padding: 20px;
            }}
            .form-container {{
                max-width: 900px;
                margin: 0 auto;
                background: white;
                border-radius: 20px;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                overflow: hidden;
            }}
            .form-header {{
                background: linear-gradient(135deg, #2d3748 0%, #1a202c 100%);
                color: white;
                padding: 30px;
                text-align: center;
            }}
            .form-header h1 {{
                font-size: 2em;
                margin-bottom: 10px;
            }}
            .form-content {{
                padding: 40px;
            }}
            .form-category {{
                margin-bottom: 30px;
                padding: 20px;
                background: #f8f9fa;
                border-radius: 10px;
            }}
            .form-category h3 {{
                color: #2d3748;
                margin-bottom: 15px;
                padding-bottom: 10px;
                border-bottom: 2px solid #667eea;
            }}
            .form-group {{
                margin-bottom: 15px;
            }}
            .form-group label {{
                display: block;
                font-weight: 600;
                color: #4a5568;
                margin-bottom: 5px;
            }}
            .form-group input {{
                width: 100%;
                padding: 10px;
                border: 2px solid #e2e8f0;
                border-radius: 8px;
                font-size: 14px;
                transition: all 0.3s ease;
            }}
            .form-group input:focus {{
                outline: none;
                border-color: #667eea;
                box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
            }}
            .form-actions {{
                display: flex;
                gap: 15px;
                justify-content: center;
                margin-top: 30px;
            }}
            .btn {{
                padding: 12px 30px;
                border: none;
                border-radius: 8px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s ease;
                text-decoration: none;
                display: inline-block;
            }}
            .btn-submit {{
                background: #667eea;
                color: white;
            }}
            .btn-submit:hover {{
                background: #5568d3;
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
            }}
            .btn-cancel {{
                background: #e2e8f0;
                color: #4a5568;
            }}
            .btn-cancel:hover {{
                background: #cbd5e0;
            }}
        </style>
    </head>
    <body>
        <div class="form-container">
            <div class="form-header">
                <h1>➕ Ajouter un nouveau camp</h1>
                <p>Remplissez les informations ci-dessous</p>
                <p>Ne saisissez pas de point-virgules (;) dans les champs sinon la saisie sera refusée</p>
            </div>
            <div class="form-content">
                <form method="post" action="{{{{ url_for('submit_camp') }}}}">
                    {form_fields}
                    <div class="form-actions">
                        <button type="submit" class="btn btn-submit">✓ Enregistrer</button>
                        <a href="{{{{ url_for('index') }}}}" class="btn btn-cancel">← Annuler</a>
                    </div>
                </form>
            </div>
        </div>
    </body>
    </html>
    """
    return render_template_string(template)

# --- Traitement des données saisies ---
@app.route("/submit_camp", methods=["POST"])
def submit_camp():
    # Verify captcha
    user_captcha = request.form.get('captcha')
    correct_captcha = session.get('captcha_answer')
    
    if not user_captcha or user_captcha != correct_captcha:
        # Invalid captcha, redirect back to form
        session['info_message'] = "Erreur de vérification : la réponse au captcha est incorrecte."
        return redirect(url_for('add_camp'))
    
    global new_camps
    new_data = {col: request.form.get(col) for col in new_camps.columns}
    #Tester que les données ne contiennent pas de point-virgule (car sinon ça casse le csv)
    for key, value in new_data.items():
        if value and ';' in value:
            #print(f"Invalid input for {key}: contains semicolon")  
            #On indique quel champ est concerné dans le message d'erreur   
            session['info_message'] = f"Erreur : le champ '{key}' contient un point-virgule, ce qui n'est pas autorisé."
            return redirect(url_for('add_camp'))
    try:
        new_camps = pd.concat([new_camps, pd.DataFrame([new_data])], ignore_index=True)
        #print("Data added successfully")
        #Sauver le camps dans un csv pour garder une trace (optionnel)
        new_camps.to_csv(CSVFILE_PATH, index=False, mode='w', sep=';')
        session['info_message'] = "Le camp a bien été ajouté et enregistré."
    except Exception as e:
        session['info_message'] = f"Erreur lors de l'ajout du camp : {e}"
        print(f"Error adding data: {e}")
    return redirect(url_for('index'))


if __name__ == "__main__":
    app.run(debug=False,  port=5000) #use_reloader=False,