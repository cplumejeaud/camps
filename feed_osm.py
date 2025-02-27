'''
Auteur : Christine Plumejeaud, 09 octobre 2024
Objectif : l'import de pays d'europe dans la base OSM
Licence : AGPL v3
Test : avec python 3.7 et postgres 11 sur mapuce
'''

import os
import psycopg2
import paramiko
import sys
import logging
import configparser
import json
import subprocess
#from sshHandler import *
from subprocess import PIPE
import shlex

import fiona
import datetime
import subprocess
import time




class FeedOsm(object):

    def __init__(self, config):
        ## Ouvrir le fichier de log
        logging.basicConfig(filename=config.get('log', 'file'), level=int(config.get('log', 'level')), filemode='w')
        self.logger = logging.getLogger(type(self).__name__)
        self.logger.debug('log file for DEBUG')
        self.logger.info('log file for INFO')
        self.logger.warning('log file for WARNINGS')
        self.logger.error('log file for ERROR')
        

    def getConnection(self, config) : 
        # Acceder aux parametres de configuration
        host = config.get('base', 'host')
        port = config.get('base', 'port')
        dbname = config.get('base', 'dbname')
        superuser = config.get('base', 'superuser')
        password = config.get('base', 'superuserpass')
        driverPostgres = 'host=' + host + ' port=' + port + ' user=' + superuser + ' dbname=' + dbname + ' password=' + password
        #driverPostgres = driverPostgres + ' options="-c search_path='+schema+',public"'
        #self.logger.debug(driverPostgres)

        options="'-c search_path=public'" #The schema you want to modify, arctic_christine first, then public

        connectString = 'host=' + host + ' port=' + port + ' user=' + superuser + ' dbname=' + dbname + ' password=' + password + ' options=' + options
        #connectString = 'host=' + host + ' port=' + port + ' user=' + user + ' dbname=' + dbname + ' password=' + password 
        self.logger.info(connectString)

        conn = None
        try:
            conn = psycopg2.connect(connectString)
        except Exception as e:
            self.logger.info("I am unable to connect to the database. " + str(e))
        # Test DB
        if conn is not None:
            cur = conn.cursor()
            cur.execute('select count(*) from pg_namespace')
            result = cur.fetchone()
            if result is None:
                self.logger.error('open_connection Failed to get count / use of database failed')
            else:
                self.logger.info('open_connection Got database connexion : ' + str(result[0]))
        else:
            self.logger.error('open_connection Failed to get database connexion')
        return conn

    def do_the_job(self, config):
        
        #liste_pays  = [ 'andorra', 'liechtenstein', 'guernsey-jersey']
        #liste_pays  = [  'isle-of-man', 'malta', 'faroe-islands', 'azores', 'macedonia', 'kosovo', 'cyprus', 'montenegro', 'luxembourg', 'albania', 'iceland', 'moldova', 'georgia', 'estonia', 'latvia', 'bulgaria', 'croatia', 'lithuania', 'serbia', 'hungary', 'romania', 'slovenia', 'slovakia', 'belarus', 'greece', 'ireland-and-northern-ireland', 'portugal', 'switzerland', 'monaco', 'turkey', 'finland', 'sweden', 'austria', 'ukraine', 'czech-republic', 'norway', 'united-kingdom']
        #liste_pays = [ 'baden-wuerttemberg', 'bayern', 'berlin', 'brandenburg', 'bremen', 'hamburg', 'hessen', 'mecklenburg-vorpommern', 'niedersachsen', 'nordrhein-westfalen', 'rheinland-pfalz', 'saarland', 'sachsen-anhalt', 'sachsen', 'schleswig-holstein', 'thueringen', 'scotland', 'wales','guernsey-jersey', 'england']
        #liste_pays = [  'hessen', 'mecklenburg-vorpommern', 'niedersachsen', 'nordrhein-westfalen', 'rheinland-pfalz', 'saarland', 'sachsen-anhalt', 'sachsen', 'schleswig-holstein', 'thueringen', 'scotland', 'wales','guernsey-jersey', 'england']
        #liste_pays  = ['guadeloupe', 'guyane', 'martinique', 'mayotte', 'reunion']
        #https://download.geofabrik.de/europe/france/guyane-latest.osm.pbf
        liste_pays  = ['canary-islands']
        liste_pays  = ['guyane']
        
        for pays in liste_pays:
            #pays = liste_pays[0]
            self.logger.info('------------------------------------------------------------------------------------------------')
            self.logger.info(pays)
            start = time.time()

            #0. Télécharger les données OSM (modifier l'URL en fonction - ici c'est dans le répertoire france)
            if True : 
                self.logger.info('calling download of {0} at {1}'.format(pays, datetime.datetime.now().isoformat()))

                param = '-P /data/osm/ https://download.geofabrik.de/europe/france/{0}-latest.osm.pbf'
                cmd = "/usr/bin/wget "+param.format(pays)
                self.logger.info(cmd)
                
                completed_process = subprocess.run(shlex.split(cmd), stdout=PIPE, stderr=PIPE)
                self.logger.info(completed_process.stdout)
                self.logger.warning(completed_process.stderr)
                self.logger.info('calling download of {0} at {1}'.format(pays, datetime.datetime.now().isoformat()))
                self.logger.info('--------------------------------------------------------- DURATION OF {0} IS {1}'.format(pays, time.time() - start))

        
            #1. Importer les données OSM


            self.logger.info('calling insert into DB of {0} at {1}'.format(pays, datetime.datetime.now().isoformat()))
            param = '-d osm -U postgres -c -s --drop  /data/osm/{0}-latest.osm.pbf'
            cmd = "/usr/bin/osm2pgsql "+param.format(pays)
            self.logger.info(cmd)
            
            
            completed_process = subprocess.run(shlex.split(cmd), stdout=PIPE, stderr=PIPE)
            self.logger.info(completed_process.stdout)
            self.logger.warning(completed_process.stderr)
            
            self.logger.info('end of insert into DB of {0} at {1}'.format(pays, datetime.datetime.now().isoformat()))
            self.logger.info('--------------------------------------------------------- DURATION OF {0} IS {1}'.format(pays, time.time() - start))

            #2. Les déplacer dans un schéma du nom du pays (avec underscore si tiret -)

            sql_query1 = 'create schema {0} '
            sql_query2 = 'alter table planet_osm_point set schema {0}'
            sql_query3 = 'alter table planet_osm_line set schema {0}'
            sql_query4 = 'alter table planet_osm_polygon set schema {0}'
            sql_query5 = 'alter table planet_osm_roads set schema {0}'

            conn = self.getConnection(config)
            cur = conn.cursor()
            try :
                cur.execute(sql_query1.format(pays.replace('-', '_')))    
                cur.execute(sql_query2.format(pays.replace('-', '_')))    
                cur.execute(sql_query3.format(pays.replace('-', '_')))    
                cur.execute(sql_query4.format(pays.replace('-', '_')))    
                cur.execute(sql_query5.format(pays.replace('-', '_')))    

                conn.commit()
            except Exception as e:
                self.logger.error(str(e))
            conn.close()

    
if __name__ == '__main__':
    # Passer en parametre le nom du fichier de configuration qui peut sinon être juste placé dans le répertoire du programme
    if len(sys.argv) == 2:
        configfile = sys.argv[1]
    else : 
        configfile = 'config_osm_05jan2025.txt'
    
    #nohup python feed_osm.py config_osm_05jan2025.txt > out05janvier.txt &
    config = configparser.RawConfigParser()
    config.read(configfile)
    print("Fichier de LOGS : " + config.get('log', 'file'))

    p = FeedOsm(config)
    p.do_the_job(config)