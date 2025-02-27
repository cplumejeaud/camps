'''
Auteur : Christine Plumejeaud, 16 février 2022
Objectif : l'import de shapes dans la base kurdistan
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


class FeedKurdistanDB(object):

    def __init__(self, config):
        ## Ouvrir le fichier de log
        logging.basicConfig(filename=config.get('log', 'file'), level=int(config.get('log', 'level')), filemode='w')
        self.logger = logging.getLogger('FeedKurdistanDB')
        self.logger.debug('log file for DEBUG')
        self.logger.info('log file for INFO')
        self.logger.warning('log file for WARNINGS')
        self.logger.error('log file for ERROR')

    def open_sshtunnel(self, config):
        '''
        https://asyncssh.readthedocs.io/en/latest/ A UTILISER à la place de SSHHandler
         #https://github.com/paramiko/paramiko/blob/master/demos/forward.py
        #http://stackoverflow.com/questions/8169739/how-to-create-a-ssh-tunnel-using-python-and-paramiko
    
        Example: this command: "ssh -L 5555:machine2:55 machine1" will connect to machine1:22 and it will forward any
        connection from your computer:5555 through machine1:22 to machine2:55.
        Suppose you want to forward your own ssh service to another port, the command to do that is:
        "ssh -L 5555:localhost:22 localhost".
        So if you do "ssh localhost -p 5555" it will connect you to your own localhost:22.
        To do that using the paramiko "forward.py" demo, you have to run it this way:
        "python forward.py localhost -p 5555 -r localhost:22".
        Execute it and in another terminal run ssh localhost -p 5555
    
        :param config:
        :return:
        '''



        server = []
        server.append(config.get('ssh', 'server'))
        server.append(int(config.get('ssh', 'port')))
        ## SSH
        #print(config.get('ssh', 'server'))
        #print(config.get('ssh', 'port'))

        remote = []
        remote.append(config.get('ssh', 'postgres_server'))
        remote.append(int(config.get('ssh', 'postgres_port')))
        ##FORWARDS
        #print(config.get('ssh', 'postgres_server'))
        #print(config.get('ssh', 'postgres_port'))

        user = config.get('ssh', 'user')
        ppk=config.get('ssh', 'ppk')
        passwd=config.get('ssh', 'passwd')

        port=int(config.get('base', 'port'))

        #print(config.get('ssh', 'user'))
        #print(config.get('ssh', 'ppk'))

        #self.ssh = SSHHandler(config)
        self.ssh.openTunnel(server, remote, user, ppk, passwd, port)

    def open_connection(self, config):
        '''
        Open database connection with Postgres
        :param config:
        :return:
        '''
        # Acceder aux parametres de configuration
        host = config.get('base', 'host')
        port = config.get('base', 'port')
        dbname = config.get('base', 'dbname')
        superuser = config.get('base', 'superuser')
        password = config.get('base', 'superuserpass')
        driverPostgres = 'host=' + host + ' port=' + port + ' user=' + superuser + ' dbname=' + dbname + ' password=' + password
        #driverPostgres = driverPostgres + ' options="-c search_path='+schema+',public"'
        self.logger.debug(driverPostgres)
    
        try:
            conn = psycopg2.connect(driverPostgres)
        except Exception as e:
            self.logger.error("I am unable to connect to the database. " + str(e))
        return conn

    def sqlexec(self, config):
        conn = self.open_connection(config)
        curs = conn.cursor()

        user = config.get('base', 'user')
        schema = config.get('base', 'schema')

        sql=f"""create schema if not exists {schema}"""
        curs.execute(sql)
        
        sql=f"""GRANT ALL ON SCHEMA {schema} TO {user}"""
        curs.execute(sql)

        sql=f"""GRANT ALL ON ALL SEQUENCES  IN SCHEMA {schema} TO {user}"""
        curs.execute(sql)

        sql=f"""ALTER SCHEMA {schema} OWNER TO {user}"""
        curs.execute(sql)
        

        conn.commit()
        curs.close()
        conn.close()

    def addreaduser(self, config):
        conn = self.open_connection(config)
        curs = conn.cursor()

        user = config.get('base', 'userReader')
        schema = config.get('base', 'schema')
        
        sql=f"""GRANT USAGE ON SCHEMA {schema} TO {user}"""
        curs.execute(sql)

        sql=f"""GRANT select ON ALL SEQUENCES  IN SCHEMA {schema} TO {user}"""
        curs.execute(sql)

        sql=f"""GRANT select ON ALL TABLES  IN SCHEMA {schema} TO {user}"""
        curs.execute(sql)
        
        conn.commit()
        curs.close()
        conn.close()

    def import_geodatabase(self, config, directory, inputfile):
        #https://gis.stackexchange.com/questions/385754/how-to-import-gdb-to-postgresql-into-separate-tables
        #https://gdal.org/drivers/vector/pg.html

        host = config.get('base', 'host')
        port = config.get('base', 'port')
        dbname = config.get('base', 'dbname')
        user = config.get('base', 'user')
        password = config.get('base', 'password')

        schema = config.get('base', 'schema').lower()
        epsg = config.get('files', 'epsg')     

        #si GEOM_TYPE == MultiSurface ou Multi Curve : -nlt CONVERT_TO_LINEAR règle le pb
        #https://gdal.org/programs/ogr2ogr.html
        cmdBase = '/usr/bin/ogr2ogr -overwrite --config OGR_TRUNCATE YES --config PG_USE_COPY YES \
            -nlt PROMOTE_TO_MULTI -nlt CONVERT_TO_LINEAR \
            -nln {schema}.{table} \
            -f "PostgreSQL" PG:"host={host} port={port} user={user} password={password} dbname={database}" \
            "{inputFile}" "{layerName}"'
        if epsg is not None and len(epsg) >= 4:
            print("Forcing to EPSG :"+epsg)
            cmdBase = '/usr/bin/ogr2ogr -overwrite --config OGR_TRUNCATE YES --config PG_USE_COPY YES \
                -nlt PROMOTE_TO_MULTI -nlt CONVERT_TO_LINEAR \
                -nln {schema}.{table} \
                -f "PostgreSQL" PG:"host={host} port={port} user={user} password={password} dbname={database}" \
                -a_srs {srs} "{inputFile}" "{layerName}"'


        for layerName in fiona.listlayers(directory+'/'+inputfile):
            #new table name corresponds to layerName. You can change it here
            table=layerName
            print(layerName)

            cmd = cmdBase.format(inputFile=directory+'/'+inputfile, schema=schema, table=table, host=host, port=port, user=user, password=password, database=dbname, srs=epsg, layerName=layerName)
            
            #run system command
            #if layerName == 'perimetre_KRG_2017' : #or layerName == 'SecondaryStreams' : 
            print(cmd)
            self.execute_commande(cmd)

            #Geometry type (MultiSurface) does not match column type (MultiPolygon)
            #Warning 1: organizePolygons() received a polygon with more than 100 parts. The processing may be really slow.  You can skip the processing by setting METHOD=SKIP, or only make it analyze counter-clock wise parts by setting METHOD=ONLY_CCW if you can assume that the outline of holes is counter-clock wise defined


    def execute_commande(self, cmd):
        """
        sship = config.get('ssh', 'sship')
        sshuser = config.get('ssh', 'sshuser')
        sshpassword = config.get('ssh', 'sshpassword')

        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        try:
            ssh.connect(sship, username=sshuser, password=sshpassword)
        except paramiko.SSHException:
            print(f'Connection Failed to {syst} ({ip})')
        except:
            print('Souci de connexion ssh')
        """

        #https://stackoverflow.com/questions/89228/how-to-execute-a-program-or-call-a-system-command
        #subprocess.run([])
        os.system('export PGCLIENTENCODING=utf8')
        #os.system(cmd)
        #subprocess.run([cmd])
        self.logger.info(cmd)
        completed_process = subprocess.run(shlex.split(cmd), stdout=PIPE, stderr=PIPE)
        self.logger.info(completed_process.stdout)
        self.logger.warning(completed_process.stderr)

        #
        # stdin, stdout, stderrst = ssh.exec_command(f"""export PGCLIENTENCODING=utf8;ogr2ogr -f "PostgreSQL" PG:"host={host} port={port} user={user} dbname={dbname} password={password} schemas={schema}" {directory}/{shapefile} -a_srs EPSG:{epsg}""")
        # ssh.close()

    def import_shapefile(self, config, directory, shapefile):
        

        host = config.get('base', 'host')
        port = config.get('base', 'port')
        dbname = config.get('base', 'dbname')
        user = config.get('base', 'user')
        password = config.get('base', 'password')

        schema = config.get('base', 'schema').lower()
        epsg = config.get('files', 'epsg')     
        table = shapefile[:shapefile.find('.')]

        #https://gis.stackexchange.com/questions/254671/ogr2ogr-error-importing-shapefile-into-postgis-numeric-field-overflow
        cmd = f"""/usr/bin/ogr2ogr -f "PostgreSQL" PG:"host={host} port={port} user={user} dbname={dbname} password={password} schemas={schema}" {directory}{shapefile}  -nln {schema}.{table} -nlt PROMOTE_TO_MULTI -overwrite -lco precision=NO"""
        if epsg is not None and len(epsg) >= 4:
            print("Forcing to EPSG :"+epsg)
            cmd = f"""/usr/bin/ogr2ogr -f "PostgreSQL" PG:"host={host} port={port} user={user} dbname={dbname} password={password} schemas={schema}" {directory}{shapefile} -a_srs EPSG:{epsg} -nln {schema}.{table} -nlt PROMOTE_TO_MULTI -overwrite -lco precision=NO"""

        #print(cmd)
        
        self.execute_commande(cmd)


    def do_the_job(self, config):
        self.sqlexec(config)

        rootdir = config.get('files', 'path2originals')
        withRecursive=json.loads(config.get('files', 'withRecursive').lower())
        print(withRecursive)
        if (not withRecursive):
            with os.scandir(rootdir) as it:
                for entry in it:
                    if not entry.name.startswith('.') and entry.name.endswith('.shp') and entry.is_file():
                        print(entry.name)
                        self.import_shapefile(config, rootdir, entry.name)
                    if  entry.name.endswith('.gdb') :
                        print(entry.name)
                        self.import_geodatabase(config, rootdir, entry.name)
        else :
            for folder, subs, files in os.walk(rootdir):
                self.logger.info("############ Traitement du répertoire :"+folder)
                for filename in files:
                    if not filename.startswith('.') and filename.endswith('.shp'):
                        self.logger.info(os.path.join(folder, filename))
                        print(filename)
                        self.import_shapefile(config, folder, filename)
                    if not filename.startswith('.') and filename.endswith('.gdb'):
                        self.logger.info(os.path.join(folder, filename))
                        print(filename)
                        self.import_geodatabase(config, folder, filename)
        
        self.addreaduser(config)

if __name__ == '__main__':
    # Passer en parametre le nom du fichier de configuration qui peut sinon être juste placé dans le répertoire du programme
    if len(sys.argv) == 2:
        configfile = sys.argv[1]
    else : 
        configfile = 'config_kurdistan.txt'
    
    config = configparser.RawConfigParser()
    config.read(configfile)
    print("Fichier de LOGS : " + config.get('log', 'file'))

    p = FeedKurdistanDB(config)
    p.do_the_job(config)
