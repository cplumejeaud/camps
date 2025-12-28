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

#Blocage d’une requête multiorigines (Cross-Origin Request) : la politique « Same Origin » ne permet pas de consulter la ressource distante située sur http://vtiles.plumegeo.fr/10/531/363.pbf. Raison : l’en-tête CORS « Access-Control-Allow-Origin » est manquant. Code d’état : 404
#https://stackoverflow.com/questions/25594893/how-to-enable-cors-in-flask

app = Flask(__name__)
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
# CONFIGURATION
# ============================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
#print(BASE_DIR)
FILE_PATH = r"C:\Travail\Enseignement\Cours_M2_python\2025\Projet_CAMPS\camps8_18-03-2025-sansNAniOUTLIERS.csv"
SHAPEFILE_PATH = r"C:\Travail\Enseignement\Cours_M2_python\2025\Projet_CAMPS\Espace_Schengen_ligne\Espace_Schengen_ligne.shp"

FILE_PATH = os.path.join(BASE_DIR, r"camps8_18-03-2025-sansNAniOUTLIERS.csv")
SHAPEFILE_PATH = os.path.join(BASE_DIR, r"Espace_Schengen_ligne\Espace_Schengen_ligne.shp")

DEGURBA_PATH = os.path.join(BASE_DIR, r"DGURBA-2018-01M-SH\DGURBA_2018_01M.shp")
COUNTRIES_PATH = os.path.join(BASE_DIR, r"ne_10m_countries_2021\ne_10m_admin_0_countries.shp")
# ============================================
# CHARGEMENT DES DONNÉES
# ============================================
def load_data():
    try:
        df = pd.read_csv(FILE_PATH, sep=None, engine='python', encoding='utf-8', on_bad_lines='skip')
    except:
        try:
            df = pd.read_csv(FILE_PATH, sep=';', encoding='utf-8', on_bad_lines='skip')
        except:
            df = pd.read_csv(FILE_PATH, sep=';', encoding='latin1', on_bad_lines='skip')
    df.columns = df.columns.str.strip()
    return df

def load_shapefile(filepath):
    gdf = gpd.read_file(filepath)
    if gdf.crs != "EPSG:4326":
        gdf = gdf.to_crs(epsg=4326)
    return gdf

df = load_data()
new_camps = pd.DataFrame(columns=df.columns.tolist())  # DataFrame pour les nouveaux camps ajoutés
gdf_schengen = load_shapefile(SHAPEFILE_PATH)
gdf_countries = load_shapefile(COUNTRIES_PATH)
#https://python-visualization.github.io/folium/latest/user_guide/plugins/vector_tiles.html

# ============================================
# CONSTANTES & MAPPINGS
# ============================================
DEGURBA_MAPPING = {
    'ville': 'ville', 'urban': 'ville', 'urbain': 'ville', 'city': 'ville',
    'banlieue': 'banlieue', 'périphérie': 'banlieue', 'suburban': 'banlieue', 'peri-urban': 'banlieue',
    'rural': 'rural', 'countryside': 'rural', 'campagne': 'rural'
}

ZONE_COLORS = {
    'ville': '#dc2626',
    'banlieue': '#f59e0b',
    'rural': '#059669',
    'non classifié': '#6b7280'
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
def normalize_zone(degurba):
    if not degurba or pd.isna(degurba):
        return 'non classifié'
    return DEGURBA_MAPPING.get(str(degurba).lower().strip(), 'non classifié')

def safe_float(value, default=0.0):
    try:
        return float(value) if pd.notna(value) else default
    except:
        return default



# ============================================
# CARTE FOLIUM
# ============================================
def create_camps_map(dataframe, newcamps):
       
    df_clean = dataframe.dropna(subset=['camp_latitude', 'camp_longitude']).copy().reset_index(drop=True)
    if df_clean.empty:
        return "<p>Aucune donnée de localisation disponible</p>"

    center_lat = df_clean['camp_latitude'].mean()
    center_lon = df_clean['camp_longitude'].mean()

    m = folium.Map(location=[center_lat, center_lon], zoom_start=5, max_bounds=True)

    #folium.TileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    #                 attr='Esri', name='Satellite', overlay=False).add_to(m)
    folium.TileLayer('CartoDB positron', name='Positron').add_to(m)

    for idx, row in df_clean.iterrows():
        #Attention, ce n'était pas degurba qu'il fallait cartographié (changer le fichier source)
        zone = normalize_zone(row.get('degurba'))
        color = ZONE_COLORS.get(zone, ZONE_COLORS['non classifié'])

        icon_html = f"""
        <div style="width:10px;height:10px;background:{color};transform:rotate(45deg);
                    border:0.75px solid white;box-shadow:0 2px 4px rgba(0,0,0,0.3);"></div>
        """
        icon = folium.DivIcon(html=icon_html, icon_size=(14,14), icon_anchor=(7,7))

        camp_name = row.get('nom_unique', 'Camp inconnu').replace("'", "\\'")

        popup_html = f"""
        <div style="font-family:Arial,sans-serif;min-width:200px;">
            <b style="font-size:14px;">{row.get('nom_unique', 'N/A')}</b><br>
            <span style="color:#666;">Type: {row.get('type_camp', 'N/A')}</span><br>
            <span style="color:#666;">Zone: {zone}</span><br>
            <button onclick="window.parent.toggleRadarForCamp({idx}, '{camp_name}')"
                    style="margin-top:10px;padding:8px 16px;background:#16a34a;color:white;
                           border:none;border-radius:4px;cursor:pointer;font-weight:600;">
                Ajouter / Retirer dans le radar
            </button>
        </div>
        """

        folium.Marker(
            location=[row['camp_latitude'], row['camp_longitude']],
            popup=folium.Popup(popup_html, max_width=300),
            tooltip=row.get('nom_unique', 'Camp'),
            icon=icon
        ).add_to(m)

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
        print(newcamps_clean.columns)
        for idx, row in newcamps_clean.iterrows():
            color = "blue"
            icon_html = f"""<div style="width:0;height:0;border-left:7px solid transparent;border-right:7px solid transparent;border-bottom:14px solid {color};border-bottom-color:{color};box-shadow:0 2px 4px rgba(0,0,0,0.3);"></div>"""
            icon = folium.DivIcon(html=icon_html, icon_size=(10,10), icon_anchor=(7,7))

            camp_name = row.get('nom_unique', 'Camp inconnu').replace("'", "\\'")

            popup_html = f"""
                <div style="font-family:Arial,sans-serif;min-width:200px;">
                    <b style="font-size:14px;">{row.get('nom_unique', 'N/A')}</b><br>
                    <span style="color:#666;">Type: {row.get('type_camp', 'N/A')}</span><br>
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

    #return m._repr_html_()
    return m

def create_legend_html():
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
        <b style="font-size: 14px; display: block; margin-bottom: 10px;">Camps</b>
        
        <div style="display: flex; align-items: center; margin-bottom: 6px;">
            <div style="
                width: 10px; height: 10px;
                background-color: {ZONE_COLORS['ville']};
                transform: rotate(45deg);
                margin-right: 8px;
                border: 1px solid white;
            "></div>
            <span style="font-size: 12px;">Ville</span>
        </div>
        
        <div style="display: flex; align-items: center; margin-bottom: 6px;">
            <div style="
                width: 10px; height: 10px;
                background-color: {ZONE_COLORS['banlieue']};
                transform: rotate(45deg);
                margin-right: 8px;
                border: 1px solid white;
            "></div>
            <span style="font-size: 12px;">Banlieue</span>
        </div>
        
        <div style="display: flex; align-items: center; margin-bottom: 6px;">
            <div style="
                width: 10px; height: 10px;
                background-color: {ZONE_COLORS['rural']};
                transform: rotate(45deg);
                margin-right: 8px;
                border: 1px solid white;
            "></div>
            <span style="font-size: 12px;">Rural</span>
        </div>
        
        <div style="display: flex; align-items: center; margin-bottom: 8px;">
            <div style="
                width: 10px; height: 10px;
                background-color: {ZONE_COLORS['non classifié']};
                transform: rotate(45deg);
                margin-right: 8px;
                border: 1px solid white;
            "></div>
            <span style="font-size: 12px;">Non classifié</span>
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
    map = create_camps_map(df, new_camps)

    # map.get_root().render()
    # mapheader = map.get_root().header.render()
    # mapbody_html = map.get_root().html.render()
    # mapscript = map.get_root().script.render()
    map_html = map._repr_html_()

    radar_html = create_global_radar_chart(df)

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
        <div class="container">
            <div class="header">
                <h1>Analyse Géographique des Camps de Migrants en Europe</h1>
                <p>Cartographie interactive et analyse des distances aux infrastructures essentielles</p>
            </div>
            <div class="content">
                <div class="section radar-section">
                    <h2>Distances aux Infrastructures</h2>
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
                    <h2>Carte Interactive</h2>
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
    return render_template_string(template, map_html=map_html, radar_html=radar_html)

@app.route("/get_camp_data/<int:camp_id>")
def get_camp_data(camp_id):
    try:
        camp = df.iloc[camp_id]
        distances = [safe_float(camp.get(col, 0)) for col in INFRASTRUCTURES.values()]
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
    # Generate captcha
    num1 = random.randint(1, 10)
    num2 = random.randint(1, 10)
    captcha_question = f"Combien font {num1} + {num2} ?"
    session['captcha_answer'] = str(num1 + num2)
    
    champs = df.columns.tolist()
    
    # Organiser les champs par catégorie
    categories = {
        'Informations générales': ['nom_unique', 'type_camp', 'capacite'],
        'Localisation': ['camp_latitude', 'camp_longitude', 'pays'],
        #'Distances infrastructures': [col for col in champs if 'distance' in col.lower()],
        #'Autres': [col for col in champs if col not in ['nom_unique', 'type_camp', 'degurba', 'camp_latitude', 'camp_longitude', 'pays'] and 'distance' not in col.lower()]
    }
    
    form_fields = ""
    for cat_name, cols in categories.items():
        form_fields += f'<div class="form-category"><h3>{cat_name}</h3>'
        for col in cols:
            form_fields += f"""
            <div class="form-group">
                <label for="{col}">{col}</label>
                <input type="text" id="{col}" name="{col}" placeholder="Entrez {col}">
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
        return redirect(url_for('add_camp'))
    
    global new_camps
    #print("I see the submit_camp")
    new_data = {col: request.form.get(col) for col in new_camps.columns}
    try:
        new_camps = pd.concat([new_camps, pd.DataFrame([new_data])], ignore_index=True)
        #print("Data added successfully")
    except Exception as e:
        print(f"Error adding data: {e}")
    return redirect(url_for('index'))


if __name__ == "__main__":
    app.run(debug=True,  port=5000) #use_reloader=False,